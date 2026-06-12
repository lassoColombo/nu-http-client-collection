# Auto-generated client for Uptime.com OpenAPI Schema v
# Source: https://uptime.com/api/v1/openapi/
# Auth: --token flag or $env.UPTIME_COM_OPENAPI_SCHEMA_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o UPTIME_COM_OPENAPI_SCHEMA_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def ordering-completer [] { ["-created_at" "created_at"] }
def check-monitoring-service-type-completer [] { ["API" "BLACKLIST" "CLOUDSTATUS" "DNS" "FTP" "GROUP" "HEARTBEAT" "HTTP" "ICMP" "IMAP" "MALWARE" "NTP" "PAGESPEED" "POP" "RDAP" "RUM2" "SFTP" "SMTP" "SSH" "SSL_CERT" "TCP" "TRANSACTION" "UDP" "WEBHOOK" "WHOIS"] }
def ordering-completer-1 [] { ["-pk" "-tag" "pk" "tag"] }
def ordering-completer-2 [] { ["-address" "-created_at" "-monitoring_service_type" "-name" "-pk" "address" "created_at" "monitoring_service_type" "name" "pk"] }
def monitoring-service-type-completer [] { ["API" "BLACKLIST" "CLOUDSTATUS" "DNS" "FTP" "GROUP" "HEARTBEAT" "HTTP" "ICMP" "IMAP" "MALWARE" "NTP" "PAGESPEED" "POP" "RDAP" "RUM2" "SFTP" "SMTP" "SSH" "SSL_CERT" "TCP" "TRANSACTION" "UDP" "WEBHOOK" "WHOIS"] }
def msp-use-ip-version-completer [] { ["" "IPV4" "IPV6"] }
def msp-dns-record-type-completer [] { ["A" "AAAA" "ANY" "CNAME" "MX" "NS" "PTR" "SOA" "TXT"] }
def msp-expect-string-type-completer [] { ["INVERSE_REGEX" "REGEX" "STRING"] }
def msp-encryption-completer [] { ["" "SSL_TLS"] }
def monitoring-service-type-completer-1 [] { ["API" "BLACKLIST" "DNS" "FTP" "HTTP" "ICMP" "IMAP" "MALWARE" "NTP" "PAGESPEED" "POP" "RDAP" "SFTP" "SMTP" "SSH" "SSL_CERT" "TCP" "TRANSACTION" "UDP" "WHOIS"] }
def state-completer [] { ["ACTIVE" "SCHEDULED" "SUPPRESSED"] }
def ordering-completer-3 [] { ["-created_at" "-name" "-pk" "created_at" "name" "pk"] }
def ordering-completer-4 [] { ["-display_name" "-pk" "display_name" "pk"] }
def credential-type-completer [] { ["BASIC" "CERTIFICATE" "TOKEN"] }
def ordering-completer-5 [] { ["-name" "-ordering" "-pk" "name" "ordering" "pk"] }
def services-num-to-show-completer [] { ["12" "16" "20" "24" "4" "8"] }
def services-primary-sort-completer [] { ["-cached_last_down_alert_at" "-cached_response_time" "-created_at" "cached_ordering" "device__address" "is_paused,cached_state_is_up"] }
def services-secondary-sort-completer [] { ["-cached_last_down_alert_at" "-cached_response_time" "-created_at" "cached_ordering" "device__address" "is_paused,cached_state_is_up"] }
def alerts-num-to-show-completer [] { ["10" "15" "5"] }
def ordering-completer-6 [] { ["-module" "-name" "-pk" "module" "name" "pk"] }
def module-completer [] { ["cachet" "datadog" "discord" "geckoboard" "google_chat" "grafana_graphite" "grafana_prometheus" "ilert" "jiraservicedesk" "klipfolio" "logz" "make" "microsoft_teams" "opsgenie" "pagerduty" "pushbullet" "pushover" "slack" "status" "statuspage" "telegram" "victorops" "wavefront" "webhook" "zapier" "zendesk"] }
def region-completer [] { ["AP1" "EU" "US" "US3" "US5"] }
def priority-completer [] { ["-1" "-2" "0" "1" "2"] }
def priority-completer-1 [] { ["" "high" "low" "normal" "urgent"] }
def ticket-type-completer [] { ["" "incident" "problem" "question" "task"] }
def accept-completer [] { ["application/json" "text/plain"] }
def ordering-completer-7 [] { ["-created_at" "-display_name" "-pk" "created_at" "display_name" "pk"] }
def file-type-completer [] { ["PDF" "XLS"] }
def recurrence-completer [] { ["DAILY" "MONTHLY" "QUARTERLY" "WEEKLY" "YEARLY"] }
def default-date-range-override-completer [] { ["LAST_30D" "LAST_7D" "LAST_MONTH" "LAST_QUARTER" "LAST_WEEK" "LAST_YEAR" "THIS_MONTH" "THIS_QUARTER" "THIS_WEEK" "THIS_YEAR" "TODAY" "YESTERDAY"] }
def on-weekday-completer [] { ["1" "2" "3" "4" "5" "6" "7"] }
def at-time-completer [] { ["0" "1" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "2" "20" "21" "22" "23" "3" "4" "5" "6" "7" "8" "9"] }
def ordering-completer-8 [] { ["-pk" "-property_name" "-variable_name" "pk" "property_name" "variable_name"] }
def default-date-range-completer [] { ["LAST_30D" "LAST_7D" "LAST_MONTH" "LAST_WEEK" "THIS_MONTH" "THIS_WEEK" "TODAY" "YESTERDAY"] }
def uptime-section-sort-completer [] { ["BY_SLA" "BY_UPTIME"] }
def response-time-section-sort-completer [] { ["BY_RESPONSE_TIME" "BY_SLA"] }
def output-completer [] { ["json" "pdf" "xls"] }
def ordering-completer-9 [] { ["-cname" "-name" "-pk" "-slug" "cname" "name" "pk" "slug"] }
def visibility-level-completer [] { ["EXTERNAL_USERS" "PUBLIC" "UPTIME_USERS"] }
def page-type-completer [] { ["INTERNAL" "PUBLIC" "PUBLIC_SLA"] }
def uptime-calculation-type-completer [] { ["BY_CHECKS" "BY_INCIDENTS"] }
def layout-preset-completer [] { ["COMPACT" "EXPANDED"] }
def timezone-completer [] { ["Africa/Abidjan" "Africa/Accra" "Africa/Addis_Ababa" "Africa/Algiers" "Africa/Asmara" "Africa/Bamako" "Africa/Bangui" "Africa/Banjul" "Africa/Bissau" "Africa/Blantyre" "Africa/Brazzaville" "Africa/Bujumbura" "Africa/Cairo" "Africa/Casablanca" "Africa/Ceuta" "Africa/Conakry" "Africa/Dakar" "Africa/Dar_es_Salaam" "Africa/Djibouti" "Africa/Douala" "Africa/El_Aaiun" "Africa/Freetown" "Africa/Gaborone" "Africa/Harare" "Africa/Johannesburg" "Africa/Juba" "Africa/Kampala" "Africa/Khartoum" "Africa/Kigali" "Africa/Kinshasa" "Africa/Lagos" "Africa/Libreville" "Africa/Lome" "Africa/Luanda" "Africa/Lubumbashi" "Africa/Lusaka" "Africa/Malabo" "Africa/Maputo" "Africa/Maseru" "Africa/Mbabane" "Africa/Mogadishu" "Africa/Monrovia" "Africa/Nairobi" "Africa/Ndjamena" "Africa/Niamey" "Africa/Nouakchott" "Africa/Ouagadougou" "Africa/Porto-Novo" "Africa/Sao_Tome" "Africa/Tripoli" "Africa/Tunis" "Africa/Windhoek" "America/Adak" "America/Anchorage" "America/Anguilla" "America/Antigua" "America/Araguaina" "America/Argentina/Buenos_Aires" "America/Argentina/Catamarca" "America/Argentina/Cordoba" "America/Argentina/Jujuy" "America/Argentina/La_Rioja" "America/Argentina/Mendoza" "America/Argentina/Rio_Gallegos" "America/Argentina/Salta" "America/Argentina/San_Juan" "America/Argentina/San_Luis" "America/Argentina/Tucuman" "America/Argentina/Ushuaia" "America/Aruba" "America/Asuncion" "America/Atikokan" "America/Bahia" "America/Bahia_Banderas" "America/Barbados" "America/Belem" "America/Belize" "America/Blanc-Sablon" "America/Boa_Vista" "America/Bogota" "America/Boise" "America/Cambridge_Bay" "America/Campo_Grande" "America/Cancun" "America/Caracas" "America/Cayenne" "America/Cayman" "America/Chicago" "America/Chihuahua" "America/Ciudad_Juarez" "America/Costa_Rica" "America/Creston" "America/Cuiaba" "America/Curacao" "America/Danmarkshavn" "America/Dawson" "America/Dawson_Creek" "America/Denver" "America/Detroit" "America/Dominica" "America/Edmonton" "America/Eirunepe" "America/El_Salvador" "America/Fort_Nelson" "America/Fortaleza" "America/Glace_Bay" "America/Goose_Bay" "America/Grand_Turk" "America/Grenada" "America/Guadeloupe" "America/Guatemala" "America/Guayaquil" "America/Guyana" "America/Halifax" "America/Havana" "America/Hermosillo" "America/Indiana/Indianapolis" "America/Indiana/Knox" "America/Indiana/Marengo" "America/Indiana/Petersburg" "America/Indiana/Tell_City" "America/Indiana/Vevay" "America/Indiana/Vincennes" "America/Indiana/Winamac" "America/Inuvik" "America/Iqaluit" "America/Jamaica" "America/Juneau" "America/Kentucky/Louisville" "America/Kentucky/Monticello" "America/Kralendijk" "America/La_Paz" "America/Lima" "America/Los_Angeles" "America/Lower_Princes" "America/Maceio" "America/Managua" "America/Manaus" "America/Marigot" "America/Martinique" "America/Matamoros" "America/Mazatlan" "America/Menominee" "America/Merida" "America/Metlakatla" "America/Mexico_City" "America/Miquelon" "America/Moncton" "America/Monterrey" "America/Montevideo" "America/Montserrat" "America/Nassau" "America/New_York" "America/Nome" "America/Noronha" "America/North_Dakota/Beulah" "America/North_Dakota/Center" "America/North_Dakota/New_Salem" "America/Nuuk" "America/Ojinaga" "America/Panama" "America/Paramaribo" "America/Phoenix" "America/Port-au-Prince" "America/Port_of_Spain" "America/Porto_Velho" "America/Puerto_Rico" "America/Punta_Arenas" "America/Rankin_Inlet" "America/Recife" "America/Regina" "America/Resolute" "America/Rio_Branco" "America/Santarem" "America/Santiago" "America/Santo_Domingo" "America/Sao_Paulo" "America/Scoresbysund" "America/Sitka" "America/St_Barthelemy" "America/St_Johns" "America/St_Kitts" "America/St_Lucia" "America/St_Thomas" "America/St_Vincent" "America/Swift_Current" "America/Tegucigalpa" "America/Thule" "America/Tijuana" "America/Toronto" "America/Tortola" "America/Vancouver" "America/Whitehorse" "America/Winnipeg" "America/Yakutat" "Asia/Aden" "Asia/Almaty" "Asia/Amman" "Asia/Anadyr" "Asia/Aqtau" "Asia/Aqtobe" "Asia/Ashgabat" "Asia/Atyrau" "Asia/Baghdad" "Asia/Bahrain" "Asia/Baku" "Asia/Bangkok" "Asia/Barnaul" "Asia/Beirut" "Asia/Bishkek" "Asia/Brunei" "Asia/Chita" "Asia/Choibalsan" "Asia/Colombo" "Asia/Damascus" "Asia/Dhaka" "Asia/Dili" "Asia/Dubai" "Asia/Dushanbe" "Asia/Famagusta" "Asia/Gaza" "Asia/Hebron" "Asia/Ho_Chi_Minh" "Asia/Hong_Kong" "Asia/Hovd" "Asia/Irkutsk" "Asia/Jakarta" "Asia/Jayapura" "Asia/Jerusalem" "Asia/Kabul" "Asia/Kamchatka" "Asia/Karachi" "Asia/Kathmandu" "Asia/Khandyga" "Asia/Kolkata" "Asia/Krasnoyarsk" "Asia/Kuala_Lumpur" "Asia/Kuching" "Asia/Kuwait" "Asia/Macau" "Asia/Magadan" "Asia/Makassar" "Asia/Manila" "Asia/Muscat" "Asia/Nicosia" "Asia/Novokuznetsk" "Asia/Novosibirsk" "Asia/Omsk" "Asia/Oral" "Asia/Phnom_Penh" "Asia/Pontianak" "Asia/Pyongyang" "Asia/Qatar" "Asia/Qostanay" "Asia/Qyzylorda" "Asia/Riyadh" "Asia/Sakhalin" "Asia/Samarkand" "Asia/Seoul" "Asia/Shanghai" "Asia/Singapore" "Asia/Srednekolymsk" "Asia/Taipei" "Asia/Tashkent" "Asia/Tbilisi" "Asia/Tehran" "Asia/Thimphu" "Asia/Tokyo" "Asia/Tomsk" "Asia/Ulaanbaatar" "Asia/Urumqi" "Asia/Ust-Nera" "Asia/Vientiane" "Asia/Vladivostok" "Asia/Yakutsk" "Asia/Yangon" "Asia/Yekaterinburg" "Asia/Yerevan" "Atlantic/Azores" "Atlantic/Bermuda" "Atlantic/Canary" "Atlantic/Cape_Verde" "Atlantic/Faroe" "Atlantic/Madeira" "Atlantic/Reykjavik" "Atlantic/South_Georgia" "Atlantic/St_Helena" "Atlantic/Stanley" "Australia/Adelaide" "Australia/Brisbane" "Australia/Broken_Hill" "Australia/Darwin" "Australia/Eucla" "Australia/Hobart" "Australia/Lindeman" "Australia/Lord_Howe" "Australia/Melbourne" "Australia/Perth" "Australia/Sydney" "Europe/Amsterdam" "Europe/Andorra" "Europe/Astrakhan" "Europe/Athens" "Europe/Belgrade" "Europe/Berlin" "Europe/Bratislava" "Europe/Brussels" "Europe/Bucharest" "Europe/Budapest" "Europe/Busingen" "Europe/Chisinau" "Europe/Copenhagen" "Europe/Dublin" "Europe/Gibraltar" "Europe/Guernsey" "Europe/Helsinki" "Europe/Isle_of_Man" "Europe/Istanbul" "Europe/Jersey" "Europe/Kaliningrad" "Europe/Kiev" "Europe/Kirov" "Europe/Kyiv" "Europe/Lisbon" "Europe/Ljubljana" "Europe/London" "Europe/Luxembourg" "Europe/Madrid" "Europe/Malta" "Europe/Mariehamn" "Europe/Minsk" "Europe/Monaco" "Europe/Moscow" "Europe/Oslo" "Europe/Paris" "Europe/Podgorica" "Europe/Prague" "Europe/Riga" "Europe/Rome" "Europe/Samara" "Europe/San_Marino" "Europe/Sarajevo" "Europe/Saratov" "Europe/Simferopol" "Europe/Skopje" "Europe/Sofia" "Europe/Stockholm" "Europe/Tallinn" "Europe/Tirane" "Europe/Ulyanovsk" "Europe/Uzhgorod" "Europe/Vaduz" "Europe/Vatican" "Europe/Vienna" "Europe/Vilnius" "Europe/Volgograd" "Europe/Warsaw" "Europe/Zagreb" "Europe/Zurich" "GMT" "Indian/Antananarivo" "Indian/Chagos" "Indian/Christmas" "Indian/Cocos" "Indian/Comoro" "Indian/Kerguelen" "Indian/Mahe" "Indian/Maldives" "Indian/Mauritius" "Indian/Mayotte" "Indian/Reunion" "Pacific/Apia" "Pacific/Auckland" "Pacific/Bougainville" "Pacific/Chatham" "Pacific/Chuuk" "Pacific/Easter" "Pacific/Efate" "Pacific/Fakaofo" "Pacific/Fiji" "Pacific/Funafuti" "Pacific/Galapagos" "Pacific/Gambier" "Pacific/Guadalcanal" "Pacific/Guam" "Pacific/Honolulu" "Pacific/Kanton" "Pacific/Kiritimati" "Pacific/Kosrae" "Pacific/Kwajalein" "Pacific/Majuro" "Pacific/Marquesas" "Pacific/Midway" "Pacific/Nauru" "Pacific/Niue" "Pacific/Norfolk" "Pacific/Noumea" "Pacific/Pago_Pago" "Pacific/Palau" "Pacific/Pitcairn" "Pacific/Pohnpei" "Pacific/Port_Moresby" "Pacific/Rarotonga" "Pacific/Saipan" "Pacific/Tahiti" "Pacific/Tarawa" "Pacific/Tongatapu" "Pacific/Wake" "Pacific/Wallis" "US/Alaska" "US/Arizona" "US/Central" "US/Eastern" "US/Hawaii" "US/Mountain" "US/Pacific" "UTC"] }
def theme-completer [] { ["INSPIRE"] }
def status-completer [] { ["degraded-performance" "major-outage" "operational" "partial-outage" "under-maintenance"] }
def auto-status-down-completer [] { ["degraded-performance" "major-outage" "partial-outage" "under-maintenance"] }
def auto-status-up-completer [] { ["degraded-performance" "major-outage" "operational" "partial-outage" "under-maintenance"] }
def incident-type-completer [] { ["INCIDENT" "SCHEDULED_MAINTENANCE"] }
def ordering-completer-10 [] { ["-pk" "-starts_at" "pk" "starts_at"] }
def incident-state-completer [] { ["identified" "investigating" "maintenance" "monitoring" "notification" "resolved"] }
def type-completer [] { ["EMAIL" "SLACK" "SMS" "WEBHOOK"] }
def ordering-completer-11 [] { ["-email" "-first_name" "-last_name" "-pk" "email" "first_name" "last_name" "pk"] }
def access-level-completer [] { ["10-READ" "30-WRITE" "50-ADMIN"] }
def require-two-factor-completer [] { ["ACCOUNT_DEFAULT" "DO_NOT_REQUIRE" "REQUIRE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "alerts alertlist" } } | get name | first)
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

# List all alerts
#
# GET /api/v1/alerts/
# operationId: get_alertlist
export def "alerts alertlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer # Order results by this field.
  --state-is-up: oneof<nothing, bool> # Filter by alert state up/down.
  --check-pk: float # Filter by check ID.
  --check-monitoring-service-type: string@check-monitoring-service-type-completer # Filter by check type.
  --check-tag: string # Filter by tag name (can be specified multiple times.)
  --start-date: string # Start date in ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) format.
  --end-date: string # End date in ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) format.
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, url: string, created_at: string, ignore_alert_url: string, check_pk: int, check_url: string, check_address: string, check_name: string, check_monitoring_service_type: string, check_is_paused: bool, state_is_up: bool, ignored: bool, num_locations_down: int, all_alerts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "state_is_up" $state_is_up "scalar") (serialize-qp "check_pk" $check_pk "scalar") (serialize-qp "check_monitoring_service_type" $check_monitoring_service_type "scalar") (serialize-qp "check_tag" $check_tag "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/alerts/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details of an alert for a specific location along with any root cause analysis data
#
# GET /api/v1/alerts/alert/{pk}/root-cause/
# operationId: get_alert_alert_root_cause
export def "alerts-alert-root-cause cause" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/alerts/alert/($pk)/root-cause/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details of a single alert
#
# GET /api/v1/alerts/{pk}/
# operationId: get_alert_detail
export def "alerts detail" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, created_at: string, ignore_alert_url: string, check_pk: int, check_url: string, check_address: string, check_name: string, check_monitoring_service_type: string, check_is_paused: bool, state_is_up: bool, ignored: bool, num_locations_down: int, all_alerts: table<pk: int, url: string, created_at: string, monitoring_server_name: string, monitoring_server_ipv4: string, monitoring_server_ipv6: string, location: string, output: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/alerts/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Toggle the ignore state of an alert
#
# POST /api/v1/alerts/{pk}/ignore/
# operationId: post_alert_ignore
export def "alerts-ignore ignore" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/alerts/($pk)/ignore/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provides APIs for generating access tokens
#
# GET /api/v1/auth/
# operationId: get_auth_list
export def "auth list" [
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
  let full_url = (build-url $base "/api/v1/auth/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download a CSV showing detailed usage info of your current plan.
#
# GET /api/v1/auth/account-usage/
# operationId: get_auth_account_usage
export def "auth-account-usage usage" [
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
  let full_url = (build-url $base "/api/v1/auth/account-usage/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shows the details of the authenticated user
#
# GET /api/v1/auth/me/
# operationId: get_auth_me
export def "auth-me me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, first_name: string, last_name: string, email: string, password: string, is_active: bool, is_primary: bool, access_level: string, is_api_enabled: bool, notify_paid_invoices: bool, assigned_subaccounts: list<string>, require_two_factor: string, must_two_factor: string, timezone: string, account: record<name: string, timezone: string, data_region: string, free_trial_expires_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/me/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all subaccounts of this account  You may select the active subaccount for any API request by using a HTTP header or query string parameter to specify the subaccount ID as follows:  <pre>https://uptime.com/api/v1/dashboard/?subaccount=123</pre>  or  <pre>curl -H "X-Subaccount: 123" -H "Authorization: token xxxx" https://uptime.com/api/v1/dashboard/</pre>  <br />
#
# GET /api/v1/auth/subaccounts/
# operationId: get_auth_subaccounts
export def "auth-subaccounts subaccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<pk: int, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/subaccounts/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new subaccount  Creates a new subaccount for this account which includes one pack which is deducted from the main account.
#
# POST /api/v1/auth/subaccounts/
# operationId: post_auth_subaccounts
export def "auth-subaccounts subaccounts-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> record<pk: int, name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/auth/subaccounts/")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get subaccount details
#
# GET /api/v1/auth/subaccounts/{pk}/
# operationId: get_auth_subaccount
export def "auth-subaccounts subaccount-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/subaccounts/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Renames subaccount
#
# PATCH /api/v1/auth/subaccounts/{pk}/
# operationId: patch_auth_subaccount
export def "auth-subaccounts subaccount-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> record<pk: int, name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/subaccounts/($pk)/")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Transfers packs to subaccount from main account and vice versa  If num is positive packs are transferred from main account to subaccount. If num is negative packs are deducted from subaccount and added to the main account.
#
# POST /api/v1/auth/subaccounts/{pk}/allocation/
# operationId: post_auth_subaccount_packs
export def "auth-subaccounts-allocation packs" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  num: int # Number of packs to be transferred
]: any -> record<num: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/auth/subaccounts/($pk)/allocation/")
  let body = {num: $num} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all tags
#
# GET /api/v1/check-tags/
# operationId: get_servicetaglist
export def "check-tags servicetaglist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-1 # Order results by this field.
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, url: string, tag: string, color_hex: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/check-tags/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new tag
#
# POST /api/v1/check-tags/
# operationId: post_servicetaglist
export def "check-tags servicetaglist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tag: string # The name of this tag
  color_hex: string # The CSS color code of the tag, eg. #334455
]: any -> record<pk: int, url: string, tag: string, color_hex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/check-tags/")
  let body = {tag: $tag, color_hex: $color_hex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single tag
#
# GET /api/v1/check-tags/{pk}/
# operationId: get_service_tag_detail
export def "check-tags detail-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, tag: string, color_hex: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/check-tags/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a tag
#
# PUT /api/v1/check-tags/{pk}/
# operationId: put_service_tag_detail
export def "check-tags detail-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tag: string # The name of this tag
  color_hex: string # The CSS color code of the tag, eg. #334455
]: any -> record<pk: int, url: string, tag: string, color_hex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/check-tags/($pk)/")
  let body = {tag: $tag, color_hex: $color_hex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a tag
#
# PATCH /api/v1/check-tags/{pk}/
# operationId: patch_service_tag_detail
export def "check-tags detail-by-pk-2" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tag: string # The name of this tag
  color_hex: string # The CSS color code of the tag, eg. #334455
]: any -> record<pk: int, url: string, tag: string, color_hex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/check-tags/($pk)/")
  let body = {tag: $tag, color_hex: $color_hex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a tag
#
# DELETE /api/v1/check-tags/{pk}/
# operationId: delete_service_tag_detail
export def "check-tags detail-by-pk-3" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/check-tags/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all checks
#
# GET /api/v1/checks/
# operationId: get_servicelist
export def "checks servicelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-2 # Order results by this field.
  --monitoring-service-type: string@monitoring-service-type-completer # Filter by check type.
  --is-paused: oneof<nothing, bool> # Filter by paused status.
  --is-under-maintenance: oneof<nothing, bool> # Filter for checks currently under maintenance.
  --state-is-up: oneof<nothing, bool> # Filter by check up/down state.
  --has-maintenance-schedule: oneof<nothing, bool> # Filter by checks that have a maintenance schedule.
  --tag: string # Filter by tag name (can be specified multiple times.)
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list, created_at: string, modified_at: string, locations: list, tags: list, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list, msp_interval: int, msp_address: string, msp_port: int, msp_username: string, msp_password: string, msp_proxy: string, msp_dns_server: string, msp_dns_record_type: string, msp_status_code: string, msp_send_string: string, msp_expect_string: string, msp_expect_string_type: string, msp_encryption: string, msp_threshold: int, msp_headers: string, msp_script: string, msp_version: int, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool, webhook_url: string, heartbeat_url: string, rumconfig: record, groupcheckconfig: record, sslconfig: record, pagespeedconfig: record, cloudstatusconfig: record, ftpconfig: record, sftpconfig: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "monitoring_service_type" $monitoring_service_type "scalar") (serialize-qp "is_paused" $is_paused "scalar") (serialize-qp "is_under_maintenance" $is_under_maintenance "scalar") (serialize-qp "state_is_up" $state_is_up "scalar") (serialize-qp "has_maintenance_schedule" $has_maintenance_schedule "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/checks/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new API check
#
# POST /api/v1/checks/add-api/
# operationId: post_service_create_api
export def "checks-add-api api" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  --msp-threshold: int # nullable, default: 30
  msp_script: string
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-use-ip-version: string@msp-use-ip-version-completer # default: 
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 4.0
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_threshold: int, msp_script: string, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-api/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_threshold: $msp_threshold, msp_script: $msp_script, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_use_ip_version: $msp_use_ip_version, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Domain Blacklist check
#
# POST /api/v1/checks/add-blacklist/
# operationId: post_service_create_blacklist
export def "checks-add-blacklist blacklist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Locations are auto-assigned for this check type if left empty or omitted. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_address: string
  --msp-num-retries: int # default: 2
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-notes: string
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_address: string, msp_num_retries: int, msp_uptime_sla: string, msp_notes: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-blacklist/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_address: $msp_address, msp_num_retries: $msp_num_retries, msp_uptime_sla: $msp_uptime_sla, msp_notes: $msp_notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Cloud Status check
#
# POST /api/v1/checks/add-cloudstatus/
# operationId: post_service_create_cloudstatus
# --cloudstatusconfig shape: {notify_only_on_down?: bool, service_name?: string, group?: int, monitoring_type?: "ALL"|"SPECIFIC", services?: list, service_titles?: list}
export def "checks-add-cloudstatus cloudstatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  cloudstatusconfig: record # shape: {notify_only_on_down?: bool, service_name?: string, group?: int, monitoring_type?: "ALL"|"SPECIFIC", services?: list, service_titles?: list}
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, cloudstatusconfig: record<notify_only_on_down: bool, service_name: string, group: int, monitoring_type: string, services: list<int>, service_titles: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-cloudstatus/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, cloudstatusconfig: $cloudstatusconfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new DNS check
#
# POST /api/v1/checks/add-dns/
# operationId: post_service_create_dns
export def "checks-add-dns dns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  msp_address: string
  --msp-dns-server: string
  msp_dns_record_type: string@msp-dns-record-type-completer # default: A
  --msp-expect-string: string
  --msp-threshold: int # nullable, default: 20
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 2.2
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_dns_server: string, msp_dns_record_type: string, msp_expect_string: string, msp_threshold: int, msp_sensitivity: int, msp_num_retries: int, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-dns/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_dns_server: $msp_dns_server, msp_dns_record_type: $msp_dns_record_type, msp_expect_string: $msp_expect_string, msp_threshold: $msp_threshold, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new FTP(S) check
#
# POST /api/v1/checks/add-ftp/
# operationId: post_service_create_ftp
# --ftpconfig shape: {ftp_paths?: string, ftp_skip_cert_verification?: bool, ftp_explicit_tls?: bool}
export def "checks-add-ftp ftp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  msp_address: string
  --msp-port: int # nullable, default: 21
  --msp-username: string
  --msp-password: string
  --msp-threshold: int # nullable, default: 40
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 2.2
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
  --ftpconfig: record # nullable — shape: {ftp_paths?: string, ftp_skip_cert_verification?: bool, ftp_explicit_tls?: bool}
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_username: string, msp_password: string, msp_threshold: int, msp_sensitivity: int, msp_num_retries: int, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool, ftpconfig: record<ftp_paths: string, ftp_skip_cert_verification: bool, ftp_explicit_tls: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-ftp/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_port: $msp_port, msp_username: $msp_username, msp_password: $msp_password, msp_threshold: $msp_threshold, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics, ftpconfig: $ftpconfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Group check
#
# POST /api/v1/checks/add-group/
# operationId: post_service_create_group
# --groupcheckconfig shape: {group_check_services?: list, group_check_tags?: list, group_check_down_condition?: "ANY"|"TWO"|"THREE"|"FOUR"|"FIVE"|"TEN"|"ONE_PCT"|"THREE_PCT"|"FIVE_PCT"|"TEN_PCT"|"TWENTYFIVE_PCT"|"FIFTY_PCT"|"ALL", group_uptime_percent_calculation?: "UP_DOWN_STATES"|"AVERAGE", group_response_time_calculation_mode?: "NONE"|"COPY"|"AVERAGE", group_response_time_check_type?: "HTTP"|"TRANSACTION"|"API"|"ICMP"|"HEARTBEAT"|"WEBHOOK", group_response_time_single_check?: string}
export def "checks-add-group group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
  --groupcheckconfig: record # nullable — shape: {group_check_services?: list, group_check_tags?: list, group_check_down_condition?: "ANY"|"TWO"|"THREE"|"FOUR"|"FIVE"|"TEN"|"ONE_PCT"|"THREE_PCT"|"FIVE_PCT"|"TEN_PCT"|"TWENTYFIVE_PCT"|"FIFTY_PCT"|"ALL", group_uptime_percent_calculation?: "UP_DOWN_STATES"|"AVERAGE", group_response_time_calculation_mode?: "NONE"|"COPY"|"AVERAGE", group_response_time_check_type?: "HTTP"|"TRANSACTION"|"API"|"ICMP"|"HEARTBEAT"|"WEBHOOK", group_response_time_single_check?: string}
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool, groupcheckconfig: record<group_check_services: list<string>, group_check_tags: list<string>, group_check_down_condition: string, group_uptime_percent_calculation: string, group_response_time_calculation_mode: string, group_response_time_check_type: string, group_response_time_single_check: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-group/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics, groupcheckconfig: $groupcheckconfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Heartbeat check
#
# POST /api/v1/checks/add-heartbeat/
# operationId: post_service_create_heartbeat
export def "checks-add-heartbeat heartbeat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool, heartbeat_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-heartbeat/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new HTTP(S) check
#
# POST /api/v1/checks/add-http/
# operationId: post_service_create_http
export def "checks-add-http http" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  msp_address: string
  --msp-port: int # nullable
  --msp-username: string
  --msp-password: string
  --msp-proxy: string
  --msp-status-code: string
  --msp-send-string: string
  --msp-expect-string: string
  --msp-expect-string-type: string@msp-expect-string-type-completer # default: STRING
  --msp-encryption: string@msp-encryption-completer # default: SSL_TLS
  --msp-threshold: int # nullable, default: 40
  --msp-headers: string
  --msp-version: int # default: 2
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-use-ip-version: string@msp-use-ip-version-completer # default: 
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 2.2
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_username: string, msp_password: string, msp_proxy: string, msp_status_code: string, msp_send_string: string, msp_expect_string: string, msp_expect_string_type: string, msp_encryption: string, msp_threshold: int, msp_headers: string, msp_version: int, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-http/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_port: $msp_port, msp_username: $msp_username, msp_password: $msp_password, msp_proxy: $msp_proxy, msp_status_code: $msp_status_code, msp_send_string: $msp_send_string, msp_expect_string: $msp_expect_string, msp_expect_string_type: $msp_expect_string_type, msp_encryption: $msp_encryption, msp_threshold: $msp_threshold, msp_headers: $msp_headers, msp_version: $msp_version, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_use_ip_version: $msp_use_ip_version, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new ICMP(Ping) check
#
# POST /api/v1/checks/add-icmp/
# operationId: post_service_create_icmp
export def "checks-add-icmp icmp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  msp_address: string
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-use-ip-version: string@msp-use-ip-version-completer # default: 
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 1.2
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-icmp/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_use_ip_version: $msp_use_ip_version, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new IMAP check
#
# POST /api/v1/checks/add-imap/
# operationId: post_service_create_imap
export def "checks-add-imap imap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  msp_address: string
  --msp-port: int # nullable
  --msp-expect-string: string
  --msp-encryption: string@msp-encryption-completer # default: SSL_TLS
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-use-ip-version: string@msp-use-ip-version-completer # default: 
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 2.2
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_expect_string: string, msp_encryption: string, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-imap/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_port: $msp_port, msp_expect_string: $msp_expect_string, msp_encryption: $msp_encryption, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_use_ip_version: $msp_use_ip_version, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Malware/Virus check
#
# POST /api/v1/checks/add-malware/
# operationId: post_service_create_malware
export def "checks-add-malware malware" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Locations are auto-assigned for this check type if left empty or omitted. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_address: string
  --msp-num-retries: int # default: 2
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-notes: string
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_address: string, msp_num_retries: int, msp_uptime_sla: string, msp_notes: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-malware/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_address: $msp_address, msp_num_retries: $msp_num_retries, msp_uptime_sla: $msp_uptime_sla, msp_notes: $msp_notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new NTP check
#
# POST /api/v1/checks/add-ntp/
# operationId: post_service_create_ntp
export def "checks-add-ntp ntp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  msp_address: string
  --msp-port: int # nullable
  --msp-threshold: int # nullable, default: 20
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-use-ip-version: string@msp-use-ip-version-completer # default: 
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 1.0
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_threshold: int, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-ntp/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_port: $msp_port, msp_threshold: $msp_threshold, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_use_ip_version: $msp_use_ip_version, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Page Speed check
#
# POST /api/v1/checks/add-pagespeed/
# operationId: post_service_create_pagespeed
# --pagespeedconfig shape: {emulated_device?: "DEFAULT"|"DESKTOP_LOW_END"|"IPHONE_17_PRO_MAX"|"IPHONE_17"|"IPHONE_16_PRO_MAX"|"IPHONE_16"|"IPHONE_15_PRO_MAX"|"IPHONE_15"|"IPHONE_14_PRO_MAX"|"IPHONE_13_PRO_MAX"|"IPHONE_13"|"IPHONE_12_PRO_MAX"|"IPHONE_12"|"IPHONE_11_PRO_MAX"|"IPHONE_11_PRO"|"IPHONE_11"|"GOOGLE_PIXEL_10"|"GOOGLE_PIXEL_10_PRO"|"GOOGLE_PIXEL_9"|"GOOGLE_PIXEL_9_PRO"|"GOOGLE_PIXEL_8_PRO"|"GOOGLE_PIXEL_7"|"GOOGLE_PIXEL_6"|"GOOGLE_PIXEL_6_PRO"|"SAMSUNG_GALAXY_S24_ULTRA"|"SAMSUNG_GALAXY_S23"|"SAMSUNG_GALAXY_Z_FOLD_5"|"SAMSUNG_GALAXY_S10"|"SAMSUNG_GALAXY_S10_PLUS"|"SAMSUNG_GALAXY_S21"|"SAMSUNG_GALAXY_S21_PLUS"|"SAMSUNG_GALAXY_S21_ULTRA"|"SAMSUNG_GALAXY_S22"|"IPAD_PRO_12_9"|"IPAD_AIR"|"IPAD_MINI"|"IPAD_PRO_11"|"MOBILE_MID_TIER"|"MOBILE_LOW_END", connection_throttling?: "UNTHROTTLED"|"BROADBAND_FAST"|"BROADBAND"|"BROADBAND_SLOW"|"LTE"|"FOUR_G"|"FOUR_G_SLOW"|"THREE_G"|"THREE_G_SLOW", exclude_urls?: string, uptime_grade_threshold?: ""|"A"|"B"|"C"|"D"|"E"|"F"}
export def "checks-add-pagespeed pagespeed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 1440
  --msp-username: string
  --msp-password: string
  --msp-headers: string
  msp_script: string # default: [{"step_def": "C_PAGESPEED_NAVIGATE", "values": {"url": "https://"}}]
  --msp-num-retries: int # default: 2
  --msp-notes: string
  --pagespeedconfig: record # nullable — shape: {emulated_device?: "DEFAULT"|"DESKTOP_LOW_END"|"IPHONE_17_PRO_MAX"|"IPHONE_17"|"IPHONE_16_PRO_MAX"|"IPHONE_16"|"IPHONE_15_PRO_MAX"|"IPHONE_15"|"IPHONE_14_PRO_MAX"|"IPHONE_13_PRO_MAX"|"IPHONE_13"|"IPHONE_12_PRO_MAX"|"IPHONE_12"|"IPHONE_11_PRO_MAX"|"IPHONE_11_PRO"|"IPHONE_11"|"GOOGLE_PIXEL_10"|"GOOGLE_PIXEL_10_PRO"|"GOOGLE_PIXEL_9"|"GOOGLE_PIXEL_9_PRO"|"GOOGLE_PIXEL_8_PRO"|"GOOGLE_PIXEL_7"|"GOOGLE_PIXEL_6"|"GOOGLE_PIXEL_6_PRO"|"SAMSUNG_GALAXY_S24_ULTRA"|"SAMSUNG_GALAXY_S23"|"SAMSUNG_GALAXY_Z_FOLD_5"|"SAMSUNG_GALAXY_S10"|"SAMSUNG_GALAXY_S10_PLUS"|"SAMSUNG_GALAXY_S21"|"SAMSUNG_GALAXY_S21_PLUS"|"SAMSUNG_GALAXY_S21_ULTRA"|"SAMSUNG_GALAXY_S22"|"IPAD_PRO_12_9"|"IPAD_AIR"|"IPAD_MINI"|"IPAD_PRO_11"|"MOBILE_MID_TIER"|"MOBILE_LOW_END", connection_throttling?: "UNTHROTTLED"|"BROADBAND_FAST"|"BROADBAND"|"BROADBAND_SLOW"|"LTE"|"FOUR_G"|"FOUR_G_SLOW"|"THREE_G"|"THREE_G_SLOW", exclude_urls?: string, uptime_grade_threshold?: ""|"A"|"B"|"C"|"D"|"E"|"F"}
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_username: string, msp_password: string, msp_headers: string, msp_script: string, msp_num_retries: int, msp_notes: string, pagespeedconfig: record<emulated_device: string, connection_throttling: string, exclude_urls: string, uptime_grade_threshold: string, cached_uptime_grade: string, cached_performance_score: int, cached_best_practices_score: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-pagespeed/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_username: $msp_username, msp_password: $msp_password, msp_headers: $msp_headers, msp_script: $msp_script, msp_num_retries: $msp_num_retries, msp_notes: $msp_notes, pagespeedconfig: $pagespeedconfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new POP check
#
# POST /api/v1/checks/add-pop/
# operationId: post_service_create_pop
export def "checks-add-pop pop" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  msp_address: string
  --msp-port: int # nullable
  --msp-expect-string: string
  --msp-encryption: string@msp-encryption-completer # default: SSL_TLS
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-use-ip-version: string@msp-use-ip-version-completer # default: 
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 2.2
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_expect_string: string, msp_encryption: string, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-pop/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_port: $msp_port, msp_expect_string: $msp_expect_string, msp_encryption: $msp_encryption, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_use_ip_version: $msp_use_ip_version, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new RDAP - Domain Lookup & Expiry check
#
# POST /api/v1/checks/add-rdap/
# operationId: post_service_create_rdap
export def "checks-add-rdap rdap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Locations are auto-assigned for this check type if left empty or omitted. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_address: string
  --msp-expect-string: string
  --msp-threshold: int # nullable, default: 20
  --msp-num-retries: int # default: 2
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-notes: string
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_address: string, msp_expect_string: string, msp_threshold: int, msp_num_retries: int, msp_uptime_sla: string, msp_notes: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-rdap/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_address: $msp_address, msp_expect_string: $msp_expect_string, msp_threshold: $msp_threshold, msp_num_retries: $msp_num_retries, msp_uptime_sla: $msp_uptime_sla, msp_notes: $msp_notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Real User Monitoring check
#
# POST /api/v1/checks/add-rum2/
# operationId: post_service_create_rum2
# --rumconfig shape: {aggregation_type?: "MED"|"AVG"|"P75"|"P90"|"P95"|"P98"|"P99", exclude_useragents?: string, apdex_threshold?: int, url_groups?: string, external_domains?: string, exclude_get_params?: string, is_ajax_disabled?: bool}
export def "checks-add-rum2 rum2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_address: string
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
  --rumconfig: record # nullable — shape: {aggregation_type?: "MED"|"AVG"|"P75"|"P90"|"P95"|"P98"|"P99", exclude_useragents?: string, apdex_threshold?: int, url_groups?: string, external_domains?: string, exclude_get_params?: string, is_ajax_disabled?: bool}
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_address: string, msp_uptime_sla: string, msp_notes: string, msp_include_in_global_metrics: bool, rumconfig: record<aggregation_type: string, exclude_useragents: string, apdex_threshold: int, url_groups: string, external_domains: string, exclude_get_params: string, is_ajax_disabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-rum2/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_address: $msp_address, msp_uptime_sla: $msp_uptime_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics, rumconfig: $rumconfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new SFTP check
#
# POST /api/v1/checks/add-sftp/
# operationId: post_service_create_sftp
# --sftpconfig shape: {ftp_paths?: string, sftp_private_key?: string, sftp_passphrase?: string, sftp_known_hosts?: string}
export def "checks-add-sftp sftp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  msp_address: string
  --msp-port: int # nullable, default: 22
  msp_username: string
  --msp-password: string
  --msp-threshold: int # nullable, default: 40
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 2.2
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
  --sftpconfig: record # nullable — shape: {ftp_paths?: string, sftp_private_key?: string, sftp_passphrase?: string, sftp_known_hosts?: string}
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_username: string, msp_password: string, msp_threshold: int, msp_sensitivity: int, msp_num_retries: int, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool, sftpconfig: record<ftp_paths: string, sftp_private_key: string, sftp_passphrase: string, sftp_known_hosts: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-sftp/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_port: $msp_port, msp_username: $msp_username, msp_password: $msp_password, msp_threshold: $msp_threshold, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics, sftpconfig: $sftpconfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new SMTP check
#
# POST /api/v1/checks/add-smtp/
# operationId: post_service_create_smtp
export def "checks-add-smtp smtp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  msp_address: string
  --msp-port: int # nullable
  --msp-username: string
  --msp-password: string
  --msp-expect-string: string
  --msp-encryption: string@msp-encryption-completer # default: SSL_TLS
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-use-ip-version: string@msp-use-ip-version-completer # default: 
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 2.2
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_username: string, msp_password: string, msp_expect_string: string, msp_encryption: string, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-smtp/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_port: $msp_port, msp_username: $msp_username, msp_password: $msp_password, msp_expect_string: $msp_expect_string, msp_encryption: $msp_encryption, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_use_ip_version: $msp_use_ip_version, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new SSH check
#
# POST /api/v1/checks/add-ssh/
# operationId: post_service_create_ssh
export def "checks-add-ssh ssh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  msp_address: string
  --msp-port: int # nullable
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-use-ip-version: string@msp-use-ip-version-completer # default: 
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 2.2
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-ssh/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_port: $msp_port, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_use_ip_version: $msp_use_ip_version, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new SSL Certificate check
#
# POST /api/v1/checks/add-ssl-cert/
# operationId: post_service_create_ssl_cert
# --sslconfig shape: {ssl_cert_protocol?: "https"|"ftp"|"ftps"|"http"|"h2"|"imap"|"imaps"|"irc"|"ircs"|"ldap"|"ldaps"|"mysql"|"pop3"|"pop3s"|"postgres"|"sieve"|"smtp"|"smtps"|"xmpp"|"xmpp-server", ssl_cert_crl?: bool, ssl_cert_first_element_only?: bool, ssl_cert_match?: string, ssl_cert_issuer?: string, ssl_cert_resolve?: string, ssl_cert_minimum_ssl_tls_version?: "sslv3"|"tlsv1"|"tlsv11"|"tlsv12"|"tlsv13", ssl_cert_fingerprint?: string, ssl_cert_selfsigned?: bool, ssl_cert_file?: string, ssl_ignore_authority_warnings?: bool, ssl_ignore_sct?: bool}
export def "checks-add-ssl-cert cert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Locations are auto-assigned for this check type if left empty or omitted. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_address: string
  --msp-port: int # nullable
  --msp-threshold: int # nullable, default: 20
  --msp-num-retries: int # default: 2
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-notes: string
  --sslconfig: record # nullable — shape: {ssl_cert_protocol?: "https"|"ftp"|"ftps"|"http"|"h2"|"imap"|"imaps"|"irc"|"ircs"|"ldap"|"ldaps"|"mysql"|"pop3"|"pop3s"|"postgres"|"sieve"|"smtp"|"smtps"|"xmpp"|"xmpp-server", ssl_cert_crl?: bool, ssl_cert_first_element_only?: bool, ssl_cert_match?: string, ssl_cert_issuer?: string, ssl_cert_resolve?: string, ssl_cert_minimum_ssl_tls_version?: "sslv3"|"tlsv1"|"tlsv11"|"tlsv12"|"tlsv13", ssl_cert_fingerprint?: string, ssl_cert_selfsigned?: bool, ssl_cert_file?: string, ssl_ignore_authority_warnings?: bool, ssl_ignore_sct?: bool}
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_address: string, msp_port: int, msp_threshold: int, msp_num_retries: int, msp_uptime_sla: string, msp_notes: string, sslconfig: record<ssl_cert_protocol: string, ssl_cert_crl: bool, ssl_cert_first_element_only: bool, ssl_cert_match: string, ssl_cert_issuer: string, ssl_cert_resolve: string, ssl_cert_minimum_ssl_tls_version: string, ssl_cert_fingerprint: string, ssl_cert_selfsigned: bool, ssl_cert_file: string, ssl_ignore_authority_warnings: bool, ssl_ignore_sct: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-ssl-cert/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_address: $msp_address, msp_port: $msp_port, msp_threshold: $msp_threshold, msp_num_retries: $msp_num_retries, msp_uptime_sla: $msp_uptime_sla, msp_notes: $msp_notes, sslconfig: $sslconfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new TCP check
#
# POST /api/v1/checks/add-tcp/
# operationId: post_service_create_tcp
export def "checks-add-tcp tcp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  msp_address: string
  --msp-port: int # nullable
  --msp-send-string: string
  --msp-expect-string: string
  --msp-encryption: string@msp-encryption-completer # default: SSL_TLS
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-use-ip-version: string@msp-use-ip-version-completer # default: 
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 2.2
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_send_string: string, msp_expect_string: string, msp_encryption: string, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-tcp/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_port: $msp_port, msp_send_string: $msp_send_string, msp_expect_string: $msp_expect_string, msp_encryption: $msp_encryption, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_use_ip_version: $msp_use_ip_version, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Transaction check
#
# POST /api/v1/checks/add-transaction/
# operationId: post_service_create_transaction
export def "checks-add-transaction transaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  --msp-threshold: int # nullable, default: 60
  msp_script: string # default: [{"step_def": "C_OPEN_URL", "values": {"url": "https://"}}]
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 32.0
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_threshold: int, msp_script: string, msp_sensitivity: int, msp_num_retries: int, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-transaction/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_threshold: $msp_threshold, msp_script: $msp_script, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new UDP check
#
# POST /api/v1/checks/add-udp/
# operationId: post_service_create_udp
export def "checks-add-udp udp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_interval: int # default: 5
  msp_address: string
  --msp-port: int # nullable
  msp_send_string: string
  msp_expect_string: string
  --msp-sensitivity: int # default: 2
  --msp-num-retries: int # default: 2
  --msp-use-ip-version: string@msp-use-ip-version-completer # default: 
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal, default: 2.2
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_send_string: string, msp_expect_string: string, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-udp/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_port: $msp_port, msp_send_string: $msp_send_string, msp_expect_string: $msp_expect_string, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_use_ip_version: $msp_use_ip_version, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Incoming Webhook check
#
# POST /api/v1/checks/add-webhook/
# operationId: post_service_create_webhook
export def "checks-add-webhook webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-response-time-sla: string # nullable, format: decimal
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool> # default: true
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-webhook/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new WHOIS - Domain Lookup & Expiry check
#
# POST /api/v1/checks/add-whois/
# operationId: post_service_create_whois
export def "checks-add-whois whois" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Locations are auto-assigned for this check type if left empty or omitted. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  msp_address: string
  msp_expect_string: string
  --msp-threshold: int # nullable, default: 20
  --msp-num-retries: int # default: 2
  --msp-uptime-sla: string # format: decimal, default: 0.99
  --msp-notes: string
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_address: string, msp_expect_string: string, msp_threshold: int, msp_num_retries: int, msp_uptime_sla: string, msp_notes: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/add-whois/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_address: $msp_address, msp_expect_string: $msp_expect_string, msp_threshold: $msp_threshold, msp_num_retries: $msp_num_retries, msp_uptime_sla: $msp_uptime_sla, msp_notes: $msp_notes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk API: Update escalations for multiple checks  **Sample data (JSON):**      {         "pk": [1, 2, 3],         "fields": {             "escalations": [{                 "wait_time": 5,                 "num_repeats: 10,                 "contact_groups": ["Default", "Other"]             }]         }     }
#
# PATCH /api/v1/checks/bulk/escalations/
# operationId: patch_service_bulk_escalations
# --fields shape: {escalations: list}
export def "checks-bulk-escalations escalations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pk: list
  --body-fields: record # shape: {escalations: list}
]: any -> record<pk: list<int>, fields: record<escalations: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/bulk/escalations/")
  let body = {pk: $pk, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [Deprecated soon] Bulk API: Update maintenance settings for multiple checks  **Sample data (JSON):**      {         "pk": [1, 2, 3],         "fields": {             "state": "SCHEDULED",             "schedule": [{                 "type": "WEEKLY",                 "from_time": "03:15",                 "to_time": "18:30",                 "weekdays": [6, 0]             }],             "pause_on_scheduled_maintenance": true         }     }
#
# PATCH /api/v1/checks/bulk/maintenance/
# operationId: patch_service_bulk_maintenance
# --fields shape: {state: "ACTIVE"|"SUPPRESSED"|"SCHEDULED", schedule?: list, pause_on_scheduled_maintenance?: bool}
export def "checks-bulk-maintenance maintenance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pk: list
  --body-fields: record # shape: {state: "ACTIVE"|"SUPPRESSED"|"SCHEDULED", schedule?: list, pause_on_scheduled_maintenance?: bool}
]: any -> record<pk: list<int>, fields: record<state: string, schedule: list<record>, pause_on_scheduled_maintenance: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/bulk/maintenance/")
  let body = {pk: $pk, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk API: Pause multiple checks  **Sample data (JSON):**      {         "pk": [1, 2, 3],         "fields": {             "send_resolved_notifications": false         }     }
#
# PATCH /api/v1/checks/bulk/pause/
# operationId: patch_service_bulk_pause
# --fields shape: {send_resolved_notifications?: bool}
export def "checks-bulk-pause pause" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pk: list
  --body-fields: record # shape: {send_resolved_notifications?: bool}
]: any -> record<pk: list<int>, fields: record<send_resolved_notifications: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/bulk/pause/")
  let body = {pk: $pk, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk API: Resume multiple checks  **Sample data (JSON):**      {         "pk": [1, 2, 3]     }
#
# PATCH /api/v1/checks/bulk/resume/
# operationId: patch_service_bulk_resume
export def "checks-bulk-resume resume" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pk: list
]: any -> record<pk: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/bulk/resume/")
  let body = {pk: $pk} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk API: Get statistics & response time for multiple checks
#
# GET /api/v1/checks/bulk/stats/
# operationId: get_service_bulk_stats
export def "checks-bulk-stats stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pk: list
  --start-date: string # The first day to show statistics for in ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) format.
  --end-date: string # The last day to show statistics for in ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) format.
  --include-alerts: oneof<nothing, bool> # Include alert data for each outage in the period.
]: nothing -> record<pk: list<int>, start_date: string, end_date: string, include_alerts: bool, checks: list<record>, totals: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pk" $pk "multi") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "include_alerts" $include_alerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/checks/bulk/stats/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk API: Update multiple checks  **Sample data (JSON):**      {         "pk": [1, 2, 3],         "fields": {             "msp_interval": 10,             "msp_sensitivity": 3,             "contact_groups": ["Default", "Other"],             "locations": ["GBR", "AUT"],             "tags": ["One", "Two"],             ...         }     }
#
# PATCH /api/v1/checks/bulk/update/
# operationId: patch_service_bulk_update
# --fields shape: {name?: string, contact_groups: list, locations?: list, tags?: list, is_paused?: bool, send_resolved_notifications?: bool, maintenance_schedules?: list, msp_interval?: int, msp_address: string, msp_port?: int, msp_username?: string, msp_password?: string, msp_proxy?: string, msp_dns_server?: string, msp_dns_record_type?: "A"|"AAAA"|"CNAME"|"MX"|"NS"|"PTR"|"SOA"|"TXT"|"ANY", msp_status_code?: string, msp_send_string?: string, msp_expect_string?: string, msp_expect_string_type?: "STRING"|"REGEX"|"INVERSE_REGEX", msp_encryption?: ""|"SSL_TLS", msp_threshold?: int, msp_headers?: string, msp_script?: string, msp_version?: int, msp_sensitivity?: int, msp_num_retries?: int, msp_use_ip_version?: ""|"IPV4"|"IPV6", msp_uptime_sla?: string, msp_response_time_sla?: string, msp_notes?: string, msp_include_in_global_metrics?: bool}
export def "checks-bulk-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pk: list
  --body-fields: record # shape: {name?: string, contact_groups: list, locations?: list, tags?: list, is_paused?: bool, send_resolved_notifications?: bool, maintenance_schedules?: list, msp_interval?: int, msp_address: string, msp_port?: int, msp_username?: string, msp_password?: string, msp_proxy?: string, msp_dns_server?: string, msp_dns_record_type?: "A"|"AAAA"|"CNAME"|"MX"|"NS"|"PTR"|"SOA"|"TXT"|"ANY", msp_status_code?: string, msp_send_string?: string, msp_expect_string?: string, msp_expect_string_type?: "STRING"|"REGEX"|"INVERSE_REGEX", msp_encryption?: ""|"SSL_TLS", msp_threshold?: int, msp_headers?: string, msp_script?: string, msp_version?: int, msp_sensitivity?: int, msp_num_retries?: int, msp_use_ip_version?: ""|"IPV4"|"IPV6", msp_uptime_sla?: string, msp_response_time_sla?: string, msp_notes?: string, msp_include_in_global_metrics?: bool}
]: any -> record<pk: list<int>, fields: record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_username: string, msp_password: string, msp_proxy: string, msp_dns_server: string, msp_dns_record_type: string, msp_status_code: string, msp_send_string: string, msp_expect_string: string, msp_expect_string_type: string, msp_encryption: string, msp_threshold: int, msp_headers: string, msp_script: string, msp_version: int, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/checks/bulk/update/")
  let body = {pk: $pk, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists the parameters available for every type of check
#
# GET /api/v1/checks/check-definitions/
# operationId: get_service_show_service_defs
export def "checks-check-definitions defs" [
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
  let full_url = (build-url $base "/api/v1/checks/check-definitions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all available cloud status groups that can be used when creating CLOUDSTATUS checks using the add-cloudstatus endpoint.
#
# GET /api/v1/checks/cloudstatus-groups/
# operationId: get_service_show_cloudstatus_groups
export def "checks-cloudstatus-groups groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Filter by group name
]: nothing -> record<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/checks/cloudstatus-groups/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all available cloud status services that can be used when creating CLOUDSTATUS checks using the add-cloudstatus endpoint.
#
# GET /api/v1/checks/cloudstatus-services/
# operationId: get_service_show_cloudstatus_services
export def "checks-cloudstatus-services services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --group: string # Filter by group name or group ID
  --search: string # Filter by name, title, or sub_title
]: nothing -> record<id: int, name: string, title: string, sub_title: string, group_id: int, group: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group" $group "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/checks/cloudstatus-services/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists locations available for Checks
#
# GET /api/v1/checks/locations/
# operationId: get_service_show_locations
export def "checks-locations locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --monitoring-service-type: string@monitoring-service-type-completer-1 # Filter locations to only those valid for this Check type.
  --include-monitoring-service-types: oneof<nothing, bool> # Set to true to include monitoring_service_types metadata for each location. Changes response items from strings to objects.
]: nothing -> record<locations: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "monitoring_service_type" $monitoring_service_type "scalar") (serialize-qp "include_monitoring_service_types" $include_monitoring_service_types "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/checks/locations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all checks for a given group check
#
# GET /api/v1/checks/{group_id}/checks/
# operationId: get_servicegrouplist
export def "checks-checks servicegrouplist" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-2 # Order results by this field.
  --monitoring-service-type: string@monitoring-service-type-completer # Filter by check type.
  --is-paused: oneof<nothing, bool> # Filter by paused status.
  --is-under-maintenance: oneof<nothing, bool> # Filter for checks currently under maintenance.
  --state-is-up: oneof<nothing, bool> # Filter by check up/down state.
  --has-maintenance-schedule: oneof<nothing, bool> # Filter by checks that have a maintenance schedule.
  --tag: string # Filter by tag name (can be specified multiple times.)
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list, created_at: string, modified_at: string, locations: list, tags: list, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list, msp_interval: int, msp_address: string, msp_port: int, msp_username: string, msp_password: string, msp_proxy: string, msp_dns_server: string, msp_dns_record_type: string, msp_status_code: string, msp_send_string: string, msp_expect_string: string, msp_expect_string_type: string, msp_encryption: string, msp_threshold: int, msp_headers: string, msp_script: string, msp_version: int, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "monitoring_service_type" $monitoring_service_type "scalar") (serialize-qp "is_paused" $is_paused "scalar") (serialize-qp "is_under_maintenance" $is_under_maintenance "scalar") (serialize-qp "state_is_up" $state_is_up "scalar") (serialize-qp "has_maintenance_schedule" $has_maintenance_schedule "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/checks/($group_id)/checks/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single check
#
# GET /api/v1/checks/{pk}/
# operationId: get_service_detail
export def "checks detail-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_username: string, msp_password: string, msp_proxy: string, msp_dns_server: string, msp_dns_record_type: string, msp_status_code: string, msp_send_string: string, msp_expect_string: string, msp_expect_string_type: string, msp_encryption: string, msp_threshold: int, msp_headers: string, msp_script: string, msp_version: int, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool, webhook_url: string, heartbeat_url: string, rumconfig: record<aggregation_type: string, exclude_useragents: string, apdex_threshold: int, url_groups: string, external_domains: string, exclude_get_params: string, is_ajax_disabled: bool>, groupcheckconfig: record<group_check_services: list<string>, group_check_tags: list<string>, group_check_down_condition: string, group_uptime_percent_calculation: string, group_response_time_calculation_mode: string, group_response_time_check_type: string, group_response_time_single_check: string>, sslconfig: record<ssl_cert_protocol: string, ssl_cert_crl: bool, ssl_cert_first_element_only: bool, ssl_cert_match: string, ssl_cert_issuer: string, ssl_cert_resolve: string, ssl_cert_minimum_ssl_tls_version: string, ssl_cert_fingerprint: string, ssl_cert_selfsigned: bool, ssl_cert_file: string, ssl_ignore_authority_warnings: bool, ssl_ignore_sct: bool>, pagespeedconfig: record<emulated_device: string, connection_throttling: string, exclude_urls: string, uptime_grade_threshold: string, cached_uptime_grade: string, cached_performance_score: int, cached_best_practices_score: int>, cloudstatusconfig: record<notify_only_on_down: bool, service_name: string, group: int, monitoring_type: string, services: list<int>, service_titles: list<string>>, ftpconfig: record<ftp_paths: string, ftp_skip_cert_verification: bool, ftp_explicit_tls: bool>, sftpconfig: record<ftp_paths: string, sftp_private_key: string, sftp_passphrase: string, sftp_known_hosts: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/checks/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a check
#
# PUT /api/v1/checks/{pk}/
# operationId: put_service_detail
# --rumconfig shape: {aggregation_type?: "MED"|"AVG"|"P75"|"P90"|"P95"|"P98"|"P99", exclude_useragents?: string, apdex_threshold?: int, url_groups?: string, external_domains?: string, exclude_get_params?: string, is_ajax_disabled?: bool}
# --groupcheckconfig shape: {group_check_services?: list, group_check_tags?: list, group_check_down_condition?: "ANY"|"TWO"|"THREE"|"FOUR"|"FIVE"|"TEN"|"ONE_PCT"|"THREE_PCT"|"FIVE_PCT"|"TEN_PCT"|"TWENTYFIVE_PCT"|"FIFTY_PCT"|"ALL", group_uptime_percent_calculation?: "UP_DOWN_STATES"|"AVERAGE", group_response_time_calculation_mode?: "NONE"|"COPY"|"AVERAGE", group_response_time_check_type?: "HTTP"|"TRANSACTION"|"API"|"ICMP"|"HEARTBEAT"|"WEBHOOK", group_response_time_single_check?: string}
# --sslconfig shape: {ssl_cert_protocol?: "https"|"ftp"|"ftps"|"http"|"h2"|"imap"|"imaps"|"irc"|"ircs"|"ldap"|"ldaps"|"mysql"|"pop3"|"pop3s"|"postgres"|"sieve"|"smtp"|"smtps"|"xmpp"|"xmpp-server", ssl_cert_crl?: bool, ssl_cert_first_element_only?: bool, ssl_cert_match?: string, ssl_cert_issuer?: string, ssl_cert_resolve?: string, ssl_cert_minimum_ssl_tls_version?: "sslv3"|"tlsv1"|"tlsv11"|"tlsv12"|"tlsv13", ssl_cert_fingerprint?: string, ssl_cert_selfsigned?: bool, ssl_cert_file?: string, ssl_ignore_authority_warnings?: bool, ssl_ignore_sct?: bool}
# --pagespeedconfig shape: {emulated_device?: "DEFAULT"|"DESKTOP_LOW_END"|"IPHONE_17_PRO_MAX"|"IPHONE_17"|"IPHONE_16_PRO_MAX"|"IPHONE_16"|"IPHONE_15_PRO_MAX"|"IPHONE_15"|"IPHONE_14_PRO_MAX"|"IPHONE_13_PRO_MAX"|"IPHONE_13"|"IPHONE_12_PRO_MAX"|"IPHONE_12"|"IPHONE_11_PRO_MAX"|"IPHONE_11_PRO"|"IPHONE_11"|"GOOGLE_PIXEL_10"|"GOOGLE_PIXEL_10_PRO"|"GOOGLE_PIXEL_9"|"GOOGLE_PIXEL_9_PRO"|"GOOGLE_PIXEL_8_PRO"|"GOOGLE_PIXEL_7"|"GOOGLE_PIXEL_6"|"GOOGLE_PIXEL_6_PRO"|"SAMSUNG_GALAXY_S24_ULTRA"|"SAMSUNG_GALAXY_S23"|"SAMSUNG_GALAXY_Z_FOLD_5"|"SAMSUNG_GALAXY_S10"|"SAMSUNG_GALAXY_S10_PLUS"|"SAMSUNG_GALAXY_S21"|"SAMSUNG_GALAXY_S21_PLUS"|"SAMSUNG_GALAXY_S21_ULTRA"|"SAMSUNG_GALAXY_S22"|"IPAD_PRO_12_9"|"IPAD_AIR"|"IPAD_MINI"|"IPAD_PRO_11"|"MOBILE_MID_TIER"|"MOBILE_LOW_END", connection_throttling?: "UNTHROTTLED"|"BROADBAND_FAST"|"BROADBAND"|"BROADBAND_SLOW"|"LTE"|"FOUR_G"|"FOUR_G_SLOW"|"THREE_G"|"THREE_G_SLOW", exclude_urls?: string, uptime_grade_threshold?: ""|"A"|"B"|"C"|"D"|"E"|"F"}
# --cloudstatusconfig shape: {notify_only_on_down?: bool, service_name?: string, group?: int, monitoring_type?: "ALL"|"SPECIFIC", services?: list, service_titles?: list}
# --ftpconfig shape: {ftp_paths?: string, ftp_skip_cert_verification?: bool, ftp_explicit_tls?: bool}
# --sftpconfig shape: {ftp_paths?: string, sftp_private_key?: string, sftp_passphrase?: string, sftp_known_hosts?: string}
export def "checks detail-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  --msp-interval: int
  msp_address: string
  --msp-port: int # nullable
  --msp-username: string
  --msp-password: string
  --msp-proxy: string
  --msp-dns-server: string
  --msp-dns-record-type: string@msp-dns-record-type-completer
  --msp-status-code: string
  --msp-send-string: string
  --msp-expect-string: string
  --msp-expect-string-type: string@msp-expect-string-type-completer
  --msp-encryption: string@msp-encryption-completer
  --msp-threshold: int # nullable
  --msp-headers: string
  --msp-script: string
  --msp-version: int
  --msp-sensitivity: int
  --msp-num-retries: int
  --msp-use-ip-version: string@msp-use-ip-version-completer
  --msp-uptime-sla: string # format: decimal
  --msp-response-time-sla: string # nullable, format: decimal
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool>
  --rumconfig: record # nullable — shape: {aggregation_type?: "MED"|"AVG"|"P75"|"P90"|"P95"|"P98"|"P99", exclude_useragents?: string, apdex_threshold?: int, url_groups?: string, external_domains?: string, exclude_get_params?: string, is_ajax_disabled?: bool}
  --groupcheckconfig: record # nullable — shape: {group_check_services?: list, group_check_tags?: list, group_check_down_condition?: "ANY"|"TWO"|"THREE"|"FOUR"|"FIVE"|"TEN"|"ONE_PCT"|"THREE_PCT"|"FIVE_PCT"|"TEN_PCT"|"TWENTYFIVE_PCT"|"FIFTY_PCT"|"ALL", group_uptime_percent_calculation?: "UP_DOWN_STATES"|"AVERAGE", group_response_time_calculation_mode?: "NONE"|"COPY"|"AVERAGE", group_response_time_check_type?: "HTTP"|"TRANSACTION"|"API"|"ICMP"|"HEARTBEAT"|"WEBHOOK", group_response_time_single_check?: string}
  --sslconfig: record # nullable — shape: {ssl_cert_protocol?: "https"|"ftp"|"ftps"|"http"|"h2"|"imap"|"imaps"|"irc"|"ircs"|"ldap"|"ldaps"|"mysql"|"pop3"|"pop3s"|"postgres"|"sieve"|"smtp"|"smtps"|"xmpp"|"xmpp-server", ssl_cert_crl?: bool, ssl_cert_first_element_only?: bool, ssl_cert_match?: string, ssl_cert_issuer?: string, ssl_cert_resolve?: string, ssl_cert_minimum_ssl_tls_version?: "sslv3"|"tlsv1"|"tlsv11"|"tlsv12"|"tlsv13", ssl_cert_fingerprint?: string, ssl_cert_selfsigned?: bool, ssl_cert_file?: string, ssl_ignore_authority_warnings?: bool, ssl_ignore_sct?: bool}
  --pagespeedconfig: record # nullable — shape: {emulated_device?: "DEFAULT"|"DESKTOP_LOW_END"|"IPHONE_17_PRO_MAX"|"IPHONE_17"|"IPHONE_16_PRO_MAX"|"IPHONE_16"|"IPHONE_15_PRO_MAX"|"IPHONE_15"|"IPHONE_14_PRO_MAX"|"IPHONE_13_PRO_MAX"|"IPHONE_13"|"IPHONE_12_PRO_MAX"|"IPHONE_12"|"IPHONE_11_PRO_MAX"|"IPHONE_11_PRO"|"IPHONE_11"|"GOOGLE_PIXEL_10"|"GOOGLE_PIXEL_10_PRO"|"GOOGLE_PIXEL_9"|"GOOGLE_PIXEL_9_PRO"|"GOOGLE_PIXEL_8_PRO"|"GOOGLE_PIXEL_7"|"GOOGLE_PIXEL_6"|"GOOGLE_PIXEL_6_PRO"|"SAMSUNG_GALAXY_S24_ULTRA"|"SAMSUNG_GALAXY_S23"|"SAMSUNG_GALAXY_Z_FOLD_5"|"SAMSUNG_GALAXY_S10"|"SAMSUNG_GALAXY_S10_PLUS"|"SAMSUNG_GALAXY_S21"|"SAMSUNG_GALAXY_S21_PLUS"|"SAMSUNG_GALAXY_S21_ULTRA"|"SAMSUNG_GALAXY_S22"|"IPAD_PRO_12_9"|"IPAD_AIR"|"IPAD_MINI"|"IPAD_PRO_11"|"MOBILE_MID_TIER"|"MOBILE_LOW_END", connection_throttling?: "UNTHROTTLED"|"BROADBAND_FAST"|"BROADBAND"|"BROADBAND_SLOW"|"LTE"|"FOUR_G"|"FOUR_G_SLOW"|"THREE_G"|"THREE_G_SLOW", exclude_urls?: string, uptime_grade_threshold?: ""|"A"|"B"|"C"|"D"|"E"|"F"}
  cloudstatusconfig: record # shape: {notify_only_on_down?: bool, service_name?: string, group?: int, monitoring_type?: "ALL"|"SPECIFIC", services?: list, service_titles?: list}
  --ftpconfig: record # nullable — shape: {ftp_paths?: string, ftp_skip_cert_verification?: bool, ftp_explicit_tls?: bool}
  --sftpconfig: record # nullable — shape: {ftp_paths?: string, sftp_private_key?: string, sftp_passphrase?: string, sftp_known_hosts?: string}
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_username: string, msp_password: string, msp_proxy: string, msp_dns_server: string, msp_dns_record_type: string, msp_status_code: string, msp_send_string: string, msp_expect_string: string, msp_expect_string_type: string, msp_encryption: string, msp_threshold: int, msp_headers: string, msp_script: string, msp_version: int, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool, webhook_url: string, heartbeat_url: string, rumconfig: record<aggregation_type: string, exclude_useragents: string, apdex_threshold: int, url_groups: string, external_domains: string, exclude_get_params: string, is_ajax_disabled: bool>, groupcheckconfig: record<group_check_services: list<string>, group_check_tags: list<string>, group_check_down_condition: string, group_uptime_percent_calculation: string, group_response_time_calculation_mode: string, group_response_time_check_type: string, group_response_time_single_check: string>, sslconfig: record<ssl_cert_protocol: string, ssl_cert_crl: bool, ssl_cert_first_element_only: bool, ssl_cert_match: string, ssl_cert_issuer: string, ssl_cert_resolve: string, ssl_cert_minimum_ssl_tls_version: string, ssl_cert_fingerprint: string, ssl_cert_selfsigned: bool, ssl_cert_file: string, ssl_ignore_authority_warnings: bool, ssl_ignore_sct: bool>, pagespeedconfig: record<emulated_device: string, connection_throttling: string, exclude_urls: string, uptime_grade_threshold: string, cached_uptime_grade: string, cached_performance_score: int, cached_best_practices_score: int>, cloudstatusconfig: record<notify_only_on_down: bool, service_name: string, group: int, monitoring_type: string, services: list<int>, service_titles: list<string>>, ftpconfig: record<ftp_paths: string, ftp_skip_cert_verification: bool, ftp_explicit_tls: bool>, sftpconfig: record<ftp_paths: string, sftp_private_key: string, sftp_passphrase: string, sftp_known_hosts: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/checks/($pk)/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_port: $msp_port, msp_username: $msp_username, msp_password: $msp_password, msp_proxy: $msp_proxy, msp_dns_server: $msp_dns_server, msp_dns_record_type: $msp_dns_record_type, msp_status_code: $msp_status_code, msp_send_string: $msp_send_string, msp_expect_string: $msp_expect_string, msp_expect_string_type: $msp_expect_string_type, msp_encryption: $msp_encryption, msp_threshold: $msp_threshold, msp_headers: $msp_headers, msp_script: $msp_script, msp_version: $msp_version, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_use_ip_version: $msp_use_ip_version, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics, rumconfig: $rumconfig, groupcheckconfig: $groupcheckconfig, sslconfig: $sslconfig, pagespeedconfig: $pagespeedconfig, cloudstatusconfig: $cloudstatusconfig, ftpconfig: $ftpconfig, sftpconfig: $sftpconfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a check
#
# PATCH /api/v1/checks/{pk}/
# operationId: patch_service_detail
# --rumconfig shape: {aggregation_type?: "MED"|"AVG"|"P75"|"P90"|"P95"|"P98"|"P99", exclude_useragents?: string, apdex_threshold?: int, url_groups?: string, external_domains?: string, exclude_get_params?: string, is_ajax_disabled?: bool}
# --groupcheckconfig shape: {group_check_services?: list, group_check_tags?: list, group_check_down_condition?: "ANY"|"TWO"|"THREE"|"FOUR"|"FIVE"|"TEN"|"ONE_PCT"|"THREE_PCT"|"FIVE_PCT"|"TEN_PCT"|"TWENTYFIVE_PCT"|"FIFTY_PCT"|"ALL", group_uptime_percent_calculation?: "UP_DOWN_STATES"|"AVERAGE", group_response_time_calculation_mode?: "NONE"|"COPY"|"AVERAGE", group_response_time_check_type?: "HTTP"|"TRANSACTION"|"API"|"ICMP"|"HEARTBEAT"|"WEBHOOK", group_response_time_single_check?: string}
# --sslconfig shape: {ssl_cert_protocol?: "https"|"ftp"|"ftps"|"http"|"h2"|"imap"|"imaps"|"irc"|"ircs"|"ldap"|"ldaps"|"mysql"|"pop3"|"pop3s"|"postgres"|"sieve"|"smtp"|"smtps"|"xmpp"|"xmpp-server", ssl_cert_crl?: bool, ssl_cert_first_element_only?: bool, ssl_cert_match?: string, ssl_cert_issuer?: string, ssl_cert_resolve?: string, ssl_cert_minimum_ssl_tls_version?: "sslv3"|"tlsv1"|"tlsv11"|"tlsv12"|"tlsv13", ssl_cert_fingerprint?: string, ssl_cert_selfsigned?: bool, ssl_cert_file?: string, ssl_ignore_authority_warnings?: bool, ssl_ignore_sct?: bool}
# --pagespeedconfig shape: {emulated_device?: "DEFAULT"|"DESKTOP_LOW_END"|"IPHONE_17_PRO_MAX"|"IPHONE_17"|"IPHONE_16_PRO_MAX"|"IPHONE_16"|"IPHONE_15_PRO_MAX"|"IPHONE_15"|"IPHONE_14_PRO_MAX"|"IPHONE_13_PRO_MAX"|"IPHONE_13"|"IPHONE_12_PRO_MAX"|"IPHONE_12"|"IPHONE_11_PRO_MAX"|"IPHONE_11_PRO"|"IPHONE_11"|"GOOGLE_PIXEL_10"|"GOOGLE_PIXEL_10_PRO"|"GOOGLE_PIXEL_9"|"GOOGLE_PIXEL_9_PRO"|"GOOGLE_PIXEL_8_PRO"|"GOOGLE_PIXEL_7"|"GOOGLE_PIXEL_6"|"GOOGLE_PIXEL_6_PRO"|"SAMSUNG_GALAXY_S24_ULTRA"|"SAMSUNG_GALAXY_S23"|"SAMSUNG_GALAXY_Z_FOLD_5"|"SAMSUNG_GALAXY_S10"|"SAMSUNG_GALAXY_S10_PLUS"|"SAMSUNG_GALAXY_S21"|"SAMSUNG_GALAXY_S21_PLUS"|"SAMSUNG_GALAXY_S21_ULTRA"|"SAMSUNG_GALAXY_S22"|"IPAD_PRO_12_9"|"IPAD_AIR"|"IPAD_MINI"|"IPAD_PRO_11"|"MOBILE_MID_TIER"|"MOBILE_LOW_END", connection_throttling?: "UNTHROTTLED"|"BROADBAND_FAST"|"BROADBAND"|"BROADBAND_SLOW"|"LTE"|"FOUR_G"|"FOUR_G_SLOW"|"THREE_G"|"THREE_G_SLOW", exclude_urls?: string, uptime_grade_threshold?: ""|"A"|"B"|"C"|"D"|"E"|"F"}
# --cloudstatusconfig shape: {notify_only_on_down?: bool, service_name?: string, group?: int, monitoring_type?: "ALL"|"SPECIFIC", services?: list, service_titles?: list}
# --ftpconfig shape: {ftp_paths?: string, ftp_skip_cert_verification?: bool, ftp_explicit_tls?: bool}
# --sftpconfig shape: {ftp_paths?: string, sftp_private_key?: string, sftp_passphrase?: string, sftp_known_hosts?: string}
export def "checks detail-by-pk-2" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  contact_groups: list # Array of contact names or IDs associated with this check. Use GET /api/v1/contacts/ to list available contacts.
  --locations: list # Array of locations associated with this check. Use GET /api/v1/checks/locations/ to list available locations.
  --tags: list # Array of tag names or IDs associated with this check. Use GET /api/v1/check-tags/ to list available tags.
  --is-paused: oneof<nothing, bool>
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
  --maintenance-schedules: list # Array of maintenance schedule IDs associated with this check.
  --msp-interval: int
  msp_address: string
  --msp-port: int # nullable
  --msp-username: string
  --msp-password: string
  --msp-proxy: string
  --msp-dns-server: string
  --msp-dns-record-type: string@msp-dns-record-type-completer
  --msp-status-code: string
  --msp-send-string: string
  --msp-expect-string: string
  --msp-expect-string-type: string@msp-expect-string-type-completer
  --msp-encryption: string@msp-encryption-completer
  --msp-threshold: int # nullable
  --msp-headers: string
  --msp-script: string
  --msp-version: int
  --msp-sensitivity: int
  --msp-num-retries: int
  --msp-use-ip-version: string@msp-use-ip-version-completer
  --msp-uptime-sla: string # format: decimal
  --msp-response-time-sla: string # nullable, format: decimal
  --msp-notes: string
  --msp-include-in-global-metrics: oneof<nothing, bool>
  --rumconfig: record # nullable — shape: {aggregation_type?: "MED"|"AVG"|"P75"|"P90"|"P95"|"P98"|"P99", exclude_useragents?: string, apdex_threshold?: int, url_groups?: string, external_domains?: string, exclude_get_params?: string, is_ajax_disabled?: bool}
  --groupcheckconfig: record # nullable — shape: {group_check_services?: list, group_check_tags?: list, group_check_down_condition?: "ANY"|"TWO"|"THREE"|"FOUR"|"FIVE"|"TEN"|"ONE_PCT"|"THREE_PCT"|"FIVE_PCT"|"TEN_PCT"|"TWENTYFIVE_PCT"|"FIFTY_PCT"|"ALL", group_uptime_percent_calculation?: "UP_DOWN_STATES"|"AVERAGE", group_response_time_calculation_mode?: "NONE"|"COPY"|"AVERAGE", group_response_time_check_type?: "HTTP"|"TRANSACTION"|"API"|"ICMP"|"HEARTBEAT"|"WEBHOOK", group_response_time_single_check?: string}
  --sslconfig: record # nullable — shape: {ssl_cert_protocol?: "https"|"ftp"|"ftps"|"http"|"h2"|"imap"|"imaps"|"irc"|"ircs"|"ldap"|"ldaps"|"mysql"|"pop3"|"pop3s"|"postgres"|"sieve"|"smtp"|"smtps"|"xmpp"|"xmpp-server", ssl_cert_crl?: bool, ssl_cert_first_element_only?: bool, ssl_cert_match?: string, ssl_cert_issuer?: string, ssl_cert_resolve?: string, ssl_cert_minimum_ssl_tls_version?: "sslv3"|"tlsv1"|"tlsv11"|"tlsv12"|"tlsv13", ssl_cert_fingerprint?: string, ssl_cert_selfsigned?: bool, ssl_cert_file?: string, ssl_ignore_authority_warnings?: bool, ssl_ignore_sct?: bool}
  --pagespeedconfig: record # nullable — shape: {emulated_device?: "DEFAULT"|"DESKTOP_LOW_END"|"IPHONE_17_PRO_MAX"|"IPHONE_17"|"IPHONE_16_PRO_MAX"|"IPHONE_16"|"IPHONE_15_PRO_MAX"|"IPHONE_15"|"IPHONE_14_PRO_MAX"|"IPHONE_13_PRO_MAX"|"IPHONE_13"|"IPHONE_12_PRO_MAX"|"IPHONE_12"|"IPHONE_11_PRO_MAX"|"IPHONE_11_PRO"|"IPHONE_11"|"GOOGLE_PIXEL_10"|"GOOGLE_PIXEL_10_PRO"|"GOOGLE_PIXEL_9"|"GOOGLE_PIXEL_9_PRO"|"GOOGLE_PIXEL_8_PRO"|"GOOGLE_PIXEL_7"|"GOOGLE_PIXEL_6"|"GOOGLE_PIXEL_6_PRO"|"SAMSUNG_GALAXY_S24_ULTRA"|"SAMSUNG_GALAXY_S23"|"SAMSUNG_GALAXY_Z_FOLD_5"|"SAMSUNG_GALAXY_S10"|"SAMSUNG_GALAXY_S10_PLUS"|"SAMSUNG_GALAXY_S21"|"SAMSUNG_GALAXY_S21_PLUS"|"SAMSUNG_GALAXY_S21_ULTRA"|"SAMSUNG_GALAXY_S22"|"IPAD_PRO_12_9"|"IPAD_AIR"|"IPAD_MINI"|"IPAD_PRO_11"|"MOBILE_MID_TIER"|"MOBILE_LOW_END", connection_throttling?: "UNTHROTTLED"|"BROADBAND_FAST"|"BROADBAND"|"BROADBAND_SLOW"|"LTE"|"FOUR_G"|"FOUR_G_SLOW"|"THREE_G"|"THREE_G_SLOW", exclude_urls?: string, uptime_grade_threshold?: ""|"A"|"B"|"C"|"D"|"E"|"F"}
  cloudstatusconfig: record # shape: {notify_only_on_down?: bool, service_name?: string, group?: int, monitoring_type?: "ALL"|"SPECIFIC", services?: list, service_titles?: list}
  --ftpconfig: record # nullable — shape: {ftp_paths?: string, ftp_skip_cert_verification?: bool, ftp_explicit_tls?: bool}
  --sftpconfig: record # nullable — shape: {ftp_paths?: string, sftp_private_key?: string, sftp_passphrase?: string, sftp_known_hosts?: string}
]: any -> record<pk: int, url: string, stats_url: string, alerts_url: string, share_url: string, name: string, cached_response_time: float, contact_groups: list<string>, created_at: string, modified_at: string, locations: list<string>, tags: list<string>, check_type: string, escalations: string, maintenance: string, monitoring_service_type: string, is_paused: bool, send_resolved_notifications: bool, is_under_maintenance: string, state_is_up: bool, state_changed_at: string, maintenance_schedules: list<int>, msp_interval: int, msp_address: string, msp_port: int, msp_username: string, msp_password: string, msp_proxy: string, msp_dns_server: string, msp_dns_record_type: string, msp_status_code: string, msp_send_string: string, msp_expect_string: string, msp_expect_string_type: string, msp_encryption: string, msp_threshold: int, msp_headers: string, msp_script: string, msp_version: int, msp_sensitivity: int, msp_num_retries: int, msp_use_ip_version: string, msp_uptime_sla: string, msp_response_time_sla: string, msp_notes: string, msp_include_in_global_metrics: bool, webhook_url: string, heartbeat_url: string, rumconfig: record<aggregation_type: string, exclude_useragents: string, apdex_threshold: int, url_groups: string, external_domains: string, exclude_get_params: string, is_ajax_disabled: bool>, groupcheckconfig: record<group_check_services: list<string>, group_check_tags: list<string>, group_check_down_condition: string, group_uptime_percent_calculation: string, group_response_time_calculation_mode: string, group_response_time_check_type: string, group_response_time_single_check: string>, sslconfig: record<ssl_cert_protocol: string, ssl_cert_crl: bool, ssl_cert_first_element_only: bool, ssl_cert_match: string, ssl_cert_issuer: string, ssl_cert_resolve: string, ssl_cert_minimum_ssl_tls_version: string, ssl_cert_fingerprint: string, ssl_cert_selfsigned: bool, ssl_cert_file: string, ssl_ignore_authority_warnings: bool, ssl_ignore_sct: bool>, pagespeedconfig: record<emulated_device: string, connection_throttling: string, exclude_urls: string, uptime_grade_threshold: string, cached_uptime_grade: string, cached_performance_score: int, cached_best_practices_score: int>, cloudstatusconfig: record<notify_only_on_down: bool, service_name: string, group: int, monitoring_type: string, services: list<int>, service_titles: list<string>>, ftpconfig: record<ftp_paths: string, ftp_skip_cert_verification: bool, ftp_explicit_tls: bool>, sftpconfig: record<ftp_paths: string, sftp_private_key: string, sftp_passphrase: string, sftp_known_hosts: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/checks/($pk)/")
  let body = {name: $name, contact_groups: $contact_groups, locations: $locations, tags: $tags, is_paused: $is_paused, send_resolved_notifications: $send_resolved_notifications, maintenance_schedules: $maintenance_schedules, msp_interval: $msp_interval, msp_address: $msp_address, msp_port: $msp_port, msp_username: $msp_username, msp_password: $msp_password, msp_proxy: $msp_proxy, msp_dns_server: $msp_dns_server, msp_dns_record_type: $msp_dns_record_type, msp_status_code: $msp_status_code, msp_send_string: $msp_send_string, msp_expect_string: $msp_expect_string, msp_expect_string_type: $msp_expect_string_type, msp_encryption: $msp_encryption, msp_threshold: $msp_threshold, msp_headers: $msp_headers, msp_script: $msp_script, msp_version: $msp_version, msp_sensitivity: $msp_sensitivity, msp_num_retries: $msp_num_retries, msp_use_ip_version: $msp_use_ip_version, msp_uptime_sla: $msp_uptime_sla, msp_response_time_sla: $msp_response_time_sla, msp_notes: $msp_notes, msp_include_in_global_metrics: $msp_include_in_global_metrics, rumconfig: $rumconfig, groupcheckconfig: $groupcheckconfig, sslconfig: $sslconfig, pagespeedconfig: $pagespeedconfig, cloudstatusconfig: $cloudstatusconfig, ftpconfig: $ftpconfig, sftpconfig: $sftpconfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a check
#
# DELETE /api/v1/checks/{pk}/
# operationId: delete_service_detail
export def "checks detail-by-pk-3" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/checks/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add additional contacts to a check  **Sample data (application/x-www-form-urlencoded):**  <pre>contact_groups[0]=Default&contact_groups[1]=Other</pre>  <br /> **Sample data (JSON):**      {"contact_groups": ["Default", "Other"]}  <br />
#
# PATCH /api/v1/checks/{pk}/add-contact-groups/
# operationId: patch_service_add_contact_groups
export def "checks-add-contact-groups groups" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  contact_groups: list # An array of contact group names or IDs to set on this check. Use GET /api/v1/contacts/ to list available contacts.
]: any -> record<contact_groups: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/checks/($pk)/add-contact-groups/")
  let body = {contact_groups: $contact_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add additional locations to a check  **Sample data (application/x-www-form-urlencoded):**  <pre>locations[0]=GBR&locations[1]=AUT</pre>  <br /> **Sample data (JSON):**      {"locations": ["GBR", "AUT"]}  <br />
#
# PATCH /api/v1/checks/{pk}/add-locations/
# operationId: patch_service_add_locations
export def "checks-add-locations locations" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  locations: list # An array of location names to add to this check. Use GET /api/v1/checks/locations/ to list available locations.
]: any -> record<locations: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/checks/($pk)/add-locations/")
  let body = {locations: $locations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add additional tags to a check  **Sample data (application/x-www-form-urlencoded):**  <pre>tags[0]=One&tags[1]=Two</pre>  <br /> **Sample data (JSON):**      {"tags": ["One", "Two"]}  <br />
#
# PATCH /api/v1/checks/{pk}/add-tags/
# operationId: patch_service_add_tags
export def "checks-add-tags tags" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tags: list # An array of tag names or IDs to set on this check. Use GET /api/v1/check-tags/ to list available tags.
]: any -> record<tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/checks/($pk)/add-tags/")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Shows the real-time analysis data - location status and recent alerts per location
#
# GET /api/v1/checks/{pk}/analysis/
# operationId: get_service_analysis
export def "checks-analysis analysis" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/checks/($pk)/analysis/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shows the current check state and latest downtime event for a check
#
# GET /api/v1/checks/{pk}/current-status/
# operationId: get_service_current_status
export def "checks-current-status status" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/checks/($pk)/current-status/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set escalations for a check  **Sample data (JSON):**      {         "escalations": [{             "wait_time": 5,             "num_repeats": 10             "contact_groups": ["Default", "Other"]         }]     }  <br />
#
# PATCH /api/v1/checks/{pk}/escalations/
# operationId: patch_service_set_escalations
# --escalations item shape: {wait_time: int, contact_groups: list, num_repeats?: int}
export def "checks-escalations escalations" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  escalations: list # A list of escalations to set on this check; see example above. — item shape: {wait_time: int, contact_groups: list, num_repeats?: int}
]: any -> record<escalations: table<wait_time: int, contact_groups: list, num_repeats: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/checks/($pk)/escalations/")
  let body = {escalations: $escalations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# [Deprecated soon] Set maintenance windows for a check  **Sample data (JSON):**      # Set under maintenance now     {         "state": "SUPPRESSED"     }      # Turn off maintenance     {         "state": "ACTIVE"     }      # Set weekly scheduled maintenance     {         "state": "SCHEDULED",         "schedule": [{             "type": "WEEKLY",             "from_time": "03:15",             "to_time": "18:30",             "weekdays": [6, 0]         }],         "pause_on_scheduled_maintenance": true     }      # Set monthly scheduled maintenance     {         "state": "SCHEDULED",         "schedule": [{             "type": "MONTHLY",             "from_time": "03:15",             "to_time": "18:30",             "monthday": 7         }],         "pause_on_scheduled_maintenance": false     }      or      {         "state": "SCHEDULED",         "schedule": [{             "type": "MONTHLY",             "from_time": "03:15",             "to_time": "18:30",             "monthday_from": 7,             "monthday_to": 9         }],         "pause_on_scheduled_maintenance": true     }      # Set one-off scheduled maintenance     {         "state": "SCHEDULED",         "schedule": [{             "type": "ONCE",             "once_start_date": "2022-10-06T18:30:00Z",             "once_end_date": "2022-10-07T14:30:00Z"         }],         "pause_on_scheduled_maintenance": false     }
#
# PATCH /api/v1/checks/{pk}/maintenance/
# operationId: patch_service_set_maintenance
# --schedule item shape: {weekdays?: list, monthday?: int, start_date?: string, to_time?: string, type: "WEEKLY"|"MONTHLY"|"ONCE", once_start_date?: string, once_end_date?: string, from_time?: string, monthday_from?: int, monthday_to?: int}
export def "checks-maintenance maintenance" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  state: string@state-completer # Current state of the check; ACTIVE (alerts sent normally), SUPPRESSED (under maintenance), SCHEDULED (maintenance windows as defined in the schedule)
  --schedule: list # The schedule entries for maintenance windows; see example above. (default: []) — item shape: {weekdays?: list, monthday?: int, start_date?: string, to_time?: string, type: "WEEKLY"|"MONTHLY"|"ONCE", once_start_date?: string, once_end_date?: string, from_time?: string, monthday_from?: int, monthday_to?: int}
  --pause-on-scheduled-maintenance: oneof<nothing, bool> # Stop check execution during maintenance mode (affects SCHEDULED only). (default: false)
]: any -> record<state: string, schedule: table<id: int, weekdays: list, monthday: int, start_date: string, to_time: string, type: string, once_start_date: string, once_end_date: string, from_time: string, monthday_from: int, monthday_to: int>, pause_on_scheduled_maintenance: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/checks/($pk)/maintenance/")
  let body = {state: $state, schedule: $schedule, pause_on_scheduled_maintenance: $pause_on_scheduled_maintenance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Pause a check
#
# POST /api/v1/checks/{pk}/pause/
# operationId: post_service_pause
export def "checks-pause pause" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --send-resolved-notifications: oneof<nothing, bool> # Send resolve notifications when pausing the check (default: false)
]: any -> record<send_resolved_notifications: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/checks/($pk)/pause/")
  let body = {send_resolved_notifications: $send_resolved_notifications} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace all contacts on a check  **Sample data (application/x-www-form-urlencoded):**  <pre>contact_groups[0]=Default&contact_groups[1]=Other</pre>  <br /> **Sample data (JSON):**      {"contact_groups": ["Default", "Other"]}  <br />
#
# PATCH /api/v1/checks/{pk}/replace-contact-groups/
# operationId: patch_service_replace_contact_groups
export def "checks-replace-contact-groups groups" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  contact_groups: list # An array of contact group names or IDs to set on this check. Use GET /api/v1/contacts/ to list available contacts.
]: any -> record<contact_groups: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/checks/($pk)/replace-contact-groups/")
  let body = {contact_groups: $contact_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace all locations on a check  **Sample data (application/x-www-form-urlencoded):**  <pre>locations[0]=GBR&locations[1]=AUT</pre>  <br /> **Sample data (JSON):**      {"locations": ["GBR", "AUT"]}  <br />
#
# PATCH /api/v1/checks/{pk}/replace-locations/
# operationId: patch_service_replace_locations
export def "checks-replace-locations locations" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  locations: list # An array of location names to add to this check. Use GET /api/v1/checks/locations/ to list available locations.
]: any -> record<locations: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/checks/($pk)/replace-locations/")
  let body = {locations: $locations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace all tags on a check  **Sample data (application/x-www-form-urlencoded):**  <pre>tags[0]=One&tags[1]=Two</pre>  <br /> **Sample data (JSON):**      {"tags": ["One", "Two"]}  <br />
#
# PATCH /api/v1/checks/{pk}/replace-tags/
# operationId: patch_service_replace_tags
export def "checks-replace-tags tags" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tags: list # An array of tag names or IDs to set on this check. Use GET /api/v1/check-tags/ to list available tags.
]: any -> record<tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/checks/($pk)/replace-tags/")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns raw response time data for a check for all locations.
#
# GET /api/v1/checks/{pk}/response-time/
# operationId: get_service_response_time_datapoints
export def "checks-response-time datapoints" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # The first day to show statistics for in ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) format.
  --end-date: string # The last day to show statistics for in ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) format.
]: nothing -> record<start_date: string, end_date: string, response_time: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/checks/($pk)/response-time/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resume a check
#
# POST /api/v1/checks/{pk}/resume/
# operationId: post_service_resume
export def "checks-resume resume" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/checks/($pk)/resume/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shows uptime and response time statistics for this check
#
# GET /api/v1/checks/{pk}/stats/
# operationId: get_service_stats
export def "checks-stats stats" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # The first day to show statistics for in ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) format.
  --end-date: string # The last day to show statistics for in ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) format.
  --location: string # Show response time for specified location only.
  --locations-response-times: oneof<nothing, bool> # Include response time datapoints for all locations.
  --include-alerts: oneof<nothing, bool> # Include alert data for each outage in the period.
  --download: oneof<nothing, bool> # Set this paramater to download an XLS containing the stats.
  --pdf: oneof<nothing, bool> # Set this paramater to download a PDF report.
]: nothing -> record<start_date: string, end_date: string, location: string, locations_response_times: bool, include_alerts: bool, download: bool, pdf: bool, available_locations: list<any>, pk: int, statistics: list<record>, totals: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "locations_response_times" $locations_response_times "scalar") (serialize-qp "include_alerts" $include_alerts "scalar") (serialize-qp "download" $download "scalar") (serialize-qp "pdf" $pdf "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/checks/($pk)/stats/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all contacts
#
# GET /api/v1/contacts/
# operationId: get_contactgrouplist
export def "contacts contactgrouplist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-3 # Order results by this field.
  --has-on-call-schedule: oneof<nothing, bool> # Filter by contacts that have on-call schedules defined.
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, url: string, created_at: string, modified_at: string, name: string, sms_list: list, email_list: list, phonecall_list: list, integrations: list, push_notification_profiles: list, oncall_schedule: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "has_on_call_schedule" $has_on_call_schedule "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/contacts/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new contact
#
# POST /api/v1/contacts/
# operationId: post_contactgrouplist
export def "contacts contactgrouplist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of this contact
  --sms-list: list # Array of cellphone numbers for SMS alerts (valid international phone number starting with +)
  --email-list: list # Array of email addresses to receive alerts
  --phonecall-list: list # Array of cellphone numbers for voice call alerts (valid international phone number starting with +)
  --integrations: list # Array of integration names or IDs associated with this contact
  --push-notification-profiles: list # Array of integration names or IDs associated with this contact
]: any -> record<pk: int, url: string, created_at: string, modified_at: string, name: string, sms_list: list<string>, email_list: list<string>, phonecall_list: list<string>, integrations: list<string>, push_notification_profiles: list<string>, oncall_schedule: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/contacts/")
  let body = {name: $name, sms_list: $sms_list, email_list: $email_list, phonecall_list: $phonecall_list, integrations: $integrations, push_notification_profiles: $push_notification_profiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single contact
#
# GET /api/v1/contacts/{pk}/
# operationId: get_contact_group_detail
export def "contacts detail-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, created_at: string, modified_at: string, name: string, sms_list: list<string>, email_list: list<string>, phonecall_list: list<string>, integrations: list<string>, push_notification_profiles: list<string>, oncall_schedule: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/contacts/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a contact
#
# PUT /api/v1/contacts/{pk}/
# operationId: put_contact_group_detail
export def "contacts detail-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of this contact
  --sms-list: list # Array of cellphone numbers for SMS alerts (valid international phone number starting with +)
  --email-list: list # Array of email addresses to receive alerts
  --phonecall-list: list # Array of cellphone numbers for voice call alerts (valid international phone number starting with +)
  --integrations: list # Array of integration names or IDs associated with this contact
  --push-notification-profiles: list # Array of integration names or IDs associated with this contact
]: any -> record<pk: int, url: string, created_at: string, modified_at: string, name: string, sms_list: list<string>, email_list: list<string>, phonecall_list: list<string>, integrations: list<string>, push_notification_profiles: list<string>, oncall_schedule: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/contacts/($pk)/")
  let body = {name: $name, sms_list: $sms_list, email_list: $email_list, phonecall_list: $phonecall_list, integrations: $integrations, push_notification_profiles: $push_notification_profiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a contact
#
# PATCH /api/v1/contacts/{pk}/
# operationId: patch_contact_group_detail
export def "contacts detail-by-pk-2" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of this contact
  --sms-list: list # Array of cellphone numbers for SMS alerts (valid international phone number starting with +)
  --email-list: list # Array of email addresses to receive alerts
  --phonecall-list: list # Array of cellphone numbers for voice call alerts (valid international phone number starting with +)
  --integrations: list # Array of integration names or IDs associated with this contact
  --push-notification-profiles: list # Array of integration names or IDs associated with this contact
]: any -> record<pk: int, url: string, created_at: string, modified_at: string, name: string, sms_list: list<string>, email_list: list<string>, phonecall_list: list<string>, integrations: list<string>, push_notification_profiles: list<string>, oncall_schedule: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/contacts/($pk)/")
  let body = {name: $name, sms_list: $sms_list, email_list: $email_list, phonecall_list: $phonecall_list, integrations: $integrations, push_notification_profiles: $push_notification_profiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a contact
#
# DELETE /api/v1/contacts/{pk}/
# operationId: delete_contact_group_detail
export def "contacts detail-by-pk-3" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/contacts/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set the on-call schedule for a contact.  **Sample data (JSON):**      # Set always on-call     {         "state": "ACTIVE"     }      # Set weekly on-call schedule     {         "state": "SCHEDULED",         "schedule": [{             "type": "WEEKLY",             "from_time": "03:15",             "to_time": "18:30",             "weekdays": [6, 0]         }]     }      # Set monthly schedule     {         "state": "SCHEDULED",         "schedule": [{             "type": "MONTHLY",             "from_time": "03:15",             "to_time": "18:30",             "monthday": 7         }]     }      or      {         "state": "SCHEDULED",         "schedule": [{             "type": "MONTHLY",             "from_time": "03:15",             "to_time": "18:30",             "monthday_from": 7,             "monthday_to": 9         }]     }
#
# PATCH /api/v1/contacts/{pk}/oncall/
# operationId: patch_contact_group_set_on_call_hours
# --schedule item shape: {weekdays: list, to_time?: string, type: "WEEKLY"|"MONTHLY"|"ONCE", once_start_date?: string, once_end_date?: string, from_time?: string, monthday_from?: int, monthday_to?: int}
export def "contacts-oncall hours" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  state: string@state-completer # Whether to use an on-call schedule. Either ACTIVE (always on call) or SCHEDULED (use defined schedule).
  --schedule: list # The schedule entries for when the contact is on-call; see example above. (default: []) — item shape: {weekdays: list, to_time?: string, type: "WEEKLY"|"MONTHLY"|"ONCE", once_start_date?: string, once_end_date?: string, from_time?: string, monthday_from?: int, monthday_to?: int}
]: any -> record<state: string, schedule: table<id: int, weekdays: list, to_time: string, type: string, once_start_date: string, once_end_date: string, from_time: string, monthday_from: int, monthday_to: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/contacts/($pk)/oncall/")
  let body = {state: $state, schedule: $schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all credentials
#
# GET /api/v1/credentials/
# operationId: get_credentiallist
export def "credentials credentiallist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-4 # Order results by this field.
  --credential-type: string@credential-type-completer # Filter by credential type.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, credential_type: string, display_name: string, description: string, hint: string, username: string, version: string, used_secret_properties: list, created_by: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "credential_type" $credential_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/credentials/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new credential      ** Request Body Requirements **      There are multiple types of credentials and each has an expected shape for the secret and potentially other required or optional fields.      The following is a list of the credential types and their expected shapes:      #Username and Password - this is the only credential type that will allow you to specify a username     {         "credential_type": "BASIC",         "username": "my_username",         "secret": {             "password": "my_password"         }     }      # Certificate     {         "credential_type": "CERTIFICATE",         "secret": {             "certificate": "my_certificate",             "key": "my_key", # optional             "passphrase": "my_passphrase" # optional         }     }      # Token - this is the option you want to store any kind of secret that doesn't fit into the other categories     {         "credential_type": "TOKEN",         "secret": {             "secret": "my_secret"         }     }
#
# POST /api/v1/credentials/
# operationId: post_credentiallist
export def "credentials credentiallist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  credential_type: string@credential-type-completer
  display_name: string
  --description: string
  secret: record
  --username: string
]: any -> record<id: int, credential_type: string, display_name: string, description: string, hint: string, username: string, version: string, used_secret_properties: list<string>, created_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/credentials/")
  let body = {credential_type: $credential_type, display_name: $display_name, description: $description, secret: $secret, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single credential
#
# GET /api/v1/credentials/{pk}/
# operationId: get_credential_methods_base_path_with_id
export def "credentials id-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, credential_type: string, display_name: string, description: string, hint: string, username: string, version: string, used_secret_properties: list<string>, created_by: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/credentials/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a credential      When updating a credential the secret is completely replaced with the new secret provided in the request body.     It is not possible to update individual fields of the secret. All previous fields will be lost.          ** Request Body Requirements **          There are multiple types of credentials and each has an expected shape for the secret and potentially other required or optional fields.          The following is a list of the credential types and their expected shapes:          #Username and Password - this is the only credential type that will allow you to specify a username         {             "credential_type": "BASIC",             "username": "my_username",             "secret": {                 "password": "my_password"             }         }          # Certificate         {             "credential_type": "CERTIFICATE",             "secret": {                 "certificate": "my_certificate",                 "key": "my_key", # optional                 "passphrase": "my_passphrase" # optional             }         }          # Token - this is the option you want to store any kind of secret that doesn't fit into the other categories         {             "credential_type": "TOKEN",             "secret": {                 "secret": "my_secret"             }         }
#
# PATCH /api/v1/credentials/{pk}/
# operationId: patch_credential_methods_base_path_with_id
# --secret shape: {secret?: string, password?: string, certificate?: string, key?: string, passphrase?: string, period?: int, num_digits?: int}
export def "credentials id-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --display-name: string # default: 
  --description: string # default: 
  --secret: record # nullable — shape: {secret?: string, password?: string, certificate?: string, key?: string, passphrase?: string, period?: int, num_digits?: int}
  --username: string # default: 
]: any -> record<id: int, credential_type: string, display_name: string, description: string, hint: string, username: string, version: string, used_secret_properties: list<string>, created_by: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/credentials/($pk)/")
  let body = {display_name: $display_name, description: $description, secret: $secret, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a credential
#
# DELETE /api/v1/credentials/{pk}/
# operationId: delete_credential_methods_base_path_with_id
export def "credentials id-by-pk-2" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/credentials/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all dashboards
#
# GET /api/v1/dashboards/
# operationId: get_dashboardlist
export def "dashboards dashboardlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-5 # Order results by this field.
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, url: string, stats_url: string, services_selected: list, services_tags: list, ordering: int, created_at: string, name: string, is_pinned: bool, metrics_show_section: bool, metrics_for_all_checks: bool, services_show_section: bool, services_num_to_show: int, match_all_tags: bool, services_include_up: bool, services_include_down: bool, services_include_paused: bool, services_include_maintenance: bool, services_primary_sort: string, services_secondary_sort: string, services_show_uptime: bool, services_show_response_time: bool, alerts_show_section: bool, alerts_for_all_checks: bool, alerts_include_ignored: bool, alerts_include_resolved: bool, alerts_num_to_show: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/dashboards/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new dashboard
#
# POST /api/v1/dashboards/
# operationId: post_dashboardlist
export def "dashboards dashboardlist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pk: int
  --services-selected: list # Include checks from this list
  --services-tags: list # Include checks with one or more of the selected tags
  --ordering: int # Sidebar ordering for this dashboard
  --name: string # The displayed name for this dashboard
  --is-pinned: oneof<nothing, bool> # Whether this dashboard is pinned to the sidebar
  --metrics-show-section: oneof<nothing, bool> # Show/hide the Summary Metrics section at the top of this dashboard
  --metrics-for-all-checks: oneof<nothing, bool> # Include metrics from all checks, not just the selected checks
  --services-show-section: oneof<nothing, bool> # Show/hide the check cards from this dashboard
  --services-num-to-show: int@services-num-to-show-completer # Number of check cards to show in the Checks section
  --match-all-tags: oneof<nothing, bool> # When true, checks must have all selected tags; when false, checks need only one
  --services-include-up: oneof<nothing, bool> # Include/exclude checks which are currently up
  --services-include-down: oneof<nothing, bool> # Include/exclude checks which are currently down
  --services-include-paused: oneof<nothing, bool> # Include/exclude checks which are currently paused
  --services-include-maintenance: oneof<nothing, bool> # Include/exclude checks which are manually marked for maintenance
  --services-primary-sort: string@services-primary-sort-completer # The primary value for ordering the checks
  --services-secondary-sort: string@services-secondary-sort-completer # The secondary value for ordering the checks, if the primary value is the same
  --services-show-uptime: oneof<nothing, bool> # Show the 24h uptime percentage on each check card
  --services-show-response-time: oneof<nothing, bool> # Show the response time graph or metric on each check card
  --alerts-show-section: oneof<nothing, bool> # Show/hide the Latest Alerts section from this dashboard
  --alerts-for-all-checks: oneof<nothing, bool> # Show/hide alerts globally across all checks, rather than only for checks selected in the Checks tab
  --alerts-include-ignored: oneof<nothing, bool> # Include/exclude alerts marked as "ignored" in the alerts listing
  --alerts-include-resolved: oneof<nothing, bool> # Include/exclude alerts that are no longer down in the alerts listing
  --alerts-num-to-show: int@alerts-num-to-show-completer # Number of alerts to show in the Latest Alerts section
]: any -> record<pk: int, url: string, stats_url: string, services_selected: list<string>, services_tags: list<string>, ordering: int, created_at: string, name: string, is_pinned: bool, metrics_show_section: bool, metrics_for_all_checks: bool, services_show_section: bool, services_num_to_show: int, match_all_tags: bool, services_include_up: bool, services_include_down: bool, services_include_paused: bool, services_include_maintenance: bool, services_primary_sort: string, services_secondary_sort: string, services_show_uptime: bool, services_show_response_time: bool, alerts_show_section: bool, alerts_for_all_checks: bool, alerts_include_ignored: bool, alerts_include_resolved: bool, alerts_num_to_show: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/dashboards/")
  let body = {pk: $pk, services_selected: $services_selected, services_tags: $services_tags, ordering: $ordering, name: $name, is_pinned: $is_pinned, metrics_show_section: $metrics_show_section, metrics_for_all_checks: $metrics_for_all_checks, services_show_section: $services_show_section, services_num_to_show: $services_num_to_show, match_all_tags: $match_all_tags, services_include_up: $services_include_up, services_include_down: $services_include_down, services_include_paused: $services_include_paused, services_include_maintenance: $services_include_maintenance, services_primary_sort: $services_primary_sort, services_secondary_sort: $services_secondary_sort, services_show_uptime: $services_show_uptime, services_show_response_time: $services_show_response_time, alerts_show_section: $alerts_show_section, alerts_for_all_checks: $alerts_for_all_checks, alerts_include_ignored: $alerts_include_ignored, alerts_include_resolved: $alerts_include_resolved, alerts_num_to_show: $alerts_num_to_show} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Shows the default dashboard defined by the system
#
# GET /api/v1/dashboards/default/
# operationId: get_dashboard_default
export def "dashboards-default default" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, stats_url: string, services_selected: list<string>, services_tags: list<string>, ordering: int, created_at: string, name: string, is_pinned: bool, metrics_show_section: bool, metrics_for_all_checks: bool, services_show_section: bool, services_num_to_show: int, match_all_tags: bool, services_include_up: bool, services_include_down: bool, services_include_paused: bool, services_include_maintenance: bool, services_primary_sort: string, services_secondary_sort: string, services_show_uptime: bool, services_show_response_time: bool, alerts_show_section: bool, alerts_for_all_checks: bool, alerts_include_ignored: bool, alerts_include_resolved: bool, alerts_num_to_show: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/dashboards/default/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single dashboard definition
#
# GET /api/v1/dashboards/{pk}/
# operationId: get_dashboard_detail
export def "dashboards detail-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, stats_url: string, services_selected: list<string>, services_tags: list<string>, ordering: int, created_at: string, name: string, is_pinned: bool, metrics_show_section: bool, metrics_for_all_checks: bool, services_show_section: bool, services_num_to_show: int, match_all_tags: bool, services_include_up: bool, services_include_down: bool, services_include_paused: bool, services_include_maintenance: bool, services_primary_sort: string, services_secondary_sort: string, services_show_uptime: bool, services_show_response_time: bool, alerts_show_section: bool, alerts_for_all_checks: bool, alerts_include_ignored: bool, alerts_include_resolved: bool, alerts_num_to_show: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboards/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a dashboard definition
#
# PUT /api/v1/dashboards/{pk}/
# operationId: put_dashboard_detail
export def "dashboards detail-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-pk: int
  --services-selected: list # Include checks from this list
  --services-tags: list # Include checks with one or more of the selected tags
  --ordering: int # Sidebar ordering for this dashboard
  --name: string # The displayed name for this dashboard
  --is-pinned: oneof<nothing, bool> # Whether this dashboard is pinned to the sidebar
  --metrics-show-section: oneof<nothing, bool> # Show/hide the Summary Metrics section at the top of this dashboard
  --metrics-for-all-checks: oneof<nothing, bool> # Include metrics from all checks, not just the selected checks
  --services-show-section: oneof<nothing, bool> # Show/hide the check cards from this dashboard
  --services-num-to-show: int@services-num-to-show-completer # Number of check cards to show in the Checks section
  --match-all-tags: oneof<nothing, bool> # When true, checks must have all selected tags; when false, checks need only one
  --services-include-up: oneof<nothing, bool> # Include/exclude checks which are currently up
  --services-include-down: oneof<nothing, bool> # Include/exclude checks which are currently down
  --services-include-paused: oneof<nothing, bool> # Include/exclude checks which are currently paused
  --services-include-maintenance: oneof<nothing, bool> # Include/exclude checks which are manually marked for maintenance
  --services-primary-sort: string@services-primary-sort-completer # The primary value for ordering the checks
  --services-secondary-sort: string@services-secondary-sort-completer # The secondary value for ordering the checks, if the primary value is the same
  --services-show-uptime: oneof<nothing, bool> # Show the 24h uptime percentage on each check card
  --services-show-response-time: oneof<nothing, bool> # Show the response time graph or metric on each check card
  --alerts-show-section: oneof<nothing, bool> # Show/hide the Latest Alerts section from this dashboard
  --alerts-for-all-checks: oneof<nothing, bool> # Show/hide alerts globally across all checks, rather than only for checks selected in the Checks tab
  --alerts-include-ignored: oneof<nothing, bool> # Include/exclude alerts marked as "ignored" in the alerts listing
  --alerts-include-resolved: oneof<nothing, bool> # Include/exclude alerts that are no longer down in the alerts listing
  --alerts-num-to-show: int@alerts-num-to-show-completer # Number of alerts to show in the Latest Alerts section
]: any -> record<pk: int, url: string, stats_url: string, services_selected: list<string>, services_tags: list<string>, ordering: int, created_at: string, name: string, is_pinned: bool, metrics_show_section: bool, metrics_for_all_checks: bool, services_show_section: bool, services_num_to_show: int, match_all_tags: bool, services_include_up: bool, services_include_down: bool, services_include_paused: bool, services_include_maintenance: bool, services_primary_sort: string, services_secondary_sort: string, services_show_uptime: bool, services_show_response_time: bool, alerts_show_section: bool, alerts_for_all_checks: bool, alerts_include_ignored: bool, alerts_include_resolved: bool, alerts_num_to_show: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboards/($pk)/")
  let body = {pk: $body_pk, services_selected: $services_selected, services_tags: $services_tags, ordering: $ordering, name: $name, is_pinned: $is_pinned, metrics_show_section: $metrics_show_section, metrics_for_all_checks: $metrics_for_all_checks, services_show_section: $services_show_section, services_num_to_show: $services_num_to_show, match_all_tags: $match_all_tags, services_include_up: $services_include_up, services_include_down: $services_include_down, services_include_paused: $services_include_paused, services_include_maintenance: $services_include_maintenance, services_primary_sort: $services_primary_sort, services_secondary_sort: $services_secondary_sort, services_show_uptime: $services_show_uptime, services_show_response_time: $services_show_response_time, alerts_show_section: $alerts_show_section, alerts_for_all_checks: $alerts_for_all_checks, alerts_include_ignored: $alerts_include_ignored, alerts_include_resolved: $alerts_include_resolved, alerts_num_to_show: $alerts_num_to_show} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a dashboard definition
#
# PATCH /api/v1/dashboards/{pk}/
# operationId: patch_dashboard_detail
export def "dashboards detail-by-pk-2" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-pk: int
  --services-selected: list # Include checks from this list
  --services-tags: list # Include checks with one or more of the selected tags
  --ordering: int # Sidebar ordering for this dashboard
  --name: string # The displayed name for this dashboard
  --is-pinned: oneof<nothing, bool> # Whether this dashboard is pinned to the sidebar
  --metrics-show-section: oneof<nothing, bool> # Show/hide the Summary Metrics section at the top of this dashboard
  --metrics-for-all-checks: oneof<nothing, bool> # Include metrics from all checks, not just the selected checks
  --services-show-section: oneof<nothing, bool> # Show/hide the check cards from this dashboard
  --services-num-to-show: int@services-num-to-show-completer # Number of check cards to show in the Checks section
  --match-all-tags: oneof<nothing, bool> # When true, checks must have all selected tags; when false, checks need only one
  --services-include-up: oneof<nothing, bool> # Include/exclude checks which are currently up
  --services-include-down: oneof<nothing, bool> # Include/exclude checks which are currently down
  --services-include-paused: oneof<nothing, bool> # Include/exclude checks which are currently paused
  --services-include-maintenance: oneof<nothing, bool> # Include/exclude checks which are manually marked for maintenance
  --services-primary-sort: string@services-primary-sort-completer # The primary value for ordering the checks
  --services-secondary-sort: string@services-secondary-sort-completer # The secondary value for ordering the checks, if the primary value is the same
  --services-show-uptime: oneof<nothing, bool> # Show the 24h uptime percentage on each check card
  --services-show-response-time: oneof<nothing, bool> # Show the response time graph or metric on each check card
  --alerts-show-section: oneof<nothing, bool> # Show/hide the Latest Alerts section from this dashboard
  --alerts-for-all-checks: oneof<nothing, bool> # Show/hide alerts globally across all checks, rather than only for checks selected in the Checks tab
  --alerts-include-ignored: oneof<nothing, bool> # Include/exclude alerts marked as "ignored" in the alerts listing
  --alerts-include-resolved: oneof<nothing, bool> # Include/exclude alerts that are no longer down in the alerts listing
  --alerts-num-to-show: int@alerts-num-to-show-completer # Number of alerts to show in the Latest Alerts section
]: any -> record<pk: int, url: string, stats_url: string, services_selected: list<string>, services_tags: list<string>, ordering: int, created_at: string, name: string, is_pinned: bool, metrics_show_section: bool, metrics_for_all_checks: bool, services_show_section: bool, services_num_to_show: int, match_all_tags: bool, services_include_up: bool, services_include_down: bool, services_include_paused: bool, services_include_maintenance: bool, services_primary_sort: string, services_secondary_sort: string, services_show_uptime: bool, services_show_response_time: bool, alerts_show_section: bool, alerts_for_all_checks: bool, alerts_include_ignored: bool, alerts_include_resolved: bool, alerts_num_to_show: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboards/($pk)/")
  let body = {pk: $body_pk, services_selected: $services_selected, services_tags: $services_tags, ordering: $ordering, name: $name, is_pinned: $is_pinned, metrics_show_section: $metrics_show_section, metrics_for_all_checks: $metrics_for_all_checks, services_show_section: $services_show_section, services_num_to_show: $services_num_to_show, match_all_tags: $match_all_tags, services_include_up: $services_include_up, services_include_down: $services_include_down, services_include_paused: $services_include_paused, services_include_maintenance: $services_include_maintenance, services_primary_sort: $services_primary_sort, services_secondary_sort: $services_secondary_sort, services_show_uptime: $services_show_uptime, services_show_response_time: $services_show_response_time, alerts_show_section: $alerts_show_section, alerts_for_all_checks: $alerts_for_all_checks, alerts_include_ignored: $alerts_include_ignored, alerts_include_resolved: $alerts_include_resolved, alerts_num_to_show: $alerts_num_to_show} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a dashboard definition
#
# DELETE /api/v1/dashboards/{pk}/
# operationId: delete_dashboard_detail
export def "dashboards detail-by-pk-3" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/dashboards/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shows the real-time statistics for this dashboard.
#
# GET /api/v1/dashboards/{pk}/stats/
# operationId: get_dashboard_stats
export def "dashboards-stats stats" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<global_metrics: record, checks: table<pk: int, url: string, name: string, msp_address: string, created_at: string, check_type: string, monitoring_service_type: string, msp_interval: int, is_paused: bool, is_under_maintenance: bool, state_is_up: bool, state_changed_at: string, cached_response_time: float, response_time_datapoints: list, uptime_24h: float>, latest_outages: table<pk: int, url: string, created_at: string, resolved_at: string, duration_secs: string, ignore_alert_url: string, check_pk: int, check_url: string, check_address: string, check_name: string, check_is_paused: bool, check_monitoring_service_type: string, state_is_up: bool, ignored: bool, num_locations_down: int, all_alerts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboards/($pk)/stats/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all integrations
#
# GET /api/v1/integrations/
# operationId: get_integrationlist
export def "integrations integrationlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-6 # Order results by this field.
  --qp-module: string@module-completer # Filter by integration provider.
  --is-errored: oneof<nothing, bool> # Filter by whether this integration has stopped due to errors.
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, url: string, name: string, module: string, contact_groups: list, is_errored: bool, last_error: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "module" $qp_module "scalar") (serialize-qp "is_errored" $is_errored "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/integrations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Cachet integration
#
# POST /api/v1/integrations/add-cachet/
# operationId: post_integration_create_cachet
export def "integrations-add-cachet cachet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # Root URL of your Cachet installation. (format: uri)
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --body-token: string # Your API token.
  --component: string # Component to update with availability status.
  --metric: string # Metric to update with response time data.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, token: string, component: string, metric: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-cachet/")
  let body = {url: $body_url, name: $name, contact_groups: $contact_groups, token: $body_token, component: $component, metric: $metric} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Datadog integration
#
# POST /api/v1/integrations/add-datadog/
# operationId: post_integration_create_datadog
export def "integrations-add-datadog datadog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --api-key: string
  --app-key: string
  --region: string@region-completer
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, api_key: string, app_key: string, region: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-datadog/")
  let body = {name: $name, contact_groups: $contact_groups, api_key: $api_key, app_key: $app_key, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Discord integration
#
# POST /api/v1/integrations/add-discord/
# operationId: post_integration_create_discord
export def "integrations-add-discord discord" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --webhook-url: string # format: uri
  --channel: string
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, webhook_url: string, channel: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-discord/")
  let body = {name: $name, contact_groups: $contact_groups, webhook_url: $webhook_url, channel: $channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Geckoboard integration
#
# POST /api/v1/integrations/add-geckoboard/
# operationId: post_integration_create_geckoboard
export def "integrations-add-geckoboard geckoboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --api-key: string
  --dataset-name: string
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, api_key: string, dataset_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-geckoboard/")
  let body = {name: $name, contact_groups: $contact_groups, api_key: $api_key, dataset_name: $dataset_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Google Chat integration
#
# POST /api/v1/integrations/add-google-chat/
# operationId: post_integration_create_google_chat
export def "integrations-add-google-chat chat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --webhook-url: string # format: uri
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-google-chat/")
  let body = {name: $name, contact_groups: $contact_groups, webhook_url: $webhook_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Grafana Graphite integration
#
# POST /api/v1/integrations/add-grafana-graphite/
# operationId: post_integration_create_grafana_graphite
export def "integrations-add-grafana-graphite graphite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --graphite-url: string # Graphite-compatible metrics endpoint, e.g. https://graphite-prod-XX-prod-XX.grafana.net/graphite/metrics. (format: uri)
  --metrics-instance-id: string # Numeric instance ID used as the username for Graphite basic auth.
  --metrics-api-token: string # API key or service account token for Graphite metrics ingestion (basic auth).
  --tags: string # Optional Graphite tags attached to every pushed metric. Enter one key=value pair per line, or separate with commas.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, graphite_url: string, metrics_instance_id: string, metrics_api_token: string, tags: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-grafana-graphite/")
  let body = {name: $name, contact_groups: $contact_groups, graphite_url: $graphite_url, metrics_instance_id: $metrics_instance_id, metrics_api_token: $metrics_api_token, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Grafana Prometheus integration
#
# POST /api/v1/integrations/add-grafana-prometheus/
# operationId: post_integration_create_grafana_prometheus
export def "integrations-add-grafana-prometheus prometheus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --prometheus-url: string # Grafana Cloud Prometheus remote_write endpoint, e.g. https://prometheus-prod-XX-prod-XX.grafana.net/api/prom/push. (format: uri)
  --metrics-instance-id: string # Numeric instance ID used as the username for basic auth.
  --metrics-api-token: string # API key or service account token for Prometheus metrics ingestion (basic auth).
  --tags: string # Optional Prometheus labels attached to every pushed sample. Enter one key=value pair per line, or separate with commas.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, prometheus_url: string, metrics_instance_id: string, metrics_api_token: string, tags: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-grafana-prometheus/")
  let body = {name: $name, contact_groups: $contact_groups, prometheus_url: $prometheus_url, metrics_instance_id: $metrics_instance_id, metrics_api_token: $metrics_api_token, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new ilert.com integration
#
# POST /api/v1/integrations/add-ilert/
# operationId: post_integration_create_ilert
export def "integrations-add-ilert ilert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --postback-url: string # format: uri
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, postback_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-ilert/")
  let body = {name: $name, contact_groups: $contact_groups, postback_url: $postback_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Jira Service Desk integration
#
# POST /api/v1/integrations/add-jiraservicedesk/
# operationId: post_integration_create_jiraservicedesk
export def "integrations-add-jiraservicedesk jiraservicedesk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --api-email: string # Email of the user whose API token is being used.
  --api-token: string # API Token created for the user, or the user's password (self-hosted only).
  --jira-subdomain: string # The domain your company uses to access Jira, e.g. "https://your-domain.atlassian.net" (format: uri)
  --project-key: string # The project key of your Service Desk project, shown on the Project Settings > Details page. E.g. "SMPSRVDESK"
  --labels: string # A comma separated list of labels attached to each incident created. The "Uptime.com" label any associated check tags are always set.
  --custom-field-id-account-name: int # An optional ID for a custom text field that should receive the account name.
  --custom-field-id-check-name: int # An optional ID for a custom text field that should receive the check name.
  --custom-field-id-check-url: int # An optional ID for a custom text field that should receive the check URL.
  --custom-fields-json: string #  <div class="dropdown">   Advanced configuration for custom fields using JSON format. See   <a href="#" role="button" id="dropdownMenuLink" data-toggle="dropdown" aria-haspopup="true"       aria-expanded="false">example values</a>.   <div class="dropdown-menu border dark-shadow" style="width: 37rem;"       aria-labelledby="dropdownMenuLink"> <pre><code>   {     "customfield_10000": "this is a text field",     "customfield_20000": "this is a multi-line text field. big text.",     "customfield_30000": "2011-07-13T15:25:00",     "customfield_40000": {       "value": "this is a select list value"     },     "customfield_50000": {       "name": "this is a group picker value"     },     "customfield_60000": [       {"value": "this is a multi select list value #1"},       {"value": "this is a multi select list value #2"}     ],   } </code></pre>   </div> </div>
  --alert-resolved-label: string # When you fill in this field, a label will be added to the Jira issue once the Alert is resolved. Note: Spaces are not supported.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, api_email: string, api_token: string, jira_subdomain: string, project_key: string, labels: string, custom_field_id_account_name: int, custom_field_id_check_name: int, custom_field_id_check_url: int, custom_fields_json: string, alert_resolved_label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-jiraservicedesk/")
  let body = {name: $name, contact_groups: $contact_groups, api_email: $api_email, api_token: $api_token, jira_subdomain: $jira_subdomain, project_key: $project_key, labels: $labels, custom_field_id_account_name: $custom_field_id_account_name, custom_field_id_check_name: $custom_field_id_check_name, custom_field_id_check_url: $custom_field_id_check_url, custom_fields_json: $custom_fields_json, alert_resolved_label: $alert_resolved_label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Klipfolio integration
#
# POST /api/v1/integrations/add-klipfolio/
# operationId: post_integration_create_klipfolio
export def "integrations-add-klipfolio klipfolio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --api-key: string
  --data-source-name: string
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, api_key: string, data_source_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-klipfolio/")
  let body = {name: $name, contact_groups: $contact_groups, api_key: $api_key, data_source_name: $data_source_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Logz.io integration
#
# POST /api/v1/integrations/add-logz/
# operationId: post_integration_create_logz
export def "integrations-add-logz logz" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --listener-url: string # The Listener domain name that logs and metrics are sent to.
  --logs-shipping-token: string # Your Logs shipping token.
  --metrics-shipping-token: string # Your Metrics shipping token.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, listener_url: string, logs_shipping_token: string, metrics_shipping_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-logz/")
  let body = {name: $name, contact_groups: $contact_groups, listener_url: $listener_url, logs_shipping_token: $logs_shipping_token, metrics_shipping_token: $metrics_shipping_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Make.com integration
#
# POST /api/v1/integrations/add-make/
# operationId: post_integration_create_make
export def "integrations-add-make make" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --webhook-url: string # Custom webhook URL from the Make.com scenario that should run when an alert is raised or cleared. (format: uri)
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-make/")
  let body = {name: $name, contact_groups: $contact_groups, webhook_url: $webhook_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Microsoft Teams integration
#
# POST /api/v1/integrations/add-microsoft-teams/
# operationId: post_integration_create_microsoft_teams
export def "integrations-add-microsoft-teams teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --webhook-url: string # format: uri
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-microsoft-teams/")
  let body = {name: $name, contact_groups: $contact_groups, webhook_url: $webhook_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new OpsGenie integration
#
# POST /api/v1/integrations/add-opsgenie/
# operationId: post_integration_create_opsgenie
export def "integrations-add-opsgenie opsgenie" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --api-endpoint: string # Listed on the Integrations / Configured Integrations page in OpsGenie. (format: uri)
  --api-key: string # Listed on the Integrations / Configured Integrations page in OpsGenie.
  --teams: string # A comma separated list of team names which will be responsible for the alert.
  --tags: string # A comma separated list of labels attached to the alert. You may overwrite the quiet hours setting for urgent alerts by adding the OverwriteQuietHours tag. Leave blank to automatically pull the tags from the check instead.
  --autoresolve: oneof<nothing, bool> # Automatically resolve incident once the check is back up.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, api_endpoint: string, api_key: string, teams: string, tags: string, autoresolve: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-opsgenie/")
  let body = {name: $name, contact_groups: $contact_groups, api_endpoint: $api_endpoint, api_key: $api_key, teams: $teams, tags: $tags, autoresolve: $autoresolve} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new PagerDuty integration
#
# POST /api/v1/integrations/add-pagerduty/
# operationId: post_integration_create_pagerduty
export def "integrations-add-pagerduty pagerduty" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --service-key: string # Listed on the Service's details page, Integrations tab.
  --autoresolve: oneof<nothing, bool> # Automatically resolve this incident once the check is back up.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, service_key: string, autoresolve: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-pagerduty/")
  let body = {name: $name, contact_groups: $contact_groups, service_key: $service_key, autoresolve: $autoresolve} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Pushbullet integration
#
# POST /api/v1/integrations/add-pushbullet/
# operationId: post_integration_create_pushbullet
export def "integrations-add-pushbullet pushbullet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --email: string # The email used in creating your Pushbullet account. (format: email)
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-pushbullet/")
  let body = {name: $name, contact_groups: $contact_groups, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Pushover integration
#
# POST /api/v1/integrations/add-pushover/
# operationId: post_integration_create_pushover
export def "integrations-add-pushover pushover" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --user: string # This may be your user key or a group key.
  --priority: int@priority-completer # Priorities higher then normal will override recipient's quiet hours.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, user: string, priority: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-pushover/")
  let body = {name: $name, contact_groups: $contact_groups, user: $user, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Slack integration
#
# POST /api/v1/integrations/add-slack/
# operationId: post_integration_create_slack
export def "integrations-add-slack slack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --webhook-url: string # format: uri
  --channel: string
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, webhook_url: string, channel: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-slack/")
  let body = {name: $name, contact_groups: $contact_groups, webhook_url: $webhook_url, channel: $channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Status.io integration
#
# POST /api/v1/integrations/add-status/
# operationId: post_integration_create_status
export def "integrations-add-status status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --statuspage-id: string # Listed on the API page.
  --api-id: string # Listed on the API page.
  --api-key: string # Listed on the API page.
  --component: string # Component to update with availability status. Listed in the Infrastructure / Modify Component / API section.
  --container: string # Container to update with availability status. Listed in the Infrastructure / Modify Component / API section.
  --metric: string # Metric to update with response time data. Listed on the Metrics / Modify Metric page when setting Data Source to Custom.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, statuspage_id: string, api_id: string, api_key: string, component: string, container: string, metric: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-status/")
  let body = {name: $name, contact_groups: $contact_groups, statuspage_id: $statuspage_id, api_id: $api_id, api_key: $api_key, component: $component, container: $container, metric: $metric} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new StatusPage.io integration
#
# POST /api/v1/integrations/add-statuspage/
# operationId: post_integration_create_statuspage
export def "integrations-add-statuspage statuspage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --api-key: string # Listed on the Manage Account / API page.
  --page: string # Listed on the Manage Account / API page.
  --component: string # Component to update with availability status, see instructions below.
  --metric: string # Metric to update with response time data. Listed in Public Metrics / Edit Metric / Advanced Options.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, api_key: string, page: string, component: string, metric: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-statuspage/")
  let body = {name: $name, contact_groups: $contact_groups, api_key: $api_key, page: $page, component: $component, metric: $metric} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Telegram integration
#
# POST /api/v1/integrations/add-telegram/
# operationId: post_integration_create_telegram
export def "integrations-add-telegram telegram" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --telegram-username: string # Username used to find chats.
  --chat-id: string # Chat ID to send alerts to.
  --chat-title: string # Title of Chat to send alerts to.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, telegram_username: string, chat_id: string, chat_title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-telegram/")
  let body = {name: $name, contact_groups: $contact_groups, telegram_username: $telegram_username, chat_id: $chat_id, chat_title: $chat_title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Splunk On-Call integration
#
# POST /api/v1/integrations/add-victorops/
# operationId: post_integration_create_victorops
export def "integrations-add-victorops victorops" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --service-key: string # Listed on the Settings / API page
  --routing-key: string # Routing key determines to which team alerts and incidents will be routed.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, service_key: string, routing_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-victorops/")
  let body = {name: $name, contact_groups: $contact_groups, service_key: $service_key, routing_key: $routing_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new VMware Aria Operations for Applications integration
#
# POST /api/v1/integrations/add-wavefront/
# operationId: post_integration_create_wavefront
export def "integrations-add-wavefront wavefront" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --wavefront-url: string # Root URL of your VMware Aria Operations for Applications service, eg. https://longboard.wavefront.com. (format: uri)
  --csp-url: string # Root URL of your VMware CSP service, for authentication, e.g. https://console.cloud.vmware.com. Leave blank to use a legacy API token. (format: uri)
  --csp-app-id: string # If you're using a Server to Server OAuth App for authentication, provide the OAuth App ID here. Otherwise, leave blank.
  --api-token: string # If you're using a legacy API token or a CSP API Token, enter it here. If you're using a Server to Server OAuth App, enter your OAuth App Secret here.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, wavefront_url: string, csp_url: string, csp_app_id: string, api_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-wavefront/")
  let body = {name: $name, contact_groups: $contact_groups, wavefront_url: $wavefront_url, csp_url: $csp_url, csp_app_id: $csp_app_id, api_token: $api_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Custom Postback URL (Webhook) integration
#
# POST /api/v1/integrations/add-webhook/
# operationId: post_integration_create_webhook
export def "integrations-add-webhook webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --postback-url: string # The URL you would like the alert details sent by HTTP POST. (format: uri)
  --headers: string # Optional custom HTTP headers in "Name: Value" format.
  --use-legacy-payload: oneof<nothing, bool> # Maintain compatibility with legacy handlers.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, postback_url: string, headers: string, use_legacy_payload: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-webhook/")
  let body = {name: $name, contact_groups: $contact_groups, postback_url: $postback_url, headers: $headers, use_legacy_payload: $use_legacy_payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Zapier integration
#
# POST /api/v1/integrations/add-zapier/
# operationId: post_integration_create_zapier
export def "integrations-add-zapier zapier" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --webhook-url: string # The Webhook URL for triggering the alert in Zapier. (format: uri)
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-zapier/")
  let body = {name: $name, contact_groups: $contact_groups, webhook_url: $webhook_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a new Zendesk integration
#
# POST /api/v1/integrations/add-zendesk/
# operationId: post_integration_create_zendesk
export def "integrations-add-zendesk zendesk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
  --api-email: string # Email of the Zendesk agent whose API token is being used.
  --api-token: string # API token created for the agent in the Zendesk Admin Center.
  --zendesk-subdomain: string # The base URL of your Zendesk account, e.g. "https://your-company.zendesk.com" (format: uri)
  --priority: string@priority-completer-1 # Priority to assign to tickets created by this integration.
  --ticket-type: string@ticket-type-completer # Type to assign to tickets created by this integration.
  --tags: string # A comma separated list of tags to attach to each ticket created. Check tags are appended automatically.
  --autoresolve: oneof<nothing, bool> # Automatically mark the ticket as solved once the check is back up.
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string, api_email: string, api_token: string, zendesk_subdomain: string, priority: string, ticket_type: string, tags: string, autoresolve: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/integrations/add-zendesk/")
  let body = {name: $name, contact_groups: $contact_groups, api_email: $api_email, api_token: $api_token, zendesk_subdomain: $zendesk_subdomain, priority: $priority, ticket_type: $ticket_type, tags: $tags, autoresolve: $autoresolve} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single integration
#
# GET /api/v1/integrations/{pk}/
# operationId: get_integration_detail
export def "integrations detail-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integrations/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an integration  See the various POST methods for additional fields available for each integration type.
#
# PUT /api/v1/integrations/{pk}/
# operationId: put_integration_detail
export def "integrations detail-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integrations/($pk)/")
  let body = {name: $name, contact_groups: $contact_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update an integration  See the various POST methods for additional fields available for each integration type.
#
# PATCH /api/v1/integrations/{pk}/
# operationId: patch_integration_detail
export def "integrations detail-by-pk-2" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Your preferred name for this integration.
  --contact-groups: list # Array of contact names or IDs this integration is assigned to
]: any -> record<pk: int, url: string, name: string, module: string, contact_groups: list<string>, is_errored: bool, last_error: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/integrations/($pk)/")
  let body = {name: $name, contact_groups: $contact_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an integration
#
# DELETE /api/v1/integrations/{pk}/
# operationId: delete_integration_detail
export def "integrations detail-by-pk-3" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/integrations/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all maintenance audit events
#
# GET /api/v1/maintenance/events/
# operationId: get_maintenanceauditeventlist
export def "maintenance-events maintenanceauditeventlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, event_type: string, service: string, schedule: string, occurrence: string, user: string, metadata: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/maintenance/events/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single maintenance audit event
#
# GET /api/v1/maintenance/events/{pk}/
# operationId: get_maintenance_audit_event_detail
export def "maintenance-events detail" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, event_type: string, service: string, schedule: string, occurrence: string, user: string, metadata: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/maintenance/events/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all maintenance notifications
#
# GET /api/v1/maintenance/notifications/
# operationId: get_maintenancenotificationlist
export def "maintenance-notifications maintenancenotificationlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, schedule_id: string, offset: string, event: string, contact_groups: list, created_at: string, modified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/maintenance/notifications/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new maintenance notification
#
# POST /api/v1/maintenance/notifications/
# operationId: post_maintenancenotificationlist
# --contact_groups item shape: {name: string}
export def "maintenance-notifications maintenancenotificationlist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: int, schedule_id: string, offset: string, event: string, contact_groups: table<id: int, name: string>, created_at: string, modified_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/maintenance/notifications/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all maintenance notification occurrences
#
# GET /api/v1/maintenance/notifications/occurrences/
# operationId: get_maintenancenotificationoccurrencelist
export def "maintenance-notifications-occurrences maintenancenotificationoccurrencelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, maintenance_occurrence: record, notification: record, scheduled_at: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/maintenance/notifications/occurrences/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single maintenance notification occurrence
#
# GET /api/v1/maintenance/notifications/occurrences/{pk}/
# operationId: get_maintenance_notification_occurrence_detail
export def "maintenance-notifications-occurrences detail" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, maintenance_occurrence: record<id: int, schedule: record<id: int, name: string, schedule_type: string, starts_at: string, ends_at: string, rrule: string, duration_minutes: int, is_active: bool, pause_checks_during_maintenance: bool, services: string, tags: list, created_at: string, modified_at: string>, starts_at: string, ends_at: string, status: string, recurrence_id: string, services: string, created_at: string>, notification: record<id: int, schedule_id: string, offset: string, event: string, contact_groups: list<record>, created_at: string, modified_at: string>, scheduled_at: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/maintenance/notifications/occurrences/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single maintenance notification
#
# GET /api/v1/maintenance/notifications/{pk}/
# operationId: get_maintenance_notification_detail
export def "maintenance-notifications detail-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, schedule_id: string, offset: string, event: string, contact_groups: table<id: int, name: string>, created_at: string, modified_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/maintenance/notifications/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a maintenance notification
#
# PUT /api/v1/maintenance/notifications/{pk}/
# operationId: put_maintenance_notification_detail
# --contact_groups item shape: {name: string}
export def "maintenance-notifications detail-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: int, schedule_id: string, offset: string, event: string, contact_groups: table<id: int, name: string>, created_at: string, modified_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/maintenance/notifications/($pk)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a maintenance notification
#
# PATCH /api/v1/maintenance/notifications/{pk}/
# operationId: patch_maintenance_notification_detail
# --contact_groups item shape: {name: string}
export def "maintenance-notifications detail-by-pk-2" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: int, schedule_id: string, offset: string, event: string, contact_groups: table<id: int, name: string>, created_at: string, modified_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/maintenance/notifications/($pk)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a maintenance notification
#
# DELETE /api/v1/maintenance/notifications/{pk}/
# operationId: delete_maintenance_notification_detail
export def "maintenance-notifications detail-by-pk-3" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/maintenance/notifications/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all maintenance occurrences
#
# GET /api/v1/maintenance/occurrences/
# operationId: get_maintenanceoccurrencelist
export def "maintenance-occurrences maintenanceoccurrencelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, schedule: record, starts_at: string, ends_at: string, status: string, recurrence_id: string, services: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/maintenance/occurrences/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single maintenance occurrence
#
# GET /api/v1/maintenance/occurrences/{pk}/
# operationId: get_maintenance_occurrence_detail
export def "maintenance-occurrences detail" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, schedule: record<id: int, name: string, schedule_type: string, starts_at: string, ends_at: string, rrule: string, duration_minutes: int, is_active: bool, pause_checks_during_maintenance: bool, services: string, tags: list<record>, created_at: string, modified_at: string>, starts_at: string, ends_at: string, status: string, recurrence_id: string, services: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/maintenance/occurrences/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a maintenance occurrence
#
# POST /api/v1/maintenance/occurrences/{pk}/cancel/
# operationId: post_maintenance_occurrence_cancel
export def "maintenance-occurrences-cancel cancel" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: int, schedule: record<id: int, name: string, schedule_type: string, starts_at: string, ends_at: string, rrule: string, duration_minutes: int, is_active: bool, pause_checks_during_maintenance: bool, services: string, tags: list<record>, created_at: string, modified_at: string>, starts_at: string, ends_at: string, status: string, recurrence_id: string, services: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/maintenance/occurrences/($pk)/cancel/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all maintenance schedules
#
# GET /api/v1/maintenance/schedules/
# operationId: get_maintenanceschedulelist
export def "maintenance-schedules maintenanceschedulelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, name: string, schedule_type: string, starts_at: string, ends_at: string, rrule: string, duration_minutes: int, is_active: bool, pause_checks_during_maintenance: bool, services: string, tags: list, created_at: string, modified_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/maintenance/schedules/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new maintenance schedule
#
# POST /api/v1/maintenance/schedules/
# operationId: post_maintenanceschedulelist
# --tags item shape: {tag: string}
export def "maintenance-schedules maintenanceschedulelist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: int, name: string, schedule_type: string, starts_at: string, ends_at: string, rrule: string, duration_minutes: int, is_active: bool, pause_checks_during_maintenance: bool, services: string, tags: table<id: int, tag: string, color_hex: string, usage_count: int>, created_at: string, modified_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/maintenance/schedules/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single maintenance schedule
#
# GET /api/v1/maintenance/schedules/{pk}/
# operationId: get_maintenance_schedule_detail
export def "maintenance-schedules detail-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, name: string, schedule_type: string, starts_at: string, ends_at: string, rrule: string, duration_minutes: int, is_active: bool, pause_checks_during_maintenance: bool, services: string, tags: table<id: int, tag: string, color_hex: string, usage_count: int>, created_at: string, modified_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/maintenance/schedules/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a maintenance schedule
#
# PUT /api/v1/maintenance/schedules/{pk}/
# operationId: put_maintenance_schedule_detail
# --tags item shape: {tag: string}
export def "maintenance-schedules detail-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: int, name: string, schedule_type: string, starts_at: string, ends_at: string, rrule: string, duration_minutes: int, is_active: bool, pause_checks_during_maintenance: bool, services: string, tags: table<id: int, tag: string, color_hex: string, usage_count: int>, created_at: string, modified_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/maintenance/schedules/($pk)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a maintenance schedule
#
# PATCH /api/v1/maintenance/schedules/{pk}/
# operationId: patch_maintenance_schedule_detail
# --tags item shape: {tag: string}
export def "maintenance-schedules detail-by-pk-2" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<id: int, name: string, schedule_type: string, starts_at: string, ends_at: string, rrule: string, duration_minutes: int, is_active: bool, pause_checks_during_maintenance: bool, services: string, tags: table<id: int, tag: string, color_hex: string, usage_count: int>, created_at: string, modified_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/maintenance/schedules/($pk)/")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a maintenance schedule
#
# DELETE /api/v1/maintenance/schedules/{pk}/
# operationId: delete_maintenance_schedule_detail
export def "maintenance-schedules detail-by-pk-3" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/maintenance/schedules/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all outages
#
# GET /api/v1/outages/
# operationId: get_outagelist
export def "outages outagelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer # Order results by this field.
  --check-pk: float # Filter by check ID.
  --check-monitoring-service-type: string@check-monitoring-service-type-completer # Filter by check type.
  --check-tag: string # Filter by tag name (can be specified multiple times.)
  --start-date: string # Start date in ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) format.
  --end-date: string # End date in ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) format.
  --ongoing: oneof<nothing, bool> # Whether the outage is ongoing (true) or resolved (false).
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, url: string, created_at: string, resolved_at: string, duration_secs: string, ignore_alert_url: string, check_pk: int, check_url: string, check_address: string, check_name: string, check_is_paused: bool, check_monitoring_service_type: string, state_is_up: bool, ignored: bool, num_locations_down: int, all_alerts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "check_pk" $check_pk "scalar") (serialize-qp "check_monitoring_service_type" $check_monitoring_service_type "scalar") (serialize-qp "check_tag" $check_tag "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "ongoing" $ongoing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/outages/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the details of a single outage
#
# GET /api/v1/outages/{pk}/
# operationId: get_outage_detail
export def "outages detail" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, created_at: string, resolved_at: string, duration_secs: string, ignore_alert_url: string, check_pk: int, check_url: string, check_address: string, check_name: string, check_is_paused: bool, check_monitoring_service_type: string, state_is_up: bool, ignored: bool, num_locations_down: int, all_alerts: table<pk: int, url: string, created_at: string, monitoring_server_name: string, monitoring_server_ipv4: string, monitoring_server_ipv6: string, location: string, output: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/outages/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all probe servers.
#
# GET /api/v1/probe-servers/
# operationId: get_monitoring_server_list
export def "probe-servers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<location: string, country: string, probe_name: string, ipv4_addresses: list<string>, ipv6_addresses: list<string>, is_private: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/probe-servers/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all probe servers IP addresses for whitelisting, in raw text format (default) or JSON format.
#
# GET /api/v1/probe-servers/ips/
# operationId: get_monitoring_server_list_ips
export def "probe-servers-ips ips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --format: string # Format of the list, "txt" (default) or "json"
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/probe-servers/ips/" $qp)
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all registered push notification devices and the associated contacts that push alerts to them
#
# GET /api/v1/push-notifications/
# operationId: get_pushnotificationlist
export def "push-notifications pushnotificationlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-7 # Order results by this field.
]: nothing -> record<count: int, next: string, previous: string, results: table<app_key: string, pk: int, url: string, created_at: string, modified_at: string, uuid: string, user: string, device_name: string, display_name: string, contact_groups: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/push-notifications/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register a new device for push notifications  **NOTE: This API is only available to the Uptime.com mobile app.** Register your device via the mobile app and it will automatically appear in the list.  **NOTE 2:** This endpoint will overwrite any existing registered device with the same UUID, if it exists.
#
# POST /api/v1/push-notifications/
# operationId: post_pushnotificationlist
export def "push-notifications pushnotificationlist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  app_key: string
  --uuid: string
  device_name: string
  contact_groups: list # Array of contact names or IDs to this push notification will receive alerts for.
]: any -> record<app_key: string, pk: int, url: string, created_at: string, modified_at: string, uuid: string, user: string, device_name: string, display_name: string, contact_groups: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/push-notifications/")
  let body = {app_key: $app_key, uuid: $uuid, device_name: $device_name, contact_groups: $contact_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single registered push notification device  **NOTE** You may identify the object by PK or UUID
#
# GET /api/v1/push-notifications/{pk}/
# operationId: get_push_notification_detail
export def "push-notifications detail-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, created_at: string, modified_at: string, uuid: string, user: string, device_name: string, display_name: string, contact_groups: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/push-notifications/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the device name and associated contacts for a push notification device  **NOTE** You may identify the object by PK or UUID
#
# PUT /api/v1/push-notifications/{pk}/
# operationId: put_push_notification_detail
export def "push-notifications detail-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  device_name: string
  contact_groups: list # Array of contact names or IDs to this push notification will receive alerts for.
]: any -> record<pk: int, url: string, created_at: string, modified_at: string, uuid: string, user: string, device_name: string, display_name: string, contact_groups: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/push-notifications/($pk)/")
  let body = {device_name: $device_name, contact_groups: $contact_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update the device name or associated contacts for a push notification device  **NOTE** You may identify the object by PK or UUID
#
# PATCH /api/v1/push-notifications/{pk}/
# operationId: patch_push_notification_detail
export def "push-notifications detail-by-pk-2" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  device_name: string
  contact_groups: list # Array of contact names or IDs to this push notification will receive alerts for.
]: any -> record<pk: int, url: string, created_at: string, modified_at: string, uuid: string, user: string, device_name: string, display_name: string, contact_groups: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/push-notifications/($pk)/")
  let body = {device_name: $device_name, contact_groups: $contact_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a registered push notification device  **NOTE** You may identify the object by PK or UUID
#
# DELETE /api/v1/push-notifications/{pk}/
# operationId: delete_push_notification_detail
export def "push-notifications detail-by-pk-3" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/push-notifications/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all scheduled reports
#
# GET /api/v1/scheduled-reports/
# operationId: get_scheduledreportlist
export def "scheduled-reports scheduledreportlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-3 # Order results by this field.
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, url: string, sla_report: string, recipient_users: list, created_at: string, name: string, file_type: string, recurrence: string, default_date_range_override: string, on_weekday: int, at_time: int, is_enabled: bool, recipient_emails: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/scheduled-reports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new scheduled report
#
# POST /api/v1/scheduled-reports/
# operationId: post_scheduledreportlist
export def "scheduled-reports scheduledreportlist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sla-report: string # Select an SLA report to send on this schedule (nullable)
  --recipient-users: list # Select the users that should receive this report
  name: string # Name of this scheduled report
  --file-type: string@file-type-completer
  --recurrence: string@recurrence-completer # How often to deliver this report
  --default-date-range-override: string@default-date-range-override-completer # Override default date range for this report
  --on-weekday: int@on-weekday-completer # Weekly reports will be sent on this day
  --at-time: int@at-time-completer # Reports will be sent at this time (local time)
  --is-enabled: oneof<nothing, bool>
  --recipient-emails: record # Additional emails that will receive this report
]: any -> record<pk: int, url: string, sla_report: string, recipient_users: list<string>, created_at: string, name: string, file_type: string, recurrence: string, default_date_range_override: string, on_weekday: int, at_time: int, is_enabled: bool, recipient_emails: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/scheduled-reports/")
  let body = {sla_report: $sla_report, recipient_users: $recipient_users, name: $name, file_type: $file_type, recurrence: $recurrence, default_date_range_override: $default_date_range_override, on_weekday: $on_weekday, at_time: $at_time, is_enabled: $is_enabled, recipient_emails: $recipient_emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single scheduled report
#
# GET /api/v1/scheduled-reports/{pk}/
# operationId: get_scheduled_report_detail
export def "scheduled-reports detail-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, sla_report: string, recipient_users: list<string>, created_at: string, name: string, file_type: string, recurrence: string, default_date_range_override: string, on_weekday: int, at_time: int, is_enabled: bool, recipient_emails: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/scheduled-reports/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a scheduled report
#
# PUT /api/v1/scheduled-reports/{pk}/
# operationId: put_scheduled_report_detail
export def "scheduled-reports detail-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sla-report: string # Select an SLA report to send on this schedule (nullable)
  --recipient-users: list # Select the users that should receive this report
  name: string # Name of this scheduled report
  --file-type: string@file-type-completer
  --recurrence: string@recurrence-completer # How often to deliver this report
  --default-date-range-override: string@default-date-range-override-completer # Override default date range for this report
  --on-weekday: int@on-weekday-completer # Weekly reports will be sent on this day
  --at-time: int@at-time-completer # Reports will be sent at this time (local time)
  --is-enabled: oneof<nothing, bool>
  --recipient-emails: record # Additional emails that will receive this report
]: any -> record<pk: int, url: string, sla_report: string, recipient_users: list<string>, created_at: string, name: string, file_type: string, recurrence: string, default_date_range_override: string, on_weekday: int, at_time: int, is_enabled: bool, recipient_emails: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/scheduled-reports/($pk)/")
  let body = {sla_report: $sla_report, recipient_users: $recipient_users, name: $name, file_type: $file_type, recurrence: $recurrence, default_date_range_override: $default_date_range_override, on_weekday: $on_weekday, at_time: $at_time, is_enabled: $is_enabled, recipient_emails: $recipient_emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a scheduled report
#
# PATCH /api/v1/scheduled-reports/{pk}/
# operationId: patch_scheduled_report_detail
export def "scheduled-reports detail-by-pk-2" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sla-report: string # Select an SLA report to send on this schedule (nullable)
  --recipient-users: list # Select the users that should receive this report
  name: string # Name of this scheduled report
  --file-type: string@file-type-completer
  --recurrence: string@recurrence-completer # How often to deliver this report
  --default-date-range-override: string@default-date-range-override-completer # Override default date range for this report
  --on-weekday: int@on-weekday-completer # Weekly reports will be sent on this day
  --at-time: int@at-time-completer # Reports will be sent at this time (local time)
  --is-enabled: oneof<nothing, bool>
  --recipient-emails: record # Additional emails that will receive this report
]: any -> record<pk: int, url: string, sla_report: string, recipient_users: list<string>, created_at: string, name: string, file_type: string, recurrence: string, default_date_range_override: string, on_weekday: int, at_time: int, is_enabled: bool, recipient_emails: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/scheduled-reports/($pk)/")
  let body = {sla_report: $sla_report, recipient_users: $recipient_users, name: $name, file_type: $file_type, recurrence: $recurrence, default_date_range_override: $default_date_range_override, on_weekday: $on_weekday, at_time: $at_time, is_enabled: $is_enabled, recipient_emails: $recipient_emails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a scheduled report
#
# DELETE /api/v1/scheduled-reports/{pk}/
# operationId: delete_scheduled_report_detail
export def "scheduled-reports detail-by-pk-3" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/scheduled-reports/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all service variables
#
# GET /api/v1/servicevariables/
# operationId: get_servicevariablelistandcreate
export def "servicevariables servicevariablelistandcreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-8 # Order results by this field.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, credential: record, property_name: string, variable_name: string, deleted_at: string, account: string, service: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/servicevariables/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new service variable       ** Request Body Requirements **      variable_name can only include alphanumeric characters and underscores     variable_name must be unique for the service      property_name must be the name of a property that can be in the credential     These properties are based on the credential type     Here is the map of credential types to the properties that can be used:         BASIC = "password", "username"         CERTIFICATE = "certificate", "key", "passphrase"         TOKEN = "secret"
#
# POST /api/v1/servicevariables/
# operationId: post_servicevariablelistandcreate
export def "servicevariables servicevariablelistandcreate-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  service_id: int
  credential_id: int
  variable_name: string
  property_name: string
]: any -> record<id: int, credential: record<id: int, credential_type: string, display_name: string, description: string, hint: string, username: string, version: string, used_secret_properties: list<string>, created_by: string>, property_name: string, variable_name: string, deleted_at: string, account: string, service: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/servicevariables/")
  let body = {service_id: $service_id, credential_id: $credential_id, variable_name: $variable_name, property_name: $property_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a service variable by ID
#
# GET /api/v1/servicevariables/{service_variable_id}/
# operationId: get_servicevariablegetupdatedelete
export def "servicevariables servicevariablegetupdatedelete-by-service_variable_id" [
  service_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, credential: record, property_name: string, variable_name: string, deleted_at: string, account: string, service: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/servicevariables/($service_variable_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a service variable      ** Request Body Requirements **      variable_name can only include alphanumeric characters and underscores     variable_name must be unique for the service      property_name must be the name of a property that can be in the credential     These properties are based on the credential type     Here is the map of credential types to the properties that can be used:         BASIC = "password", "username"         CERTIFICATE = "certificate", "key", "passphrase"         TOKEN = "secret"
#
# PATCH /api/v1/servicevariables/{service_variable_id}/
# operationId: patch_servicevariablegetupdatedelete
export def "servicevariables servicevariablegetupdatedelete-by-service_variable_id-1" [
  service_variable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --credential-id: int # nullable
  --variable-name: string # nullable
  --property-name: string # nullable
]: any -> record<id: int, credential: record<id: int, credential_type: string, display_name: string, description: string, hint: string, username: string, version: string, used_secret_properties: list<string>, created_by: string>, property_name: string, variable_name: string, deleted_at: string, account: string, service: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/servicevariables/($service_variable_id)/")
  let body = {credential_id: $credential_id, variable_name: $variable_name, property_name: $property_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a service variable by ID
#
# DELETE /api/v1/servicevariables/{service_variable_id}/
# operationId: delete_servicevariablegetupdatedelete
export def "servicevariables servicevariablegetupdatedelete-by-service_variable_id-2" [
  service_variable_id: string
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
  let full_url = (build-url $base $"/api/v1/servicevariables/($service_variable_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all SLA reports
#
# GET /api/v1/sla-reports/
# operationId: get_slareportlist
export def "sla-reports slareportlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-3 # Order results by this field.
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, url: string, stats_url: string, services_tags: list, services_selected: list, reporting_groups: list, created_at: string, name: string, default_date_range: string, show_uptime_section: bool, show_uptime_sla: bool, filter_with_downtime: bool, filter_uptime_sla_violations: bool, uptime_section_sort: string, show_response_time_section: bool, show_response_time_sla: bool, filter_slowest: bool, filter_response_time_sla_violations: bool, response_time_section_sort: string, logo: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/sla-reports/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new SLA report
#
# POST /api/v1/sla-reports/
# operationId: post_slareportlist
# --reporting_groups item shape: {group_services: list, name: string}
export def "sla-reports slareportlist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --services-tags: list # Include checks with one or more of the selected tags
  --services-selected: list # Include checks from this list
  --reporting-groups: list # item shape: {group_services: list, name: string}
  name: string # Name of this SLA report
  --default-date-range: string@default-date-range-completer
  --show-uptime-section: oneof<nothing, bool>
  --show-uptime-sla: oneof<nothing, bool>
  --filter-with-downtime: oneof<nothing, bool>
  --filter-uptime-sla-violations: oneof<nothing, bool>
  --uptime-section-sort: string@uptime-section-sort-completer
  --show-response-time-section: oneof<nothing, bool>
  --show-response-time-sla: oneof<nothing, bool>
  --filter-slowest: oneof<nothing, bool>
  --filter-response-time-sla-violations: oneof<nothing, bool>
  --response-time-section-sort: string@response-time-section-sort-completer
  --logo: string # nullable, format: binary
]: any -> record<pk: int, url: string, stats_url: string, services_tags: list<string>, services_selected: list<string>, reporting_groups: table<id: int, group_services: list, created_at: string, modified_at: string, name: string>, created_at: string, name: string, default_date_range: string, show_uptime_section: bool, show_uptime_sla: bool, filter_with_downtime: bool, filter_uptime_sla_violations: bool, uptime_section_sort: string, show_response_time_section: bool, show_response_time_sla: bool, filter_slowest: bool, filter_response_time_sla_violations: bool, response_time_section_sort: string, logo: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/sla-reports/")
  let body = {services_tags: $services_tags, services_selected: $services_selected, reporting_groups: $reporting_groups, name: $name, default_date_range: $default_date_range, show_uptime_section: $show_uptime_section, show_uptime_sla: $show_uptime_sla, filter_with_downtime: $filter_with_downtime, filter_uptime_sla_violations: $filter_uptime_sla_violations, uptime_section_sort: $uptime_section_sort, show_response_time_section: $show_response_time_section, show_response_time_sla: $show_response_time_sla, filter_slowest: $filter_slowest, filter_response_time_sla_violations: $filter_response_time_sla_violations, response_time_section_sort: $response_time_section_sort, logo: $logo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single SLA report
#
# GET /api/v1/sla-reports/{pk}/
# operationId: get_sla_report_detail
export def "sla-reports detail-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, stats_url: string, services_tags: list<string>, services_selected: list<string>, reporting_groups: table<id: int, group_services: list, created_at: string, modified_at: string, name: string>, created_at: string, name: string, default_date_range: string, show_uptime_section: bool, show_uptime_sla: bool, filter_with_downtime: bool, filter_uptime_sla_violations: bool, uptime_section_sort: string, show_response_time_section: bool, show_response_time_sla: bool, filter_slowest: bool, filter_response_time_sla_violations: bool, response_time_section_sort: string, logo: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/sla-reports/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an SLA report
#
# PUT /api/v1/sla-reports/{pk}/
# operationId: put_sla_report_detail
# --reporting_groups item shape: {group_services: list, name: string}
export def "sla-reports detail-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --services-tags: list # Include checks with one or more of the selected tags
  --services-selected: list # Include checks from this list
  --reporting-groups: list # item shape: {group_services: list, name: string}
  name: string # Name of this SLA report
  --default-date-range: string@default-date-range-completer
  --show-uptime-section: oneof<nothing, bool>
  --show-uptime-sla: oneof<nothing, bool>
  --filter-with-downtime: oneof<nothing, bool>
  --filter-uptime-sla-violations: oneof<nothing, bool>
  --uptime-section-sort: string@uptime-section-sort-completer
  --show-response-time-section: oneof<nothing, bool>
  --show-response-time-sla: oneof<nothing, bool>
  --filter-slowest: oneof<nothing, bool>
  --filter-response-time-sla-violations: oneof<nothing, bool>
  --response-time-section-sort: string@response-time-section-sort-completer
  --logo: string # nullable, format: binary
]: any -> record<pk: int, url: string, stats_url: string, services_tags: list<string>, services_selected: list<string>, reporting_groups: table<id: int, group_services: list, created_at: string, modified_at: string, name: string>, created_at: string, name: string, default_date_range: string, show_uptime_section: bool, show_uptime_sla: bool, filter_with_downtime: bool, filter_uptime_sla_violations: bool, uptime_section_sort: string, show_response_time_section: bool, show_response_time_sla: bool, filter_slowest: bool, filter_response_time_sla_violations: bool, response_time_section_sort: string, logo: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/sla-reports/($pk)/")
  let body = {services_tags: $services_tags, services_selected: $services_selected, reporting_groups: $reporting_groups, name: $name, default_date_range: $default_date_range, show_uptime_section: $show_uptime_section, show_uptime_sla: $show_uptime_sla, filter_with_downtime: $filter_with_downtime, filter_uptime_sla_violations: $filter_uptime_sla_violations, uptime_section_sort: $uptime_section_sort, show_response_time_section: $show_response_time_section, show_response_time_sla: $show_response_time_sla, filter_slowest: $filter_slowest, filter_response_time_sla_violations: $filter_response_time_sla_violations, response_time_section_sort: $response_time_section_sort, logo: $logo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update an SLA report
#
# PATCH /api/v1/sla-reports/{pk}/
# operationId: patch_sla_report_detail
# --reporting_groups item shape: {group_services: list, name: string}
export def "sla-reports detail-by-pk-2" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --services-tags: list # Include checks with one or more of the selected tags
  --services-selected: list # Include checks from this list
  --reporting-groups: list # item shape: {group_services: list, name: string}
  name: string # Name of this SLA report
  --default-date-range: string@default-date-range-completer
  --show-uptime-section: oneof<nothing, bool>
  --show-uptime-sla: oneof<nothing, bool>
  --filter-with-downtime: oneof<nothing, bool>
  --filter-uptime-sla-violations: oneof<nothing, bool>
  --uptime-section-sort: string@uptime-section-sort-completer
  --show-response-time-section: oneof<nothing, bool>
  --show-response-time-sla: oneof<nothing, bool>
  --filter-slowest: oneof<nothing, bool>
  --filter-response-time-sla-violations: oneof<nothing, bool>
  --response-time-section-sort: string@response-time-section-sort-completer
  --logo: string # nullable, format: binary
]: any -> record<pk: int, url: string, stats_url: string, services_tags: list<string>, services_selected: list<string>, reporting_groups: table<id: int, group_services: list, created_at: string, modified_at: string, name: string>, created_at: string, name: string, default_date_range: string, show_uptime_section: bool, show_uptime_sla: bool, filter_with_downtime: bool, filter_uptime_sla_violations: bool, uptime_section_sort: string, show_response_time_section: bool, show_response_time_sla: bool, filter_slowest: bool, filter_response_time_sla_violations: bool, response_time_section_sort: string, logo: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/sla-reports/($pk)/")
  let body = {services_tags: $services_tags, services_selected: $services_selected, reporting_groups: $reporting_groups, name: $name, default_date_range: $default_date_range, show_uptime_section: $show_uptime_section, show_uptime_sla: $show_uptime_sla, filter_with_downtime: $filter_with_downtime, filter_uptime_sla_violations: $filter_uptime_sla_violations, uptime_section_sort: $uptime_section_sort, show_response_time_section: $show_response_time_section, show_response_time_sla: $show_response_time_sla, filter_slowest: $filter_slowest, filter_response_time_sla_violations: $filter_response_time_sla_violations, response_time_section_sort: $response_time_section_sort, logo: $logo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an SLA report
#
# DELETE /api/v1/sla-reports/{pk}/
# operationId: delete_sla_report_detail
export def "sla-reports detail-by-pk-3" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/sla-reports/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generates the report for the specified time period
#
# GET /api/v1/sla-reports/{pk}/stats/
# operationId: get_sla_report_stats
export def "sla-reports-stats stats" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # The first day to show statistics for in ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) format.
  --end-date: string # The last day to show statistics for in ISO 8601 (YYYY-MM-DDTHH:MM:SSZ) format.
  --output: string@output-completer # The output format of the report: [json, pdf, xls]
]: nothing -> record<start_date: string, end_date: string, output: string, has_response_time_data: bool, uses_daily_response_time_data: bool, uptime: record, groups: list<record>, response_time: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "output" $output "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/sla-reports/($pk)/stats/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all SLA reports
#
# GET /api/v1/sla-reports/{sla_report_id}/groups/
# operationId: get_slareportinggrouplist
export def "sla-reports-groups slareportinggrouplist-by-sla_report_id" [
  sla_report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-3 # Order results by this field.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, group_services: list, created_at: string, modified_at: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/sla-reports/($sla_report_id)/groups/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new SLA report
#
# POST /api/v1/sla-reports/{sla_report_id}/groups/
# operationId: post_slareportinggrouplist
export def "sla-reports-groups slareportinggrouplist-by-sla_report_id-1" [
  sla_report_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  group_services: list # Include checks from this list.
  name: string # Name of this SLA report Group
]: any -> record<id: int, group_services: list<string>, created_at: string, modified_at: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/sla-reports/($sla_report_id)/groups/")
  let body = {group_services: $group_services, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /api/v1/sla-reports/{sla_report_id}/groups/{pk}/
#
# operationId: get_sla_report_reporting_group_detail
export def "sla-reports-groups detail-by-sla_report_id-pk" [
  sla_report_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, group_services: list<string>, created_at: string, modified_at: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/sla-reports/($sla_report_id)/groups/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a reporting group from sla report
#
# DELETE /api/v1/sla-reports/{sla_report_id}/groups/{pk}/
# operationId: delete_sla_report_reporting_group_detail
export def "sla-reports-groups detail-by-sla_report_id-pk-1" [
  sla_report_id: string
  pk: string
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
  let full_url = (build-url $base $"/api/v1/sla-reports/($sla_report_id)/groups/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all status pages
#
# GET /api/v1/statuspages/
# operationId: get_statuspagelist
export def "statuspages statuspagelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-9 # Order results by this field.
  --visibility-level: string@visibility-level-completer # Status Page by visibility level.
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, name: string, visibility_level: string, description: string, page_type: string, public_url: string, private_url: string, cname_url: string, url: string, incidents_url: string, components_url: string, metrics_url: string, history_url: string, current_status_url: string, slug: string, page_type_display: string, cname: string, allow_subscriptions: bool, allow_subscriptions_slack: bool, allow_subscriptions_sms: bool, allow_subscriptions_webhook: bool, allow_subscriptions_rss: bool, allow_subscriptions_email: bool, allow_notifications: bool, allow_search_indexing: bool, allow_drill_down: bool, auth_username: string, auth_password: string, description_html: string, max_visible_component_days: int, show_status_tab: bool, default_status_date_range: int, show_active_incidents: bool, show_component_response_time: bool, show_history_tab: bool, default_history_date_range: int, uptime_calculation_type: string, show_history_snake: bool, show_component_history: bool, hide_empty_tabs_status: bool, hide_empty_tabs_history: bool, show_summary_metrics: bool, show_past_incidents: bool, allow_pdf_report: bool, layout_preset: string, show_component_bars: bool, show_component_group_descriptions: bool, google_analytics_code: string, contact_email: string, email_from: string, email_reply_to: string, custom_header_html: string, custom_footer_html: string, custom_css: string, custom_header_html_inspire: string, custom_footer_html_inspire: string, custom_css_inspire: string, email_logo_url: string, logo_url: string, favicon_url: string, company_website_url: string, timezone: string, theme: string, custom_header_text_color_hex: string, custom_header_bg_color_hex: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "visibility_level" $visibility_level "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/statuspages/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new status page
#
# POST /api/v1/statuspages/
# operationId: post_statuspagelist
export def "statuspages statuspagelist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --visibility-level: string@visibility-level-completer
  --description: string
  page_type: string@page-type-completer
  --slug: string # nullable
  --cname: string # nullable
  --allow-subscriptions-slack: oneof<nothing, bool>
  --allow-subscriptions-sms: oneof<nothing, bool>
  --allow-subscriptions-webhook: oneof<nothing, bool>
  --allow-subscriptions-rss: oneof<nothing, bool>
  --allow-subscriptions-email: oneof<nothing, bool>
  --allow-notifications: oneof<nothing, bool>
  --allow-search-indexing: oneof<nothing, bool>
  --allow-drill-down: oneof<nothing, bool>
  --auth-username: string
  --auth-password: string
  --max-visible-component-days: int # nullable
  --show-status-tab: oneof<nothing, bool>
  --default-status-date-range: int
  --show-active-incidents: oneof<nothing, bool>
  --show-component-response-time: oneof<nothing, bool>
  --show-history-tab: oneof<nothing, bool>
  --default-history-date-range: int
  --uptime-calculation-type: string@uptime-calculation-type-completer
  --show-history-snake: oneof<nothing, bool>
  --show-component-history: oneof<nothing, bool>
  --hide-empty-tabs-status: oneof<nothing, bool>
  --hide-empty-tabs-history: oneof<nothing, bool>
  --show-summary-metrics: oneof<nothing, bool>
  --show-past-incidents: oneof<nothing, bool>
  --allow-pdf-report: oneof<nothing, bool>
  --layout-preset: string@layout-preset-completer
  --show-component-bars: oneof<nothing, bool>
  --show-component-group-descriptions: oneof<nothing, bool>
  --google-analytics-code: string
  --contact-email: string # format: email
  --email-from: string # format: email
  --email-reply-to: string # format: email
  --custom-header-html: string
  --custom-footer-html: string
  --custom-css: string
  --custom-header-html-inspire: string
  --custom-footer-html-inspire: string
  --custom-css-inspire: string
  --company-website-url: string # format: uri
  --timezone: string@timezone-completer
  --theme: string@theme-completer # Theme for the status page. Only 'INSPIRE' can be set via the API; existing 'LEGACY' status pages may be migrated to 'INSPIRE'.
  --custom-header-text-color-hex: string
  --custom-header-bg-color-hex: string
]: any -> record<pk: int, name: string, visibility_level: string, description: string, page_type: string, public_url: string, private_url: string, cname_url: string, url: string, incidents_url: string, components_url: string, metrics_url: string, history_url: string, current_status_url: string, slug: string, page_type_display: string, cname: string, allow_subscriptions: bool, allow_subscriptions_slack: bool, allow_subscriptions_sms: bool, allow_subscriptions_webhook: bool, allow_subscriptions_rss: bool, allow_subscriptions_email: bool, allow_notifications: bool, allow_search_indexing: bool, allow_drill_down: bool, auth_username: string, auth_password: string, description_html: string, max_visible_component_days: int, show_status_tab: bool, default_status_date_range: int, show_active_incidents: bool, show_component_response_time: bool, show_history_tab: bool, default_history_date_range: int, uptime_calculation_type: string, show_history_snake: bool, show_component_history: bool, hide_empty_tabs_status: bool, hide_empty_tabs_history: bool, show_summary_metrics: bool, show_past_incidents: bool, allow_pdf_report: bool, layout_preset: string, show_component_bars: bool, show_component_group_descriptions: bool, google_analytics_code: string, contact_email: string, email_from: string, email_reply_to: string, custom_header_html: string, custom_footer_html: string, custom_css: string, custom_header_html_inspire: string, custom_footer_html_inspire: string, custom_css_inspire: string, email_logo_url: string, logo_url: string, favicon_url: string, company_website_url: string, timezone: string, theme: string, custom_header_text_color_hex: string, custom_header_bg_color_hex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/statuspages/")
  let body = {name: $name, visibility_level: $visibility_level, description: $description, page_type: $page_type, slug: $slug, cname: $cname, allow_subscriptions_slack: $allow_subscriptions_slack, allow_subscriptions_sms: $allow_subscriptions_sms, allow_subscriptions_webhook: $allow_subscriptions_webhook, allow_subscriptions_rss: $allow_subscriptions_rss, allow_subscriptions_email: $allow_subscriptions_email, allow_notifications: $allow_notifications, allow_search_indexing: $allow_search_indexing, allow_drill_down: $allow_drill_down, auth_username: $auth_username, auth_password: $auth_password, max_visible_component_days: $max_visible_component_days, show_status_tab: $show_status_tab, default_status_date_range: $default_status_date_range, show_active_incidents: $show_active_incidents, show_component_response_time: $show_component_response_time, show_history_tab: $show_history_tab, default_history_date_range: $default_history_date_range, uptime_calculation_type: $uptime_calculation_type, show_history_snake: $show_history_snake, show_component_history: $show_component_history, hide_empty_tabs_status: $hide_empty_tabs_status, hide_empty_tabs_history: $hide_empty_tabs_history, show_summary_metrics: $show_summary_metrics, show_past_incidents: $show_past_incidents, allow_pdf_report: $allow_pdf_report, layout_preset: $layout_preset, show_component_bars: $show_component_bars, show_component_group_descriptions: $show_component_group_descriptions, google_analytics_code: $google_analytics_code, contact_email: $contact_email, email_from: $email_from, email_reply_to: $email_reply_to, custom_header_html: $custom_header_html, custom_footer_html: $custom_footer_html, custom_css: $custom_css, custom_header_html_inspire: $custom_header_html_inspire, custom_footer_html_inspire: $custom_footer_html_inspire, custom_css_inspire: $custom_css_inspire, company_website_url: $company_website_url, timezone: $timezone, theme: $theme, custom_header_text_color_hex: $custom_header_text_color_hex, custom_header_bg_color_hex: $custom_header_bg_color_hex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single status page
#
# GET /api/v1/statuspages/{pk}/
# operationId: get_statuspage_detail
export def "statuspages detail-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, name: string, visibility_level: string, description: string, page_type: string, public_url: string, private_url: string, cname_url: string, url: string, incidents_url: string, components_url: string, metrics_url: string, history_url: string, current_status_url: string, slug: string, page_type_display: string, cname: string, allow_subscriptions: bool, allow_subscriptions_slack: bool, allow_subscriptions_sms: bool, allow_subscriptions_webhook: bool, allow_subscriptions_rss: bool, allow_subscriptions_email: bool, allow_notifications: bool, allow_search_indexing: bool, allow_drill_down: bool, auth_username: string, auth_password: string, description_html: string, max_visible_component_days: int, show_status_tab: bool, default_status_date_range: int, show_active_incidents: bool, show_component_response_time: bool, show_history_tab: bool, default_history_date_range: int, uptime_calculation_type: string, show_history_snake: bool, show_component_history: bool, hide_empty_tabs_status: bool, hide_empty_tabs_history: bool, show_summary_metrics: bool, show_past_incidents: bool, allow_pdf_report: bool, layout_preset: string, show_component_bars: bool, show_component_group_descriptions: bool, google_analytics_code: string, contact_email: string, email_from: string, email_reply_to: string, custom_header_html: string, custom_footer_html: string, custom_css: string, custom_header_html_inspire: string, custom_footer_html_inspire: string, custom_css_inspire: string, email_logo_url: string, logo_url: string, favicon_url: string, company_website_url: string, timezone: string, theme: string, custom_header_text_color_hex: string, custom_header_bg_color_hex: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a status page
#
# PUT /api/v1/statuspages/{pk}/
# operationId: put_statuspage_detail
export def "statuspages detail-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --visibility-level: string@visibility-level-completer
  --description: string
  page_type: string@page-type-completer
  --slug: string # nullable
  --cname: string # nullable
  --allow-subscriptions-slack: oneof<nothing, bool>
  --allow-subscriptions-sms: oneof<nothing, bool>
  --allow-subscriptions-webhook: oneof<nothing, bool>
  --allow-subscriptions-rss: oneof<nothing, bool>
  --allow-subscriptions-email: oneof<nothing, bool>
  --allow-notifications: oneof<nothing, bool>
  --allow-search-indexing: oneof<nothing, bool>
  --allow-drill-down: oneof<nothing, bool>
  --auth-username: string
  --auth-password: string
  --max-visible-component-days: int # nullable
  --show-status-tab: oneof<nothing, bool>
  --default-status-date-range: int
  --show-active-incidents: oneof<nothing, bool>
  --show-component-response-time: oneof<nothing, bool>
  --show-history-tab: oneof<nothing, bool>
  --default-history-date-range: int
  --uptime-calculation-type: string@uptime-calculation-type-completer
  --show-history-snake: oneof<nothing, bool>
  --show-component-history: oneof<nothing, bool>
  --hide-empty-tabs-status: oneof<nothing, bool>
  --hide-empty-tabs-history: oneof<nothing, bool>
  --show-summary-metrics: oneof<nothing, bool>
  --show-past-incidents: oneof<nothing, bool>
  --allow-pdf-report: oneof<nothing, bool>
  --layout-preset: string@layout-preset-completer
  --show-component-bars: oneof<nothing, bool>
  --show-component-group-descriptions: oneof<nothing, bool>
  --google-analytics-code: string
  --contact-email: string # format: email
  --email-from: string # format: email
  --email-reply-to: string # format: email
  --custom-header-html: string
  --custom-footer-html: string
  --custom-css: string
  --custom-header-html-inspire: string
  --custom-footer-html-inspire: string
  --custom-css-inspire: string
  --company-website-url: string # format: uri
  --timezone: string@timezone-completer
  --theme: string@theme-completer # Theme for the status page. Only 'INSPIRE' can be set via the API; existing 'LEGACY' status pages may be migrated to 'INSPIRE'.
  --custom-header-text-color-hex: string
  --custom-header-bg-color-hex: string
]: any -> record<pk: int, name: string, visibility_level: string, description: string, page_type: string, public_url: string, private_url: string, cname_url: string, url: string, incidents_url: string, components_url: string, metrics_url: string, history_url: string, current_status_url: string, slug: string, page_type_display: string, cname: string, allow_subscriptions: bool, allow_subscriptions_slack: bool, allow_subscriptions_sms: bool, allow_subscriptions_webhook: bool, allow_subscriptions_rss: bool, allow_subscriptions_email: bool, allow_notifications: bool, allow_search_indexing: bool, allow_drill_down: bool, auth_username: string, auth_password: string, description_html: string, max_visible_component_days: int, show_status_tab: bool, default_status_date_range: int, show_active_incidents: bool, show_component_response_time: bool, show_history_tab: bool, default_history_date_range: int, uptime_calculation_type: string, show_history_snake: bool, show_component_history: bool, hide_empty_tabs_status: bool, hide_empty_tabs_history: bool, show_summary_metrics: bool, show_past_incidents: bool, allow_pdf_report: bool, layout_preset: string, show_component_bars: bool, show_component_group_descriptions: bool, google_analytics_code: string, contact_email: string, email_from: string, email_reply_to: string, custom_header_html: string, custom_footer_html: string, custom_css: string, custom_header_html_inspire: string, custom_footer_html_inspire: string, custom_css_inspire: string, email_logo_url: string, logo_url: string, favicon_url: string, company_website_url: string, timezone: string, theme: string, custom_header_text_color_hex: string, custom_header_bg_color_hex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($pk)/")
  let body = {name: $name, visibility_level: $visibility_level, description: $description, page_type: $page_type, slug: $slug, cname: $cname, allow_subscriptions_slack: $allow_subscriptions_slack, allow_subscriptions_sms: $allow_subscriptions_sms, allow_subscriptions_webhook: $allow_subscriptions_webhook, allow_subscriptions_rss: $allow_subscriptions_rss, allow_subscriptions_email: $allow_subscriptions_email, allow_notifications: $allow_notifications, allow_search_indexing: $allow_search_indexing, allow_drill_down: $allow_drill_down, auth_username: $auth_username, auth_password: $auth_password, max_visible_component_days: $max_visible_component_days, show_status_tab: $show_status_tab, default_status_date_range: $default_status_date_range, show_active_incidents: $show_active_incidents, show_component_response_time: $show_component_response_time, show_history_tab: $show_history_tab, default_history_date_range: $default_history_date_range, uptime_calculation_type: $uptime_calculation_type, show_history_snake: $show_history_snake, show_component_history: $show_component_history, hide_empty_tabs_status: $hide_empty_tabs_status, hide_empty_tabs_history: $hide_empty_tabs_history, show_summary_metrics: $show_summary_metrics, show_past_incidents: $show_past_incidents, allow_pdf_report: $allow_pdf_report, layout_preset: $layout_preset, show_component_bars: $show_component_bars, show_component_group_descriptions: $show_component_group_descriptions, google_analytics_code: $google_analytics_code, contact_email: $contact_email, email_from: $email_from, email_reply_to: $email_reply_to, custom_header_html: $custom_header_html, custom_footer_html: $custom_footer_html, custom_css: $custom_css, custom_header_html_inspire: $custom_header_html_inspire, custom_footer_html_inspire: $custom_footer_html_inspire, custom_css_inspire: $custom_css_inspire, company_website_url: $company_website_url, timezone: $timezone, theme: $theme, custom_header_text_color_hex: $custom_header_text_color_hex, custom_header_bg_color_hex: $custom_header_bg_color_hex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a status page
#
# PATCH /api/v1/statuspages/{pk}/
# operationId: patch_statuspage_detail
export def "statuspages detail-by-pk-2" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --visibility-level: string@visibility-level-completer
  --description: string
  page_type: string@page-type-completer
  --slug: string # nullable
  --cname: string # nullable
  --allow-subscriptions-slack: oneof<nothing, bool>
  --allow-subscriptions-sms: oneof<nothing, bool>
  --allow-subscriptions-webhook: oneof<nothing, bool>
  --allow-subscriptions-rss: oneof<nothing, bool>
  --allow-subscriptions-email: oneof<nothing, bool>
  --allow-notifications: oneof<nothing, bool>
  --allow-search-indexing: oneof<nothing, bool>
  --allow-drill-down: oneof<nothing, bool>
  --auth-username: string
  --auth-password: string
  --max-visible-component-days: int # nullable
  --show-status-tab: oneof<nothing, bool>
  --default-status-date-range: int
  --show-active-incidents: oneof<nothing, bool>
  --show-component-response-time: oneof<nothing, bool>
  --show-history-tab: oneof<nothing, bool>
  --default-history-date-range: int
  --uptime-calculation-type: string@uptime-calculation-type-completer
  --show-history-snake: oneof<nothing, bool>
  --show-component-history: oneof<nothing, bool>
  --hide-empty-tabs-status: oneof<nothing, bool>
  --hide-empty-tabs-history: oneof<nothing, bool>
  --show-summary-metrics: oneof<nothing, bool>
  --show-past-incidents: oneof<nothing, bool>
  --allow-pdf-report: oneof<nothing, bool>
  --layout-preset: string@layout-preset-completer
  --show-component-bars: oneof<nothing, bool>
  --show-component-group-descriptions: oneof<nothing, bool>
  --google-analytics-code: string
  --contact-email: string # format: email
  --email-from: string # format: email
  --email-reply-to: string # format: email
  --custom-header-html: string
  --custom-footer-html: string
  --custom-css: string
  --custom-header-html-inspire: string
  --custom-footer-html-inspire: string
  --custom-css-inspire: string
  --company-website-url: string # format: uri
  --timezone: string@timezone-completer
  --theme: string@theme-completer # Theme for the status page. Only 'INSPIRE' can be set via the API; existing 'LEGACY' status pages may be migrated to 'INSPIRE'.
  --custom-header-text-color-hex: string
  --custom-header-bg-color-hex: string
]: any -> record<pk: int, name: string, visibility_level: string, description: string, page_type: string, public_url: string, private_url: string, cname_url: string, url: string, incidents_url: string, components_url: string, metrics_url: string, history_url: string, current_status_url: string, slug: string, page_type_display: string, cname: string, allow_subscriptions: bool, allow_subscriptions_slack: bool, allow_subscriptions_sms: bool, allow_subscriptions_webhook: bool, allow_subscriptions_rss: bool, allow_subscriptions_email: bool, allow_notifications: bool, allow_search_indexing: bool, allow_drill_down: bool, auth_username: string, auth_password: string, description_html: string, max_visible_component_days: int, show_status_tab: bool, default_status_date_range: int, show_active_incidents: bool, show_component_response_time: bool, show_history_tab: bool, default_history_date_range: int, uptime_calculation_type: string, show_history_snake: bool, show_component_history: bool, hide_empty_tabs_status: bool, hide_empty_tabs_history: bool, show_summary_metrics: bool, show_past_incidents: bool, allow_pdf_report: bool, layout_preset: string, show_component_bars: bool, show_component_group_descriptions: bool, google_analytics_code: string, contact_email: string, email_from: string, email_reply_to: string, custom_header_html: string, custom_footer_html: string, custom_css: string, custom_header_html_inspire: string, custom_footer_html_inspire: string, custom_css_inspire: string, email_logo_url: string, logo_url: string, favicon_url: string, company_website_url: string, timezone: string, theme: string, custom_header_text_color_hex: string, custom_header_bg_color_hex: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($pk)/")
  let body = {name: $name, visibility_level: $visibility_level, description: $description, page_type: $page_type, slug: $slug, cname: $cname, allow_subscriptions_slack: $allow_subscriptions_slack, allow_subscriptions_sms: $allow_subscriptions_sms, allow_subscriptions_webhook: $allow_subscriptions_webhook, allow_subscriptions_rss: $allow_subscriptions_rss, allow_subscriptions_email: $allow_subscriptions_email, allow_notifications: $allow_notifications, allow_search_indexing: $allow_search_indexing, allow_drill_down: $allow_drill_down, auth_username: $auth_username, auth_password: $auth_password, max_visible_component_days: $max_visible_component_days, show_status_tab: $show_status_tab, default_status_date_range: $default_status_date_range, show_active_incidents: $show_active_incidents, show_component_response_time: $show_component_response_time, show_history_tab: $show_history_tab, default_history_date_range: $default_history_date_range, uptime_calculation_type: $uptime_calculation_type, show_history_snake: $show_history_snake, show_component_history: $show_component_history, hide_empty_tabs_status: $hide_empty_tabs_status, hide_empty_tabs_history: $hide_empty_tabs_history, show_summary_metrics: $show_summary_metrics, show_past_incidents: $show_past_incidents, allow_pdf_report: $allow_pdf_report, layout_preset: $layout_preset, show_component_bars: $show_component_bars, show_component_group_descriptions: $show_component_group_descriptions, google_analytics_code: $google_analytics_code, contact_email: $contact_email, email_from: $email_from, email_reply_to: $email_reply_to, custom_header_html: $custom_header_html, custom_footer_html: $custom_footer_html, custom_css: $custom_css, custom_header_html_inspire: $custom_header_html_inspire, custom_footer_html_inspire: $custom_footer_html_inspire, custom_css_inspire: $custom_css_inspire, company_website_url: $company_website_url, timezone: $timezone, theme: $theme, custom_header_text_color_hex: $custom_header_text_color_hex, custom_header_bg_color_hex: $custom_header_bg_color_hex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a status page
#
# DELETE /api/v1/statuspages/{pk}/
# operationId: delete_statuspage_detail
export def "statuspages detail-by-pk-3" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/statuspages/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current status of a status page
#
# GET /api/v1/statuspages/{pk}/current-status/
# operationId: get_statuspage_current_status
export def "statuspages-current-status status" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, name: string, visibility_level: string, description: string, page_type: string, public_url: string, private_url: string, cname_url: string, url: string, incidents_url: string, components_url: string, metrics_url: string, history_url: string, current_status_url: string, global_is_operational: bool, active_incidents: table<pk: int, name: string, description: string, starts_at: string, ends_at: string, duration: string, include_in_global_metrics: bool, incident_type_display: string, updates: list, affected_components: list, created_at: string, incident_state: string, incident_type: string, url: string, update_component_status: bool, notify_subscribers: bool, send_maintenance_start_notification: bool, resolve_components: bool>, upcoming_maintenance: table<pk: int, name: string, description: string, starts_at: string, ends_at: string, duration: string, include_in_global_metrics: bool, incident_type_display: string, updates: list, affected_components: list, created_at: string, incident_state: string, incident_type: string, url: string, update_component_status: bool, notify_subscribers: bool, send_maintenance_start_notification: bool, resolve_components: bool>, components: table<pk: int, created_at: string, name: string, description: string, is_group: bool, group_id: int, service_id: int, service_url: string, status: string, auto_status_down: string, auto_status_up: string, sorting_weight: int, url: string>, metrics: table<pk: int, name: string, service_type: string, service_name: string, service_id: int, service_url: string, url: string, is_visible: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($pk)/current-status/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get history of a status page
#
# GET /api/v1/statuspages/{pk}/history/
# operationId: get_statuspage_history
export def "statuspages-history history" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Start date in ISO 8601 (YYYY-MM-DD) format.
  --end-date: string # End date in ISO 8601 (YYYY-MM-DD) format.
]: nothing -> record<pk: int, name: string, visibility_level: string, description: string, page_type: string, public_url: string, private_url: string, cname_url: string, url: string, incidents_url: string, components_url: string, metrics_url: string, history_url: string, current_status_url: string, component_history: string, date_history: string, global_metrics: string, past_incidents: table<pk: int, name: string, description: string, starts_at: string, ends_at: string, duration: string, include_in_global_metrics: bool, incident_type_display: string, updates: list, affected_components: list, created_at: string, incident_state: string, incident_type: string, url: string, update_component_status: bool, notify_subscribers: bool, send_maintenance_start_notification: bool, resolve_components: bool>, active_incidents: table<pk: int, name: string, description: string, starts_at: string, ends_at: string, duration: string, include_in_global_metrics: bool, incident_type_display: string, updates: list, affected_components: list, created_at: string, incident_state: string, incident_type: string, url: string, update_component_status: bool, notify_subscribers: bool, send_maintenance_start_notification: bool, resolve_components: bool>, uptime_calculation_type: string, start_date: string, end_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/statuspages/($pk)/history/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all status page components
#
# GET /api/v1/statuspages/{statuspage_id}/components/
# operationId: get_componentslist
export def "statuspages-components componentslist-by-statuspage_id" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --group-id: float # Filter by whether this component belongs to group with this ID
  --is-group: oneof<nothing, bool> # Filter by whether this component is a group
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, created_at: string, name: string, description: string, is_group: bool, group_id: int, service_id: int, service_url: string, status: string, auto_status_down: string, auto_status_up: string, sorting_weight: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "group_id" $group_id "scalar") (serialize-qp "is_group" $is_group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/components/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new status page component
#
# POST /api/v1/statuspages/{statuspage_id}/components/
# operationId: post_componentslist
export def "statuspages-components componentslist-by-statuspage_id-1" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
  --is-group: oneof<nothing, bool>
  --group-id: int # nullable
  --service-id: int # nullable
  --status: string@status-completer
  --auto-status-down: string@auto-status-down-completer
  --auto-status-up: string@auto-status-up-completer
  --sorting-weight: int
]: any -> record<pk: int, created_at: string, name: string, description: string, is_group: bool, group_id: int, service_id: int, service_url: string, status: string, auto_status_down: string, auto_status_up: string, sorting_weight: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/components/")
  let body = {name: $name, description: $description, is_group: $is_group, group_id: $group_id, service_id: $service_id, status: $status, auto_status_down: $auto_status_down, auto_status_up: $auto_status_up, sorting_weight: $sorting_weight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single status page component
#
# GET /api/v1/statuspages/{statuspage_id}/components/{pk}/
# operationId: get_component_detail
export def "statuspages-components detail-by-statuspage_id-pk" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, created_at: string, name: string, description: string, is_group: bool, group_id: int, service_id: int, service_url: string, status: string, auto_status_down: string, auto_status_up: string, sorting_weight: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/components/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a status page component
#
# PUT /api/v1/statuspages/{statuspage_id}/components/{pk}/
# operationId: put_component_detail
export def "statuspages-components detail-by-statuspage_id-pk-1" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
  --is-group: oneof<nothing, bool>
  --group-id: int # nullable
  --service-id: int # nullable
  --status: string@status-completer
  --auto-status-down: string@auto-status-down-completer
  --auto-status-up: string@auto-status-up-completer
  --sorting-weight: int
]: any -> record<pk: int, created_at: string, name: string, description: string, is_group: bool, group_id: int, service_id: int, service_url: string, status: string, auto_status_down: string, auto_status_up: string, sorting_weight: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/components/($pk)/")
  let body = {name: $name, description: $description, is_group: $is_group, group_id: $group_id, service_id: $service_id, status: $status, auto_status_down: $auto_status_down, auto_status_up: $auto_status_up, sorting_weight: $sorting_weight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a status page component
#
# PATCH /api/v1/statuspages/{statuspage_id}/components/{pk}/
# operationId: patch_component_detail
export def "statuspages-components detail-by-statuspage_id-pk-2" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string
  --is-group: oneof<nothing, bool>
  --group-id: int # nullable
  --service-id: int # nullable
  --status: string@status-completer
  --auto-status-down: string@auto-status-down-completer
  --auto-status-up: string@auto-status-up-completer
  --sorting-weight: int
]: any -> record<pk: int, created_at: string, name: string, description: string, is_group: bool, group_id: int, service_id: int, service_url: string, status: string, auto_status_down: string, auto_status_up: string, sorting_weight: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/components/($pk)/")
  let body = {name: $name, description: $description, is_group: $is_group, group_id: $group_id, service_id: $service_id, status: $status, auto_status_down: $auto_status_down, auto_status_up: $auto_status_up, sorting_weight: $sorting_weight} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a status page component
#
# DELETE /api/v1/statuspages/{statuspage_id}/components/{pk}/
# operationId: delete_component_detail
export def "statuspages-components detail-by-statuspage_id-pk-3" [
  statuspage_id: string
  pk: string
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
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/components/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all status page incidents or maintenance windows
#
# GET /api/v1/statuspages/{statuspage_id}/incidents/
# operationId: get_incidentlist
export def "statuspages-incidents incidentlist-by-statuspage_id" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --incident-type: string@incident-type-completer # Filter by incident type
  --start-date: string # Start date in ISO 8601 (YYYY-MM-DD) format.
  --end-date: string # Start date in ISO 8601 (YYYY-MM-DD) format.
  --ordering: string@ordering-completer-10 # Order results by this field.
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, name: string, description: string, starts_at: string, ends_at: string, duration: string, include_in_global_metrics: bool, incident_type_display: string, updates: list, affected_components: list, created_at: string, incident_state: string, incident_type: string, url: string, update_component_status: bool, notify_subscribers: bool, send_maintenance_start_notification: bool, resolve_components: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "incident_type" $incident_type "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "ordering" $ordering "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/incidents/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new status page incident or maintenance window
#
# POST /api/v1/statuspages/{statuspage_id}/incidents/
# operationId: post_incidentlist
# --updates item shape: {updated_at: string, description?: string, incident_state: "investigating"|"identified"|"monitoring"|"resolved"|"notification"|"maintenance", notify_subscribers?: bool, resolve_components?: bool, resolve_incident?: bool}
# --affected_components item shape: {id?: int, status: "major-outage"|"partial-outage"|"degraded-performance"|"under-maintenance", component: record}
export def "statuspages-incidents incidentlist-by-statuspage_id-1" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of incident, eg. a problem or resolution
  starts_at: string # When this incident occurred in GMT (format: date-time)
  --ends-at: string # nullable, format: date-time
  --include-in-global-metrics: oneof<nothing, bool>
  updates: list # item shape: {updated_at: string, description?: string, incident_state: "investigating"|"identified"|"monitoring"|"resolved"|"notification"|"maintenance", notify_subscribers?: bool, resolve_components?: bool, resolve_incident?: bool}
  --affected-components: list # nullable — item shape: {id?: int, status: "major-outage"|"partial-outage"|"degraded-performance"|"under-maintenance", component: record}
  incident_type: string@incident-type-completer
  --update-component-status: oneof<nothing, bool>
  --notify-subscribers: oneof<nothing, bool> # Send notifications to subscribers of this Status Page
  --send-maintenance-start-notification: oneof<nothing, bool>
  --resolve-components: oneof<nothing, bool> # Resolve all affected components to 'Operational'. Requires 'ends_at' to be set. (default: false)
]: any -> record<pk: int, name: string, description: string, starts_at: string, ends_at: string, duration: string, include_in_global_metrics: bool, incident_type_display: string, updates: table<id: int, created_at: string, updated_at: string, description: string, incident_state: string, incident_state_display: string, notify_subscribers: bool, resolve_components: bool, resolve_incident: bool>, affected_components: table<id: int, status: string, name: string, description: string, component: record>, created_at: string, incident_state: string, incident_type: string, url: string, update_component_status: bool, notify_subscribers: bool, send_maintenance_start_notification: bool, resolve_components: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/incidents/")
  let body = {name: $name, starts_at: $starts_at, ends_at: $ends_at, include_in_global_metrics: $include_in_global_metrics, updates: $updates, affected_components: $affected_components, incident_type: $incident_type, update_component_status: $update_component_status, notify_subscribers: $notify_subscribers, send_maintenance_start_notification: $send_maintenance_start_notification, resolve_components: $resolve_components} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all incident's updates
#
# GET /api/v1/statuspages/{statuspage_id}/incidents/{incident_id}/updates/
# operationId: get_incidentupdatelist
export def "statuspages-incidents-updates incidentupdatelist-by-statuspage_id-incident_id" [
  statuspage_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, created_at: string, updated_at: string, description: string, incident_state: string, incident_state_display: string, notify_subscribers: bool, resolve_components: bool, resolve_incident: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/incidents/($incident_id)/updates/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new incident update
#
# POST /api/v1/statuspages/{statuspage_id}/incidents/{incident_id}/updates/
# operationId: post_incidentupdatelist
export def "statuspages-incidents-updates incidentupdatelist-by-statuspage_id-incident_id-1" [
  statuspage_id: string
  incident_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  updated_at: string # format: date-time
  --description: string
  incident_state: string@incident-state-completer
  --notify-subscribers: oneof<nothing, bool> # Send notifications to subscribers of this Status Page
  --resolve-components: oneof<nothing, bool> # Resolve all affected components to 'Operational'. Requires 'ends_at' to be set on the parent Incident. (default: false)
  --resolve-incident: oneof<nothing, bool> # Resolve the parent Incident. (default: false)
]: any -> record<id: int, created_at: string, updated_at: string, description: string, incident_state: string, incident_state_display: string, notify_subscribers: bool, resolve_components: bool, resolve_incident: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/incidents/($incident_id)/updates/")
  let body = {updated_at: $updated_at, description: $description, incident_state: $incident_state, notify_subscribers: $notify_subscribers, resolve_components: $resolve_components, resolve_incident: $resolve_incident} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single status page incident update
#
# GET /api/v1/statuspages/{statuspage_id}/incidents/{incident_id}/updates/{pk}/
# operationId: get_incident_update_detail
export def "statuspages-incidents-updates detail-by-statuspage_id-incident_id-pk" [
  statuspage_id: string
  incident_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, created_at: string, updated_at: string, description: string, incident_state: string, incident_state_display: string, notify_subscribers: bool, resolve_components: bool, resolve_incident: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/incidents/($incident_id)/updates/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a single status page incident update
#
# PUT /api/v1/statuspages/{statuspage_id}/incidents/{incident_id}/updates/{pk}/
# operationId: put_incident_update_detail
export def "statuspages-incidents-updates detail-by-statuspage_id-incident_id-pk-1" [
  statuspage_id: string
  incident_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  updated_at: string # format: date-time
  --description: string
  incident_state: string@incident-state-completer
  --notify-subscribers: oneof<nothing, bool> # Send notifications to subscribers of this Status Page
  --resolve-components: oneof<nothing, bool> # Resolve all affected components to 'Operational'. Requires 'ends_at' to be set on the parent Incident. (default: false)
  --resolve-incident: oneof<nothing, bool> # Resolve the parent Incident. (default: false)
]: any -> record<id: int, created_at: string, updated_at: string, description: string, incident_state: string, incident_state_display: string, notify_subscribers: bool, resolve_components: bool, resolve_incident: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/incidents/($incident_id)/updates/($pk)/")
  let body = {updated_at: $updated_at, description: $description, incident_state: $incident_state, notify_subscribers: $notify_subscribers, resolve_components: $resolve_components, resolve_incident: $resolve_incident} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a single status page incident update
#
# PATCH /api/v1/statuspages/{statuspage_id}/incidents/{incident_id}/updates/{pk}/
# operationId: patch_incident_update_detail
export def "statuspages-incidents-updates detail-by-statuspage_id-incident_id-pk-2" [
  statuspage_id: string
  incident_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  updated_at: string # format: date-time
  --description: string
  incident_state: string@incident-state-completer
  --notify-subscribers: oneof<nothing, bool> # Send notifications to subscribers of this Status Page
  --resolve-components: oneof<nothing, bool> # Resolve all affected components to 'Operational'. Requires 'ends_at' to be set on the parent Incident. (default: false)
  --resolve-incident: oneof<nothing, bool> # Resolve the parent Incident. (default: false)
]: any -> record<id: int, created_at: string, updated_at: string, description: string, incident_state: string, incident_state_display: string, notify_subscribers: bool, resolve_components: bool, resolve_incident: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/incidents/($incident_id)/updates/($pk)/")
  let body = {updated_at: $updated_at, description: $description, incident_state: $incident_state, notify_subscribers: $notify_subscribers, resolve_components: $resolve_components, resolve_incident: $resolve_incident} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a single status page incident update
#
# DELETE /api/v1/statuspages/{statuspage_id}/incidents/{incident_id}/updates/{pk}/
# operationId: delete_incident_update_detail
export def "statuspages-incidents-updates detail-by-statuspage_id-incident_id-pk-3" [
  statuspage_id: string
  incident_id: string
  pk: string
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
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/incidents/($incident_id)/updates/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single status page incident or maintenance window
#
# GET /api/v1/statuspages/{statuspage_id}/incidents/{pk}/
# operationId: get_incident_detail
export def "statuspages-incidents detail-by-statuspage_id-pk" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, name: string, description: string, starts_at: string, ends_at: string, duration: string, include_in_global_metrics: bool, incident_type_display: string, updates: table<id: int, created_at: string, updated_at: string, description: string, incident_state: string, incident_state_display: string, notify_subscribers: bool, resolve_components: bool, resolve_incident: bool>, affected_components: table<id: int, status: string, name: string, description: string, component: record>, created_at: string, incident_state: string, incident_type: string, url: string, update_component_status: bool, notify_subscribers: bool, send_maintenance_start_notification: bool, resolve_components: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/incidents/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a single status page incident or maintenance window
#
# PUT /api/v1/statuspages/{statuspage_id}/incidents/{pk}/
# operationId: put_incident_detail
# --updates item shape: {updated_at: string, description?: string, incident_state: "investigating"|"identified"|"monitoring"|"resolved"|"notification"|"maintenance", notify_subscribers?: bool, resolve_components?: bool, resolve_incident?: bool}
# --affected_components item shape: {id?: int, status: "major-outage"|"partial-outage"|"degraded-performance"|"under-maintenance", component: record}
export def "statuspages-incidents detail-by-statuspage_id-pk-1" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of incident, eg. a problem or resolution
  starts_at: string # When this incident occurred in GMT (format: date-time)
  --ends-at: string # nullable, format: date-time
  --include-in-global-metrics: oneof<nothing, bool>
  updates: list # item shape: {updated_at: string, description?: string, incident_state: "investigating"|"identified"|"monitoring"|"resolved"|"notification"|"maintenance", notify_subscribers?: bool, resolve_components?: bool, resolve_incident?: bool}
  --affected-components: list # nullable — item shape: {id?: int, status: "major-outage"|"partial-outage"|"degraded-performance"|"under-maintenance", component: record}
  incident_type: string@incident-type-completer
  --update-component-status: oneof<nothing, bool>
  --notify-subscribers: oneof<nothing, bool> # Send notifications to subscribers of this Status Page
  --send-maintenance-start-notification: oneof<nothing, bool>
  --resolve-components: oneof<nothing, bool> # Resolve all affected components to 'Operational'. Requires 'ends_at' to be set. (default: false)
]: any -> record<pk: int, name: string, description: string, starts_at: string, ends_at: string, duration: string, include_in_global_metrics: bool, incident_type_display: string, updates: table<id: int, created_at: string, updated_at: string, description: string, incident_state: string, incident_state_display: string, notify_subscribers: bool, resolve_components: bool, resolve_incident: bool>, affected_components: table<id: int, status: string, name: string, description: string, component: record>, created_at: string, incident_state: string, incident_type: string, url: string, update_component_status: bool, notify_subscribers: bool, send_maintenance_start_notification: bool, resolve_components: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/incidents/($pk)/")
  let body = {name: $name, starts_at: $starts_at, ends_at: $ends_at, include_in_global_metrics: $include_in_global_metrics, updates: $updates, affected_components: $affected_components, incident_type: $incident_type, update_component_status: $update_component_status, notify_subscribers: $notify_subscribers, send_maintenance_start_notification: $send_maintenance_start_notification, resolve_components: $resolve_components} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a single status page incident or maintenance window
#
# PATCH /api/v1/statuspages/{statuspage_id}/incidents/{pk}/
# operationId: patch_incident_detail
# --updates item shape: {updated_at: string, description?: string, incident_state: "investigating"|"identified"|"monitoring"|"resolved"|"notification"|"maintenance", notify_subscribers?: bool, resolve_components?: bool, resolve_incident?: bool}
# --affected_components item shape: {id?: int, status: "major-outage"|"partial-outage"|"degraded-performance"|"under-maintenance", component: record}
export def "statuspages-incidents detail-by-statuspage_id-pk-2" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of incident, eg. a problem or resolution
  starts_at: string # When this incident occurred in GMT (format: date-time)
  --ends-at: string # nullable, format: date-time
  --include-in-global-metrics: oneof<nothing, bool>
  updates: list # item shape: {updated_at: string, description?: string, incident_state: "investigating"|"identified"|"monitoring"|"resolved"|"notification"|"maintenance", notify_subscribers?: bool, resolve_components?: bool, resolve_incident?: bool}
  --affected-components: list # nullable — item shape: {id?: int, status: "major-outage"|"partial-outage"|"degraded-performance"|"under-maintenance", component: record}
  incident_type: string@incident-type-completer
  --update-component-status: oneof<nothing, bool>
  --notify-subscribers: oneof<nothing, bool> # Send notifications to subscribers of this Status Page
  --send-maintenance-start-notification: oneof<nothing, bool>
  --resolve-components: oneof<nothing, bool> # Resolve all affected components to 'Operational'. Requires 'ends_at' to be set. (default: false)
]: any -> record<pk: int, name: string, description: string, starts_at: string, ends_at: string, duration: string, include_in_global_metrics: bool, incident_type_display: string, updates: table<id: int, created_at: string, updated_at: string, description: string, incident_state: string, incident_state_display: string, notify_subscribers: bool, resolve_components: bool, resolve_incident: bool>, affected_components: table<id: int, status: string, name: string, description: string, component: record>, created_at: string, incident_state: string, incident_type: string, url: string, update_component_status: bool, notify_subscribers: bool, send_maintenance_start_notification: bool, resolve_components: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/incidents/($pk)/")
  let body = {name: $name, starts_at: $starts_at, ends_at: $ends_at, include_in_global_metrics: $include_in_global_metrics, updates: $updates, affected_components: $affected_components, incident_type: $incident_type, update_component_status: $update_component_status, notify_subscribers: $notify_subscribers, send_maintenance_start_notification: $send_maintenance_start_notification, resolve_components: $resolve_components} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a single status page incident or maintenance window
#
# DELETE /api/v1/statuspages/{statuspage_id}/incidents/{pk}/
# operationId: delete_incident_detail
export def "statuspages-incidents detail-by-statuspage_id-pk-3" [
  statuspage_id: string
  pk: string
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
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/incidents/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all status page metrics
#
# GET /api/v1/statuspages/{statuspage_id}/metrics/
# operationId: get_metricslist
export def "statuspages-metrics metricslist-by-statuspage_id" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --is-visible: oneof<nothing, bool> # Filter by whether this metric is visible to Status Page visitors
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, name: string, service_type: string, service_name: string, service_id: int, service_url: string, url: string, is_visible: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "is_visible" $is_visible "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/metrics/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new status page metric
#
# POST /api/v1/statuspages/{statuspage_id}/metrics/
# operationId: post_metricslist
export def "statuspages-metrics metricslist-by-statuspage_id-1" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  service_id: int
  --is-visible: oneof<nothing, bool>
]: any -> record<pk: int, name: string, service_type: string, service_name: string, service_id: int, service_url: string, url: string, is_visible: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/metrics/")
  let body = {name: $name, service_id: $service_id, is_visible: $is_visible} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single status page metric
#
# GET /api/v1/statuspages/{statuspage_id}/metrics/{pk}/
# operationId: get_metric_detail
export def "statuspages-metrics detail-by-statuspage_id-pk" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, name: string, service_type: string, service_name: string, service_id: int, service_url: string, url: string, is_visible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/metrics/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a status page metric
#
# PUT /api/v1/statuspages/{statuspage_id}/metrics/{pk}/
# operationId: put_metric_detail
export def "statuspages-metrics detail-by-statuspage_id-pk-1" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  service_id: int
  --is-visible: oneof<nothing, bool>
]: any -> record<pk: int, name: string, service_type: string, service_name: string, service_id: int, service_url: string, url: string, is_visible: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/metrics/($pk)/")
  let body = {name: $name, service_id: $service_id, is_visible: $is_visible} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a status page metric
#
# PATCH /api/v1/statuspages/{statuspage_id}/metrics/{pk}/
# operationId: patch_metric_detail
export def "statuspages-metrics detail-by-statuspage_id-pk-2" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  service_id: int
  --is-visible: oneof<nothing, bool>
]: any -> record<pk: int, name: string, service_type: string, service_name: string, service_id: int, service_url: string, url: string, is_visible: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/metrics/($pk)/")
  let body = {name: $name, service_id: $service_id, is_visible: $is_visible} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a status page metric
#
# DELETE /api/v1/statuspages/{statuspage_id}/metrics/{pk}/
# operationId: delete_metric_detail
export def "statuspages-metrics detail-by-statuspage_id-pk-3" [
  statuspage_id: string
  pk: string
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
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/metrics/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all status page subscribers
#
# GET /api/v1/statuspages/{statuspage_id}/subscribers/
# operationId: get_statuspagesubscriberslist
export def "statuspages-subscribers statuspagesubscriberslist-by-statuspage_id" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --type: string@type-completer # Filter by subscription type.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, target: string, type: string, created_at: string, target_verified_on: string, force_validation_sms: bool, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscribers/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new status page subscriber
#
# POST /api/v1/statuspages/{statuspage_id}/subscribers/
# operationId: post_statuspagesubscriberslist
export def "statuspages-subscribers statuspagesubscriberslist-by-statuspage_id-1" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int
  --target: string
  type: string@type-completer
  --created-at: string # nullable, format: date-time
  --force-validation-sms: oneof<nothing, bool> # default: false
]: any -> record<id: int, target: string, type: string, created_at: string, target_verified_on: string, force_validation_sms: bool, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscribers/")
  let body = {id: $id, target: $target, type: $type, created_at: $created_at, force_validation_sms: $force_validation_sms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single status page subscriber
#
# GET /api/v1/statuspages/{statuspage_id}/subscribers/{pk}/
# operationId: get_subscription_detail
export def "statuspages-subscribers detail-by-statuspage_id-pk" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, target: string, type: string, created_at: string, target_verified_on: string, force_validation_sms: bool, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscribers/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a status page subscriber
#
# DELETE /api/v1/statuspages/{statuspage_id}/subscribers/{pk}/
# operationId: delete_subscription_detail
export def "statuspages-subscribers detail-by-statuspage_id-pk-1" [
  statuspage_id: string
  pk: string
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
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscribers/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all allowed email domains
#
# GET /api/v1/statuspages/{statuspage_id}/subscription-domain-allow-list/
# operationId: get_statuspagesubscriptiondomainallowlist
export def "statuspages-subscription-domain-allow-list statuspagesubscriptiondomainallowlist-by-statuspage_id" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, domain: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscription-domain-allow-list/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new allowed email domain
#
# POST /api/v1/statuspages/{statuspage_id}/subscription-domain-allow-list/
# operationId: post_statuspagesubscriptiondomainallowlist
export def "statuspages-subscription-domain-allow-list statuspagesubscriptiondomainallowlist-by-statuspage_id-1" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: string
]: any -> record<id: int, domain: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscription-domain-allow-list/")
  let body = {domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single status page allowed email domain
#
# GET /api/v1/statuspages/{statuspage_id}/subscription-domain-allow-list/{pk}/
# operationId: get_subscription_domain_allow_details
export def "statuspages-subscription-domain-allow-list details-by-statuspage_id-pk" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, domain: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscription-domain-allow-list/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /api/v1/statuspages/{statuspage_id}/subscription-domain-allow-list/{pk}/
#
# operationId: patch_subscription_domain_allow_details
export def "statuspages-subscription-domain-allow-list details-by-statuspage_id-pk-1" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: string
]: any -> record<id: int, domain: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscription-domain-allow-list/($pk)/")
  let body = {domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a status page allowed email domain
#
# DELETE /api/v1/statuspages/{statuspage_id}/subscription-domain-allow-list/{pk}/
# operationId: delete_subscription_domain_allow_details
export def "statuspages-subscription-domain-allow-list details-by-statuspage_id-pk-2" [
  statuspage_id: string
  pk: string
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
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscription-domain-allow-list/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all blocked email domains
#
# GET /api/v1/statuspages/{statuspage_id}/subscription-domain-block-list/
# operationId: get_statuspagesubscriptiondomainblocklist
export def "statuspages-subscription-domain-block-list statuspagesubscriptiondomainblocklist-by-statuspage_id" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
]: nothing -> record<count: int, next: string, previous: string, results: table<id: int, domain: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscription-domain-block-list/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create new blocked email domain
#
# POST /api/v1/statuspages/{statuspage_id}/subscription-domain-block-list/
# operationId: post_statuspagesubscriptiondomainblocklist
export def "statuspages-subscription-domain-block-list statuspagesubscriptiondomainblocklist-by-statuspage_id-1" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: string
]: any -> record<id: int, domain: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscription-domain-block-list/")
  let body = {domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single status page blocked email domain
#
# GET /api/v1/statuspages/{statuspage_id}/subscription-domain-block-list/{pk}/
# operationId: get_subscription_domain_block_details
export def "statuspages-subscription-domain-block-list details-by-statuspage_id-pk" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, domain: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscription-domain-block-list/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /api/v1/statuspages/{statuspage_id}/subscription-domain-block-list/{pk}/
#
# operationId: patch_subscription_domain_block_details
export def "statuspages-subscription-domain-block-list details-by-statuspage_id-pk-1" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: string
]: any -> record<id: int, domain: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscription-domain-block-list/($pk)/")
  let body = {domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a status page blocked email domain
#
# DELETE /api/v1/statuspages/{statuspage_id}/subscription-domain-block-list/{pk}/
# operationId: delete_subscription_domain_block_details
export def "statuspages-subscription-domain-block-list details-by-statuspage_id-pk-2" [
  statuspage_id: string
  pk: string
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
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/subscription-domain-block-list/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all status page external users
#
# GET /api/v1/statuspages/{statuspage_id}/users/
# operationId: get_statuspageexternaluserlist
export def "statuspages-users statuspageexternaluserlist-by-statuspage_id" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --is-active: oneof<nothing, bool> # Filter by whether this user can view the status page or not.
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, email: string, first_name: string, last_name: string, is_active: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "is_active" $is_active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/users/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new status external user
#
# POST /api/v1/statuspages/{statuspage_id}/users/
# operationId: post_statuspageexternaluserlist
export def "statuspages-users statuspageexternaluserlist-by-statuspage_id-1" [
  statuspage_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pk: int
  email: string # format: email
  first_name: string
  last_name: string
  --is-active: oneof<nothing, bool>
]: any -> record<pk: int, email: string, first_name: string, last_name: string, is_active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/users/")
  let body = {pk: $pk, email: $email, first_name: $first_name, last_name: $last_name, is_active: $is_active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single status external user
#
# GET /api/v1/statuspages/{statuspage_id}/users/{pk}/
# operationId: get_external_user_detail
export def "statuspages-users detail-by-statuspage_id-pk" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, email: string, first_name: string, last_name: string, is_active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/users/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a status page external user
#
# PUT /api/v1/statuspages/{statuspage_id}/users/{pk}/
# operationId: put_external_user_detail
export def "statuspages-users detail-by-statuspage_id-pk-1" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-pk: int
  email: string # format: email
  first_name: string
  last_name: string
  --is-active: oneof<nothing, bool>
]: any -> record<pk: int, email: string, first_name: string, last_name: string, is_active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/users/($pk)/")
  let body = {pk: $body_pk, email: $email, first_name: $first_name, last_name: $last_name, is_active: $is_active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a status page external user
#
# PATCH /api/v1/statuspages/{statuspage_id}/users/{pk}/
# operationId: patch_external_user_detail
export def "statuspages-users detail-by-statuspage_id-pk-2" [
  statuspage_id: string
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-pk: int
  email: string # format: email
  first_name: string
  last_name: string
  --is-active: oneof<nothing, bool>
]: any -> record<pk: int, email: string, first_name: string, last_name: string, is_active: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/users/($pk)/")
  let body = {pk: $body_pk, email: $email, first_name: $first_name, last_name: $last_name, is_active: $is_active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a status page external user
#
# DELETE /api/v1/statuspages/{statuspage_id}/users/{pk}/
# operationId: delete_external_user_detail
export def "statuspages-users detail-by-statuspage_id-pk-3" [
  statuspage_id: string
  pk: string
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
  let full_url = (build-url $base $"/api/v1/statuspages/($statuspage_id)/users/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all users
#
# GET /api/v1/users/
# operationId: get_userlist
export def "users userlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # A page number within the paginated result set.
  --page-size: int # Number of results to return per page.
  --search: string # A search term.
  --ordering: string@ordering-completer-11 # Order results by this field.
  --email: string # Filter by email address.
  --access-level: string@access-level-completer # Filter by access level.
  --subaccount: string # Filter by users that have access to this subaccount ID.
  --is-active: oneof<nothing, bool> # Filter by whether the user is active.
  --is-api-enabled: oneof<nothing, bool> # Filter by whether the API is enabled for this user.
  --notify-paid-invoices: oneof<nothing, bool> # Filter by whether invoices are sent to this user.
]: nothing -> record<count: int, next: string, previous: string, results: table<pk: int, url: string, first_name: string, last_name: string, email: string, password: string, is_active: bool, is_primary: bool, access_level: string, is_api_enabled: bool, notify_paid_invoices: bool, assigned_subaccounts: list, require_two_factor: string, must_two_factor: string, timezone: string, account: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "access_level" $access_level "scalar") (serialize-qp "subaccount" $subaccount "scalar") (serialize-qp "is_active" $is_active "scalar") (serialize-qp "is_api_enabled" $is_api_enabled "scalar") (serialize-qp "notify_paid_invoices" $notify_paid_invoices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new user
#
# POST /api/v1/users/
# operationId: post_userlist
# --account shape: {name: string, timezone?: "Pacific/Midway"|"Pacific/Niue"|"Pacific/Pago_Pago"|"America/Adak"|"Pacific/Honolulu"|"Pacific/Rarotonga"|"Pacific/Tahiti"|"US/Hawaii"|"Pacific/Marquesas"|"America/Anchorage"|"Pacific/Gambier"|"America/Juneau"|"America/Metlakatla"|"America/Nome"|"America/Sitka"|"US/Alaska"|"America/Yakutat"|"America/Dawson"|"America/Los_Angeles"|"Pacific/Pitcairn"|"America/Tijuana"|"US/Pacific"|"America/Vancouver"|"America/Whitehorse"|"America/Boise"|"America/Cambridge_Bay"|"America/Chihuahua"|"America/Ciudad_Juarez"|"America/Creston"|"America/Dawson_Creek"|"America/Denver"|"America/Edmonton"|"America/Fort_Nelson"|"America/Hermosillo"|"America/Inuvik"|"America/Mazatlan"|"America/Ojinaga"|"America/Phoenix"|"US/Arizona"|"US/Mountain"|"America/Bahia_Banderas"|"America/Belize"|"America/North_Dakota/Beulah"|"America/North_Dakota/Center"|"America/Chicago"|"America/Costa_Rica"|"Pacific/Easter"|"America/El_Salvador"|"Pacific/Galapagos"|"America/Guatemala"|"America/Indiana/Knox"|"America/Managua"|"America/Matamoros"|"America/Menominee"|"America/Merida"|"America/Mexico_City"|"America/Monterrey"|"America/North_Dakota/New_Salem"|"America/Rankin_Inlet"|"America/Regina"|"America/Resolute"|"America/Swift_Current"|"America/Tegucigalpa"|"America/Indiana/Tell_City"|"US/Central"|"America/Winnipeg"|"America/Atikokan"|"America/Bogota"|"America/Cancun"|"America/Cayman"|"America/Detroit"|"America/Eirunepe"|"America/Guayaquil"|"America/Havana"|"America/Indiana/Indianapolis"|"America/Iqaluit"|"America/Jamaica"|"America/Lima"|"America/Kentucky/Louisville"|"America/Indiana/Marengo"|"America/Kentucky/Monticello"|"America/Nassau"|"America/New_York"|"America/Panama"|"America/Indiana/Petersburg"|"America/Port-au-Prince"|"America/Rio_Branco"|"America/Toronto"|"US/Eastern"|"America/Indiana/Vevay"|"America/Indiana/Vincennes"|"America/Indiana/Winamac"|"America/Caracas"|"America/Anguilla"|"America/Antigua"|"America/Aruba"|"America/Asuncion"|"America/Barbados"|"Atlantic/Bermuda"|"America/Blanc-Sablon"|"America/Boa_Vista"|"America/Campo_Grande"|"America/Cuiaba"|"America/Curacao"|"America/Dominica"|"America/Glace_Bay"|"America/Goose_Bay"|"America/Grand_Turk"|"America/Grenada"|"America/Guadeloupe"|"America/Guyana"|"America/Halifax"|"America/Kralendijk"|"America/La_Paz"|"America/Lower_Princes"|"America/Manaus"|"America/Marigot"|"America/Martinique"|"America/Moncton"|"America/Montserrat"|"America/Port_of_Spain"|"America/Porto_Velho"|"America/Puerto_Rico"|"America/Punta_Arenas"|"America/Santiago"|"America/Santo_Domingo"|"America/St_Barthelemy"|"America/St_Kitts"|"America/St_Lucia"|"America/St_Thomas"|"America/St_Vincent"|"America/Thule"|"America/Tortola"|"America/St_Johns"|"America/Araguaina"|"America/Bahia"|"America/Belem"|"America/Argentina/Buenos_Aires"|"America/Argentina/Catamarca"|"America/Cayenne"|"America/Argentina/Cordoba"|"America/Fortaleza"|"America/Argentina/Jujuy"|"America/Argentina/La_Rioja"|"America/Maceio"|"America/Argentina/Mendoza"|"America/Miquelon"|"America/Montevideo"|"America/Nuuk"|"America/Paramaribo"|"America/Recife"|"America/Argentina/Rio_Gallegos"|"America/Argentina/Salta"|"America/Argentina/San_Juan"|"America/Argentina/San_Luis"|"America/Santarem"|"America/Sao_Paulo"|"Atlantic/Stanley"|"America/Argentina/Tucuman"|"America/Argentina/Ushuaia"|"America/Noronha"|"Atlantic/South_Georgia"|"Atlantic/Azores"|"Atlantic/Cape_Verde"|"America/Scoresbysund"|"Africa/Abidjan"|"Africa/Accra"|"Africa/Bamako"|"Africa/Banjul"|"Africa/Bissau"|"Atlantic/Canary"|"Africa/Casablanca"|"Africa/Conakry"|"Africa/Dakar"|"America/Danmarkshavn"|"Africa/El_Aaiun"|"Atlantic/Faroe"|"Africa/Freetown"|"GMT"|"Europe/Guernsey"|"Europe/Isle_of_Man"|"Europe/Jersey"|"Europe/Lisbon"|"Africa/Lome"|"Europe/London"|"Atlantic/Madeira"|"Africa/Monrovia"|"Africa/Nouakchott"|"Africa/Ouagadougou"|"Atlantic/Reykjavik"|"Africa/Sao_Tome"|"Atlantic/St_Helena"|"UTC"|"Africa/Algiers"|"Europe/Amsterdam"|"Europe/Andorra"|"Africa/Bangui"|"Europe/Belgrade"|"Europe/Berlin"|"Europe/Bratislava"|"Africa/Brazzaville"|"Europe/Brussels"|"Europe/Budapest"|"Europe/Busingen"|"Africa/Ceuta"|"Europe/Copenhagen"|"Africa/Douala"|"Europe/Dublin"|"Europe/Gibraltar"|"Africa/Kinshasa"|"Africa/Lagos"|"Africa/Libreville"|"Europe/Ljubljana"|"Africa/Luanda"|"Europe/Luxembourg"|"Europe/Madrid"|"Africa/Malabo"|"Europe/Malta"|"Europe/Monaco"|"Africa/Ndjamena"|"Africa/Niamey"|"Europe/Oslo"|"Europe/Paris"|"Europe/Podgorica"|"Africa/Porto-Novo"|"Europe/Prague"|"Europe/Rome"|"Europe/San_Marino"|"Europe/Sarajevo"|"Europe/Skopje"|"Europe/Stockholm"|"Europe/Tirane"|"Africa/Tunis"|"Europe/Vaduz"|"Europe/Vatican"|"Europe/Vienna"|"Europe/Warsaw"|"Europe/Zagreb"|"Europe/Zurich"|"Asia/Amman"|"Europe/Athens"|"Asia/Beirut"|"Africa/Blantyre"|"Europe/Bucharest"|"Africa/Bujumbura"|"Africa/Cairo"|"Europe/Chisinau"|"Asia/Damascus"|"Asia/Famagusta"|"Africa/Gaborone"|"Asia/Gaza"|"Africa/Harare"|"Asia/Hebron"|"Europe/Helsinki"|"Europe/Istanbul"|"Asia/Jerusalem"|"Africa/Johannesburg"|"Europe/Kaliningrad"|"Europe/Kiev"|"Africa/Kigali"|"Europe/Kyiv"|"Africa/Lubumbashi"|"Africa/Lusaka"|"Africa/Maputo"|"Europe/Mariehamn"|"Africa/Maseru"|"Africa/Mbabane"|"Asia/Nicosia"|"Europe/Riga"|"Europe/Sofia"|"Europe/Tallinn"|"Africa/Tripoli"|"Europe/Uzhgorod"|"Europe/Vilnius"|"Africa/Windhoek"|"Africa/Addis_Ababa"|"Asia/Aden"|"Indian/Antananarivo"|"Africa/Asmara"|"Europe/Astrakhan"|"Asia/Baghdad"|"Asia/Bahrain"|"Indian/Comoro"|"Africa/Dar_es_Salaam"|"Africa/Djibouti"|"Africa/Juba"|"Africa/Kampala"|"Africa/Khartoum"|"Europe/Kirov"|"Asia/Kuwait"|"Indian/Mayotte"|"Europe/Minsk"|"Africa/Mogadishu"|"Europe/Moscow"|"Africa/Nairobi"|"Asia/Qatar"|"Asia/Riyadh"|"Europe/Saratov"|"Europe/Simferopol"|"Europe/Ulyanovsk"|"Europe/Volgograd"|"Asia/Tehran"|"Asia/Baku"|"Asia/Dubai"|"Indian/Mahe"|"Indian/Mauritius"|"Asia/Muscat"|"Indian/Reunion"|"Europe/Samara"|"Asia/Tbilisi"|"Asia/Yerevan"|"Asia/Kabul"|"Asia/Aqtau"|"Asia/Aqtobe"|"Asia/Ashgabat"|"Asia/Atyrau"|"Asia/Dushanbe"|"Asia/Karachi"|"Indian/Kerguelen"|"Indian/Maldives"|"Asia/Oral"|"Asia/Samarkand"|"Asia/Tashkent"|"Asia/Yekaterinburg"|"Asia/Colombo"|"Asia/Kolkata"|"Asia/Kathmandu"|"Asia/Almaty"|"Asia/Barnaul"|"Asia/Bishkek"|"Indian/Chagos"|"Asia/Dhaka"|"Asia/Novosibirsk"|"Asia/Omsk"|"Asia/Qostanay"|"Asia/Qyzylorda"|"Asia/Thimphu"|"Asia/Tomsk"|"Asia/Urumqi"|"Indian/Cocos"|"Asia/Yangon"|"Asia/Bangkok"|"Indian/Christmas"|"Asia/Ho_Chi_Minh"|"Asia/Hovd"|"Asia/Jakarta"|"Asia/Krasnoyarsk"|"Asia/Novokuznetsk"|"Asia/Phnom_Penh"|"Asia/Pontianak"|"Asia/Vientiane"|"Asia/Brunei"|"Asia/Chita"|"Asia/Choibalsan"|"Asia/Hong_Kong"|"Asia/Irkutsk"|"Asia/Kuala_Lumpur"|"Asia/Kuching"|"Asia/Macau"|"Asia/Makassar"|"Asia/Manila"|"Australia/Perth"|"Asia/Shanghai"|"Asia/Singapore"|"Asia/Taipei"|"Asia/Ulaanbaatar"|"Asia/Pyongyang"|"Australia/Eucla"|"Asia/Dili"|"Asia/Jayapura"|"Asia/Khandyga"|"Pacific/Palau"|"Asia/Seoul"|"Asia/Tokyo"|"Asia/Yakutsk"|"Australia/Adelaide"|"Australia/Broken_Hill"|"Australia/Darwin"|"Australia/Brisbane"|"Pacific/Chuuk"|"Pacific/Guam"|"Australia/Hobart"|"Australia/Lindeman"|"Asia/Magadan"|"Australia/Melbourne"|"Pacific/Port_Moresby"|"Pacific/Saipan"|"Asia/Sakhalin"|"Australia/Sydney"|"Asia/Ust-Nera"|"Asia/Vladivostok"|"Australia/Lord_Howe"|"Pacific/Bougainville"|"Pacific/Efate"|"Pacific/Guadalcanal"|"Pacific/Kosrae"|"Pacific/Norfolk"|"Pacific/Noumea"|"Pacific/Pohnpei"|"Asia/Srednekolymsk"|"Asia/Anadyr"|"Pacific/Auckland"|"Pacific/Fiji"|"Pacific/Funafuti"|"Asia/Kamchatka"|"Pacific/Kwajalein"|"Pacific/Majuro"|"Pacific/Nauru"|"Pacific/Tarawa"|"Pacific/Wake"|"Pacific/Wallis"|"Pacific/Chatham"|"Pacific/Apia"|"Pacific/Fakaofo"|"Pacific/Kanton"|"Pacific/Tongatapu"|"Pacific/Kiritimati", data_region?: "US"|"EU", free_trial_expires_at?: string}
export def "users userlist-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  first_name: string # The user's first name
  last_name: string # The user's first name
  email: string # The user's email address, used as their username (format: email)
  --password: string # The user's password
  --access-level: string@access-level-completer # The permission level for this user
  --is-api-enabled: oneof<nothing, bool> # Whether this user may access the API
  --notify-paid-invoices: oneof<nothing, bool> # Whether this user should receive new invoices
  --assigned-subaccounts: list # Which subaccounts this user may access, or empty for All Subaccounts.
  --require-two-factor: string@require-two-factor-completer
]: any -> record<pk: int, url: string, first_name: string, last_name: string, email: string, password: string, is_active: bool, is_primary: bool, access_level: string, is_api_enabled: bool, notify_paid_invoices: bool, assigned_subaccounts: list<string>, require_two_factor: string, must_two_factor: string, timezone: string, account: record<name: string, timezone: string, data_region: string, free_trial_expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/")
  let body = {first_name: $first_name, last_name: $last_name, email: $email, password: $password, access_level: $access_level, is_api_enabled: $is_api_enabled, notify_paid_invoices: $notify_paid_invoices, assigned_subaccounts: $assigned_subaccounts, require_two_factor: $require_two_factor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a single user
#
# GET /api/v1/users/{pk}/
# operationId: get_user_detail
export def "users detail-by-pk" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<pk: int, url: string, first_name: string, last_name: string, email: string, password: string, is_active: bool, is_primary: bool, access_level: string, is_api_enabled: bool, notify_paid_invoices: bool, assigned_subaccounts: list<string>, require_two_factor: string, must_two_factor: string, timezone: string, account: record<name: string, timezone: string, data_region: string, free_trial_expires_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /api/v1/users/{pk}/
# operationId: put_user_detail
# --account shape: {name: string, timezone?: "Pacific/Midway"|"Pacific/Niue"|"Pacific/Pago_Pago"|"America/Adak"|"Pacific/Honolulu"|"Pacific/Rarotonga"|"Pacific/Tahiti"|"US/Hawaii"|"Pacific/Marquesas"|"America/Anchorage"|"Pacific/Gambier"|"America/Juneau"|"America/Metlakatla"|"America/Nome"|"America/Sitka"|"US/Alaska"|"America/Yakutat"|"America/Dawson"|"America/Los_Angeles"|"Pacific/Pitcairn"|"America/Tijuana"|"US/Pacific"|"America/Vancouver"|"America/Whitehorse"|"America/Boise"|"America/Cambridge_Bay"|"America/Chihuahua"|"America/Ciudad_Juarez"|"America/Creston"|"America/Dawson_Creek"|"America/Denver"|"America/Edmonton"|"America/Fort_Nelson"|"America/Hermosillo"|"America/Inuvik"|"America/Mazatlan"|"America/Ojinaga"|"America/Phoenix"|"US/Arizona"|"US/Mountain"|"America/Bahia_Banderas"|"America/Belize"|"America/North_Dakota/Beulah"|"America/North_Dakota/Center"|"America/Chicago"|"America/Costa_Rica"|"Pacific/Easter"|"America/El_Salvador"|"Pacific/Galapagos"|"America/Guatemala"|"America/Indiana/Knox"|"America/Managua"|"America/Matamoros"|"America/Menominee"|"America/Merida"|"America/Mexico_City"|"America/Monterrey"|"America/North_Dakota/New_Salem"|"America/Rankin_Inlet"|"America/Regina"|"America/Resolute"|"America/Swift_Current"|"America/Tegucigalpa"|"America/Indiana/Tell_City"|"US/Central"|"America/Winnipeg"|"America/Atikokan"|"America/Bogota"|"America/Cancun"|"America/Cayman"|"America/Detroit"|"America/Eirunepe"|"America/Guayaquil"|"America/Havana"|"America/Indiana/Indianapolis"|"America/Iqaluit"|"America/Jamaica"|"America/Lima"|"America/Kentucky/Louisville"|"America/Indiana/Marengo"|"America/Kentucky/Monticello"|"America/Nassau"|"America/New_York"|"America/Panama"|"America/Indiana/Petersburg"|"America/Port-au-Prince"|"America/Rio_Branco"|"America/Toronto"|"US/Eastern"|"America/Indiana/Vevay"|"America/Indiana/Vincennes"|"America/Indiana/Winamac"|"America/Caracas"|"America/Anguilla"|"America/Antigua"|"America/Aruba"|"America/Asuncion"|"America/Barbados"|"Atlantic/Bermuda"|"America/Blanc-Sablon"|"America/Boa_Vista"|"America/Campo_Grande"|"America/Cuiaba"|"America/Curacao"|"America/Dominica"|"America/Glace_Bay"|"America/Goose_Bay"|"America/Grand_Turk"|"America/Grenada"|"America/Guadeloupe"|"America/Guyana"|"America/Halifax"|"America/Kralendijk"|"America/La_Paz"|"America/Lower_Princes"|"America/Manaus"|"America/Marigot"|"America/Martinique"|"America/Moncton"|"America/Montserrat"|"America/Port_of_Spain"|"America/Porto_Velho"|"America/Puerto_Rico"|"America/Punta_Arenas"|"America/Santiago"|"America/Santo_Domingo"|"America/St_Barthelemy"|"America/St_Kitts"|"America/St_Lucia"|"America/St_Thomas"|"America/St_Vincent"|"America/Thule"|"America/Tortola"|"America/St_Johns"|"America/Araguaina"|"America/Bahia"|"America/Belem"|"America/Argentina/Buenos_Aires"|"America/Argentina/Catamarca"|"America/Cayenne"|"America/Argentina/Cordoba"|"America/Fortaleza"|"America/Argentina/Jujuy"|"America/Argentina/La_Rioja"|"America/Maceio"|"America/Argentina/Mendoza"|"America/Miquelon"|"America/Montevideo"|"America/Nuuk"|"America/Paramaribo"|"America/Recife"|"America/Argentina/Rio_Gallegos"|"America/Argentina/Salta"|"America/Argentina/San_Juan"|"America/Argentina/San_Luis"|"America/Santarem"|"America/Sao_Paulo"|"Atlantic/Stanley"|"America/Argentina/Tucuman"|"America/Argentina/Ushuaia"|"America/Noronha"|"Atlantic/South_Georgia"|"Atlantic/Azores"|"Atlantic/Cape_Verde"|"America/Scoresbysund"|"Africa/Abidjan"|"Africa/Accra"|"Africa/Bamako"|"Africa/Banjul"|"Africa/Bissau"|"Atlantic/Canary"|"Africa/Casablanca"|"Africa/Conakry"|"Africa/Dakar"|"America/Danmarkshavn"|"Africa/El_Aaiun"|"Atlantic/Faroe"|"Africa/Freetown"|"GMT"|"Europe/Guernsey"|"Europe/Isle_of_Man"|"Europe/Jersey"|"Europe/Lisbon"|"Africa/Lome"|"Europe/London"|"Atlantic/Madeira"|"Africa/Monrovia"|"Africa/Nouakchott"|"Africa/Ouagadougou"|"Atlantic/Reykjavik"|"Africa/Sao_Tome"|"Atlantic/St_Helena"|"UTC"|"Africa/Algiers"|"Europe/Amsterdam"|"Europe/Andorra"|"Africa/Bangui"|"Europe/Belgrade"|"Europe/Berlin"|"Europe/Bratislava"|"Africa/Brazzaville"|"Europe/Brussels"|"Europe/Budapest"|"Europe/Busingen"|"Africa/Ceuta"|"Europe/Copenhagen"|"Africa/Douala"|"Europe/Dublin"|"Europe/Gibraltar"|"Africa/Kinshasa"|"Africa/Lagos"|"Africa/Libreville"|"Europe/Ljubljana"|"Africa/Luanda"|"Europe/Luxembourg"|"Europe/Madrid"|"Africa/Malabo"|"Europe/Malta"|"Europe/Monaco"|"Africa/Ndjamena"|"Africa/Niamey"|"Europe/Oslo"|"Europe/Paris"|"Europe/Podgorica"|"Africa/Porto-Novo"|"Europe/Prague"|"Europe/Rome"|"Europe/San_Marino"|"Europe/Sarajevo"|"Europe/Skopje"|"Europe/Stockholm"|"Europe/Tirane"|"Africa/Tunis"|"Europe/Vaduz"|"Europe/Vatican"|"Europe/Vienna"|"Europe/Warsaw"|"Europe/Zagreb"|"Europe/Zurich"|"Asia/Amman"|"Europe/Athens"|"Asia/Beirut"|"Africa/Blantyre"|"Europe/Bucharest"|"Africa/Bujumbura"|"Africa/Cairo"|"Europe/Chisinau"|"Asia/Damascus"|"Asia/Famagusta"|"Africa/Gaborone"|"Asia/Gaza"|"Africa/Harare"|"Asia/Hebron"|"Europe/Helsinki"|"Europe/Istanbul"|"Asia/Jerusalem"|"Africa/Johannesburg"|"Europe/Kaliningrad"|"Europe/Kiev"|"Africa/Kigali"|"Europe/Kyiv"|"Africa/Lubumbashi"|"Africa/Lusaka"|"Africa/Maputo"|"Europe/Mariehamn"|"Africa/Maseru"|"Africa/Mbabane"|"Asia/Nicosia"|"Europe/Riga"|"Europe/Sofia"|"Europe/Tallinn"|"Africa/Tripoli"|"Europe/Uzhgorod"|"Europe/Vilnius"|"Africa/Windhoek"|"Africa/Addis_Ababa"|"Asia/Aden"|"Indian/Antananarivo"|"Africa/Asmara"|"Europe/Astrakhan"|"Asia/Baghdad"|"Asia/Bahrain"|"Indian/Comoro"|"Africa/Dar_es_Salaam"|"Africa/Djibouti"|"Africa/Juba"|"Africa/Kampala"|"Africa/Khartoum"|"Europe/Kirov"|"Asia/Kuwait"|"Indian/Mayotte"|"Europe/Minsk"|"Africa/Mogadishu"|"Europe/Moscow"|"Africa/Nairobi"|"Asia/Qatar"|"Asia/Riyadh"|"Europe/Saratov"|"Europe/Simferopol"|"Europe/Ulyanovsk"|"Europe/Volgograd"|"Asia/Tehran"|"Asia/Baku"|"Asia/Dubai"|"Indian/Mahe"|"Indian/Mauritius"|"Asia/Muscat"|"Indian/Reunion"|"Europe/Samara"|"Asia/Tbilisi"|"Asia/Yerevan"|"Asia/Kabul"|"Asia/Aqtau"|"Asia/Aqtobe"|"Asia/Ashgabat"|"Asia/Atyrau"|"Asia/Dushanbe"|"Asia/Karachi"|"Indian/Kerguelen"|"Indian/Maldives"|"Asia/Oral"|"Asia/Samarkand"|"Asia/Tashkent"|"Asia/Yekaterinburg"|"Asia/Colombo"|"Asia/Kolkata"|"Asia/Kathmandu"|"Asia/Almaty"|"Asia/Barnaul"|"Asia/Bishkek"|"Indian/Chagos"|"Asia/Dhaka"|"Asia/Novosibirsk"|"Asia/Omsk"|"Asia/Qostanay"|"Asia/Qyzylorda"|"Asia/Thimphu"|"Asia/Tomsk"|"Asia/Urumqi"|"Indian/Cocos"|"Asia/Yangon"|"Asia/Bangkok"|"Indian/Christmas"|"Asia/Ho_Chi_Minh"|"Asia/Hovd"|"Asia/Jakarta"|"Asia/Krasnoyarsk"|"Asia/Novokuznetsk"|"Asia/Phnom_Penh"|"Asia/Pontianak"|"Asia/Vientiane"|"Asia/Brunei"|"Asia/Chita"|"Asia/Choibalsan"|"Asia/Hong_Kong"|"Asia/Irkutsk"|"Asia/Kuala_Lumpur"|"Asia/Kuching"|"Asia/Macau"|"Asia/Makassar"|"Asia/Manila"|"Australia/Perth"|"Asia/Shanghai"|"Asia/Singapore"|"Asia/Taipei"|"Asia/Ulaanbaatar"|"Asia/Pyongyang"|"Australia/Eucla"|"Asia/Dili"|"Asia/Jayapura"|"Asia/Khandyga"|"Pacific/Palau"|"Asia/Seoul"|"Asia/Tokyo"|"Asia/Yakutsk"|"Australia/Adelaide"|"Australia/Broken_Hill"|"Australia/Darwin"|"Australia/Brisbane"|"Pacific/Chuuk"|"Pacific/Guam"|"Australia/Hobart"|"Australia/Lindeman"|"Asia/Magadan"|"Australia/Melbourne"|"Pacific/Port_Moresby"|"Pacific/Saipan"|"Asia/Sakhalin"|"Australia/Sydney"|"Asia/Ust-Nera"|"Asia/Vladivostok"|"Australia/Lord_Howe"|"Pacific/Bougainville"|"Pacific/Efate"|"Pacific/Guadalcanal"|"Pacific/Kosrae"|"Pacific/Norfolk"|"Pacific/Noumea"|"Pacific/Pohnpei"|"Asia/Srednekolymsk"|"Asia/Anadyr"|"Pacific/Auckland"|"Pacific/Fiji"|"Pacific/Funafuti"|"Asia/Kamchatka"|"Pacific/Kwajalein"|"Pacific/Majuro"|"Pacific/Nauru"|"Pacific/Tarawa"|"Pacific/Wake"|"Pacific/Wallis"|"Pacific/Chatham"|"Pacific/Apia"|"Pacific/Fakaofo"|"Pacific/Kanton"|"Pacific/Tongatapu"|"Pacific/Kiritimati", data_region?: "US"|"EU", free_trial_expires_at?: string}
export def "users detail-by-pk-1" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  first_name: string # The user's first name
  last_name: string # The user's first name
  email: string # The user's email address, used as their username (format: email)
  --password: string # The user's password
  --access-level: string@access-level-completer # The permission level for this user
  --is-api-enabled: oneof<nothing, bool> # Whether this user may access the API
  --notify-paid-invoices: oneof<nothing, bool> # Whether this user should receive new invoices
  --assigned-subaccounts: list # Which subaccounts this user may access, or empty for All Subaccounts.
  --require-two-factor: string@require-two-factor-completer
]: any -> record<pk: int, url: string, first_name: string, last_name: string, email: string, password: string, is_active: bool, is_primary: bool, access_level: string, is_api_enabled: bool, notify_paid_invoices: bool, assigned_subaccounts: list<string>, require_two_factor: string, must_two_factor: string, timezone: string, account: record<name: string, timezone: string, data_region: string, free_trial_expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($pk)/")
  let body = {first_name: $first_name, last_name: $last_name, email: $email, password: $password, access_level: $access_level, is_api_enabled: $is_api_enabled, notify_paid_invoices: $notify_paid_invoices, assigned_subaccounts: $assigned_subaccounts, require_two_factor: $require_two_factor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Partially update a user
#
# PATCH /api/v1/users/{pk}/
# operationId: patch_user_detail
# --account shape: {name: string, timezone?: "Pacific/Midway"|"Pacific/Niue"|"Pacific/Pago_Pago"|"America/Adak"|"Pacific/Honolulu"|"Pacific/Rarotonga"|"Pacific/Tahiti"|"US/Hawaii"|"Pacific/Marquesas"|"America/Anchorage"|"Pacific/Gambier"|"America/Juneau"|"America/Metlakatla"|"America/Nome"|"America/Sitka"|"US/Alaska"|"America/Yakutat"|"America/Dawson"|"America/Los_Angeles"|"Pacific/Pitcairn"|"America/Tijuana"|"US/Pacific"|"America/Vancouver"|"America/Whitehorse"|"America/Boise"|"America/Cambridge_Bay"|"America/Chihuahua"|"America/Ciudad_Juarez"|"America/Creston"|"America/Dawson_Creek"|"America/Denver"|"America/Edmonton"|"America/Fort_Nelson"|"America/Hermosillo"|"America/Inuvik"|"America/Mazatlan"|"America/Ojinaga"|"America/Phoenix"|"US/Arizona"|"US/Mountain"|"America/Bahia_Banderas"|"America/Belize"|"America/North_Dakota/Beulah"|"America/North_Dakota/Center"|"America/Chicago"|"America/Costa_Rica"|"Pacific/Easter"|"America/El_Salvador"|"Pacific/Galapagos"|"America/Guatemala"|"America/Indiana/Knox"|"America/Managua"|"America/Matamoros"|"America/Menominee"|"America/Merida"|"America/Mexico_City"|"America/Monterrey"|"America/North_Dakota/New_Salem"|"America/Rankin_Inlet"|"America/Regina"|"America/Resolute"|"America/Swift_Current"|"America/Tegucigalpa"|"America/Indiana/Tell_City"|"US/Central"|"America/Winnipeg"|"America/Atikokan"|"America/Bogota"|"America/Cancun"|"America/Cayman"|"America/Detroit"|"America/Eirunepe"|"America/Guayaquil"|"America/Havana"|"America/Indiana/Indianapolis"|"America/Iqaluit"|"America/Jamaica"|"America/Lima"|"America/Kentucky/Louisville"|"America/Indiana/Marengo"|"America/Kentucky/Monticello"|"America/Nassau"|"America/New_York"|"America/Panama"|"America/Indiana/Petersburg"|"America/Port-au-Prince"|"America/Rio_Branco"|"America/Toronto"|"US/Eastern"|"America/Indiana/Vevay"|"America/Indiana/Vincennes"|"America/Indiana/Winamac"|"America/Caracas"|"America/Anguilla"|"America/Antigua"|"America/Aruba"|"America/Asuncion"|"America/Barbados"|"Atlantic/Bermuda"|"America/Blanc-Sablon"|"America/Boa_Vista"|"America/Campo_Grande"|"America/Cuiaba"|"America/Curacao"|"America/Dominica"|"America/Glace_Bay"|"America/Goose_Bay"|"America/Grand_Turk"|"America/Grenada"|"America/Guadeloupe"|"America/Guyana"|"America/Halifax"|"America/Kralendijk"|"America/La_Paz"|"America/Lower_Princes"|"America/Manaus"|"America/Marigot"|"America/Martinique"|"America/Moncton"|"America/Montserrat"|"America/Port_of_Spain"|"America/Porto_Velho"|"America/Puerto_Rico"|"America/Punta_Arenas"|"America/Santiago"|"America/Santo_Domingo"|"America/St_Barthelemy"|"America/St_Kitts"|"America/St_Lucia"|"America/St_Thomas"|"America/St_Vincent"|"America/Thule"|"America/Tortola"|"America/St_Johns"|"America/Araguaina"|"America/Bahia"|"America/Belem"|"America/Argentina/Buenos_Aires"|"America/Argentina/Catamarca"|"America/Cayenne"|"America/Argentina/Cordoba"|"America/Fortaleza"|"America/Argentina/Jujuy"|"America/Argentina/La_Rioja"|"America/Maceio"|"America/Argentina/Mendoza"|"America/Miquelon"|"America/Montevideo"|"America/Nuuk"|"America/Paramaribo"|"America/Recife"|"America/Argentina/Rio_Gallegos"|"America/Argentina/Salta"|"America/Argentina/San_Juan"|"America/Argentina/San_Luis"|"America/Santarem"|"America/Sao_Paulo"|"Atlantic/Stanley"|"America/Argentina/Tucuman"|"America/Argentina/Ushuaia"|"America/Noronha"|"Atlantic/South_Georgia"|"Atlantic/Azores"|"Atlantic/Cape_Verde"|"America/Scoresbysund"|"Africa/Abidjan"|"Africa/Accra"|"Africa/Bamako"|"Africa/Banjul"|"Africa/Bissau"|"Atlantic/Canary"|"Africa/Casablanca"|"Africa/Conakry"|"Africa/Dakar"|"America/Danmarkshavn"|"Africa/El_Aaiun"|"Atlantic/Faroe"|"Africa/Freetown"|"GMT"|"Europe/Guernsey"|"Europe/Isle_of_Man"|"Europe/Jersey"|"Europe/Lisbon"|"Africa/Lome"|"Europe/London"|"Atlantic/Madeira"|"Africa/Monrovia"|"Africa/Nouakchott"|"Africa/Ouagadougou"|"Atlantic/Reykjavik"|"Africa/Sao_Tome"|"Atlantic/St_Helena"|"UTC"|"Africa/Algiers"|"Europe/Amsterdam"|"Europe/Andorra"|"Africa/Bangui"|"Europe/Belgrade"|"Europe/Berlin"|"Europe/Bratislava"|"Africa/Brazzaville"|"Europe/Brussels"|"Europe/Budapest"|"Europe/Busingen"|"Africa/Ceuta"|"Europe/Copenhagen"|"Africa/Douala"|"Europe/Dublin"|"Europe/Gibraltar"|"Africa/Kinshasa"|"Africa/Lagos"|"Africa/Libreville"|"Europe/Ljubljana"|"Africa/Luanda"|"Europe/Luxembourg"|"Europe/Madrid"|"Africa/Malabo"|"Europe/Malta"|"Europe/Monaco"|"Africa/Ndjamena"|"Africa/Niamey"|"Europe/Oslo"|"Europe/Paris"|"Europe/Podgorica"|"Africa/Porto-Novo"|"Europe/Prague"|"Europe/Rome"|"Europe/San_Marino"|"Europe/Sarajevo"|"Europe/Skopje"|"Europe/Stockholm"|"Europe/Tirane"|"Africa/Tunis"|"Europe/Vaduz"|"Europe/Vatican"|"Europe/Vienna"|"Europe/Warsaw"|"Europe/Zagreb"|"Europe/Zurich"|"Asia/Amman"|"Europe/Athens"|"Asia/Beirut"|"Africa/Blantyre"|"Europe/Bucharest"|"Africa/Bujumbura"|"Africa/Cairo"|"Europe/Chisinau"|"Asia/Damascus"|"Asia/Famagusta"|"Africa/Gaborone"|"Asia/Gaza"|"Africa/Harare"|"Asia/Hebron"|"Europe/Helsinki"|"Europe/Istanbul"|"Asia/Jerusalem"|"Africa/Johannesburg"|"Europe/Kaliningrad"|"Europe/Kiev"|"Africa/Kigali"|"Europe/Kyiv"|"Africa/Lubumbashi"|"Africa/Lusaka"|"Africa/Maputo"|"Europe/Mariehamn"|"Africa/Maseru"|"Africa/Mbabane"|"Asia/Nicosia"|"Europe/Riga"|"Europe/Sofia"|"Europe/Tallinn"|"Africa/Tripoli"|"Europe/Uzhgorod"|"Europe/Vilnius"|"Africa/Windhoek"|"Africa/Addis_Ababa"|"Asia/Aden"|"Indian/Antananarivo"|"Africa/Asmara"|"Europe/Astrakhan"|"Asia/Baghdad"|"Asia/Bahrain"|"Indian/Comoro"|"Africa/Dar_es_Salaam"|"Africa/Djibouti"|"Africa/Juba"|"Africa/Kampala"|"Africa/Khartoum"|"Europe/Kirov"|"Asia/Kuwait"|"Indian/Mayotte"|"Europe/Minsk"|"Africa/Mogadishu"|"Europe/Moscow"|"Africa/Nairobi"|"Asia/Qatar"|"Asia/Riyadh"|"Europe/Saratov"|"Europe/Simferopol"|"Europe/Ulyanovsk"|"Europe/Volgograd"|"Asia/Tehran"|"Asia/Baku"|"Asia/Dubai"|"Indian/Mahe"|"Indian/Mauritius"|"Asia/Muscat"|"Indian/Reunion"|"Europe/Samara"|"Asia/Tbilisi"|"Asia/Yerevan"|"Asia/Kabul"|"Asia/Aqtau"|"Asia/Aqtobe"|"Asia/Ashgabat"|"Asia/Atyrau"|"Asia/Dushanbe"|"Asia/Karachi"|"Indian/Kerguelen"|"Indian/Maldives"|"Asia/Oral"|"Asia/Samarkand"|"Asia/Tashkent"|"Asia/Yekaterinburg"|"Asia/Colombo"|"Asia/Kolkata"|"Asia/Kathmandu"|"Asia/Almaty"|"Asia/Barnaul"|"Asia/Bishkek"|"Indian/Chagos"|"Asia/Dhaka"|"Asia/Novosibirsk"|"Asia/Omsk"|"Asia/Qostanay"|"Asia/Qyzylorda"|"Asia/Thimphu"|"Asia/Tomsk"|"Asia/Urumqi"|"Indian/Cocos"|"Asia/Yangon"|"Asia/Bangkok"|"Indian/Christmas"|"Asia/Ho_Chi_Minh"|"Asia/Hovd"|"Asia/Jakarta"|"Asia/Krasnoyarsk"|"Asia/Novokuznetsk"|"Asia/Phnom_Penh"|"Asia/Pontianak"|"Asia/Vientiane"|"Asia/Brunei"|"Asia/Chita"|"Asia/Choibalsan"|"Asia/Hong_Kong"|"Asia/Irkutsk"|"Asia/Kuala_Lumpur"|"Asia/Kuching"|"Asia/Macau"|"Asia/Makassar"|"Asia/Manila"|"Australia/Perth"|"Asia/Shanghai"|"Asia/Singapore"|"Asia/Taipei"|"Asia/Ulaanbaatar"|"Asia/Pyongyang"|"Australia/Eucla"|"Asia/Dili"|"Asia/Jayapura"|"Asia/Khandyga"|"Pacific/Palau"|"Asia/Seoul"|"Asia/Tokyo"|"Asia/Yakutsk"|"Australia/Adelaide"|"Australia/Broken_Hill"|"Australia/Darwin"|"Australia/Brisbane"|"Pacific/Chuuk"|"Pacific/Guam"|"Australia/Hobart"|"Australia/Lindeman"|"Asia/Magadan"|"Australia/Melbourne"|"Pacific/Port_Moresby"|"Pacific/Saipan"|"Asia/Sakhalin"|"Australia/Sydney"|"Asia/Ust-Nera"|"Asia/Vladivostok"|"Australia/Lord_Howe"|"Pacific/Bougainville"|"Pacific/Efate"|"Pacific/Guadalcanal"|"Pacific/Kosrae"|"Pacific/Norfolk"|"Pacific/Noumea"|"Pacific/Pohnpei"|"Asia/Srednekolymsk"|"Asia/Anadyr"|"Pacific/Auckland"|"Pacific/Fiji"|"Pacific/Funafuti"|"Asia/Kamchatka"|"Pacific/Kwajalein"|"Pacific/Majuro"|"Pacific/Nauru"|"Pacific/Tarawa"|"Pacific/Wake"|"Pacific/Wallis"|"Pacific/Chatham"|"Pacific/Apia"|"Pacific/Fakaofo"|"Pacific/Kanton"|"Pacific/Tongatapu"|"Pacific/Kiritimati", data_region?: "US"|"EU", free_trial_expires_at?: string}
export def "users detail-by-pk-2" [
  pk: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  first_name: string # The user's first name
  last_name: string # The user's first name
  email: string # The user's email address, used as their username (format: email)
  --password: string # The user's password
  --access-level: string@access-level-completer # The permission level for this user
  --is-api-enabled: oneof<nothing, bool> # Whether this user may access the API
  --notify-paid-invoices: oneof<nothing, bool> # Whether this user should receive new invoices
  --assigned-subaccounts: list # Which subaccounts this user may access, or empty for All Subaccounts.
  --require-two-factor: string@require-two-factor-completer
]: any -> record<pk: int, url: string, first_name: string, last_name: string, email: string, password: string, is_active: bool, is_primary: bool, access_level: string, is_api_enabled: bool, notify_paid_invoices: bool, assigned_subaccounts: list<string>, require_two_factor: string, must_two_factor: string, timezone: string, account: record<name: string, timezone: string, data_region: string, free_trial_expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/users/($pk)/")
  let body = {first_name: $first_name, last_name: $last_name, email: $email, password: $password, access_level: $access_level, is_api_enabled: $is_api_enabled, notify_paid_invoices: $notify_paid_invoices, assigned_subaccounts: $assigned_subaccounts, require_two_factor: $require_two_factor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Permanently delete a user
#
# DELETE /api/v1/users/{pk}/
# operationId: delete_user_detail
export def "users detail-by-pk-3" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/users/($pk)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactivate a user
#
# POST /api/v1/users/{pk}/deactivate/
# operationId: post_user_deactivate
export def "users-deactivate deactivate" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/users/($pk)/deactivate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reactivate a user
#
# POST /api/v1/users/{pk}/reactivate/
# operationId: post_user_reactivate
export def "users-reactivate reactivate" [
  pk: string
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
  let full_url = (build-url $base $"/api/v1/users/($pk)/reactivate/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
