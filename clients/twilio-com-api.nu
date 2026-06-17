# Auto-generated client for Twilio - Api v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/api/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_API_TOKEN

const BASE_URL = "https://api.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def status-completer [] { ["active" "closed" "suspended"] }
def sms-fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def sms-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def voice-fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def voice-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-completer-1 [] { ["busy" "canceled" "completed" "failed" "in-progress" "no-answer" "queued" "ringing"] }
def async-amd-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def fallback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def recording-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def bank-account-type-completer [] { ["commercial-checking" "consumer-checking" "consumer-savings"] }
def payment-method-completer [] { ["ach-debit" "credit-card"] }
def token-type-completer [] { ["one-time" "reusable"] }
def capture-completer [] { ["bank-account-number" "bank-routing-number" "expiration-date" "payment-card-number" "postal-code" "security-code"] }
def status-completer-2 [] { ["cancel" "complete"] }
def status-completer-3 [] { ["absent" "completed" "in-progress" "paused" "processing" "stopped"] }
def track-completer [] { ["both_tracks" "inbound_track" "outbound_track"] }
def status-completer-4 [] { ["stopped"] }
def status-completer-5 [] { ["canceled" "completed"] }
def status-completer-6 [] { ["completed" "in-progress" "init"] }
def amd-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def conference-recording-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def conference-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def wait-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def announce-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def hold-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-completer-7 [] { ["completed"] }
def deauthorize-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def emergency-status-completer [] { ["Active" "Inactive"] }
def voice-receive-mode-completer [] { ["fax" "voice"] }
def address-retention-completer [] { ["retain"] }
def content-retention-completer [] { ["retain"] }
def schedule-type-completer [] { ["fixed"] }
def outcome-completer [] { ["confirmed" "unconfirmed"] }
def status-completer-8 [] { ["canceled"] }
def voice-status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def category-completer [] { ["a2p-registration-fees" "agent-conference" "amazon-polly" "answering-machine-detection" "authy-authentications" "authy-calls-outbound" "authy-monthly-fees" "authy-phone-intelligence" "authy-phone-verifications" "authy-sms-outbound" "call-progess-events" "calleridlookups" "calls" "calls-client" "calls-globalconference" "calls-inbound" "calls-inbound-local" "calls-inbound-mobile" "calls-inbound-tollfree" "calls-outbound" "calls-pay-verb-transactions" "calls-recordings" "calls-sip" "calls-sip-inbound" "calls-sip-outbound" "calls-transfers" "carrier-lookups" "conversations" "conversations-api-requests" "conversations-conversation-events" "conversations-endpoint-connectivity" "conversations-events" "conversations-participant-events" "conversations-participants" "cps" "flex-usage" "fraud-lookups" "group-rooms" "group-rooms-data-track" "group-rooms-encrypted-media-recorded" "group-rooms-media-downloaded" "group-rooms-media-recorded" "group-rooms-media-routed" "group-rooms-media-stored" "group-rooms-participant-minutes" "group-rooms-recorded-minutes" "imp-v1-usage" "lookups" "marketplace" "marketplace-algorithmia-named-entity-recognition" "marketplace-cadence-transcription" "marketplace-cadence-translation" "marketplace-capio-speech-to-text" "marketplace-convriza-ababa" "marketplace-deepgram-phrase-detector" "marketplace-digital-segment-business-info" "marketplace-facebook-offline-conversions" "marketplace-google-speech-to-text" "marketplace-ibm-watson-message-insights" "marketplace-ibm-watson-message-sentiment" "marketplace-ibm-watson-recording-analysis" "marketplace-ibm-watson-tone-analyzer" "marketplace-icehook-systems-scout" "marketplace-infogroup-dataaxle-bizinfo" "marketplace-keen-io-contact-center-analytics" "marketplace-marchex-cleancall" "marketplace-marchex-sentiment-analysis-for-sms" "marketplace-marketplace-nextcaller-social-id" "marketplace-mobile-commons-opt-out-classifier" "marketplace-nexiwave-voicemail-to-text" "marketplace-nextcaller-advanced-caller-identification" "marketplace-nomorobo-spam-score" "marketplace-payfone-tcpa-compliance" "marketplace-remeeting-automatic-speech-recognition" "marketplace-tcpa-defense-solutions-blacklist-feed" "marketplace-telo-opencnam" "marketplace-truecnam-true-spam" "marketplace-twilio-caller-name-lookup-us" "marketplace-twilio-carrier-information-lookup" "marketplace-voicebase-pci" "marketplace-voicebase-transcription" "marketplace-voicebase-transcription-custom-vocabulary" "marketplace-whitepages-pro-caller-identification" "marketplace-whitepages-pro-phone-intelligence" "marketplace-whitepages-pro-phone-reputation" "marketplace-wolfarm-spoken-results" "marketplace-wolfram-short-answer" "marketplace-ytica-contact-center-reporting-analytics" "mediastorage" "mms" "mms-inbound" "mms-inbound-longcode" "mms-inbound-shortcode" "mms-messages-carrierfees" "mms-outbound" "mms-outbound-longcode" "mms-outbound-shortcode" "monitor-reads" "monitor-storage" "monitor-writes" "notify" "notify-actions-attempts" "notify-channels" "number-format-lookups" "pchat" "pchat-users" "peer-to-peer-rooms-participant-minutes" "pfax" "pfax-minutes" "pfax-minutes-inbound" "pfax-minutes-outbound" "pfax-pages" "phonenumbers" "phonenumbers-cps" "phonenumbers-emergency" "phonenumbers-local" "phonenumbers-mobile" "phonenumbers-setups" "phonenumbers-tollfree" "premiumsupport" "proxy" "proxy-active-sessions" "pstnconnectivity" "pv" "pv-composition-media-downloaded" "pv-composition-media-encrypted" "pv-composition-media-stored" "pv-composition-minutes" "pv-recording-compositions" "pv-room-participants" "pv-room-participants-au1" "pv-room-participants-br1" "pv-room-participants-ie1" "pv-room-participants-jp1" "pv-room-participants-sg1" "pv-room-participants-us1" "pv-room-participants-us2" "pv-rooms" "pv-sip-endpoint-registrations" "recordings" "recordingstorage" "rooms-group-bandwidth" "rooms-group-minutes" "rooms-peer-to-peer-minutes" "shortcodes" "shortcodes-customerowned" "shortcodes-mms-enablement" "shortcodes-mps" "shortcodes-random" "shortcodes-uk" "shortcodes-vanity" "small-group-rooms" "small-group-rooms-data-track" "small-group-rooms-participant-minutes" "sms" "sms-inbound" "sms-inbound-longcode" "sms-inbound-shortcode" "sms-messages-carrierfees" "sms-messages-features" "sms-messages-features-senderid" "sms-outbound" "sms-outbound-content-inspection" "sms-outbound-longcode" "sms-outbound-shortcode" "speech-recognition" "studio-engagements" "sync" "sync-actions" "sync-endpoint-hours" "sync-endpoint-hours-above-daily-cap" "taskrouter-tasks" "totalprice" "transcriptions" "trunking-cps" "trunking-emergency-calls" "trunking-origination" "trunking-origination-local" "trunking-origination-mobile" "trunking-origination-tollfree" "trunking-recordings" "trunking-secure" "trunking-termination" "turnmegabytes" "turnmegabytes-australia" "turnmegabytes-brasil" "turnmegabytes-germany" "turnmegabytes-india" "turnmegabytes-ireland" "turnmegabytes-japan" "turnmegabytes-singapore" "turnmegabytes-useast" "turnmegabytes-uswest" "twilio-interconnect" "verify-push" "verify-totp" "verify-whatsapp-conversations-business-initiated" "video-recordings" "virtual-agent" "voice-insights" "voice-insights-client-insights-on-demand-minute" "voice-insights-ptsn-insights-on-demand-minute" "voice-insights-sip-interface-insights-on-demand-minute" "voice-insights-sip-trunking-insights-on-demand-minute" "wireless" "wireless-orders" "wireless-orders-artwork" "wireless-orders-bulk" "wireless-orders-esim" "wireless-orders-starter" "wireless-usage" "wireless-usage-commands" "wireless-usage-commands-africa" "wireless-usage-commands-asia" "wireless-usage-commands-centralandsouthamerica" "wireless-usage-commands-europe" "wireless-usage-commands-home" "wireless-usage-commands-northamerica" "wireless-usage-commands-oceania" "wireless-usage-commands-roaming" "wireless-usage-data" "wireless-usage-data-africa" "wireless-usage-data-asia" "wireless-usage-data-centralandsouthamerica" "wireless-usage-data-custom-additionalmb" "wireless-usage-data-custom-first5mb" "wireless-usage-data-domestic-roaming" "wireless-usage-data-europe" "wireless-usage-data-individual-additionalgb" "wireless-usage-data-individual-firstgb" "wireless-usage-data-international-roaming-canada" "wireless-usage-data-international-roaming-india" "wireless-usage-data-international-roaming-mexico" "wireless-usage-data-northamerica" "wireless-usage-data-oceania" "wireless-usage-data-pooled" "wireless-usage-data-pooled-downlink" "wireless-usage-data-pooled-uplink" "wireless-usage-mrc" "wireless-usage-mrc-custom" "wireless-usage-mrc-individual" "wireless-usage-mrc-pooled" "wireless-usage-mrc-suspended" "wireless-usage-sms" "wireless-usage-voice"] }
def recurring-completer [] { ["alltime" "daily" "monthly" "yearly"] }
def trigger-by-completer [] { ["count" "price" "usage"] }
def usage-category-completer [] { ["a2p-registration-fees" "agent-conference" "amazon-polly" "answering-machine-detection" "authy-authentications" "authy-calls-outbound" "authy-monthly-fees" "authy-phone-intelligence" "authy-phone-verifications" "authy-sms-outbound" "call-progess-events" "calleridlookups" "calls" "calls-client" "calls-globalconference" "calls-inbound" "calls-inbound-local" "calls-inbound-mobile" "calls-inbound-tollfree" "calls-outbound" "calls-pay-verb-transactions" "calls-recordings" "calls-sip" "calls-sip-inbound" "calls-sip-outbound" "calls-transfers" "carrier-lookups" "conversations" "conversations-api-requests" "conversations-conversation-events" "conversations-endpoint-connectivity" "conversations-events" "conversations-participant-events" "conversations-participants" "cps" "flex-usage" "fraud-lookups" "group-rooms" "group-rooms-data-track" "group-rooms-encrypted-media-recorded" "group-rooms-media-downloaded" "group-rooms-media-recorded" "group-rooms-media-routed" "group-rooms-media-stored" "group-rooms-participant-minutes" "group-rooms-recorded-minutes" "imp-v1-usage" "lookups" "marketplace" "marketplace-algorithmia-named-entity-recognition" "marketplace-cadence-transcription" "marketplace-cadence-translation" "marketplace-capio-speech-to-text" "marketplace-convriza-ababa" "marketplace-deepgram-phrase-detector" "marketplace-digital-segment-business-info" "marketplace-facebook-offline-conversions" "marketplace-google-speech-to-text" "marketplace-ibm-watson-message-insights" "marketplace-ibm-watson-message-sentiment" "marketplace-ibm-watson-recording-analysis" "marketplace-ibm-watson-tone-analyzer" "marketplace-icehook-systems-scout" "marketplace-infogroup-dataaxle-bizinfo" "marketplace-keen-io-contact-center-analytics" "marketplace-marchex-cleancall" "marketplace-marchex-sentiment-analysis-for-sms" "marketplace-marketplace-nextcaller-social-id" "marketplace-mobile-commons-opt-out-classifier" "marketplace-nexiwave-voicemail-to-text" "marketplace-nextcaller-advanced-caller-identification" "marketplace-nomorobo-spam-score" "marketplace-payfone-tcpa-compliance" "marketplace-remeeting-automatic-speech-recognition" "marketplace-tcpa-defense-solutions-blacklist-feed" "marketplace-telo-opencnam" "marketplace-truecnam-true-spam" "marketplace-twilio-caller-name-lookup-us" "marketplace-twilio-carrier-information-lookup" "marketplace-voicebase-pci" "marketplace-voicebase-transcription" "marketplace-voicebase-transcription-custom-vocabulary" "marketplace-whitepages-pro-caller-identification" "marketplace-whitepages-pro-phone-intelligence" "marketplace-whitepages-pro-phone-reputation" "marketplace-wolfarm-spoken-results" "marketplace-wolfram-short-answer" "marketplace-ytica-contact-center-reporting-analytics" "mediastorage" "mms" "mms-inbound" "mms-inbound-longcode" "mms-inbound-shortcode" "mms-messages-carrierfees" "mms-outbound" "mms-outbound-longcode" "mms-outbound-shortcode" "monitor-reads" "monitor-storage" "monitor-writes" "notify" "notify-actions-attempts" "notify-channels" "number-format-lookups" "pchat" "pchat-users" "peer-to-peer-rooms-participant-minutes" "pfax" "pfax-minutes" "pfax-minutes-inbound" "pfax-minutes-outbound" "pfax-pages" "phonenumbers" "phonenumbers-cps" "phonenumbers-emergency" "phonenumbers-local" "phonenumbers-mobile" "phonenumbers-setups" "phonenumbers-tollfree" "premiumsupport" "proxy" "proxy-active-sessions" "pstnconnectivity" "pv" "pv-composition-media-downloaded" "pv-composition-media-encrypted" "pv-composition-media-stored" "pv-composition-minutes" "pv-recording-compositions" "pv-room-participants" "pv-room-participants-au1" "pv-room-participants-br1" "pv-room-participants-ie1" "pv-room-participants-jp1" "pv-room-participants-sg1" "pv-room-participants-us1" "pv-room-participants-us2" "pv-rooms" "pv-sip-endpoint-registrations" "recordings" "recordingstorage" "rooms-group-bandwidth" "rooms-group-minutes" "rooms-peer-to-peer-minutes" "shortcodes" "shortcodes-customerowned" "shortcodes-mms-enablement" "shortcodes-mps" "shortcodes-random" "shortcodes-uk" "shortcodes-vanity" "small-group-rooms" "small-group-rooms-data-track" "small-group-rooms-participant-minutes" "sms" "sms-inbound" "sms-inbound-longcode" "sms-inbound-shortcode" "sms-messages-carrierfees" "sms-messages-features" "sms-messages-features-senderid" "sms-outbound" "sms-outbound-content-inspection" "sms-outbound-longcode" "sms-outbound-shortcode" "speech-recognition" "studio-engagements" "sync" "sync-actions" "sync-endpoint-hours" "sync-endpoint-hours-above-daily-cap" "taskrouter-tasks" "totalprice" "transcriptions" "trunking-cps" "trunking-emergency-calls" "trunking-origination" "trunking-origination-local" "trunking-origination-mobile" "trunking-origination-tollfree" "trunking-recordings" "trunking-secure" "trunking-termination" "turnmegabytes" "turnmegabytes-australia" "turnmegabytes-brasil" "turnmegabytes-germany" "turnmegabytes-india" "turnmegabytes-ireland" "turnmegabytes-japan" "turnmegabytes-singapore" "turnmegabytes-useast" "turnmegabytes-uswest" "twilio-interconnect" "verify-push" "verify-totp" "verify-whatsapp-conversations-business-initiated" "video-recordings" "virtual-agent" "voice-insights" "voice-insights-client-insights-on-demand-minute" "voice-insights-ptsn-insights-on-demand-minute" "voice-insights-sip-interface-insights-on-demand-minute" "voice-insights-sip-trunking-insights-on-demand-minute" "wireless" "wireless-orders" "wireless-orders-artwork" "wireless-orders-bulk" "wireless-orders-esim" "wireless-orders-starter" "wireless-usage" "wireless-usage-commands" "wireless-usage-commands-africa" "wireless-usage-commands-asia" "wireless-usage-commands-centralandsouthamerica" "wireless-usage-commands-europe" "wireless-usage-commands-home" "wireless-usage-commands-northamerica" "wireless-usage-commands-oceania" "wireless-usage-commands-roaming" "wireless-usage-data" "wireless-usage-data-africa" "wireless-usage-data-asia" "wireless-usage-data-centralandsouthamerica" "wireless-usage-data-custom-additionalmb" "wireless-usage-data-custom-first5mb" "wireless-usage-data-domestic-roaming" "wireless-usage-data-europe" "wireless-usage-data-individual-additionalgb" "wireless-usage-data-individual-firstgb" "wireless-usage-data-international-roaming-canada" "wireless-usage-data-international-roaming-india" "wireless-usage-data-international-roaming-mexico" "wireless-usage-data-northamerica" "wireless-usage-data-oceania" "wireless-usage-data-pooled" "wireless-usage-data-pooled-downlink" "wireless-usage-data-pooled-uplink" "wireless-usage-mrc" "wireless-usage-mrc-custom" "wireless-usage-mrc-individual" "wireless-usage-mrc-pooled" "wireless-usage-mrc-suspended" "wireless-usage-sms" "wireless-usage-voice"] }
def callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2010-04-01-accountsjson list-account" } } | get name | first)
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

# Retrieves a collection of Accounts belonging to the account used to make the request
#
# GET /2010-04-01/Accounts.json
# operationId: ListAccount
export def "2010-04-01-accountsjson list-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # Only return the Account resources with friendly names that exactly match this name.
  --status: string@status-completer # Only return Account resources with the given status. Can be `closed`, `suspended` or `active`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<accounts: table<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/2010-04-01/Accounts.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Twilio Subaccount from the account making the request
#
# POST /2010-04-01/Accounts.json
# operationId: CreateAccount
export def "2010-04-01-accountsjson create-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A human readable description of the account to create, defaults to `SubAccount Created at {YYYY-MM-DD HH:MM meridian}`
]: any -> record<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base "/2010-04-01/Accounts.json")
  let body = {"FriendlyName": $friendly_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/Addresses.json
#
# operationId: ListAddress
export def "2010-04-01-accounts-addressesjson list-address" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-name: string # The `customer_name` of the Address resources to read.
  --friendly-name: string # The string that identifies the Address resources to read.
  --iso-country: string # The ISO country code of the Address resources to read. (format: iso-country-code)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<addresses: table<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, emergency_enabled: bool, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, street_secondary: string, uri: string, validated: bool, verified: bool>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "CustomerName" $customer_name "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "IsoCountry" $iso_country "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Addresses.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/Addresses.json
#
# operationId: CreateAddress
export def "2010-04-01-accounts-addressesjson create-address" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-correct-address: oneof<nothing, bool> # Whether we should automatically correct the address. Can be: `true` or `false` and the default is `true`. If empty or `true`, we will correct the address you provide if necessary. If `false`, we won't alter the address you provide.
  city: string # The city of the new address.
  customer_name: string # The name to associate with the new address.
  --emergency-enabled: oneof<nothing, bool> # Whether to enable emergency calling on the new address. Can be: `true` or `false`.
  --friendly-name: string # A descriptive string that you create to describe the new address. It can be up to 64 characters long.
  iso_country: string # The ISO country code of the new address. (format: iso-country-code)
  postal_code: string # The postal code of the new address.
  region: string # The state or region of the new address.
  street: string # The number and street address of the new address.
  --street-secondary: string # The additional number and street address of the address.
]: any -> record<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, emergency_enabled: bool, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, street_secondary: string, uri: string, validated: bool, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Addresses.json"))
  let body = {"AutoCorrectAddress": $auto_correct_address, "City": $city, "CustomerName": $customer_name, "EmergencyEnabled": $emergency_enabled, "FriendlyName": $friendly_name, "IsoCountry": $iso_country, "PostalCode": $postal_code, "Region": $region, "Street": $street, "StreetSecondary": $street_secondary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/Addresses/{AddressSid}/DependentPhoneNumbers.json
#
# operationId: ListDependentPhoneNumber
export def "2010-04-01-accounts-addresses-dependent-phone-numbersjson list-dependent-phone-number" [
  account_sid: string
  address_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<dependent_phone_numbers: table<account_sid: string, address_requirements: string, api_version: string, capabilities: any, date_created: string, date_updated: string, emergency_address_sid: string, emergency_status: string, friendly_name: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, address_sid: $address_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Addresses/{address_sid}/DependentPhoneNumbers.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /2010-04-01/Accounts/{AccountSid}/Addresses/{Sid}.json
#
# operationId: DeleteAddress
export def "2010-04-01-accounts-addresses delete-address" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Addresses/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Addresses/{Sid}.json
#
# operationId: FetchAddress
export def "2010-04-01-accounts-addresses get-address" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, emergency_enabled: bool, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, street_secondary: string, uri: string, validated: bool, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Addresses/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/Addresses/{Sid}.json
#
# operationId: UpdateAddress
export def "2010-04-01-accounts-addresses update-address" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-correct-address: oneof<nothing, bool> # Whether we should automatically correct the address. Can be: `true` or `false` and the default is `true`. If empty or `true`, we will correct the address you provide if necessary. If `false`, we won't alter the address you provide.
  --city: string # The city of the address.
  --customer-name: string # The name to associate with the address.
  --emergency-enabled: oneof<nothing, bool> # Whether to enable emergency calling on the address. Can be: `true` or `false`.
  --friendly-name: string # A descriptive string that you create to describe the address. It can be up to 64 characters long.
  --postal-code: string # The postal code of the address.
  --region: string # The state or region of the address.
  --street: string # The number and street address of the address.
  --street-secondary: string # The additional number and street address of the address.
]: any -> record<account_sid: string, city: string, customer_name: string, date_created: string, date_updated: string, emergency_enabled: bool, friendly_name: string, iso_country: string, postal_code: string, region: string, sid: string, street: string, street_secondary: string, uri: string, validated: bool, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Addresses/{sid}.json"))
  let body = {"AutoCorrectAddress": $auto_correct_address, "City": $city, "CustomerName": $customer_name, "EmergencyEnabled": $emergency_enabled, "FriendlyName": $friendly_name, "PostalCode": $postal_code, "Region": $region, "Street": $street, "StreetSecondary": $street_secondary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of applications representing an application within the requesting account
#
# GET /2010-04-01/Accounts/{AccountSid}/Applications.json
# operationId: ListApplication
export def "2010-04-01-accounts-applicationsjson list-application" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The string that identifies the Application resources to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<applications: table<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, public_application_connect_enabled: bool, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Applications.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new application within your account
#
# POST /2010-04-01/Accounts/{AccountSid}/Applications.json
# operationId: CreateApplication
export def "2010-04-01-accounts-applicationsjson create-application" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use to start a new TwiML session. Can be: `2010-04-01` or `2008-08-01`. The default value is the account's default API version.
  --friendly-name: string # A descriptive string that you create to describe the new application. It can be up to 64 characters long.
  --message-status-callback: string # The URL we should call using a POST method to send message status information to your application. (format: uri)
  --public-application-connect-enabled: oneof<nothing, bool> # Whether to allow other Twilio accounts to dial this applicaton using Dial verb. Can be: `true` or `false`.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method we should use to call `sms_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while retrieving or executing the TwiML from `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method we should use to call `sms_url`. Can be: `GET` or `POST`. (format: http-method)
  --sms-status-callback: string # The URL we should call using a POST method to send status information about SMS messages sent by the application. (format: uri)
  --sms-url: string # The URL we should call when the phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST`. (format: http-method)
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether we should look up the caller's caller-ID name from the CNAM database (additional charges apply). Can be: `true` or `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method we should use to call `voice_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-url: string # The URL we should call when the phone number assigned to this application receives a call. (format: uri)
]: any -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, public_application_connect_enabled: bool, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Applications.json"))
  let body = {"ApiVersion": $api_version, "FriendlyName": $friendly_name, "MessageStatusCallback": $message_status_callback, "PublicApplicationConnectEnabled": $public_application_connect_enabled, "SmsFallbackMethod": $sms_fallback_method, "SmsFallbackUrl": $sms_fallback_url, "SmsMethod": $sms_method, "SmsStatusCallback": $sms_status_callback, "SmsUrl": $sms_url, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "VoiceCallerIdLookup": $voice_caller_id_lookup, "VoiceFallbackMethod": $voice_fallback_method, "VoiceFallbackUrl": $voice_fallback_url, "VoiceMethod": $voice_method, "VoiceUrl": $voice_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete the application by the specified application sid
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Applications/{Sid}.json
# operationId: DeleteApplication
export def "2010-04-01-accounts-applications delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Applications/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the application specified by the provided sid
#
# GET /2010-04-01/Accounts/{AccountSid}/Applications/{Sid}.json
# operationId: FetchApplication
export def "2010-04-01-accounts-applications get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, public_application_connect_enabled: bool, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Applications/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the application's properties
#
# POST /2010-04-01/Accounts/{AccountSid}/Applications/{Sid}.json
# operationId: UpdateApplication
export def "2010-04-01-accounts-applications update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use to start a new TwiML session. Can be: `2010-04-01` or `2008-08-01`. The default value is your account's default API version.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --message-status-callback: string # The URL we should call using a POST method to send message status information to your application. (format: uri)
  --public-application-connect-enabled: oneof<nothing, bool> # Whether to allow other Twilio accounts to dial this applicaton using Dial verb. Can be: `true` or `false`.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method we should use to call `sms_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while retrieving or executing the TwiML from `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method we should use to call `sms_url`. Can be: `GET` or `POST`. (format: http-method)
  --sms-status-callback: string # Same as message_status_callback: The URL we should call using a POST method to send status information about SMS messages sent by the application. Deprecated, included for backwards compatibility. (format: uri)
  --sms-url: string # The URL we should call when the phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST`. (format: http-method)
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether we should look up the caller's caller-ID name from the CNAM database (additional charges apply). Can be: `true` or `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method we should use to call `voice_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-url: string # The URL we should call when the phone number assigned to this application receives a call. (format: uri)
]: any -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, message_status_callback: string, public_application_connect_enabled: bool, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_status_callback: string, sms_url: string, status_callback: string, status_callback_method: string, uri: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Applications/{sid}.json"))
  let body = {"ApiVersion": $api_version, "FriendlyName": $friendly_name, "MessageStatusCallback": $message_status_callback, "PublicApplicationConnectEnabled": $public_application_connect_enabled, "SmsFallbackMethod": $sms_fallback_method, "SmsFallbackUrl": $sms_fallback_url, "SmsMethod": $sms_method, "SmsStatusCallback": $sms_status_callback, "SmsUrl": $sms_url, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "VoiceCallerIdLookup": $voice_caller_id_lookup, "VoiceFallbackMethod": $voice_fallback_method, "VoiceFallbackUrl": $voice_fallback_url, "VoiceMethod": $voice_method, "VoiceUrl": $voice_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of authorized-connect-apps belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/AuthorizedConnectApps.json
# operationId: ListAuthorizedConnectApp
export def "2010-04-01-accounts-authorized-connect-appsjson list-authorized-connect-app" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<authorized_connect_apps: table<account_sid: string, connect_app_company_name: string, connect_app_description: string, connect_app_friendly_name: string, connect_app_homepage_url: string, connect_app_sid: string, date_created: string, date_updated: string, permissions: list, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/AuthorizedConnectApps.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of an authorized-connect-app
#
# GET /2010-04-01/Accounts/{AccountSid}/AuthorizedConnectApps/{ConnectAppSid}.json
# operationId: FetchAuthorizedConnectApp
export def "2010-04-01-accounts-authorized-connect-apps get" [
  account_sid: string
  connect_app_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, connect_app_company_name: string, connect_app_description: string, connect_app_friendly_name: string, connect_app_homepage_url: string, connect_app_sid: string, date_created: string, date_updated: string, permissions: list<string>, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, connect_app_sid: $connect_app_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/AuthorizedConnectApps/{connect_app_sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers.json
#
# operationId: ListAvailablePhoneNumberCountry
export def "2010-04-01-accounts-available-phone-numbersjson list-available-phone-number-country" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<countries: table<beta: bool, country: string, country_code: string, subresource_uris: record, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/AvailablePhoneNumbers.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}.json
#
# operationId: FetchAvailablePhoneNumberCountry
export def "2010-04-01-accounts-available-phone-numbers get-available-phone-number-country" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<beta: bool, country: string, country_code: string, subresource_uris: record, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, country_code: $country_code} | format pattern "/2010-04-01/Accounts/{account_sid}/AvailablePhoneNumbers/{country_code}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/Local.json
#
# operationId: ListAvailablePhoneNumberLocal
export def "2010-04-01-accounts-available-phone-numbers-localjson list-available-phone-number-local" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumberlocal-resource?code-sample=code-find-phone-numbers-by-number-pattern) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumberlocal-resource?code-sample=code-find-phone-numbers-by-character-pattern). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $area_code "scalar") (serialize-qp "Contains" $contains "scalar") (serialize-qp "SmsEnabled" $sms_enabled "scalar") (serialize-qp "MmsEnabled" $mms_enabled "scalar") (serialize-qp "VoiceEnabled" $voice_enabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $exclude_all_address_required "scalar") (serialize-qp "ExcludeLocalAddressRequired" $exclude_local_address_required "scalar") (serialize-qp "ExcludeForeignAddressRequired" $exclude_foreign_address_required "scalar") (serialize-qp "Beta" $beta "scalar") (serialize-qp "NearNumber" $near_number "scalar") (serialize-qp "NearLatLong" $near_lat_long "scalar") (serialize-qp "Distance" $distance "scalar") (serialize-qp "InPostalCode" $in_postal_code "scalar") (serialize-qp "InRegion" $in_region "scalar") (serialize-qp "InRateCenter" $in_rate_center "scalar") (serialize-qp "InLata" $in_lata "scalar") (serialize-qp "InLocality" $in_locality "scalar") (serialize-qp "FaxEnabled" $fax_enabled "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, country_code: $country_code} | format pattern "/2010-04-01/Accounts/{account_sid}/AvailablePhoneNumbers/{country_code}/Local.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/MachineToMachine.json
#
# operationId: ListAvailablePhoneNumberMachineToMachine
export def "2010-04-01-accounts-available-phone-numbers-machine-to-machinejson list" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-2) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-3). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $area_code "scalar") (serialize-qp "Contains" $contains "scalar") (serialize-qp "SmsEnabled" $sms_enabled "scalar") (serialize-qp "MmsEnabled" $mms_enabled "scalar") (serialize-qp "VoiceEnabled" $voice_enabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $exclude_all_address_required "scalar") (serialize-qp "ExcludeLocalAddressRequired" $exclude_local_address_required "scalar") (serialize-qp "ExcludeForeignAddressRequired" $exclude_foreign_address_required "scalar") (serialize-qp "Beta" $beta "scalar") (serialize-qp "NearNumber" $near_number "scalar") (serialize-qp "NearLatLong" $near_lat_long "scalar") (serialize-qp "Distance" $distance "scalar") (serialize-qp "InPostalCode" $in_postal_code "scalar") (serialize-qp "InRegion" $in_region "scalar") (serialize-qp "InRateCenter" $in_rate_center "scalar") (serialize-qp "InLata" $in_lata "scalar") (serialize-qp "InLocality" $in_locality "scalar") (serialize-qp "FaxEnabled" $fax_enabled "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, country_code: $country_code} | format pattern "/2010-04-01/Accounts/{account_sid}/AvailablePhoneNumbers/{country_code}/MachineToMachine.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/Mobile.json
#
# operationId: ListAvailablePhoneNumberMobile
export def "2010-04-01-accounts-available-phone-numbers-mobilejson list-available-phone-number-mobile" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-2) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-3). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $area_code "scalar") (serialize-qp "Contains" $contains "scalar") (serialize-qp "SmsEnabled" $sms_enabled "scalar") (serialize-qp "MmsEnabled" $mms_enabled "scalar") (serialize-qp "VoiceEnabled" $voice_enabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $exclude_all_address_required "scalar") (serialize-qp "ExcludeLocalAddressRequired" $exclude_local_address_required "scalar") (serialize-qp "ExcludeForeignAddressRequired" $exclude_foreign_address_required "scalar") (serialize-qp "Beta" $beta "scalar") (serialize-qp "NearNumber" $near_number "scalar") (serialize-qp "NearLatLong" $near_lat_long "scalar") (serialize-qp "Distance" $distance "scalar") (serialize-qp "InPostalCode" $in_postal_code "scalar") (serialize-qp "InRegion" $in_region "scalar") (serialize-qp "InRateCenter" $in_rate_center "scalar") (serialize-qp "InLata" $in_lata "scalar") (serialize-qp "InLocality" $in_locality "scalar") (serialize-qp "FaxEnabled" $fax_enabled "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, country_code: $country_code} | format pattern "/2010-04-01/Accounts/{account_sid}/AvailablePhoneNumbers/{country_code}/Mobile.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/National.json
#
# operationId: ListAvailablePhoneNumberNational
export def "2010-04-01-accounts-available-phone-numbers-nationaljson list-available-phone-number-national" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-2) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-3). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $area_code "scalar") (serialize-qp "Contains" $contains "scalar") (serialize-qp "SmsEnabled" $sms_enabled "scalar") (serialize-qp "MmsEnabled" $mms_enabled "scalar") (serialize-qp "VoiceEnabled" $voice_enabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $exclude_all_address_required "scalar") (serialize-qp "ExcludeLocalAddressRequired" $exclude_local_address_required "scalar") (serialize-qp "ExcludeForeignAddressRequired" $exclude_foreign_address_required "scalar") (serialize-qp "Beta" $beta "scalar") (serialize-qp "NearNumber" $near_number "scalar") (serialize-qp "NearLatLong" $near_lat_long "scalar") (serialize-qp "Distance" $distance "scalar") (serialize-qp "InPostalCode" $in_postal_code "scalar") (serialize-qp "InRegion" $in_region "scalar") (serialize-qp "InRateCenter" $in_rate_center "scalar") (serialize-qp "InLata" $in_lata "scalar") (serialize-qp "InLocality" $in_locality "scalar") (serialize-qp "FaxEnabled" $fax_enabled "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, country_code: $country_code} | format pattern "/2010-04-01/Accounts/{account_sid}/AvailablePhoneNumbers/{country_code}/National.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/SharedCost.json
#
# operationId: ListAvailablePhoneNumberSharedCost
export def "2010-04-01-accounts-available-phone-numbers-shared-costjson list-available-phone-number-shared-cost" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-2) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-3). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $area_code "scalar") (serialize-qp "Contains" $contains "scalar") (serialize-qp "SmsEnabled" $sms_enabled "scalar") (serialize-qp "MmsEnabled" $mms_enabled "scalar") (serialize-qp "VoiceEnabled" $voice_enabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $exclude_all_address_required "scalar") (serialize-qp "ExcludeLocalAddressRequired" $exclude_local_address_required "scalar") (serialize-qp "ExcludeForeignAddressRequired" $exclude_foreign_address_required "scalar") (serialize-qp "Beta" $beta "scalar") (serialize-qp "NearNumber" $near_number "scalar") (serialize-qp "NearLatLong" $near_lat_long "scalar") (serialize-qp "Distance" $distance "scalar") (serialize-qp "InPostalCode" $in_postal_code "scalar") (serialize-qp "InRegion" $in_region "scalar") (serialize-qp "InRateCenter" $in_rate_center "scalar") (serialize-qp "InLata" $in_lata "scalar") (serialize-qp "InLocality" $in_locality "scalar") (serialize-qp "FaxEnabled" $fax_enabled "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, country_code: $country_code} | format pattern "/2010-04-01/Accounts/{account_sid}/AvailablePhoneNumbers/{country_code}/SharedCost.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/TollFree.json
#
# operationId: ListAvailablePhoneNumberTollFree
export def "2010-04-01-accounts-available-phone-numbers-toll-freejson list-available-phone-number-toll-free" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-2) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-3). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $area_code "scalar") (serialize-qp "Contains" $contains "scalar") (serialize-qp "SmsEnabled" $sms_enabled "scalar") (serialize-qp "MmsEnabled" $mms_enabled "scalar") (serialize-qp "VoiceEnabled" $voice_enabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $exclude_all_address_required "scalar") (serialize-qp "ExcludeLocalAddressRequired" $exclude_local_address_required "scalar") (serialize-qp "ExcludeForeignAddressRequired" $exclude_foreign_address_required "scalar") (serialize-qp "Beta" $beta "scalar") (serialize-qp "NearNumber" $near_number "scalar") (serialize-qp "NearLatLong" $near_lat_long "scalar") (serialize-qp "Distance" $distance "scalar") (serialize-qp "InPostalCode" $in_postal_code "scalar") (serialize-qp "InRegion" $in_region "scalar") (serialize-qp "InRateCenter" $in_rate_center "scalar") (serialize-qp "InLata" $in_lata "scalar") (serialize-qp "InLocality" $in_locality "scalar") (serialize-qp "FaxEnabled" $fax_enabled "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, country_code: $country_code} | format pattern "/2010-04-01/Accounts/{account_sid}/AvailablePhoneNumbers/{country_code}/TollFree.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/AvailablePhoneNumbers/{CountryCode}/Voip.json
#
# operationId: ListAvailablePhoneNumberVoip
export def "2010-04-01-accounts-available-phone-numbers-voipjson list-available-phone-number-voip" [
  account_sid: string
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --area-code: int # The area code of the phone numbers to read. Applies to only phone numbers in the US and Canada.
  --contains: string # The pattern on which to match phone numbers. Valid characters are `*`, `0-9`, `a-z`, and `A-Z`. The `*` character matches any single digit. For examples, see [Example 2](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-2) and [Example 3](https://www.twilio.com/docs/phone-numbers/api/availablephonenumber-resource#local-get-basic-example-3). If specified, this value must have at least two characters.
  --sms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive text messages. Can be: `true` or `false`.
  --mms-enabled: oneof<nothing, bool> # Whether the phone numbers can receive MMS messages. Can be: `true` or `false`.
  --voice-enabled: oneof<nothing, bool> # Whether the phone numbers can receive calls. Can be: `true` or `false`.
  --exclude-all-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require an [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-local-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a local [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --exclude-foreign-address-required: oneof<nothing, bool> # Whether to exclude phone numbers that require a foreign [Address](https://www.twilio.com/docs/usage/api/address). Can be: `true` or `false` and the default is `false`.
  --beta: oneof<nothing, bool> # Whether to read phone numbers that are new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --near-number: string # Given a phone number, find a geographically close number within `distance` miles. Distance defaults to 25 miles. Applies to only phone numbers in the US and Canada. (format: phone-number)
  --near-lat-long: string # Given a latitude/longitude pair `lat,long` find geographically close numbers within `distance` miles. Applies to only phone numbers in the US and Canada.
  --distance: int # The search radius, in miles, for a `near_` query.  Can be up to `500` and the default is `25`. Applies to only phone numbers in the US and Canada.
  --in-postal-code: string # Limit results to a particular postal code. Given a phone number, search within the same postal code as that number. Applies to only phone numbers in the US and Canada.
  --in-region: string # Limit results to a particular region, state, or province. Given a phone number, search within the same region as that number. Applies to only phone numbers in the US and Canada.
  --in-rate-center: string # Limit results to a specific rate center, or given a phone number search within the same rate center as that number. Requires `in_lata` to be set as well. Applies to only phone numbers in the US and Canada.
  --in-lata: string # Limit results to a specific local access and transport area ([LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area)). Given a phone number, search within the same [LATA](https://en.wikipedia.org/wiki/Local_access_and_transport_area) as that number. Applies to only phone numbers in the US and Canada.
  --in-locality: string # Limit results to a particular locality or city. Given a phone number, search within the same Locality as that number.
  --fax-enabled: oneof<nothing, bool> # Whether the phone numbers can receive faxes. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<available_phone_numbers: table<address_requirements: string, beta: bool, capabilities: record, friendly_name: string, iso_country: string, lata: string, latitude: float, locality: string, longitude: float, phone_number: string, postal_code: string, rate_center: string, region: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "AreaCode" $area_code "scalar") (serialize-qp "Contains" $contains "scalar") (serialize-qp "SmsEnabled" $sms_enabled "scalar") (serialize-qp "MmsEnabled" $mms_enabled "scalar") (serialize-qp "VoiceEnabled" $voice_enabled "scalar") (serialize-qp "ExcludeAllAddressRequired" $exclude_all_address_required "scalar") (serialize-qp "ExcludeLocalAddressRequired" $exclude_local_address_required "scalar") (serialize-qp "ExcludeForeignAddressRequired" $exclude_foreign_address_required "scalar") (serialize-qp "Beta" $beta "scalar") (serialize-qp "NearNumber" $near_number "scalar") (serialize-qp "NearLatLong" $near_lat_long "scalar") (serialize-qp "Distance" $distance "scalar") (serialize-qp "InPostalCode" $in_postal_code "scalar") (serialize-qp "InRegion" $in_region "scalar") (serialize-qp "InRateCenter" $in_rate_center "scalar") (serialize-qp "InLata" $in_lata "scalar") (serialize-qp "InLocality" $in_locality "scalar") (serialize-qp "FaxEnabled" $fax_enabled "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, country_code: $country_code} | format pattern "/2010-04-01/Accounts/{account_sid}/AvailablePhoneNumbers/{country_code}/Voip.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the balance for an Account based on Account Sid. Balance changes may not be reflected immediately. Child accounts do not contain balance information
#
# GET /2010-04-01/Accounts/{AccountSid}/Balance.json
# operationId: FetchBalance
export def "2010-04-01-accounts-balancejson get-balance" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, balance: string, currency: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Balance.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves a collection of calls made to and from your account
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls.json
# operationId: ListCall
export def "2010-04-01-accounts-callsjson list-call" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-to: string # Only show calls made to this phone number, SIP address, Client identifier or SIM SID. (format: phone-number)
  --qp-from: string # Only include calls from this phone number, SIP address, Client identifier or SIM SID. (format: phone-number)
  --parent-call-sid: string # Only include calls spawned by calls with this SID.
  --status: string@status-completer-1 # The status of the calls to include. Can be: `queued`, `ringing`, `in-progress`, `canceled`, `completed`, `failed`, `busy`, or `no-answer`.
  --start-time: string # Only include calls that started on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read only calls that started on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read calls that started on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read calls that started on or after midnight of this date. (format: date-time)
  --start-time: string # Only include calls that started on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read only calls that started on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read calls that started on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read calls that started on or after midnight of this date. (format: date-time)
  --start-time: string # Only include calls that started on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read only calls that started on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read calls that started on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read calls that started on or after midnight of this date. (format: date-time)
  --end-time: string # Only include calls that ended on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read only calls that ended on this date. You can also specify an inequality, such as `EndTime<=YYYY-MM-DD`, to read calls that ended on or before midnight of this date, and `EndTime>=YYYY-MM-DD` to read calls that ended on or after midnight of this date. (format: date-time)
  --end-time: string # Only include calls that ended on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read only calls that ended on this date. You can also specify an inequality, such as `EndTime<=YYYY-MM-DD`, to read calls that ended on or before midnight of this date, and `EndTime>=YYYY-MM-DD` to read calls that ended on or after midnight of this date. (format: date-time)
  --end-time: string # Only include calls that ended on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read only calls that ended on this date. You can also specify an inequality, such as `EndTime<=YYYY-MM-DD`, to read calls that ended on or before midnight of this date, and `EndTime>=YYYY-MM-DD` to read calls that ended on or after midnight of this date. (format: date-time)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<calls: table<account_sid: string, answered_by: string, api_version: string, caller_name: string, date_created: string, date_updated: string, direction: string, duration: string, end_time: string, forwarded_from: string, from: string, from_formatted: string, group_sid: string, parent_call_sid: string, phone_number_sid: string, price: string, price_unit: string, queue_time: string, sid: string, start_time: string, status: string, subresource_uris: record, to: string, to_formatted: string, trunk_sid: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "To" $qp_to "scalar") (serialize-qp "From" $qp_from "scalar") (serialize-qp "ParentCallSid" $parent_call_sid "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "StartTime" $start_time "scalar") (serialize-qp "StartTime<" $start_time "scalar") (serialize-qp "StartTime>" $start_time "scalar") (serialize-qp "EndTime" $end_time "scalar") (serialize-qp "EndTime<" $end_time "scalar") (serialize-qp "EndTime>" $end_time "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new outgoing call to phones, SIP-enabled endpoints or Twilio Client connections
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls.json
# operationId: CreateCall
export def "2010-04-01-accounts-callsjson create-call" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --application-sid: string # The SID of the Application resource that will handle the call, if the call will be handled by an application.
  --async-amd: string # Select whether to perform answering machine detection in the background. Default, blocks the execution of the call until Answering Machine Detection is completed. Can be: `true` or `false`.
  --async-amd-status-callback: string # The URL that we should call using the `async_amd_status_callback_method` to notify customer application whether the call was answered by human, machine or fax. (format: uri)
  --async-amd-status-callback-method: string@async-amd-status-callback-method-completer # The HTTP method we should use when calling the `async_amd_status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --byoc: string # The SID of a BYOC (Bring Your Own Carrier) trunk to route this call with. Note that `byoc` is only meaningful when `to` is a phone number; it will otherwise be ignored. (Beta)
  --call-reason: string # The Reason for the outgoing call. Use it to specify the purpose of the call that is presented on the called party's phone. (Branded Calls Beta)
  --call-token: string # A token string needed to invoke a forwarded call. A call_token is generated when an incoming call is received on a Twilio number. Pass an incoming call's call_token value to a forwarded call via the call_token parameter when creating a new call. A forwarded call should bear the same CallerID of the original incoming call.
  --caller-id: string # The phone number, SIP address, or Client identifier that made this call. Phone numbers are in [E.164 format](https://wwnw.twilio.com/docs/glossary/what-e164) (e.g., +16175551212). SIP addresses are formatted as `name@company.com`.
  --fallback-method: string@fallback-method-completer # The HTTP method that we should use to request the `fallback_url`. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --fallback-url: string # The URL that we call using the `fallback_method` if an error occurs when requesting or executing the TwiML at `url`. If an `application_sid` parameter is present, this parameter is ignored. (format: uri)
  --body-from: string # The phone number or client identifier to use as the caller id. If using a phone number, it must be a Twilio number or a Verified [outgoing caller id](https://www.twilio.com/docs/voice/api/outgoing-caller-ids) for your account. If the `to` parameter is a phone number, `From` must also be a phone number. (format: endpoint)
  --machine-detection: string # Whether to detect if a human, answering machine, or fax has picked up the call. Can be: `Enable` or `DetectMessageEnd`. Use `Enable` if you would like us to return `AnsweredBy` as soon as the called party is identified. Use `DetectMessageEnd`, if you would like to leave a message on an answering machine. If `send_digits` is provided, this parameter is ignored. For more information, see [Answering Machine Detection](https://www.twilio.com/docs/voice/answering-machine-detection).
  --machine-detection-silence-timeout: int # The number of milliseconds of initial silence after which an `unknown` AnsweredBy result will be returned. Possible Values: 2000-10000. Default: 5000.
  --machine-detection-speech-end-threshold: int # The number of milliseconds of silence after speech activity at which point the speech activity is considered complete. Possible Values: 500-5000. Default: 1200.
  --machine-detection-speech-threshold: int # The number of milliseconds that is used as the measuring stick for the length of the speech activity, where durations lower than this value will be interpreted as a human and longer than this value as a machine. Possible Values: 1000-6000. Default: 2400.
  --machine-detection-timeout: int # The number of seconds that we should attempt to detect an answering machine before timing out and sending a voice request with `AnsweredBy` of `unknown`. The default timeout is 30 seconds.
  --method: string@method-completer # The HTTP method we should use when calling the `url` parameter's value. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --record: oneof<nothing, bool> # Whether to record the call. Can be `true` to record the phone call, or `false` to not. The default is `false`. The `recording_url` is sent to the `status_callback` URL.
  --recording-channels: string # The number of channels in the final recording. Can be: `mono` or `dual`. The default is `mono`. `mono` records both legs of the call in a single channel of the recording file. `dual` records each leg to a separate channel of the recording file. The first channel of a dual-channel recording contains the parent call and the second channel contains the child call.
  --recording-status-callback: string # The URL that we call when the recording is available to be accessed.
  --recording-status-callback-event: list # The recording status events that will trigger calls to the URL specified in `recording_status_callback`. Can be: `in-progress`, `completed` and `absent`. Defaults to `completed`. Separate  multiple values with a space.
  --recording-status-callback-method: string@recording-status-callback-method-completer # The HTTP method we should use when calling the `recording_status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --recording-track: string # The audio track to record for the call. Can be: `inbound`, `outbound` or `both`. The default is `both`. `inbound` records the audio that is received by Twilio. `outbound` records the audio that is generated from Twilio. `both` records the audio that is received and generated by Twilio.
  --send-digits: string # A string of keys to dial after connecting to the number, maximum of 32 digits. Valid digits in the string include: any digit (`0`-`9`), '`#`', '`*`' and '`w`', to insert a half second pause. For example, if you connected to a company phone number and wanted to pause for one second, and then dial extension 1234 followed by the pound key, the value of this parameter would be `ww1234#`. Remember to URL-encode this string, since the '`#`' character has special meaning in a URL. If both `SendDigits` and `MachineDetection` parameters are provided, then `MachineDetection` will be ignored.
  --sip-auth-password: string # The password required to authenticate the user account specified in `sip_auth_username`.
  --sip-auth-username: string # The username used to authenticate the caller making a SIP call.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. If no `status_callback_event` is specified, we will send the `completed` status. If an `application_sid` parameter is present, this parameter is ignored. URLs must contain a valid hostname (underscores are not permitted). (format: uri)
  --status-callback-event: list # The call progress events that we will send to the `status_callback` URL. Can be: `initiated`, `ringing`, `answered`, and `completed`. If no event is specified, we send the `completed` status. If you want to receive multiple events, specify each one in a separate `status_callback_event` parameter. See the code sample for [monitoring call progress](https://www.twilio.com/docs/voice/api/call-resource?code-sample=code-create-a-call-resource-and-specify-a-statuscallbackevent&code-sdk-version=json). If an `application_sid` is present, this parameter is ignored.
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use when calling the `status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --time-limit: int # The maximum duration of the call in seconds. Constraints depend on account and configuration.
  --timeout: int # The integer number of seconds that we should allow the phone to ring before assuming there is no answer. The default is `60` seconds and the maximum is `600` seconds. For some call flows, we will add a 5-second buffer to the timeout value you provide. For this reason, a timeout value of 10 seconds could result in an actual timeout closer to 15 seconds. You can set this to a short time, such as `15` seconds, to hang up before reaching an answering machine or voicemail.
  --body-to: string # The phone number, SIP address, or client identifier to call. (format: endpoint)
  --trim: string # Whether to trim any leading and trailing silence from the recording. Can be: `trim-silence` or `do-not-trim` and the default is `trim-silence`.
  --twiml: string # TwiML instructions for the call Twilio will use without fetching Twiml from url parameter. If both `twiml` and `url` are provided then `twiml` parameter will be ignored. Max 4000 characters. (format: twiml)
  --body-url: string # The absolute URL that returns the TwiML instructions for the call. We will call this URL using the `method` when the call connects. For more information, see the [Url Parameter](https://www.twilio.com/docs/voice/make-calls#specify-a-url-parameter) section in [Making Calls](https://www.twilio.com/docs/voice/make-calls). (format: uri)
]: any -> record<account_sid: string, answered_by: string, api_version: string, caller_name: string, date_created: string, date_updated: string, direction: string, duration: string, end_time: string, forwarded_from: string, from: string, from_formatted: string, group_sid: string, parent_call_sid: string, phone_number_sid: string, price: string, price_unit: string, queue_time: string, sid: string, start_time: string, status: string, subresource_uris: record, to: string, to_formatted: string, trunk_sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls.json"))
  let body = {"ApplicationSid": $application_sid, "AsyncAmd": $async_amd, "AsyncAmdStatusCallback": $async_amd_status_callback, "AsyncAmdStatusCallbackMethod": $async_amd_status_callback_method, "Byoc": $byoc, "CallReason": $call_reason, "CallToken": $call_token, "CallerId": $caller_id, "FallbackMethod": $fallback_method, "FallbackUrl": $fallback_url, "From": $body_from, "MachineDetection": $machine_detection, "MachineDetectionSilenceTimeout": $machine_detection_silence_timeout, "MachineDetectionSpeechEndThreshold": $machine_detection_speech_end_threshold, "MachineDetectionSpeechThreshold": $machine_detection_speech_threshold, "MachineDetectionTimeout": $machine_detection_timeout, "Method": $method, "Record": $record, "RecordingChannels": $recording_channels, "RecordingStatusCallback": $recording_status_callback, "RecordingStatusCallbackEvent": $recording_status_callback_event, "RecordingStatusCallbackMethod": $recording_status_callback_method, "RecordingTrack": $recording_track, "SendDigits": $send_digits, "SipAuthPassword": $sip_auth_password, "SipAuthUsername": $sip_auth_username, "StatusCallback": $status_callback, "StatusCallbackEvent": $status_callback_event, "StatusCallbackMethod": $status_callback_method, "TimeLimit": $time_limit, "Timeout": $timeout, "To": $body_to, "Trim": $trim, "Twiml": $twiml, "Url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a FeedbackSummary resource for a call
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/FeedbackSummary.json
# operationId: CreateCallFeedbackSummary
export def "2010-04-01-accounts-calls-feedback-summaryjson create-call-feedback-summary" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  end_date: string # Only include feedback given on or before this date. Format is `YYYY-MM-DD` and specified in UTC. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to also include Feedback resources from all subaccounts. `true` includes feedback from all subaccounts and `false`, the default, includes feedback from only the specified account.
  start_date: string # Only include feedback given on or after this date. Format is `YYYY-MM-DD` and specified in UTC. (format: date)
  --status-callback: string # The URL that we will request when the feedback summary is complete. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method (`GET` or `POST`) we use to make the request to the `StatusCallback` URL. (format: http-method)
]: any -> record<account_sid: string, call_count: int, call_feedback_count: int, date_created: string, date_updated: string, end_date: string, include_subaccounts: bool, issues: list<any>, quality_score_average: float, quality_score_median: float, quality_score_standard_deviation: float, sid: string, start_date: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/FeedbackSummary.json"))
  let body = {"EndDate": $end_date, "IncludeSubaccounts": $include_subaccounts, "StartDate": $start_date, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a FeedbackSummary resource from a call
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Calls/FeedbackSummary/{Sid}.json
# operationId: DeleteCallFeedbackSummary
export def "2010-04-01-accounts-calls-feedback-summary delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/FeedbackSummary/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a FeedbackSummary resource from a call
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/FeedbackSummary/{Sid}.json
# operationId: FetchCallFeedbackSummary
export def "2010-04-01-accounts-calls-feedback-summary get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, call_count: int, call_feedback_count: int, date_created: string, date_updated: string, end_date: string, include_subaccounts: bool, issues: list<any>, quality_score_average: float, quality_score_median: float, quality_score_standard_deviation: float, sid: string, start_date: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/FeedbackSummary/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all events for a call.
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Events.json
# operationId: ListCallEvent
export def "2010-04-01-accounts-calls-eventsjson list-call-event" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, events: table<request: any, response: any>, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Events.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a Feedback resource from a call
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Feedback.json
# operationId: FetchCallFeedback
export def "2010-04-01-accounts-calls-feedbackjson get-call-feedback" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, issues: list<string>, quality_score: int, sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Feedback.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Feedback resource for a call
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Feedback.json
# operationId: UpdateCallFeedback
export def "2010-04-01-accounts-calls-feedbackjson update-call-feedback" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --issue: list # One or more issues experienced during the call. The issues can be: `imperfect-audio`, `dropped-call`, `incorrect-caller-id`, `post-dial-delay`, `digits-not-captured`, `audio-latency`, `unsolicited-call`, or `one-way-audio`.
  --quality-score: int # The call quality expressed as an integer from `1` to `5` where `1` represents very poor call quality and `5` represents a perfect call.
]: any -> record<account_sid: string, date_created: string, date_updated: string, issues: list<string>, quality_score: int, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Feedback.json"))
  let body = {"Issue": $issue, "QualityScore": $quality_score} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Notifications.json
#
# operationId: ListCallNotification
export def "2010-04-01-accounts-calls-notificationsjson list-call-notification" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --log: int # Only read notifications of the specified log level. Can be:  `0` to read only ERROR notifications or `1` to read only WARNING notifications. By default, all notifications are read.
  --message-date: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --message-date: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --message-date: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, notifications: table<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, sid: string, uri: string>, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Log" $log "scalar") (serialize-qp "MessageDate" $message_date "scalar") (serialize-qp "MessageDate<" $message_date "scalar") (serialize-qp "MessageDate>" $message_date "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Notifications.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Notifications/{Sid}.json
#
# operationId: FetchCallNotification
export def "2010-04-01-accounts-calls-notifications get" [
  account_sid: string
  call_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, request_variables: string, response_body: string, response_headers: string, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Notifications/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# create an instance of payments. This will start a new payments session
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Payments.json
# operationId: CreatePayments
export def "2010-04-01-accounts-calls-paymentsjson create-payments" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bank-account-type: string@bank-account-type-completer
  --charge-amount: float # A positive decimal value less than 1,000,000 to charge against the credit card or bank account. Default currency can be overwritten with `currency` field. Leave blank or set to 0 to tokenize.
  --currency: string # The currency of the `charge_amount`, formatted as [ISO 4127](http://www.iso.org/iso/home/standards/currency_codes.htm) format. The default value is `USD` and all values allowed from the Pay Connector are accepted.
  --description: string # The description can be used to provide more details regarding the transaction. This information is submitted along with the payment details to the Payment Connector which are then posted on the transactions.
  idempotency_key: string # A unique token that will be used to ensure that multiple API calls with the same information do not result in multiple transactions. This should be a unique string value per API call and can be a randomly generated.
  --input: string # A list of inputs that should be accepted. Currently only `dtmf` is supported. All digits captured during a pay session are redacted from the logs.
  --min-postal-code-length: int # A positive integer that is used to validate the length of the `PostalCode` inputted by the user. User must enter this many digits.
  --parameter: any # A single-level JSON object used to pass custom parameters to payment processors. (Required for ACH payments). The information that has to be included here depends on the <Pay> Connector. [Read more](https://www.twilio.com/console/voice/pay-connectors).
  --payment-connector: string # This is the unique name corresponding to the Pay Connector installed in the Twilio Add-ons. Learn more about [<Pay> Connectors](https://www.twilio.com/console/voice/pay-connectors). The default value is `Default`.
  --payment-method: string@payment-method-completer
  --postal-code: oneof<nothing, bool> # Indicates whether the credit card postal code (zip code) is a required piece of payment information that must be provided by the caller. The default is `true`.
  --security-code: oneof<nothing, bool> # Indicates whether the credit card security code is a required piece of payment information that must be provided by the caller. The default is `true`.
  status_callback: string # Provide an absolute or relative URL to receive status updates regarding your Pay session. Read more about the [expected StatusCallback values](https://www.twilio.com/docs/voice/api/payment-resource#statuscallback) (format: uri)
  --timeout: int # The number of seconds that <Pay> should wait for the caller to press a digit between each subsequent digit, after the first one, before moving on to validate the digits captured. The default is `5`, maximum is `600`.
  --token-type: string@token-type-completer
  --valid-card-types: string # Credit card types separated by space that Pay should accept. The default value is `visa mastercard amex`
]: any -> record<account_sid: string, call_sid: string, date_created: string, date_updated: string, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Payments.json"))
  let body = {"BankAccountType": $bank_account_type, "ChargeAmount": $charge_amount, "Currency": $currency, "Description": $description, "IdempotencyKey": $idempotency_key, "Input": $input, "MinPostalCodeLength": $min_postal_code_length, "Parameter": $parameter, "PaymentConnector": $payment_connector, "PaymentMethod": $payment_method, "PostalCode": $postal_code, "SecurityCode": $security_code, "StatusCallback": $status_callback, "Timeout": $timeout, "TokenType": $token_type, "ValidCardTypes": $valid_card_types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# update an instance of payments with different phases of payment flows.
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Payments/{Sid}.json
# operationId: UpdatePayments
export def "2010-04-01-accounts-calls-payments update" [
  account_sid: string
  call_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --capture: string@capture-completer
  idempotency_key: string # A unique token that will be used to ensure that multiple API calls with the same information do not result in multiple transactions. This should be a unique string value per API call and can be a randomly generated.
  --status: string@status-completer-2
  status_callback: string # Provide an absolute or relative URL to receive status updates regarding your Pay session. Read more about the [Update](https://www.twilio.com/docs/voice/api/payment-resource#statuscallback-update) and [Complete/Cancel](https://www.twilio.com/docs/voice/api/payment-resource#statuscallback-cancelcomplete) POST requests. (format: uri)
]: any -> record<account_sid: string, call_sid: string, date_created: string, date_updated: string, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Payments/{sid}.json"))
  let body = {"Capture": $capture, "IdempotencyKey": $idempotency_key, "Status": $status, "StatusCallback": $status_callback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of recordings belonging to the call used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings.json
# operationId: ListCallRecording
export def "2010-04-01-accounts-calls-recordingsjson list-call-recording" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, recordings: table<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: float, price_unit: string, sid: string, source: string, start_time: string, status: string, track: string, uri: string>, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "DateCreated" $date_created "scalar") (serialize-qp "DateCreated<" $date_created "scalar") (serialize-qp "DateCreated>" $date_created "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Recordings.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a recording for the call
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings.json
# operationId: CreateCallRecording
export def "2010-04-01-accounts-calls-recordingsjson create-call-recording" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --recording-channels: string # The number of channels used in the recording. Can be: `mono` or `dual` and the default is `mono`. `mono` records all parties of the call into one channel. `dual` records each party of a 2-party call into separate channels.
  --recording-status-callback: string # The URL we should call using the `recording_status_callback_method` on each recording event specified in  `recording_status_callback_event`. For more information, see [RecordingStatusCallback parameters](https://www.twilio.com/docs/voice/api/recording#recordingstatuscallback). (format: uri)
  --recording-status-callback-event: list # The recording status events on which we should call the `recording_status_callback` URL. Can be: `in-progress`, `completed` and `absent` and the default is `completed`. Separate multiple event values with a space.
  --recording-status-callback-method: string@recording-status-callback-method-completer # The HTTP method we should use to call `recording_status_callback`. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --recording-track: string # The audio track to record for the call. Can be: `inbound`, `outbound` or `both`. The default is `both`. `inbound` records the audio that is received by Twilio. `outbound` records the audio that is generated from Twilio. `both` records the audio that is received and generated by Twilio.
  --trim: string # Whether to trim any leading and trailing silence in the recording. Can be: `trim-silence` or `do-not-trim` and the default is `do-not-trim`. `trim-silence` trims the silence from the beginning and end of the recording and `do-not-trim` does not.
]: any -> record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: float, price_unit: string, sid: string, source: string, start_time: string, status: string, track: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Recordings.json"))
  let body = {"RecordingChannels": $recording_channels, "RecordingStatusCallback": $recording_status_callback, "RecordingStatusCallbackEvent": $recording_status_callback_event, "RecordingStatusCallbackMethod": $recording_status_callback_method, "RecordingTrack": $recording_track, "Trim": $trim} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a recording from your account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings/{Sid}.json
# operationId: DeleteCallRecording
export def "2010-04-01-accounts-calls-recordings delete" [
  account_sid: string
  call_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Recordings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of a recording for a call
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings/{Sid}.json
# operationId: FetchCallRecording
export def "2010-04-01-accounts-calls-recordings get" [
  account_sid: string
  call_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: float, price_unit: string, sid: string, source: string, start_time: string, status: string, track: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Recordings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Changes the status of the recording to paused, stopped, or in-progress. Note: Pass `Twilio.CURRENT` instead of recording sid to reference current active recording.
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Recordings/{Sid}.json
# operationId: UpdateCallRecording
export def "2010-04-01-accounts-calls-recordings update" [
  account_sid: string
  call_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pause-behavior: string # Whether to record during a pause. Can be: `skip` or `silence` and the default is `silence`. `skip` does not record during the pause period, while `silence` will replace the actual audio of the call with silence during the pause period. This parameter only applies when setting `status` is set to `paused`.
  status: string@status-completer-3
]: any -> record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: float, price_unit: string, sid: string, source: string, start_time: string, status: string, track: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Recordings/{sid}.json"))
  let body = {"PauseBehavior": $pause_behavior, "Status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a Siprec
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Siprec.json
# operationId: CreateSiprec
export def "2010-04-01-accounts-calls-siprecjson create-siprec" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --connector-name: string # Unique name used when configuring the connector via Marketplace Add-on.
  --name: string # The user-specified name of this Siprec, if one was given when the Siprec was created. This may be used to stop the Siprec.
  --parameter1-name: string # Parameter name
  --parameter1-value: string # Parameter value
  --parameter10-name: string # Parameter name
  --parameter10-value: string # Parameter value
  --parameter11-name: string # Parameter name
  --parameter11-value: string # Parameter value
  --parameter12-name: string # Parameter name
  --parameter12-value: string # Parameter value
  --parameter13-name: string # Parameter name
  --parameter13-value: string # Parameter value
  --parameter14-name: string # Parameter name
  --parameter14-value: string # Parameter value
  --parameter15-name: string # Parameter name
  --parameter15-value: string # Parameter value
  --parameter16-name: string # Parameter name
  --parameter16-value: string # Parameter value
  --parameter17-name: string # Parameter name
  --parameter17-value: string # Parameter value
  --parameter18-name: string # Parameter name
  --parameter18-value: string # Parameter value
  --parameter19-name: string # Parameter name
  --parameter19-value: string # Parameter value
  --parameter2-name: string # Parameter name
  --parameter2-value: string # Parameter value
  --parameter20-name: string # Parameter name
  --parameter20-value: string # Parameter value
  --parameter21-name: string # Parameter name
  --parameter21-value: string # Parameter value
  --parameter22-name: string # Parameter name
  --parameter22-value: string # Parameter value
  --parameter23-name: string # Parameter name
  --parameter23-value: string # Parameter value
  --parameter24-name: string # Parameter name
  --parameter24-value: string # Parameter value
  --parameter25-name: string # Parameter name
  --parameter25-value: string # Parameter value
  --parameter26-name: string # Parameter name
  --parameter26-value: string # Parameter value
  --parameter27-name: string # Parameter name
  --parameter27-value: string # Parameter value
  --parameter28-name: string # Parameter name
  --parameter28-value: string # Parameter value
  --parameter29-name: string # Parameter name
  --parameter29-value: string # Parameter value
  --parameter3-name: string # Parameter name
  --parameter3-value: string # Parameter value
  --parameter30-name: string # Parameter name
  --parameter30-value: string # Parameter value
  --parameter31-name: string # Parameter name
  --parameter31-value: string # Parameter value
  --parameter32-name: string # Parameter name
  --parameter32-value: string # Parameter value
  --parameter33-name: string # Parameter name
  --parameter33-value: string # Parameter value
  --parameter34-name: string # Parameter name
  --parameter34-value: string # Parameter value
  --parameter35-name: string # Parameter name
  --parameter35-value: string # Parameter value
  --parameter36-name: string # Parameter name
  --parameter36-value: string # Parameter value
  --parameter37-name: string # Parameter name
  --parameter37-value: string # Parameter value
  --parameter38-name: string # Parameter name
  --parameter38-value: string # Parameter value
  --parameter39-name: string # Parameter name
  --parameter39-value: string # Parameter value
  --parameter4-name: string # Parameter name
  --parameter4-value: string # Parameter value
  --parameter40-name: string # Parameter name
  --parameter40-value: string # Parameter value
  --parameter41-name: string # Parameter name
  --parameter41-value: string # Parameter value
  --parameter42-name: string # Parameter name
  --parameter42-value: string # Parameter value
  --parameter43-name: string # Parameter name
  --parameter43-value: string # Parameter value
  --parameter44-name: string # Parameter name
  --parameter44-value: string # Parameter value
  --parameter45-name: string # Parameter name
  --parameter45-value: string # Parameter value
  --parameter46-name: string # Parameter name
  --parameter46-value: string # Parameter value
  --parameter47-name: string # Parameter name
  --parameter47-value: string # Parameter value
  --parameter48-name: string # Parameter name
  --parameter48-value: string # Parameter value
  --parameter49-name: string # Parameter name
  --parameter49-value: string # Parameter value
  --parameter5-name: string # Parameter name
  --parameter5-value: string # Parameter value
  --parameter50-name: string # Parameter name
  --parameter50-value: string # Parameter value
  --parameter51-name: string # Parameter name
  --parameter51-value: string # Parameter value
  --parameter52-name: string # Parameter name
  --parameter52-value: string # Parameter value
  --parameter53-name: string # Parameter name
  --parameter53-value: string # Parameter value
  --parameter54-name: string # Parameter name
  --parameter54-value: string # Parameter value
  --parameter55-name: string # Parameter name
  --parameter55-value: string # Parameter value
  --parameter56-name: string # Parameter name
  --parameter56-value: string # Parameter value
  --parameter57-name: string # Parameter name
  --parameter57-value: string # Parameter value
  --parameter58-name: string # Parameter name
  --parameter58-value: string # Parameter value
  --parameter59-name: string # Parameter name
  --parameter59-value: string # Parameter value
  --parameter6-name: string # Parameter name
  --parameter6-value: string # Parameter value
  --parameter60-name: string # Parameter name
  --parameter60-value: string # Parameter value
  --parameter61-name: string # Parameter name
  --parameter61-value: string # Parameter value
  --parameter62-name: string # Parameter name
  --parameter62-value: string # Parameter value
  --parameter63-name: string # Parameter name
  --parameter63-value: string # Parameter value
  --parameter64-name: string # Parameter name
  --parameter64-value: string # Parameter value
  --parameter65-name: string # Parameter name
  --parameter65-value: string # Parameter value
  --parameter66-name: string # Parameter name
  --parameter66-value: string # Parameter value
  --parameter67-name: string # Parameter name
  --parameter67-value: string # Parameter value
  --parameter68-name: string # Parameter name
  --parameter68-value: string # Parameter value
  --parameter69-name: string # Parameter name
  --parameter69-value: string # Parameter value
  --parameter7-name: string # Parameter name
  --parameter7-value: string # Parameter value
  --parameter70-name: string # Parameter name
  --parameter70-value: string # Parameter value
  --parameter71-name: string # Parameter name
  --parameter71-value: string # Parameter value
  --parameter72-name: string # Parameter name
  --parameter72-value: string # Parameter value
  --parameter73-name: string # Parameter name
  --parameter73-value: string # Parameter value
  --parameter74-name: string # Parameter name
  --parameter74-value: string # Parameter value
  --parameter75-name: string # Parameter name
  --parameter75-value: string # Parameter value
  --parameter76-name: string # Parameter name
  --parameter76-value: string # Parameter value
  --parameter77-name: string # Parameter name
  --parameter77-value: string # Parameter value
  --parameter78-name: string # Parameter name
  --parameter78-value: string # Parameter value
  --parameter79-name: string # Parameter name
  --parameter79-value: string # Parameter value
  --parameter8-name: string # Parameter name
  --parameter8-value: string # Parameter value
  --parameter80-name: string # Parameter name
  --parameter80-value: string # Parameter value
  --parameter81-name: string # Parameter name
  --parameter81-value: string # Parameter value
  --parameter82-name: string # Parameter name
  --parameter82-value: string # Parameter value
  --parameter83-name: string # Parameter name
  --parameter83-value: string # Parameter value
  --parameter84-name: string # Parameter name
  --parameter84-value: string # Parameter value
  --parameter85-name: string # Parameter name
  --parameter85-value: string # Parameter value
  --parameter86-name: string # Parameter name
  --parameter86-value: string # Parameter value
  --parameter87-name: string # Parameter name
  --parameter87-value: string # Parameter value
  --parameter88-name: string # Parameter name
  --parameter88-value: string # Parameter value
  --parameter89-name: string # Parameter name
  --parameter89-value: string # Parameter value
  --parameter9-name: string # Parameter name
  --parameter9-value: string # Parameter value
  --parameter90-name: string # Parameter name
  --parameter90-value: string # Parameter value
  --parameter91-name: string # Parameter name
  --parameter91-value: string # Parameter value
  --parameter92-name: string # Parameter name
  --parameter92-value: string # Parameter value
  --parameter93-name: string # Parameter name
  --parameter93-value: string # Parameter value
  --parameter94-name: string # Parameter name
  --parameter94-value: string # Parameter value
  --parameter95-name: string # Parameter name
  --parameter95-value: string # Parameter value
  --parameter96-name: string # Parameter name
  --parameter96-value: string # Parameter value
  --parameter97-name: string # Parameter name
  --parameter97-value: string # Parameter value
  --parameter98-name: string # Parameter name
  --parameter98-value: string # Parameter value
  --parameter99-name: string # Parameter name
  --parameter99-value: string # Parameter value
  --status-callback: string # Absolute URL of the status callback. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The http method for the status_callback (one of GET, POST). (format: http-method)
  --track: string@track-completer
]: any -> record<account_sid: string, call_sid: string, date_updated: string, name: string, sid: string, status: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Siprec.json"))
  let body = {"ConnectorName": $connector_name, "Name": $name, "Parameter1.Name": $parameter1_name, "Parameter1.Value": $parameter1_value, "Parameter10.Name": $parameter10_name, "Parameter10.Value": $parameter10_value, "Parameter11.Name": $parameter11_name, "Parameter11.Value": $parameter11_value, "Parameter12.Name": $parameter12_name, "Parameter12.Value": $parameter12_value, "Parameter13.Name": $parameter13_name, "Parameter13.Value": $parameter13_value, "Parameter14.Name": $parameter14_name, "Parameter14.Value": $parameter14_value, "Parameter15.Name": $parameter15_name, "Parameter15.Value": $parameter15_value, "Parameter16.Name": $parameter16_name, "Parameter16.Value": $parameter16_value, "Parameter17.Name": $parameter17_name, "Parameter17.Value": $parameter17_value, "Parameter18.Name": $parameter18_name, "Parameter18.Value": $parameter18_value, "Parameter19.Name": $parameter19_name, "Parameter19.Value": $parameter19_value, "Parameter2.Name": $parameter2_name, "Parameter2.Value": $parameter2_value, "Parameter20.Name": $parameter20_name, "Parameter20.Value": $parameter20_value, "Parameter21.Name": $parameter21_name, "Parameter21.Value": $parameter21_value, "Parameter22.Name": $parameter22_name, "Parameter22.Value": $parameter22_value, "Parameter23.Name": $parameter23_name, "Parameter23.Value": $parameter23_value, "Parameter24.Name": $parameter24_name, "Parameter24.Value": $parameter24_value, "Parameter25.Name": $parameter25_name, "Parameter25.Value": $parameter25_value, "Parameter26.Name": $parameter26_name, "Parameter26.Value": $parameter26_value, "Parameter27.Name": $parameter27_name, "Parameter27.Value": $parameter27_value, "Parameter28.Name": $parameter28_name, "Parameter28.Value": $parameter28_value, "Parameter29.Name": $parameter29_name, "Parameter29.Value": $parameter29_value, "Parameter3.Name": $parameter3_name, "Parameter3.Value": $parameter3_value, "Parameter30.Name": $parameter30_name, "Parameter30.Value": $parameter30_value, "Parameter31.Name": $parameter31_name, "Parameter31.Value": $parameter31_value, "Parameter32.Name": $parameter32_name, "Parameter32.Value": $parameter32_value, "Parameter33.Name": $parameter33_name, "Parameter33.Value": $parameter33_value, "Parameter34.Name": $parameter34_name, "Parameter34.Value": $parameter34_value, "Parameter35.Name": $parameter35_name, "Parameter35.Value": $parameter35_value, "Parameter36.Name": $parameter36_name, "Parameter36.Value": $parameter36_value, "Parameter37.Name": $parameter37_name, "Parameter37.Value": $parameter37_value, "Parameter38.Name": $parameter38_name, "Parameter38.Value": $parameter38_value, "Parameter39.Name": $parameter39_name, "Parameter39.Value": $parameter39_value, "Parameter4.Name": $parameter4_name, "Parameter4.Value": $parameter4_value, "Parameter40.Name": $parameter40_name, "Parameter40.Value": $parameter40_value, "Parameter41.Name": $parameter41_name, "Parameter41.Value": $parameter41_value, "Parameter42.Name": $parameter42_name, "Parameter42.Value": $parameter42_value, "Parameter43.Name": $parameter43_name, "Parameter43.Value": $parameter43_value, "Parameter44.Name": $parameter44_name, "Parameter44.Value": $parameter44_value, "Parameter45.Name": $parameter45_name, "Parameter45.Value": $parameter45_value, "Parameter46.Name": $parameter46_name, "Parameter46.Value": $parameter46_value, "Parameter47.Name": $parameter47_name, "Parameter47.Value": $parameter47_value, "Parameter48.Name": $parameter48_name, "Parameter48.Value": $parameter48_value, "Parameter49.Name": $parameter49_name, "Parameter49.Value": $parameter49_value, "Parameter5.Name": $parameter5_name, "Parameter5.Value": $parameter5_value, "Parameter50.Name": $parameter50_name, "Parameter50.Value": $parameter50_value, "Parameter51.Name": $parameter51_name, "Parameter51.Value": $parameter51_value, "Parameter52.Name": $parameter52_name, "Parameter52.Value": $parameter52_value, "Parameter53.Name": $parameter53_name, "Parameter53.Value": $parameter53_value, "Parameter54.Name": $parameter54_name, "Parameter54.Value": $parameter54_value, "Parameter55.Name": $parameter55_name, "Parameter55.Value": $parameter55_value, "Parameter56.Name": $parameter56_name, "Parameter56.Value": $parameter56_value, "Parameter57.Name": $parameter57_name, "Parameter57.Value": $parameter57_value, "Parameter58.Name": $parameter58_name, "Parameter58.Value": $parameter58_value, "Parameter59.Name": $parameter59_name, "Parameter59.Value": $parameter59_value, "Parameter6.Name": $parameter6_name, "Parameter6.Value": $parameter6_value, "Parameter60.Name": $parameter60_name, "Parameter60.Value": $parameter60_value, "Parameter61.Name": $parameter61_name, "Parameter61.Value": $parameter61_value, "Parameter62.Name": $parameter62_name, "Parameter62.Value": $parameter62_value, "Parameter63.Name": $parameter63_name, "Parameter63.Value": $parameter63_value, "Parameter64.Name": $parameter64_name, "Parameter64.Value": $parameter64_value, "Parameter65.Name": $parameter65_name, "Parameter65.Value": $parameter65_value, "Parameter66.Name": $parameter66_name, "Parameter66.Value": $parameter66_value, "Parameter67.Name": $parameter67_name, "Parameter67.Value": $parameter67_value, "Parameter68.Name": $parameter68_name, "Parameter68.Value": $parameter68_value, "Parameter69.Name": $parameter69_name, "Parameter69.Value": $parameter69_value, "Parameter7.Name": $parameter7_name, "Parameter7.Value": $parameter7_value, "Parameter70.Name": $parameter70_name, "Parameter70.Value": $parameter70_value, "Parameter71.Name": $parameter71_name, "Parameter71.Value": $parameter71_value, "Parameter72.Name": $parameter72_name, "Parameter72.Value": $parameter72_value, "Parameter73.Name": $parameter73_name, "Parameter73.Value": $parameter73_value, "Parameter74.Name": $parameter74_name, "Parameter74.Value": $parameter74_value, "Parameter75.Name": $parameter75_name, "Parameter75.Value": $parameter75_value, "Parameter76.Name": $parameter76_name, "Parameter76.Value": $parameter76_value, "Parameter77.Name": $parameter77_name, "Parameter77.Value": $parameter77_value, "Parameter78.Name": $parameter78_name, "Parameter78.Value": $parameter78_value, "Parameter79.Name": $parameter79_name, "Parameter79.Value": $parameter79_value, "Parameter8.Name": $parameter8_name, "Parameter8.Value": $parameter8_value, "Parameter80.Name": $parameter80_name, "Parameter80.Value": $parameter80_value, "Parameter81.Name": $parameter81_name, "Parameter81.Value": $parameter81_value, "Parameter82.Name": $parameter82_name, "Parameter82.Value": $parameter82_value, "Parameter83.Name": $parameter83_name, "Parameter83.Value": $parameter83_value, "Parameter84.Name": $parameter84_name, "Parameter84.Value": $parameter84_value, "Parameter85.Name": $parameter85_name, "Parameter85.Value": $parameter85_value, "Parameter86.Name": $parameter86_name, "Parameter86.Value": $parameter86_value, "Parameter87.Name": $parameter87_name, "Parameter87.Value": $parameter87_value, "Parameter88.Name": $parameter88_name, "Parameter88.Value": $parameter88_value, "Parameter89.Name": $parameter89_name, "Parameter89.Value": $parameter89_value, "Parameter9.Name": $parameter9_name, "Parameter9.Value": $parameter9_value, "Parameter90.Name": $parameter90_name, "Parameter90.Value": $parameter90_value, "Parameter91.Name": $parameter91_name, "Parameter91.Value": $parameter91_value, "Parameter92.Name": $parameter92_name, "Parameter92.Value": $parameter92_value, "Parameter93.Name": $parameter93_name, "Parameter93.Value": $parameter93_value, "Parameter94.Name": $parameter94_name, "Parameter94.Value": $parameter94_value, "Parameter95.Name": $parameter95_name, "Parameter95.Value": $parameter95_value, "Parameter96.Name": $parameter96_name, "Parameter96.Value": $parameter96_value, "Parameter97.Name": $parameter97_name, "Parameter97.Value": $parameter97_value, "Parameter98.Name": $parameter98_name, "Parameter98.Value": $parameter98_value, "Parameter99.Name": $parameter99_name, "Parameter99.Value": $parameter99_value, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "Track": $track} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Stop a Siprec using either the SID of the Siprec resource or the `name` used when creating the resource
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Siprec/{Sid}.json
# operationId: UpdateSiprec
export def "2010-04-01-accounts-calls-siprec update" [
  account_sid: string
  call_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-4
]: any -> record<account_sid: string, call_sid: string, date_updated: string, name: string, sid: string, status: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Siprec/{sid}.json"))
  let body = {"Status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a Stream
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Streams.json
# operationId: CreateStream
export def "2010-04-01-accounts-calls-streamsjson create-stream" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The user-specified name of this Stream, if one was given when the Stream was created. This may be used to stop the Stream.
  --parameter1-name: string # Parameter name
  --parameter1-value: string # Parameter value
  --parameter10-name: string # Parameter name
  --parameter10-value: string # Parameter value
  --parameter11-name: string # Parameter name
  --parameter11-value: string # Parameter value
  --parameter12-name: string # Parameter name
  --parameter12-value: string # Parameter value
  --parameter13-name: string # Parameter name
  --parameter13-value: string # Parameter value
  --parameter14-name: string # Parameter name
  --parameter14-value: string # Parameter value
  --parameter15-name: string # Parameter name
  --parameter15-value: string # Parameter value
  --parameter16-name: string # Parameter name
  --parameter16-value: string # Parameter value
  --parameter17-name: string # Parameter name
  --parameter17-value: string # Parameter value
  --parameter18-name: string # Parameter name
  --parameter18-value: string # Parameter value
  --parameter19-name: string # Parameter name
  --parameter19-value: string # Parameter value
  --parameter2-name: string # Parameter name
  --parameter2-value: string # Parameter value
  --parameter20-name: string # Parameter name
  --parameter20-value: string # Parameter value
  --parameter21-name: string # Parameter name
  --parameter21-value: string # Parameter value
  --parameter22-name: string # Parameter name
  --parameter22-value: string # Parameter value
  --parameter23-name: string # Parameter name
  --parameter23-value: string # Parameter value
  --parameter24-name: string # Parameter name
  --parameter24-value: string # Parameter value
  --parameter25-name: string # Parameter name
  --parameter25-value: string # Parameter value
  --parameter26-name: string # Parameter name
  --parameter26-value: string # Parameter value
  --parameter27-name: string # Parameter name
  --parameter27-value: string # Parameter value
  --parameter28-name: string # Parameter name
  --parameter28-value: string # Parameter value
  --parameter29-name: string # Parameter name
  --parameter29-value: string # Parameter value
  --parameter3-name: string # Parameter name
  --parameter3-value: string # Parameter value
  --parameter30-name: string # Parameter name
  --parameter30-value: string # Parameter value
  --parameter31-name: string # Parameter name
  --parameter31-value: string # Parameter value
  --parameter32-name: string # Parameter name
  --parameter32-value: string # Parameter value
  --parameter33-name: string # Parameter name
  --parameter33-value: string # Parameter value
  --parameter34-name: string # Parameter name
  --parameter34-value: string # Parameter value
  --parameter35-name: string # Parameter name
  --parameter35-value: string # Parameter value
  --parameter36-name: string # Parameter name
  --parameter36-value: string # Parameter value
  --parameter37-name: string # Parameter name
  --parameter37-value: string # Parameter value
  --parameter38-name: string # Parameter name
  --parameter38-value: string # Parameter value
  --parameter39-name: string # Parameter name
  --parameter39-value: string # Parameter value
  --parameter4-name: string # Parameter name
  --parameter4-value: string # Parameter value
  --parameter40-name: string # Parameter name
  --parameter40-value: string # Parameter value
  --parameter41-name: string # Parameter name
  --parameter41-value: string # Parameter value
  --parameter42-name: string # Parameter name
  --parameter42-value: string # Parameter value
  --parameter43-name: string # Parameter name
  --parameter43-value: string # Parameter value
  --parameter44-name: string # Parameter name
  --parameter44-value: string # Parameter value
  --parameter45-name: string # Parameter name
  --parameter45-value: string # Parameter value
  --parameter46-name: string # Parameter name
  --parameter46-value: string # Parameter value
  --parameter47-name: string # Parameter name
  --parameter47-value: string # Parameter value
  --parameter48-name: string # Parameter name
  --parameter48-value: string # Parameter value
  --parameter49-name: string # Parameter name
  --parameter49-value: string # Parameter value
  --parameter5-name: string # Parameter name
  --parameter5-value: string # Parameter value
  --parameter50-name: string # Parameter name
  --parameter50-value: string # Parameter value
  --parameter51-name: string # Parameter name
  --parameter51-value: string # Parameter value
  --parameter52-name: string # Parameter name
  --parameter52-value: string # Parameter value
  --parameter53-name: string # Parameter name
  --parameter53-value: string # Parameter value
  --parameter54-name: string # Parameter name
  --parameter54-value: string # Parameter value
  --parameter55-name: string # Parameter name
  --parameter55-value: string # Parameter value
  --parameter56-name: string # Parameter name
  --parameter56-value: string # Parameter value
  --parameter57-name: string # Parameter name
  --parameter57-value: string # Parameter value
  --parameter58-name: string # Parameter name
  --parameter58-value: string # Parameter value
  --parameter59-name: string # Parameter name
  --parameter59-value: string # Parameter value
  --parameter6-name: string # Parameter name
  --parameter6-value: string # Parameter value
  --parameter60-name: string # Parameter name
  --parameter60-value: string # Parameter value
  --parameter61-name: string # Parameter name
  --parameter61-value: string # Parameter value
  --parameter62-name: string # Parameter name
  --parameter62-value: string # Parameter value
  --parameter63-name: string # Parameter name
  --parameter63-value: string # Parameter value
  --parameter64-name: string # Parameter name
  --parameter64-value: string # Parameter value
  --parameter65-name: string # Parameter name
  --parameter65-value: string # Parameter value
  --parameter66-name: string # Parameter name
  --parameter66-value: string # Parameter value
  --parameter67-name: string # Parameter name
  --parameter67-value: string # Parameter value
  --parameter68-name: string # Parameter name
  --parameter68-value: string # Parameter value
  --parameter69-name: string # Parameter name
  --parameter69-value: string # Parameter value
  --parameter7-name: string # Parameter name
  --parameter7-value: string # Parameter value
  --parameter70-name: string # Parameter name
  --parameter70-value: string # Parameter value
  --parameter71-name: string # Parameter name
  --parameter71-value: string # Parameter value
  --parameter72-name: string # Parameter name
  --parameter72-value: string # Parameter value
  --parameter73-name: string # Parameter name
  --parameter73-value: string # Parameter value
  --parameter74-name: string # Parameter name
  --parameter74-value: string # Parameter value
  --parameter75-name: string # Parameter name
  --parameter75-value: string # Parameter value
  --parameter76-name: string # Parameter name
  --parameter76-value: string # Parameter value
  --parameter77-name: string # Parameter name
  --parameter77-value: string # Parameter value
  --parameter78-name: string # Parameter name
  --parameter78-value: string # Parameter value
  --parameter79-name: string # Parameter name
  --parameter79-value: string # Parameter value
  --parameter8-name: string # Parameter name
  --parameter8-value: string # Parameter value
  --parameter80-name: string # Parameter name
  --parameter80-value: string # Parameter value
  --parameter81-name: string # Parameter name
  --parameter81-value: string # Parameter value
  --parameter82-name: string # Parameter name
  --parameter82-value: string # Parameter value
  --parameter83-name: string # Parameter name
  --parameter83-value: string # Parameter value
  --parameter84-name: string # Parameter name
  --parameter84-value: string # Parameter value
  --parameter85-name: string # Parameter name
  --parameter85-value: string # Parameter value
  --parameter86-name: string # Parameter name
  --parameter86-value: string # Parameter value
  --parameter87-name: string # Parameter name
  --parameter87-value: string # Parameter value
  --parameter88-name: string # Parameter name
  --parameter88-value: string # Parameter value
  --parameter89-name: string # Parameter name
  --parameter89-value: string # Parameter value
  --parameter9-name: string # Parameter name
  --parameter9-value: string # Parameter value
  --parameter90-name: string # Parameter name
  --parameter90-value: string # Parameter value
  --parameter91-name: string # Parameter name
  --parameter91-value: string # Parameter value
  --parameter92-name: string # Parameter name
  --parameter92-value: string # Parameter value
  --parameter93-name: string # Parameter name
  --parameter93-value: string # Parameter value
  --parameter94-name: string # Parameter name
  --parameter94-value: string # Parameter value
  --parameter95-name: string # Parameter name
  --parameter95-value: string # Parameter value
  --parameter96-name: string # Parameter name
  --parameter96-value: string # Parameter value
  --parameter97-name: string # Parameter name
  --parameter97-value: string # Parameter value
  --parameter98-name: string # Parameter name
  --parameter98-value: string # Parameter value
  --parameter99-name: string # Parameter name
  --parameter99-value: string # Parameter value
  --status-callback: string # Absolute URL of the status callback. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The http method for the status_callback (one of GET, POST). (format: http-method)
  --track: string@track-completer
  --body-url: string # Relative or absolute url where WebSocket connection will be established. (format: uri)
]: any -> record<account_sid: string, call_sid: string, date_updated: string, name: string, sid: string, status: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Streams.json"))
  let body = {"Name": $name, "Parameter1.Name": $parameter1_name, "Parameter1.Value": $parameter1_value, "Parameter10.Name": $parameter10_name, "Parameter10.Value": $parameter10_value, "Parameter11.Name": $parameter11_name, "Parameter11.Value": $parameter11_value, "Parameter12.Name": $parameter12_name, "Parameter12.Value": $parameter12_value, "Parameter13.Name": $parameter13_name, "Parameter13.Value": $parameter13_value, "Parameter14.Name": $parameter14_name, "Parameter14.Value": $parameter14_value, "Parameter15.Name": $parameter15_name, "Parameter15.Value": $parameter15_value, "Parameter16.Name": $parameter16_name, "Parameter16.Value": $parameter16_value, "Parameter17.Name": $parameter17_name, "Parameter17.Value": $parameter17_value, "Parameter18.Name": $parameter18_name, "Parameter18.Value": $parameter18_value, "Parameter19.Name": $parameter19_name, "Parameter19.Value": $parameter19_value, "Parameter2.Name": $parameter2_name, "Parameter2.Value": $parameter2_value, "Parameter20.Name": $parameter20_name, "Parameter20.Value": $parameter20_value, "Parameter21.Name": $parameter21_name, "Parameter21.Value": $parameter21_value, "Parameter22.Name": $parameter22_name, "Parameter22.Value": $parameter22_value, "Parameter23.Name": $parameter23_name, "Parameter23.Value": $parameter23_value, "Parameter24.Name": $parameter24_name, "Parameter24.Value": $parameter24_value, "Parameter25.Name": $parameter25_name, "Parameter25.Value": $parameter25_value, "Parameter26.Name": $parameter26_name, "Parameter26.Value": $parameter26_value, "Parameter27.Name": $parameter27_name, "Parameter27.Value": $parameter27_value, "Parameter28.Name": $parameter28_name, "Parameter28.Value": $parameter28_value, "Parameter29.Name": $parameter29_name, "Parameter29.Value": $parameter29_value, "Parameter3.Name": $parameter3_name, "Parameter3.Value": $parameter3_value, "Parameter30.Name": $parameter30_name, "Parameter30.Value": $parameter30_value, "Parameter31.Name": $parameter31_name, "Parameter31.Value": $parameter31_value, "Parameter32.Name": $parameter32_name, "Parameter32.Value": $parameter32_value, "Parameter33.Name": $parameter33_name, "Parameter33.Value": $parameter33_value, "Parameter34.Name": $parameter34_name, "Parameter34.Value": $parameter34_value, "Parameter35.Name": $parameter35_name, "Parameter35.Value": $parameter35_value, "Parameter36.Name": $parameter36_name, "Parameter36.Value": $parameter36_value, "Parameter37.Name": $parameter37_name, "Parameter37.Value": $parameter37_value, "Parameter38.Name": $parameter38_name, "Parameter38.Value": $parameter38_value, "Parameter39.Name": $parameter39_name, "Parameter39.Value": $parameter39_value, "Parameter4.Name": $parameter4_name, "Parameter4.Value": $parameter4_value, "Parameter40.Name": $parameter40_name, "Parameter40.Value": $parameter40_value, "Parameter41.Name": $parameter41_name, "Parameter41.Value": $parameter41_value, "Parameter42.Name": $parameter42_name, "Parameter42.Value": $parameter42_value, "Parameter43.Name": $parameter43_name, "Parameter43.Value": $parameter43_value, "Parameter44.Name": $parameter44_name, "Parameter44.Value": $parameter44_value, "Parameter45.Name": $parameter45_name, "Parameter45.Value": $parameter45_value, "Parameter46.Name": $parameter46_name, "Parameter46.Value": $parameter46_value, "Parameter47.Name": $parameter47_name, "Parameter47.Value": $parameter47_value, "Parameter48.Name": $parameter48_name, "Parameter48.Value": $parameter48_value, "Parameter49.Name": $parameter49_name, "Parameter49.Value": $parameter49_value, "Parameter5.Name": $parameter5_name, "Parameter5.Value": $parameter5_value, "Parameter50.Name": $parameter50_name, "Parameter50.Value": $parameter50_value, "Parameter51.Name": $parameter51_name, "Parameter51.Value": $parameter51_value, "Parameter52.Name": $parameter52_name, "Parameter52.Value": $parameter52_value, "Parameter53.Name": $parameter53_name, "Parameter53.Value": $parameter53_value, "Parameter54.Name": $parameter54_name, "Parameter54.Value": $parameter54_value, "Parameter55.Name": $parameter55_name, "Parameter55.Value": $parameter55_value, "Parameter56.Name": $parameter56_name, "Parameter56.Value": $parameter56_value, "Parameter57.Name": $parameter57_name, "Parameter57.Value": $parameter57_value, "Parameter58.Name": $parameter58_name, "Parameter58.Value": $parameter58_value, "Parameter59.Name": $parameter59_name, "Parameter59.Value": $parameter59_value, "Parameter6.Name": $parameter6_name, "Parameter6.Value": $parameter6_value, "Parameter60.Name": $parameter60_name, "Parameter60.Value": $parameter60_value, "Parameter61.Name": $parameter61_name, "Parameter61.Value": $parameter61_value, "Parameter62.Name": $parameter62_name, "Parameter62.Value": $parameter62_value, "Parameter63.Name": $parameter63_name, "Parameter63.Value": $parameter63_value, "Parameter64.Name": $parameter64_name, "Parameter64.Value": $parameter64_value, "Parameter65.Name": $parameter65_name, "Parameter65.Value": $parameter65_value, "Parameter66.Name": $parameter66_name, "Parameter66.Value": $parameter66_value, "Parameter67.Name": $parameter67_name, "Parameter67.Value": $parameter67_value, "Parameter68.Name": $parameter68_name, "Parameter68.Value": $parameter68_value, "Parameter69.Name": $parameter69_name, "Parameter69.Value": $parameter69_value, "Parameter7.Name": $parameter7_name, "Parameter7.Value": $parameter7_value, "Parameter70.Name": $parameter70_name, "Parameter70.Value": $parameter70_value, "Parameter71.Name": $parameter71_name, "Parameter71.Value": $parameter71_value, "Parameter72.Name": $parameter72_name, "Parameter72.Value": $parameter72_value, "Parameter73.Name": $parameter73_name, "Parameter73.Value": $parameter73_value, "Parameter74.Name": $parameter74_name, "Parameter74.Value": $parameter74_value, "Parameter75.Name": $parameter75_name, "Parameter75.Value": $parameter75_value, "Parameter76.Name": $parameter76_name, "Parameter76.Value": $parameter76_value, "Parameter77.Name": $parameter77_name, "Parameter77.Value": $parameter77_value, "Parameter78.Name": $parameter78_name, "Parameter78.Value": $parameter78_value, "Parameter79.Name": $parameter79_name, "Parameter79.Value": $parameter79_value, "Parameter8.Name": $parameter8_name, "Parameter8.Value": $parameter8_value, "Parameter80.Name": $parameter80_name, "Parameter80.Value": $parameter80_value, "Parameter81.Name": $parameter81_name, "Parameter81.Value": $parameter81_value, "Parameter82.Name": $parameter82_name, "Parameter82.Value": $parameter82_value, "Parameter83.Name": $parameter83_name, "Parameter83.Value": $parameter83_value, "Parameter84.Name": $parameter84_name, "Parameter84.Value": $parameter84_value, "Parameter85.Name": $parameter85_name, "Parameter85.Value": $parameter85_value, "Parameter86.Name": $parameter86_name, "Parameter86.Value": $parameter86_value, "Parameter87.Name": $parameter87_name, "Parameter87.Value": $parameter87_value, "Parameter88.Name": $parameter88_name, "Parameter88.Value": $parameter88_value, "Parameter89.Name": $parameter89_name, "Parameter89.Value": $parameter89_value, "Parameter9.Name": $parameter9_name, "Parameter9.Value": $parameter9_value, "Parameter90.Name": $parameter90_name, "Parameter90.Value": $parameter90_value, "Parameter91.Name": $parameter91_name, "Parameter91.Value": $parameter91_value, "Parameter92.Name": $parameter92_name, "Parameter92.Value": $parameter92_value, "Parameter93.Name": $parameter93_name, "Parameter93.Value": $parameter93_value, "Parameter94.Name": $parameter94_name, "Parameter94.Value": $parameter94_value, "Parameter95.Name": $parameter95_name, "Parameter95.Value": $parameter95_value, "Parameter96.Name": $parameter96_name, "Parameter96.Value": $parameter96_value, "Parameter97.Name": $parameter97_name, "Parameter97.Value": $parameter97_value, "Parameter98.Name": $parameter98_name, "Parameter98.Value": $parameter98_value, "Parameter99.Name": $parameter99_name, "Parameter99.Value": $parameter99_value, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "Track": $track, "Url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Stop a Stream using either the SID of the Stream resource or the `name` used when creating the resource
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/Streams/{Sid}.json
# operationId: UpdateStream
export def "2010-04-01-accounts-calls-streams update" [
  account_sid: string
  call_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-4
]: any -> record<account_sid: string, call_sid: string, date_updated: string, name: string, sid: string, status: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/Streams/{sid}.json"))
  let body = {"Status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Subscribe to User Defined Messages for a given Call SID.
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/UserDefinedMessageSubscriptions.json
# operationId: CreateUserDefinedMessageSubscription
export def "2010-04-01-accounts-calls-user-defined-message-subscriptionsjson create-user-defined-message-subscription" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  callback: string # The URL we should call using the `method` to send user defined events to your application. URLs must contain a valid hostname (underscores are not permitted). (format: uri)
  --idempotency-key: string # A unique string value to identify API call. This should be a unique string value per API call and can be a randomly generated.
  --method: string@method-completer # The HTTP method Twilio will use when requesting the above `Url`. Either `GET` or `POST`. Default is `POST`. (format: http-method)
]: any -> record<account_sid: string, call_sid: string, date_created: string, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/UserDefinedMessageSubscriptions.json"))
  let body = {"Callback": $callback, "IdempotencyKey": $idempotency_key, "Method": $method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific User Defined Message Subscription.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/UserDefinedMessageSubscriptions/{Sid}.json
# operationId: DeleteUserDefinedMessageSubscription
export def "2010-04-01-accounts-calls-user-defined-message-subscriptions delete" [
  account_sid: string
  call_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/UserDefinedMessageSubscriptions/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new User Defined Message for the given Call SID.
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{CallSid}/UserDefinedMessages.json
# operationId: CreateUserDefinedMessage
export def "2010-04-01-accounts-calls-user-defined-messagesjson create-user-defined-message" [
  account_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # The User Defined Message in the form of URL-encoded JSON string.
  --idempotency-key: string # A unique string value to identify API call. This should be a unique string value per API call and can be a randomly generated.
]: any -> record<account_sid: string, call_sid: string, date_created: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{call_sid}/UserDefinedMessages.json"))
  let body = {"Content": $content, "IdempotencyKey": $idempotency_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a Call record from your account. Once the record is deleted, it will no longer appear in the API and Account Portal logs.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Calls/{Sid}.json
# operationId: DeleteCall
export def "2010-04-01-accounts-calls delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the call specified by the provided Call SID
#
# GET /2010-04-01/Accounts/{AccountSid}/Calls/{Sid}.json
# operationId: FetchCall
export def "2010-04-01-accounts-calls get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, answered_by: string, api_version: string, caller_name: string, date_created: string, date_updated: string, direction: string, duration: string, end_time: string, forwarded_from: string, from: string, from_formatted: string, group_sid: string, parent_call_sid: string, phone_number_sid: string, price: string, price_unit: string, queue_time: string, sid: string, start_time: string, status: string, subresource_uris: record, to: string, to_formatted: string, trunk_sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiates a call redirect or terminates a call
#
# POST /2010-04-01/Accounts/{AccountSid}/Calls/{Sid}.json
# operationId: UpdateCall
export def "2010-04-01-accounts-calls update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fallback-method: string@fallback-method-completer # The HTTP method that we should use to request the `fallback_url`. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --fallback-url: string # The URL that we call using the `fallback_method` if an error occurs when requesting or executing the TwiML at `url`. If an `application_sid` parameter is present, this parameter is ignored. (format: uri)
  --method: string@method-completer # The HTTP method we should use when calling the `url`. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --status: string@status-completer-5
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. If no `status_callback_event` is specified, we will send the `completed` status. If an `application_sid` parameter is present, this parameter is ignored. URLs must contain a valid hostname (underscores are not permitted). (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use when requesting the `status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. If an `application_sid` parameter is present, this parameter is ignored. (format: http-method)
  --time-limit: int # The maximum duration of the call in seconds. Constraints depend on account and configuration.
  --twiml: string # TwiML instructions for the call Twilio will use without fetching Twiml from url. Twiml and url parameters are mutually exclusive (format: twiml)
  --body-url: string # The absolute URL that returns the TwiML instructions for the call. We will call this URL using the `method` when the call connects. For more information, see the [Url Parameter](https://www.twilio.com/docs/voice/make-calls#specify-a-url-parameter) section in [Making Calls](https://www.twilio.com/docs/voice/make-calls). (format: uri)
]: any -> record<account_sid: string, answered_by: string, api_version: string, caller_name: string, date_created: string, date_updated: string, direction: string, duration: string, end_time: string, forwarded_from: string, from: string, from_formatted: string, group_sid: string, parent_call_sid: string, phone_number_sid: string, price: string, price_unit: string, queue_time: string, sid: string, start_time: string, status: string, subresource_uris: record, to: string, to_formatted: string, trunk_sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Calls/{sid}.json"))
  let body = {"FallbackMethod": $fallback_method, "FallbackUrl": $fallback_url, "Method": $method, "Status": $status, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "TimeLimit": $time_limit, "Twiml": $twiml, "Url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of conferences belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences.json
# operationId: ListConference
export def "2010-04-01-accounts-conferencesjson list-conference" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. To read conferences that started on or before midnight on a date, use `<=YYYY-MM-DD`, and to specify  conferences that started on or after midnight on a date, use `>=YYYY-MM-DD`. (format: date)
  --date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. To read conferences that started on or before midnight on a date, use `<=YYYY-MM-DD`, and to specify  conferences that started on or after midnight on a date, use `>=YYYY-MM-DD`. (format: date)
  --date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. To read conferences that started on or before midnight on a date, use `<=YYYY-MM-DD`, and to specify  conferences that started on or after midnight on a date, use `>=YYYY-MM-DD`. (format: date)
  --date-updated: string # The `date_updated` value, specified as `YYYY-MM-DD`, of the resources to read. To read conferences that were last updated on or before midnight on a date, use `<=YYYY-MM-DD`, and to specify conferences that were last updated on or after midnight on a given date, use  `>=YYYY-MM-DD`. (format: date)
  --date-updated: string # The `date_updated` value, specified as `YYYY-MM-DD`, of the resources to read. To read conferences that were last updated on or before midnight on a date, use `<=YYYY-MM-DD`, and to specify conferences that were last updated on or after midnight on a given date, use  `>=YYYY-MM-DD`. (format: date)
  --date-updated: string # The `date_updated` value, specified as `YYYY-MM-DD`, of the resources to read. To read conferences that were last updated on or before midnight on a date, use `<=YYYY-MM-DD`, and to specify conferences that were last updated on or after midnight on a given date, use  `>=YYYY-MM-DD`. (format: date)
  --friendly-name: string # The string that identifies the Conference resources to read.
  --status: string@status-completer-6 # The status of the resources to read. Can be: `init`, `in-progress`, or `completed`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<conferences: table<account_sid: string, api_version: string, call_sid_ending_conference: string, date_created: string, date_updated: string, friendly_name: string, reason_conference_ended: string, region: string, sid: string, status: string, subresource_uris: record, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "DateCreated" $date_created "scalar") (serialize-qp "DateCreated<" $date_created "scalar") (serialize-qp "DateCreated>" $date_created "scalar") (serialize-qp "DateUpdated" $date_updated "scalar") (serialize-qp "DateUpdated<" $date_updated "scalar") (serialize-qp "DateUpdated>" $date_updated "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Conferences.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of participants belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants.json
# operationId: ListParticipant
export def "2010-04-01-accounts-conferences-participantsjson list-participant" [
  account_sid: string
  conference_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --muted: oneof<nothing, bool> # Whether to return only participants that are muted. Can be: `true` or `false`.
  --hold: oneof<nothing, bool> # Whether to return only participants that are on hold. Can be: `true` or `false`.
  --coaching: oneof<nothing, bool> # Whether to return only participants who are coaching another call. Can be: `true` or `false`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, participants: table<account_sid: string, call_sid: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, hold: bool, label: string, muted: bool, start_conference_on_enter: bool, status: string, uri: string>, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Muted" $muted "scalar") (serialize-qp "Hold" $hold "scalar") (serialize-qp "Coaching" $coaching "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, conference_sid: $conference_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Conferences/{conference_sid}/Participants.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants.json
#
# operationId: CreateParticipant
export def "2010-04-01-accounts-conferences-participantsjson create-participant" [
  account_sid: string
  conference_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amd-status-callback: string # The URL that we should call using the `amd_status_callback_method` to notify customer application whether the call was answered by human, machine or fax. (format: uri)
  --amd-status-callback-method: string@amd-status-callback-method-completer # The HTTP method we should use when calling the `amd_status_callback` URL. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --beep: string # Whether to play a notification beep to the conference when the participant joins. Can be: `true`, `false`, `onEnter`, or `onExit`. The default value is `true`.
  --byoc: string # The SID of a BYOC (Bring Your Own Carrier) trunk to route this call with. Note that `byoc` is only meaningful when `to` is a phone number; it will otherwise be ignored. (Beta)
  --call-reason: string # The Reason for the outgoing call. Use it to specify the purpose of the call that is presented on the called party's phone. (Branded Calls Beta)
  --call-sid-to-coach: string # The SID of the participant who is being `coached`. The participant being coached is the only participant who can hear the participant who is `coaching`.
  --caller-id: string # The phone number, Client identifier, or username portion of SIP address that made this call. Phone numbers are in [E.164](https://www.twilio.com/docs/glossary/what-e164) format (e.g., +16175551212). Client identifiers are formatted `client:name`. If using a phone number, it must be a Twilio number or a Verified [outgoing caller id](https://www.twilio.com/docs/voice/api/outgoing-caller-ids) for your account. If the `to` parameter is a phone number, `callerId` must also be a phone number. If `to` is sip address, this value of `callerId` should be a username portion to be used to populate the From header that is passed to the SIP endpoint.
  --coaching: oneof<nothing, bool> # Whether the participant is coaching another call. Can be: `true` or `false`. If not present, defaults to `false` unless `call_sid_to_coach` is defined. If `true`, `call_sid_to_coach` must be defined.
  --conference-record: string # Whether to record the conference the participant is joining. Can be: `true`, `false`, `record-from-start`, and `do-not-record`. The default value is `false`.
  --conference-recording-status-callback: string # The URL we should call using the `conference_recording_status_callback_method` when the conference recording is available. (format: uri)
  --conference-recording-status-callback-event: list # The conference recording state changes that generate a call to `conference_recording_status_callback`. Can be: `in-progress`, `completed`, `failed`, and `absent`. Separate multiple values with a space, ex: `'in-progress completed failed'`
  --conference-recording-status-callback-method: string@conference-recording-status-callback-method-completer # The HTTP method we should use to call `conference_recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --conference-status-callback: string # The URL we should call using the `conference_status_callback_method` when the conference events in `conference_status_callback_event` occur. Only the value set by the first participant to join the conference is used. Subsequent `conference_status_callback` values are ignored. (format: uri)
  --conference-status-callback-event: list # The conference state changes that should generate a call to `conference_status_callback`. Can be: `start`, `end`, `join`, `leave`, `mute`, `hold`, `modify`, `speaker`, and `announcement`. Separate multiple values with a space. Defaults to `start end`.
  --conference-status-callback-method: string@conference-status-callback-method-completer # The HTTP method we should use to call `conference_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --conference-trim: string # Whether to trim leading and trailing silence from your recorded conference audio files. Can be: `trim-silence` or `do-not-trim` and defaults to `trim-silence`.
  --early-media: oneof<nothing, bool> # Whether to allow an agent to hear the state of the outbound call, including ringing or disconnect messages. Can be: `true` or `false` and defaults to `true`.
  --end-conference-on-exit: oneof<nothing, bool> # Whether to end the conference when the participant leaves. Can be: `true` or `false` and defaults to `false`.
  --body-from: string # The phone number, Client identifier, or username portion of SIP address that made this call. Phone numbers are in [E.164](https://www.twilio.com/docs/glossary/what-e164) format (e.g., +16175551212). Client identifiers are formatted `client:name`. If using a phone number, it must be a Twilio number or a Verified [outgoing caller id](https://www.twilio.com/docs/voice/api/outgoing-caller-ids) for your account. If the `to` parameter is a phone number, `from` must also be a phone number. If `to` is sip address, this value of `from` should be a username portion to be used to populate the P-Asserted-Identity header that is passed to the SIP endpoint. (format: endpoint)
  --jitter-buffer-size: string # Jitter buffer size for the connecting participant. Twilio will use this setting to apply Jitter Buffer before participant's audio is mixed into the conference. Can be: `off`, `small`, `medium`, and `large`. Default to `large`.
  --label: string # A label for this participant. If one is supplied, it may subsequently be used to fetch, update or delete the participant.
  --machine-detection: string # Whether to detect if a human, answering machine, or fax has picked up the call. Can be: `Enable` or `DetectMessageEnd`. Use `Enable` if you would like us to return `AnsweredBy` as soon as the called party is identified. Use `DetectMessageEnd`, if you would like to leave a message on an answering machine. If `send_digits` is provided, this parameter is ignored. For more information, see [Answering Machine Detection](https://www.twilio.com/docs/voice/answering-machine-detection).
  --machine-detection-silence-timeout: int # The number of milliseconds of initial silence after which an `unknown` AnsweredBy result will be returned. Possible Values: 2000-10000. Default: 5000.
  --machine-detection-speech-end-threshold: int # The number of milliseconds of silence after speech activity at which point the speech activity is considered complete. Possible Values: 500-5000. Default: 1200.
  --machine-detection-speech-threshold: int # The number of milliseconds that is used as the measuring stick for the length of the speech activity, where durations lower than this value will be interpreted as a human and longer than this value as a machine. Possible Values: 1000-6000. Default: 2400.
  --machine-detection-timeout: int # The number of seconds that we should attempt to detect an answering machine before timing out and sending a voice request with `AnsweredBy` of `unknown`. The default timeout is 30 seconds.
  --max-participants: int # The maximum number of participants in the conference. Can be a positive integer from `2` to `250`. The default value is `250`.
  --muted: oneof<nothing, bool> # Whether the agent is muted in the conference. Can be `true` or `false` and the default is `false`.
  --record: oneof<nothing, bool> # Whether to record the participant and their conferences, including the time between conferences. Can be `true` or `false` and the default is `false`.
  --recording-channels: string # The recording channels for the final recording. Can be: `mono` or `dual` and the default is `mono`.
  --recording-status-callback: string # The URL that we should call using the `recording_status_callback_method` when the recording status changes. (format: uri)
  --recording-status-callback-event: list # The recording state changes that should generate a call to `recording_status_callback`. Can be: `started`, `in-progress`, `paused`, `resumed`, `stopped`, `completed`, `failed`, and `absent`. Separate multiple values with a space, ex: `'in-progress completed failed'`.
  --recording-status-callback-method: string@recording-status-callback-method-completer # The HTTP method we should use when we call `recording_status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --recording-track: string # The audio track to record for the call. Can be: `inbound`, `outbound` or `both`. The default is `both`. `inbound` records the audio that is received by Twilio. `outbound` records the audio that is sent from Twilio. `both` records the audio that is received and sent by Twilio.
  --region: string # The [region](https://support.twilio.com/hc/en-us/articles/223132167-How-global-low-latency-routing-and-region-selection-work-for-conferences-and-Client-calls) where we should mix the recorded audio. Can be:`us1`, `ie1`, `de1`, `sg1`, `br1`, `au1`, or `jp1`.
  --sip-auth-password: string # The SIP password for authentication.
  --sip-auth-username: string # The SIP username used for authentication.
  --start-conference-on-enter: oneof<nothing, bool> # Whether to start the conference when the participant joins, if it has not already started. Can be: `true` or `false` and the default is `true`. If `false` and the conference has not started, the participant is muted and hears background music until another participant starts the conference.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-event: list # The conference state changes that should generate a call to `status_callback`. Can be: `initiated`, `ringing`, `answered`, and `completed`. Separate multiple values with a space. The default value is `completed`.
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` and `POST` and defaults to `POST`. (format: http-method)
  --time-limit: int # The maximum duration of the call in seconds. Constraints depend on account and configuration.
  --timeout: int # The number of seconds that we should allow the phone to ring before assuming there is no answer. Can be an integer between `5` and `600`, inclusive. The default value is `60`. We always add a 5-second timeout buffer to outgoing calls, so  value of 10 would result in an actual timeout that was closer to 15 seconds.
  --body-to: string # The phone number, SIP address, or Client identifier that received this call. Phone numbers are in [E.164](https://www.twilio.com/docs/glossary/what-e164) format (e.g., +16175551212). SIP addresses are formatted as `sip:name@company.com`. Client identifiers are formatted `client:name`. [Custom parameters](https://www.twilio.com/docs/voice/api/conference-participant-resource#custom-parameters) may also be specified. (format: endpoint)
  --wait-method: string@wait-method-completer # The HTTP method we should use to call `wait_url`. Can be `GET` or `POST` and the default is `POST`. When using a static audio file, this should be `GET` so that we can cache the file. (format: http-method)
  --wait-url: string # The URL we should call using the `wait_method` for the music to play while participants are waiting for the conference to start. The default value is the URL of our standard hold music. [Learn more about hold music](https://www.twilio.com/labs/twimlets/holdmusic). (format: uri)
]: any -> record<account_sid: string, call_sid: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, hold: bool, label: string, muted: bool, start_conference_on_enter: bool, status: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, conference_sid: $conference_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Conferences/{conference_sid}/Participants.json"))
  let body = {"AmdStatusCallback": $amd_status_callback, "AmdStatusCallbackMethod": $amd_status_callback_method, "Beep": $beep, "Byoc": $byoc, "CallReason": $call_reason, "CallSidToCoach": $call_sid_to_coach, "CallerId": $caller_id, "Coaching": $coaching, "ConferenceRecord": $conference_record, "ConferenceRecordingStatusCallback": $conference_recording_status_callback, "ConferenceRecordingStatusCallbackEvent": $conference_recording_status_callback_event, "ConferenceRecordingStatusCallbackMethod": $conference_recording_status_callback_method, "ConferenceStatusCallback": $conference_status_callback, "ConferenceStatusCallbackEvent": $conference_status_callback_event, "ConferenceStatusCallbackMethod": $conference_status_callback_method, "ConferenceTrim": $conference_trim, "EarlyMedia": $early_media, "EndConferenceOnExit": $end_conference_on_exit, "From": $body_from, "JitterBufferSize": $jitter_buffer_size, "Label": $label, "MachineDetection": $machine_detection, "MachineDetectionSilenceTimeout": $machine_detection_silence_timeout, "MachineDetectionSpeechEndThreshold": $machine_detection_speech_end_threshold, "MachineDetectionSpeechThreshold": $machine_detection_speech_threshold, "MachineDetectionTimeout": $machine_detection_timeout, "MaxParticipants": $max_participants, "Muted": $muted, "Record": $record, "RecordingChannels": $recording_channels, "RecordingStatusCallback": $recording_status_callback, "RecordingStatusCallbackEvent": $recording_status_callback_event, "RecordingStatusCallbackMethod": $recording_status_callback_method, "RecordingTrack": $recording_track, "Region": $region, "SipAuthPassword": $sip_auth_password, "SipAuthUsername": $sip_auth_username, "StartConferenceOnEnter": $start_conference_on_enter, "StatusCallback": $status_callback, "StatusCallbackEvent": $status_callback_event, "StatusCallbackMethod": $status_callback_method, "TimeLimit": $time_limit, "Timeout": $timeout, "To": $body_to, "WaitMethod": $wait_method, "WaitUrl": $wait_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Kick a participant from a given conference
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants/{CallSid}.json
# operationId: DeleteParticipant
export def "2010-04-01-accounts-conferences-participants delete" [
  account_sid: string
  conference_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, conference_sid: $conference_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Conferences/{conference_sid}/Participants/{call_sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of a participant
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants/{CallSid}.json
# operationId: FetchParticipant
export def "2010-04-01-accounts-conferences-participants get" [
  account_sid: string
  conference_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, call_sid: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, hold: bool, label: string, muted: bool, start_conference_on_enter: bool, status: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, conference_sid: $conference_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Conferences/{conference_sid}/Participants/{call_sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the properties of the participant
#
# POST /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Participants/{CallSid}.json
# operationId: UpdateParticipant
export def "2010-04-01-accounts-conferences-participants update" [
  account_sid: string
  conference_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --announce-method: string@announce-method-completer # The HTTP method we should use to call `announce_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --announce-url: string # The URL we call using the `announce_method` for an announcement to the participant. The URL may return an MP3 file, a WAV file, or a TwiML document that contains `<Play>`, `<Say>`, `<Pause>`, or `<Redirect>` verbs. (format: uri)
  --beep-on-exit: oneof<nothing, bool> # Whether to play a notification beep to the conference when the participant exits. Can be: `true` or `false`.
  --call-sid-to-coach: string # The SID of the participant who is being `coached`. The participant being coached is the only participant who can hear the participant who is `coaching`.
  --coaching: oneof<nothing, bool> # Whether the participant is coaching another call. Can be: `true` or `false`. If not present, defaults to `false` unless `call_sid_to_coach` is defined. If `true`, `call_sid_to_coach` must be defined.
  --end-conference-on-exit: oneof<nothing, bool> # Whether to end the conference when the participant leaves. Can be: `true` or `false` and defaults to `false`.
  --hold: oneof<nothing, bool> # Whether the participant should be on hold. Can be: `true` or `false`. `true` puts the participant on hold, and `false` lets them rejoin the conference.
  --hold-method: string@hold-method-completer # The HTTP method we should use to call `hold_url`. Can be: `GET` or `POST` and the default is `GET`. (format: http-method)
  --hold-url: string # The URL we call using the `hold_method` for music that plays when the participant is on hold. The URL may return an MP3 file, a WAV file, or a TwiML document that contains `<Play>`, `<Say>`, `<Pause>`, or `<Redirect>` verbs. (format: uri)
  --muted: oneof<nothing, bool> # Whether the participant should be muted. Can be `true` or `false`. `true` will mute the participant, and `false` will un-mute them. Anything value other than `true` or `false` is interpreted as `false`.
  --wait-method: string@wait-method-completer # The HTTP method we should use to call `wait_url`. Can be `GET` or `POST` and the default is `POST`. When using a static audio file, this should be `GET` so that we can cache the file. (format: http-method)
  --wait-url: string # The URL we call using the `wait_method` for the music to play while participants are waiting for the conference to start. The URL may return an MP3 file, a WAV file, or a TwiML document that contains `<Play>`, `<Say>`, `<Pause>`, or `<Redirect>` verbs. The default value is the URL of our standard hold music. [Learn more about hold music](https://www.twilio.com/labs/twimlets/holdmusic). (format: uri)
]: any -> record<account_sid: string, call_sid: string, call_sid_to_coach: string, coaching: bool, conference_sid: string, date_created: string, date_updated: string, end_conference_on_exit: bool, hold: bool, label: string, muted: bool, start_conference_on_enter: bool, status: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, conference_sid: $conference_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Conferences/{conference_sid}/Participants/{call_sid}.json"))
  let body = {"AnnounceMethod": $announce_method, "AnnounceUrl": $announce_url, "BeepOnExit": $beep_on_exit, "CallSidToCoach": $call_sid_to_coach, "Coaching": $coaching, "EndConferenceOnExit": $end_conference_on_exit, "Hold": $hold, "HoldMethod": $hold_method, "HoldUrl": $hold_url, "Muted": $muted, "WaitMethod": $wait_method, "WaitUrl": $wait_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of recordings belonging to the call used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings.json
# operationId: ListConferenceRecording
export def "2010-04-01-accounts-conferences-recordingsjson list-conference-recording" [
  account_sid: string
  conference_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --date-created: string # The `date_created` value, specified as `YYYY-MM-DD`, of the resources to read. You can also specify inequality: `DateCreated<=YYYY-MM-DD` will return recordings generated at or before midnight on a given date, and `DateCreated>=YYYY-MM-DD` returns recordings generated at or after midnight on a date. (format: date)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, recordings: table<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, uri: string>, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "DateCreated" $date_created "scalar") (serialize-qp "DateCreated<" $date_created "scalar") (serialize-qp "DateCreated>" $date_created "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, conference_sid: $conference_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Conferences/{conference_sid}/Recordings.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a recording from your account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings/{Sid}.json
# operationId: DeleteConferenceRecording
export def "2010-04-01-accounts-conferences-recordings delete" [
  account_sid: string
  conference_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, conference_sid: $conference_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Conferences/{conference_sid}/Recordings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of a recording for a call
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings/{Sid}.json
# operationId: FetchConferenceRecording
export def "2010-04-01-accounts-conferences-recordings get" [
  account_sid: string
  conference_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, conference_sid: $conference_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Conferences/{conference_sid}/Recordings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Changes the status of the recording to paused, stopped, or in-progress. Note: To use `Twilio.CURRENT`, pass it as recording sid.
#
# POST /2010-04-01/Accounts/{AccountSid}/Conferences/{ConferenceSid}/Recordings/{Sid}.json
# operationId: UpdateConferenceRecording
export def "2010-04-01-accounts-conferences-recordings update" [
  account_sid: string
  conference_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pause-behavior: string # Whether to record during a pause. Can be: `skip` or `silence` and the default is `silence`. `skip` does not record during the pause period, while `silence` will replace the actual audio of the call with silence during the pause period. This parameter only applies when setting `status` is set to `paused`.
  status: string@status-completer-3
]: any -> record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, conference_sid: $conference_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Conferences/{conference_sid}/Recordings/{sid}.json"))
  let body = {"PauseBehavior": $pause_behavior, "Status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an instance of a conference
#
# GET /2010-04-01/Accounts/{AccountSid}/Conferences/{Sid}.json
# operationId: FetchConference
export def "2010-04-01-accounts-conferences get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, api_version: string, call_sid_ending_conference: string, date_created: string, date_updated: string, friendly_name: string, reason_conference_ended: string, region: string, sid: string, status: string, subresource_uris: record, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Conferences/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/Conferences/{Sid}.json
#
# operationId: UpdateConference
export def "2010-04-01-accounts-conferences update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --announce-method: string@announce-method-completer # The HTTP method used to call `announce_url`. Can be: `GET` or `POST` and the default is `POST` (format: http-method)
  --announce-url: string # The URL we should call to announce something into the conference. The URL may return an MP3 file, a WAV file, or a TwiML document that contains `<Play>`, `<Say>`, `<Pause>`, or `<Redirect>` verbs. (format: uri)
  --status: string@status-completer-7
]: any -> record<account_sid: string, api_version: string, call_sid_ending_conference: string, date_created: string, date_updated: string, friendly_name: string, reason_conference_ended: string, region: string, sid: string, status: string, subresource_uris: record, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Conferences/{sid}.json"))
  let body = {"AnnounceMethod": $announce_method, "AnnounceUrl": $announce_url, "Status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of connect-apps belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/ConnectApps.json
# operationId: ListConnectApp
export def "2010-04-01-accounts-connect-appsjson list-connect-app" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<connect_apps: table<account_sid: string, authorize_redirect_url: string, company_name: string, deauthorize_callback_method: string, deauthorize_callback_url: string, description: string, friendly_name: string, homepage_url: string, permissions: list, sid: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/ConnectApps.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an instance of a connect-app
#
# DELETE /2010-04-01/Accounts/{AccountSid}/ConnectApps/{Sid}.json
# operationId: DeleteConnectApp
export def "2010-04-01-accounts-connect-apps delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/ConnectApps/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of a connect-app
#
# GET /2010-04-01/Accounts/{AccountSid}/ConnectApps/{Sid}.json
# operationId: FetchConnectApp
export def "2010-04-01-accounts-connect-apps get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, authorize_redirect_url: string, company_name: string, deauthorize_callback_method: string, deauthorize_callback_url: string, description: string, friendly_name: string, homepage_url: string, permissions: list<string>, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/ConnectApps/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a connect-app with the specified parameters
#
# POST /2010-04-01/Accounts/{AccountSid}/ConnectApps/{Sid}.json
# operationId: UpdateConnectApp
export def "2010-04-01-accounts-connect-apps update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorize-redirect-url: string # The URL to redirect the user to after we authenticate the user and obtain authorization to access the Connect App. (format: uri)
  --company-name: string # The company name to set for the Connect App.
  --deauthorize-callback-method: string@deauthorize-callback-method-completer # The HTTP method to use when calling `deauthorize_callback_url`. (format: http-method)
  --deauthorize-callback-url: string # The URL to call using the `deauthorize_callback_method` to de-authorize the Connect App. (format: uri)
  --description: string # A description of the Connect App.
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --homepage-url: string # A public URL where users can obtain more information about this Connect App. (format: uri)
  --permissions: list # A comma-separated list of the permissions you will request from the users of this ConnectApp.  Can include: `get-all` and `post-all`.
]: any -> record<account_sid: string, authorize_redirect_url: string, company_name: string, deauthorize_callback_method: string, deauthorize_callback_url: string, description: string, friendly_name: string, homepage_url: string, permissions: list<string>, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/ConnectApps/{sid}.json"))
  let body = {"AuthorizeRedirectUrl": $authorize_redirect_url, "CompanyName": $company_name, "DeauthorizeCallbackMethod": $deauthorize_callback_method, "DeauthorizeCallbackUrl": $deauthorize_callback_url, "Description": $description, "FriendlyName": $friendly_name, "HomepageUrl": $homepage_url, "Permissions": $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of incoming-phone-numbers belonging to the account used to make the request.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers.json
# operationId: ListIncomingPhoneNumber
export def "2010-04-01-accounts-incoming-phone-numbersjson list-incoming-phone-number" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --beta: oneof<nothing, bool> # Whether to include phone numbers new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --friendly-name: string # A string that identifies the IncomingPhoneNumber resources to read.
  --phone-number: string # The phone numbers of the IncomingPhoneNumber resources to read. You can specify partial numbers and use '*' as a wildcard for any digit. (format: phone-number)
  --origin: string # Whether to include phone numbers based on their origin. Can be: `twilio` or `hosted`. By default, phone numbers of all origin are included.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, incoming_phone_numbers: table<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Beta" $beta "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PhoneNumber" $phone_number "scalar") (serialize-qp "Origin" $origin "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Purchase a phone-number for the account.
#
# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers.json
# operationId: CreateIncomingPhoneNumber
export def "2010-04-01-accounts-incoming-phone-numbersjson create-incoming-phone-number" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-sid: string # The SID of the Address resource we should associate with the new phone number. Some regions require addresses to meet local regulations.
  --api-version: string # The API version to use for incoming calls made to the new phone number. The default is `2010-04-01`.
  --area-code: string # The desired area code for your new incoming phone number. Can be any three-digit, US or Canada area code. We will provision an available phone number within this area code for you. **You must provide an `area_code` or a `phone_number`.** (US and Canada only).
  --bundle-sid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
  --emergency-address-sid: string # The SID of the emergency address configuration to use for emergency calling from the new phone number.
  --emergency-status: string@emergency-status-completer
  --friendly-name: string # A descriptive string that you created to describe the new phone number. It can be up to 64 characters long. By default, this is a formatted version of the new phone number.
  --identity-sid: string # The SID of the Identity resource that we should associate with the new phone number. Some regions require an identity to meet local regulations.
  --phone-number: string # The phone number to purchase specified in [E.164](https://www.twilio.com/docs/glossary/what-e164) format.  E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --sms-application-sid: string # The SID of the application that should handle SMS messages sent to the new phone number. If an `sms_application_sid` is present, we ignore all of the `sms_*_url` urls and use those set on the application.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-url: string # The URL we should call when the new phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --trunk-sid: string # The SID of the Trunk we should use to handle calls to the new phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --voice-application-sid: string # The SID of the application we should use to handle calls to the new phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use only those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-receive-mode: string@voice-receive-mode-completer
  --voice-url: string # The URL that we should call to answer a call to the new phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
]: any -> record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers.json"))
  let body = {"AddressSid": $address_sid, "ApiVersion": $api_version, "AreaCode": $area_code, "BundleSid": $bundle_sid, "EmergencyAddressSid": $emergency_address_sid, "EmergencyStatus": $emergency_status, "FriendlyName": $friendly_name, "IdentitySid": $identity_sid, "PhoneNumber": $phone_number, "SmsApplicationSid": $sms_application_sid, "SmsFallbackMethod": $sms_fallback_method, "SmsFallbackUrl": $sms_fallback_url, "SmsMethod": $sms_method, "SmsUrl": $sms_url, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "TrunkSid": $trunk_sid, "VoiceApplicationSid": $voice_application_sid, "VoiceCallerIdLookup": $voice_caller_id_lookup, "VoiceFallbackMethod": $voice_fallback_method, "VoiceFallbackUrl": $voice_fallback_url, "VoiceMethod": $voice_method, "VoiceReceiveMode": $voice_receive_mode, "VoiceUrl": $voice_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Local.json
#
# operationId: ListIncomingPhoneNumberLocal
export def "2010-04-01-accounts-incoming-phone-numbers-localjson list-incoming-phone-number-local" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --beta: oneof<nothing, bool> # Whether to include phone numbers new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --friendly-name: string # A string that identifies the resources to read.
  --phone-number: string # The phone numbers of the IncomingPhoneNumber resources to read. You can specify partial numbers and use '*' as a wildcard for any digit. (format: phone-number)
  --origin: string # Whether to include phone numbers based on their origin. Can be: `twilio` or `hosted`. By default, phone numbers of all origin are included.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, incoming_phone_numbers: table<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Beta" $beta "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PhoneNumber" $phone_number "scalar") (serialize-qp "Origin" $origin "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/Local.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Local.json
#
# operationId: CreateIncomingPhoneNumberLocal
export def "2010-04-01-accounts-incoming-phone-numbers-localjson create-incoming-phone-number-local" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-sid: string # The SID of the Address resource we should associate with the new phone number. Some regions require addresses to meet local regulations.
  --api-version: string # The API version to use for incoming calls made to the new phone number. The default is `2010-04-01`.
  --bundle-sid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
  --emergency-address-sid: string # The SID of the emergency address configuration to use for emergency calling from the new phone number.
  --emergency-status: string@emergency-status-completer
  --friendly-name: string # A descriptive string that you created to describe the new phone number. It can be up to 64 characters long. By default, this is a formatted version of the phone number.
  --identity-sid: string # The SID of the Identity resource that we should associate with the new phone number. Some regions require an identity to meet local regulations.
  phone_number: string # The phone number to purchase specified in [E.164](https://www.twilio.com/docs/glossary/what-e164) format.  E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --sms-application-sid: string # The SID of the application that should handle SMS messages sent to the new phone number. If an `sms_application_sid` is present, we ignore all of the `sms_*_url` urls and use those set on the application.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-url: string # The URL we should call when the new phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --trunk-sid: string # The SID of the Trunk we should use to handle calls to the new phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --voice-application-sid: string # The SID of the application we should use to handle calls to the new phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use only those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-receive-mode: string@voice-receive-mode-completer
  --voice-url: string # The URL that we should call to answer a call to the new phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
]: any -> record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/Local.json"))
  let body = {"AddressSid": $address_sid, "ApiVersion": $api_version, "BundleSid": $bundle_sid, "EmergencyAddressSid": $emergency_address_sid, "EmergencyStatus": $emergency_status, "FriendlyName": $friendly_name, "IdentitySid": $identity_sid, "PhoneNumber": $phone_number, "SmsApplicationSid": $sms_application_sid, "SmsFallbackMethod": $sms_fallback_method, "SmsFallbackUrl": $sms_fallback_url, "SmsMethod": $sms_method, "SmsUrl": $sms_url, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "TrunkSid": $trunk_sid, "VoiceApplicationSid": $voice_application_sid, "VoiceCallerIdLookup": $voice_caller_id_lookup, "VoiceFallbackMethod": $voice_fallback_method, "VoiceFallbackUrl": $voice_fallback_url, "VoiceMethod": $voice_method, "VoiceReceiveMode": $voice_receive_mode, "VoiceUrl": $voice_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Mobile.json
#
# operationId: ListIncomingPhoneNumberMobile
export def "2010-04-01-accounts-incoming-phone-numbers-mobilejson list-incoming-phone-number-mobile" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --beta: oneof<nothing, bool> # Whether to include phone numbers new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --friendly-name: string # A string that identifies the resources to read.
  --phone-number: string # The phone numbers of the IncomingPhoneNumber resources to read. You can specify partial numbers and use '*' as a wildcard for any digit. (format: phone-number)
  --origin: string # Whether to include phone numbers based on their origin. Can be: `twilio` or `hosted`. By default, phone numbers of all origin are included.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, incoming_phone_numbers: table<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Beta" $beta "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PhoneNumber" $phone_number "scalar") (serialize-qp "Origin" $origin "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/Mobile.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/Mobile.json
#
# operationId: CreateIncomingPhoneNumberMobile
export def "2010-04-01-accounts-incoming-phone-numbers-mobilejson create-incoming-phone-number-mobile" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-sid: string # The SID of the Address resource we should associate with the new phone number. Some regions require addresses to meet local regulations.
  --api-version: string # The API version to use for incoming calls made to the new phone number. The default is `2010-04-01`.
  --bundle-sid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
  --emergency-address-sid: string # The SID of the emergency address configuration to use for emergency calling from the new phone number.
  --emergency-status: string@emergency-status-completer
  --friendly-name: string # A descriptive string that you created to describe the new phone number. It can be up to 64 characters long. By default, the is a formatted version of the phone number.
  --identity-sid: string # The SID of the Identity resource that we should associate with the new phone number. Some regions require an identity to meet local regulations.
  phone_number: string # The phone number to purchase specified in [E.164](https://www.twilio.com/docs/glossary/what-e164) format.  E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --sms-application-sid: string # The SID of the application that should handle SMS messages sent to the new phone number. If an `sms_application_sid` is present, we ignore all of the `sms_*_url` urls and use those of the application.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-url: string # The URL we should call when the new phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --trunk-sid: string # The SID of the Trunk we should use to handle calls to the new phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --voice-application-sid: string # The SID of the application we should use to handle calls to the new phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use only those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-receive-mode: string@voice-receive-mode-completer
  --voice-url: string # The URL that we should call to answer a call to the new phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
]: any -> record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/Mobile.json"))
  let body = {"AddressSid": $address_sid, "ApiVersion": $api_version, "BundleSid": $bundle_sid, "EmergencyAddressSid": $emergency_address_sid, "EmergencyStatus": $emergency_status, "FriendlyName": $friendly_name, "IdentitySid": $identity_sid, "PhoneNumber": $phone_number, "SmsApplicationSid": $sms_application_sid, "SmsFallbackMethod": $sms_fallback_method, "SmsFallbackUrl": $sms_fallback_url, "SmsMethod": $sms_method, "SmsUrl": $sms_url, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "TrunkSid": $trunk_sid, "VoiceApplicationSid": $voice_application_sid, "VoiceCallerIdLookup": $voice_caller_id_lookup, "VoiceFallbackMethod": $voice_fallback_method, "VoiceFallbackUrl": $voice_fallback_url, "VoiceMethod": $voice_method, "VoiceReceiveMode": $voice_receive_mode, "VoiceUrl": $voice_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/TollFree.json
#
# operationId: ListIncomingPhoneNumberTollFree
export def "2010-04-01-accounts-incoming-phone-numbers-toll-freejson list-incoming-phone-number-toll-free" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --beta: oneof<nothing, bool> # Whether to include phone numbers new to the Twilio platform. Can be: `true` or `false` and the default is `true`.
  --friendly-name: string # A string that identifies the resources to read.
  --phone-number: string # The phone numbers of the IncomingPhoneNumber resources to read. You can specify partial numbers and use '*' as a wildcard for any digit. (format: phone-number)
  --origin: string # Whether to include phone numbers based on their origin. Can be: `twilio` or `hosted`. By default, phone numbers of all origin are included.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, incoming_phone_numbers: table<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Beta" $beta "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PhoneNumber" $phone_number "scalar") (serialize-qp "Origin" $origin "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/TollFree.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/TollFree.json
#
# operationId: CreateIncomingPhoneNumberTollFree
export def "2010-04-01-accounts-incoming-phone-numbers-toll-freejson create-incoming-phone-number-toll-free" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-sid: string # The SID of the Address resource we should associate with the new phone number. Some regions require addresses to meet local regulations.
  --api-version: string # The API version to use for incoming calls made to the new phone number. The default is `2010-04-01`.
  --bundle-sid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
  --emergency-address-sid: string # The SID of the emergency address configuration to use for emergency calling from the new phone number.
  --emergency-status: string@emergency-status-completer
  --friendly-name: string # A descriptive string that you created to describe the new phone number. It can be up to 64 characters long. By default, this is a formatted version of the phone number.
  --identity-sid: string # The SID of the Identity resource that we should associate with the new phone number. Some regions require an Identity to meet local regulations.
  phone_number: string # The phone number to purchase specified in [E.164](https://www.twilio.com/docs/glossary/what-e164) format.  E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --sms-application-sid: string # The SID of the application that should handle SMS messages sent to the new phone number. If an `sms_application_sid` is present, we ignore all `sms_*_url` values and use those of the application.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-url: string # The URL we should call when the new phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --trunk-sid: string # The SID of the Trunk we should use to handle calls to the new phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --voice-application-sid: string # The SID of the application we should use to handle calls to the new phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-receive-mode: string@voice-receive-mode-completer
  --voice-url: string # The URL that we should call to answer a call to the new phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
]: any -> record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/TollFree.json"))
  let body = {"AddressSid": $address_sid, "ApiVersion": $api_version, "BundleSid": $bundle_sid, "EmergencyAddressSid": $emergency_address_sid, "EmergencyStatus": $emergency_status, "FriendlyName": $friendly_name, "IdentitySid": $identity_sid, "PhoneNumber": $phone_number, "SmsApplicationSid": $sms_application_sid, "SmsFallbackMethod": $sms_fallback_method, "SmsFallbackUrl": $sms_fallback_url, "SmsMethod": $sms_method, "SmsUrl": $sms_url, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "TrunkSid": $trunk_sid, "VoiceApplicationSid": $voice_application_sid, "VoiceCallerIdLookup": $voice_caller_id_lookup, "VoiceFallbackMethod": $voice_fallback_method, "VoiceFallbackUrl": $voice_fallback_url, "VoiceMethod": $voice_method, "VoiceReceiveMode": $voice_receive_mode, "VoiceUrl": $voice_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of Add-on installations currently assigned to this Number.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns.json
# operationId: ListIncomingPhoneNumberAssignedAddOn
export def "2010-04-01-accounts-incoming-phone-numbers-assigned-add-onsjson list-incoming-phone-number-assigned-add-on" [
  account_sid: string
  resource_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<assigned_add_ons: table<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, resource_sid: string, sid: string, subresource_uris: record, unique_name: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, resource_sid: $resource_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/{resource_sid}/AssignedAddOns.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign an Add-on installation to the Number specified.
#
# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns.json
# operationId: CreateIncomingPhoneNumberAssignedAddOn
export def "2010-04-01-accounts-incoming-phone-numbers-assigned-add-onsjson create-incoming-phone-number-assigned-add-on" [
  account_sid: string
  resource_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  installed_add_on_sid: string # The SID that identifies the Add-on installation.
]: any -> record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, resource_sid: string, sid: string, subresource_uris: record, unique_name: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, resource_sid: $resource_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/{resource_sid}/AssignedAddOns.json"))
  let body = {"InstalledAddOnSid": $installed_add_on_sid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of Extensions for the Assigned Add-on.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{AssignedAddOnSid}/Extensions.json
# operationId: ListIncomingPhoneNumberAssignedAddOnExtension
export def "2010-04-01-accounts-incoming-phone-numbers-assigned-add-ons-extensionsjson list-incoming-phone-number-assigned-add-on-extension" [
  account_sid: string
  resource_sid: string
  assigned_add_on_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, extensions: table<account_sid: string, assigned_add_on_sid: string, enabled: bool, friendly_name: string, product_name: string, resource_sid: string, sid: string, unique_name: string, uri: string>, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, resource_sid: $resource_sid, assigned_add_on_sid: $assigned_add_on_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/{resource_sid}/AssignedAddOns/{assigned_add_on_sid}/Extensions.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of an Extension for the Assigned Add-on.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{AssignedAddOnSid}/Extensions/{Sid}.json
# operationId: FetchIncomingPhoneNumberAssignedAddOnExtension
export def "2010-04-01-accounts-incoming-phone-numbers-assigned-add-ons-extensions get" [
  account_sid: string
  resource_sid: string
  assigned_add_on_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, assigned_add_on_sid: string, enabled: bool, friendly_name: string, product_name: string, resource_sid: string, sid: string, unique_name: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, resource_sid: $resource_sid, assigned_add_on_sid: $assigned_add_on_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/{resource_sid}/AssignedAddOns/{assigned_add_on_sid}/Extensions/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove the assignment of an Add-on installation from the Number specified.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{Sid}.json
# operationId: DeleteIncomingPhoneNumberAssignedAddOn
export def "2010-04-01-accounts-incoming-phone-numbers-assigned-add-ons delete" [
  account_sid: string
  resource_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, resource_sid: $resource_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/{resource_sid}/AssignedAddOns/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of an Add-on installation currently assigned to this Number.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{ResourceSid}/AssignedAddOns/{Sid}.json
# operationId: FetchIncomingPhoneNumberAssignedAddOn
export def "2010-04-01-accounts-incoming-phone-numbers-assigned-add-ons get" [
  account_sid: string
  resource_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, configuration: any, date_created: string, date_updated: string, description: string, friendly_name: string, resource_sid: string, sid: string, subresource_uris: record, unique_name: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, resource_sid: $resource_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/{resource_sid}/AssignedAddOns/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a phone-numbers belonging to the account used to make the request.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{Sid}.json
# operationId: DeleteIncomingPhoneNumber
export def "2010-04-01-accounts-incoming-phone-numbers delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an incoming-phone-number belonging to the account used to make the request.
#
# GET /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{Sid}.json
# operationId: FetchIncomingPhoneNumber
export def "2010-04-01-accounts-incoming-phone-numbers get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an incoming-phone-number instance.
#
# POST /2010-04-01/Accounts/{AccountSid}/IncomingPhoneNumbers/{Sid}.json
# operationId: UpdateIncomingPhoneNumber
export def "2010-04-01-accounts-incoming-phone-numbers update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-account-sid: string # The SID of the [Account](https://www.twilio.com/docs/iam/api/account) that created the IncomingPhoneNumber resource to update.  For more information, see [Exchanging Numbers Between Subaccounts](https://www.twilio.com/docs/iam/api/subaccounts#exchanging-numbers).
  --address-sid: string # The SID of the Address resource we should associate with the phone number. Some regions require addresses to meet local regulations.
  --api-version: string # The API version to use for incoming calls made to the phone number. The default is `2010-04-01`.
  --bundle-sid: string # The SID of the Bundle resource that you associate with the phone number. Some regions require a Bundle to meet local Regulations.
  --emergency-address-sid: string # The SID of the emergency address configuration to use for emergency calling from this phone number.
  --emergency-status: string@emergency-status-completer
  --friendly-name: string # A descriptive string that you created to describe this phone number. It can be up to 64 characters long. By default, this is a formatted version of the phone number.
  --identity-sid: string # The SID of the Identity resource that we should associate with the phone number. Some regions require an identity to meet local regulations.
  --sms-application-sid: string # The SID of the application that should handle SMS messages sent to the number. If an `sms_application_sid` is present, we ignore all of the `sms_*_url` urls and use those set on the application.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that we should use to call `sms_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call when an error occurs while requesting or executing the TwiML defined by `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method that we should use to call `sms_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --sms-url: string # The URL we should call when the phone number receives an incoming SMS message. (format: uri)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --trunk-sid: string # The SID of the Trunk we should use to handle phone calls to the phone number. If a `trunk_sid` is present, we ignore all of the voice urls and voice applications and use only those set on the Trunk. Setting a `trunk_sid` will automatically delete your `voice_application_sid` and vice versa.
  --voice-application-sid: string # The SID of the application we should use to handle phone calls to the phone number. If a `voice_application_sid` is present, we ignore all of the voice urls and use only those set on the application. Setting a `voice_application_sid` will automatically delete your `trunk_sid` and vice versa.
  --voice-caller-id-lookup: oneof<nothing, bool> # Whether to lookup the caller's name from the CNAM database and post it to your app. Can be: `true` or `false` and defaults to `false`.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method that we should use to call `voice_fallback_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs retrieving or executing the TwiML requested by `url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method that we should use to call `voice_url`. Can be: `GET` or `POST` and defaults to `POST`. (format: http-method)
  --voice-receive-mode: string@voice-receive-mode-completer
  --voice-url: string # The URL that we should call to answer a call to the phone number. The `voice_url` will not be called if a `voice_application_sid` or a `trunk_sid` is set. (format: uri)
]: any -> record<account_sid: string, address_requirements: string, address_sid: string, api_version: string, beta: bool, bundle_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, emergency_address_sid: string, emergency_address_status: string, emergency_status: string, friendly_name: string, identity_sid: string, origin: string, phone_number: string, sid: string, sms_application_sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, status_callback: string, status_callback_method: string, trunk_sid: string, uri: string, voice_application_sid: string, voice_caller_id_lookup: bool, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_receive_mode: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/IncomingPhoneNumbers/{sid}.json"))
  let body = {"AccountSid": $body_account_sid, "AddressSid": $address_sid, "ApiVersion": $api_version, "BundleSid": $bundle_sid, "EmergencyAddressSid": $emergency_address_sid, "EmergencyStatus": $emergency_status, "FriendlyName": $friendly_name, "IdentitySid": $identity_sid, "SmsApplicationSid": $sms_application_sid, "SmsFallbackMethod": $sms_fallback_method, "SmsFallbackUrl": $sms_fallback_url, "SmsMethod": $sms_method, "SmsUrl": $sms_url, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "TrunkSid": $trunk_sid, "VoiceApplicationSid": $voice_application_sid, "VoiceCallerIdLookup": $voice_caller_id_lookup, "VoiceFallbackMethod": $voice_fallback_method, "VoiceFallbackUrl": $voice_fallback_url, "VoiceMethod": $voice_method, "VoiceReceiveMode": $voice_receive_mode, "VoiceUrl": $voice_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/Keys.json
#
# operationId: ListKey
export def "2010-04-01-accounts-keysjson list-key" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, keys: table<date_created: string, date_updated: string, friendly_name: string, sid: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Keys.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/Keys.json
#
# operationId: CreateNewKey
export def "2010-04-01-accounts-keysjson create-new-key" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> record<date_created: string, date_updated: string, friendly_name: string, secret: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Keys.json"))
  let body = {"FriendlyName": $friendly_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /2010-04-01/Accounts/{AccountSid}/Keys/{Sid}.json
#
# operationId: DeleteKey
export def "2010-04-01-accounts-keys delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Keys/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Keys/{Sid}.json
#
# operationId: FetchKey
export def "2010-04-01-accounts-keys get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Keys/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/Keys/{Sid}.json
#
# operationId: UpdateKey
export def "2010-04-01-accounts-keys update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> record<date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Keys/{sid}.json"))
  let body = {"FriendlyName": $friendly_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of messages belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Messages.json
# operationId: ListMessage
export def "2010-04-01-accounts-messagesjson list-message" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-to: string # Read messages sent to only this phone number. (format: phone-number)
  --qp-from: string # Read messages sent from only this phone number or alphanumeric sender ID. (format: phone-number)
  --date-sent: string # The date of the messages to show. Specify a date as `YYYY-MM-DD` in GMT to read only messages sent on this date. For example: `2009-07-06`. You can also specify an inequality, such as `DateSent<=YYYY-MM-DD`, to read messages sent on or before midnight on a date, and `DateSent>=YYYY-MM-DD` to read messages sent on or after midnight on a date. (format: date-time)
  --date-sent: string # The date of the messages to show. Specify a date as `YYYY-MM-DD` in GMT to read only messages sent on this date. For example: `2009-07-06`. You can also specify an inequality, such as `DateSent<=YYYY-MM-DD`, to read messages sent on or before midnight on a date, and `DateSent>=YYYY-MM-DD` to read messages sent on or after midnight on a date. (format: date-time)
  --date-sent: string # The date of the messages to show. Specify a date as `YYYY-MM-DD` in GMT to read only messages sent on this date. For example: `2009-07-06`. You can also specify an inequality, such as `DateSent<=YYYY-MM-DD`, to read messages sent on or before midnight on a date, and `DateSent>=YYYY-MM-DD` to read messages sent on or after midnight on a date. (format: date-time)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, messages: table<account_sid: string, api_version: string, body: string, date_created: string, date_sent: string, date_updated: string, direction: string, error_code: int, error_message: string, from: string, messaging_service_sid: string, num_media: string, num_segments: string, price: string, price_unit: string, sid: string, status: string, subresource_uris: record, to: string, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "To" $qp_to "scalar") (serialize-qp "From" $qp_from "scalar") (serialize-qp "DateSent" $date_sent "scalar") (serialize-qp "DateSent<" $date_sent "scalar") (serialize-qp "DateSent>" $date_sent "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Messages.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send a message from the account used to make the request
#
# POST /2010-04-01/Accounts/{AccountSid}/Messages.json
# operationId: CreateMessage
export def "2010-04-01-accounts-messagesjson create-message" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-retention: string@address-retention-completer
  --application-sid: string # The SID of the application that should receive message status. We POST a `message_sid` parameter and a `message_status` parameter with a value of `sent` or `failed` to the [application](https://www.twilio.com/docs/usage/api/applications)'s `message_status_callback`. If a `status_callback` parameter is also passed, it will be ignored and the application's `message_status_callback` parameter will be used.
  --attempt: int # Total number of attempts made ( including this ) to send out the message regardless of the provider used
  --body-body: string # The text of the message you want to send. Can be up to 1,600 characters in length.
  --content-retention: string@content-retention-completer
  --content-sid: string # The SID of the Content object returned at Content API content create time (https://www.twilio.com/docs/content-api/create-and-send-your-first-content-api-template#create-a-template). If this parameter is not specified, then the Content API will not be utilized.
  --content-variables: string # Key-value pairs of variable names to substitution values, used alongside a content_sid. If not specified, Content API will default to the default variables defined at create time.
  --force-delivery: oneof<nothing, bool> # Reserved
  --body-from: string # A Twilio phone number in [E.164](https://www.twilio.com/docs/glossary/what-e164) format, an [alphanumeric sender ID](https://www.twilio.com/docs/sms/send-messages#use-an-alphanumeric-sender-id), or a [Channel Endpoint address](https://www.twilio.com/docs/sms/channels#channel-addresses) that is enabled for the type of message you want to send. Phone numbers or [short codes](https://www.twilio.com/docs/sms/api/short-code) purchased from Twilio also work here. You cannot, for example, spoof messages from a private cell phone number. If you are using `messaging_service_sid`, this parameter must be empty. (format: phone-number)
  --max-price: float # The maximum total price in US dollars that you will pay for the message to be delivered. Can be a decimal value that has up to 4 decimal places. All messages are queued for delivery and the message cost is checked before the message is sent. If the cost exceeds `max_price`, the message will fail and a status of `Failed` is sent to the status callback. If `MaxPrice` is not set, the message cost is not checked.
  --media-url: list # The URL of the media to send with the message. The media can be of type `gif`, `png`, and `jpeg` and will be formatted correctly on the recipient's device. The media size limit is 5MB for supported file types (JPEG, PNG, GIF) and 500KB for [other types](https://www.twilio.com/docs/sms/accepted-mime-types) of accepted media. To send more than one image in the message body, provide multiple `media_url` parameters in the POST request. You can include up to 10 `media_url` parameters per message. You can send images in an SMS message in only the US and Canada.
  --messaging-service-sid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/sms/services#send-a-message-with-copilot) you want to associate with the Message. Set this parameter to use the [Messaging Service Settings and Copilot Features](https://www.twilio.com/console/sms/services) you have configured and leave the `from` parameter empty. When only this parameter is set, Twilio will use your enabled Copilot Features to select the `from` phone number for delivery.
  --persistent-action: list # Rich actions for Channels Messages.
  --provide-feedback: oneof<nothing, bool> # Whether to confirm delivery of the message. Set this value to `true` if you are sending messages that have a trackable user action and you intend to confirm delivery of the message using the [Message Feedback API](https://www.twilio.com/docs/sms/api/message-feedback-resource). This parameter is `false` by default.
  --schedule-type: string@schedule-type-completer
  --send-as-mms: oneof<nothing, bool> # If set to True, Twilio will deliver the message as a single MMS message, regardless of the presence of media.
  --send-at: string # The time that Twilio will send the message. Must be in ISO 8601 format. (format: date-time)
  --shorten-urls: oneof<nothing, bool> # Determines the usage of Click Tracking. Setting it to `true` will instruct Twilio to replace all links in the Message with a shortened version based on the associated Domain Sid and track clicks on them. If this parameter is not set on an API call, we will use the value set on the Messaging Service. If this parameter is not set and the value is not configured on the Messaging Service used this will default to `false`.
  --smart-encoded: oneof<nothing, bool> # Whether to detect Unicode characters that have a similar GSM-7 character and replace them. Can be: `true` or `false`.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application. If specified, we POST these message status changes to the URL: `queued`, `failed`, `sent`, `delivered`, or `undelivered`. Twilio will POST its [standard request parameters](https://www.twilio.com/docs/sms/twiml#request-parameters) as well as some additional parameters including `MessageSid`, `MessageStatus`, and `ErrorCode`. If you include this parameter with the `messaging_service_sid`, we use this URL instead of the Status Callback URL of the [Messaging Service](https://www.twilio.com/docs/sms/services/api). URLs must contain a valid hostname and underscores are not allowed. (format: uri)
  --body-to: string # The destination phone number in [E.164](https://www.twilio.com/docs/glossary/what-e164) format for SMS/MMS or [Channel user address](https://www.twilio.com/docs/sms/channels#channel-addresses) for other 3rd-party channels. (format: phone-number)
  --validity-period: int # How long in seconds the message can remain in our outgoing message queue. After this period elapses, the message fails and we call your status callback. Can be between 1 and the default value of 14,400 seconds. After a message has been accepted by a carrier, however, we cannot guarantee that the message will not be queued after this period. We recommend that this value be at least 5 seconds.
]: any -> record<account_sid: string, api_version: string, body: string, date_created: string, date_sent: string, date_updated: string, direction: string, error_code: int, error_message: string, from: string, messaging_service_sid: string, num_media: string, num_segments: string, price: string, price_unit: string, sid: string, status: string, subresource_uris: record, to: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Messages.json"))
  let body = {"AddressRetention": $address_retention, "ApplicationSid": $application_sid, "Attempt": $attempt, "Body": $body_body, "ContentRetention": $content_retention, "ContentSid": $content_sid, "ContentVariables": $content_variables, "ForceDelivery": $force_delivery, "From": $body_from, "MaxPrice": $max_price, "MediaUrl": $media_url, "MessagingServiceSid": $messaging_service_sid, "PersistentAction": $persistent_action, "ProvideFeedback": $provide_feedback, "ScheduleType": $schedule_type, "SendAsMms": $send_as_mms, "SendAt": $send_at, "ShortenUrls": $shorten_urls, "SmartEncoded": $smart_encoded, "StatusCallback": $status_callback, "To": $body_to, "ValidityPeriod": $validity_period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# POST /2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Feedback.json
#
# operationId: CreateMessageFeedback
export def "2010-04-01-accounts-messages-feedbackjson create-message-feedback" [
  account_sid: string
  message_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --outcome: string@outcome-completer
]: any -> record<account_sid: string, date_created: string, date_updated: string, message_sid: string, outcome: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, message_sid: $message_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Messages/{message_sid}/Feedback.json"))
  let body = {"Outcome": $outcome} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of Media resources belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Media.json
# operationId: ListMedia
export def "2010-04-01-accounts-messages-mediajson list-media" [
  account_sid: string
  message_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created: string # Only include media that was created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read media that was created on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read media that was created on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read media that was created on or after midnight of this date. (format: date-time)
  --date-created: string # Only include media that was created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read media that was created on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read media that was created on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read media that was created on or after midnight of this date. (format: date-time)
  --date-created: string # Only include media that was created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read media that was created on this date. You can also specify an inequality, such as `StartTime<=YYYY-MM-DD`, to read media that was created on or before midnight of this date, and `StartTime>=YYYY-MM-DD` to read media that was created on or after midnight of this date. (format: date-time)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, media_list: table<account_sid: string, content_type: string, date_created: string, date_updated: string, parent_sid: string, sid: string, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "DateCreated" $date_created "scalar") (serialize-qp "DateCreated<" $date_created "scalar") (serialize-qp "DateCreated>" $date_created "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, message_sid: $message_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Messages/{message_sid}/Media.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete media from your account. Once delete, you will no longer be billed
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Media/{Sid}.json
# operationId: DeleteMedia
export def "2010-04-01-accounts-messages-media delete" [
  account_sid: string
  message_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, message_sid: $message_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Messages/{message_sid}/Media/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a single media instance belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Messages/{MessageSid}/Media/{Sid}.json
# operationId: FetchMedia
export def "2010-04-01-accounts-messages-media get" [
  account_sid: string
  message_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, content_type: string, date_created: string, date_updated: string, parent_sid: string, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, message_sid: $message_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Messages/{message_sid}/Media/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a message record from your account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Messages/{Sid}.json
# operationId: DeleteMessage
export def "2010-04-01-accounts-messages delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Messages/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a message belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Messages/{Sid}.json
# operationId: FetchMessage
export def "2010-04-01-accounts-messages get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, api_version: string, body: string, date_created: string, date_sent: string, date_updated: string, direction: string, error_code: int, error_message: string, from: string, messaging_service_sid: string, num_media: string, num_segments: string, price: string, price_unit: string, sid: string, status: string, subresource_uris: record, to: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Messages/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# To redact a message-body from a post-flight message record, post to the message instance resource with an empty body
#
# POST /2010-04-01/Accounts/{AccountSid}/Messages/{Sid}.json
# operationId: UpdateMessage
export def "2010-04-01-accounts-messages update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string # The text of the message you want to send. Can be up to 1,600 characters long.
  --status: string@status-completer-8
]: any -> record<account_sid: string, api_version: string, body: string, date_created: string, date_sent: string, date_updated: string, direction: string, error_code: int, error_message: string, from: string, messaging_service_sid: string, num_media: string, num_segments: string, price: string, price_unit: string, sid: string, status: string, subresource_uris: record, to: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Messages/{sid}.json"))
  let body = {"Body": $body_body, "Status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of notifications belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Notifications.json
# operationId: ListNotification
export def "2010-04-01-accounts-notificationsjson list-notification" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --log: int # Only read notifications of the specified log level. Can be:  `0` to read only ERROR notifications or `1` to read only WARNING notifications. By default, all notifications are read.
  --message-date: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --message-date: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --message-date: string # Only show notifications for the specified date, formatted as `YYYY-MM-DD`. You can also specify an inequality, such as `<=YYYY-MM-DD` for messages logged at or before midnight on a date, or `>=YYYY-MM-DD` for messages logged at or after midnight on a date. (format: date)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, notifications: table<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, sid: string, uri: string>, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Log" $log "scalar") (serialize-qp "MessageDate" $message_date "scalar") (serialize-qp "MessageDate<" $message_date "scalar") (serialize-qp "MessageDate>" $message_date "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Notifications.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a notification belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Notifications/{Sid}.json
# operationId: FetchNotification
export def "2010-04-01-accounts-notifications get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, api_version: string, call_sid: string, date_created: string, date_updated: string, error_code: string, log: string, message_date: string, message_text: string, more_info: string, request_method: string, request_url: string, request_variables: string, response_body: string, response_headers: string, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Notifications/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of outgoing-caller-ids belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds.json
# operationId: ListOutgoingCallerId
export def "2010-04-01-accounts-outgoing-caller-idsjson list" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --phone-number: string # The phone number of the OutgoingCallerId resources to read. (format: phone-number)
  --friendly-name: string # The string that identifies the OutgoingCallerId resources to read.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, outgoing_caller_ids: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, phone_number: string, sid: string, uri: string>, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PhoneNumber" $phone_number "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/OutgoingCallerIds.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds.json
#
# operationId: CreateValidationRequest
export def "2010-04-01-accounts-outgoing-caller-idsjson create-validation-request" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-delay: int # The number of seconds to delay before initiating the verification call. Can be an integer between `0` and `60`, inclusive. The default is `0`.
  --extension: string # The digits to dial after connecting the verification call.
  --friendly-name: string # A descriptive string that you create to describe the new caller ID resource. It can be up to 64 characters long. The default value is a formatted version of the phone number.
  phone_number: string # The phone number to verify in [E.164](https://www.twilio.com/docs/glossary/what-e164) format, which consists of a + followed by the country code and subscriber number. (format: phone-number)
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information about the verification process to your application. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `GET` or `POST`, and the default is `POST`. (format: http-method)
]: any -> record<account_sid: string, call_sid: string, friendly_name: string, phone_number: string, validation_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/OutgoingCallerIds.json"))
  let body = {"CallDelay": $call_delay, "Extension": $extension, "FriendlyName": $friendly_name, "PhoneNumber": $phone_number, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete the caller-id specified from the account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds/{Sid}.json
# operationId: DeleteOutgoingCallerId
export def "2010-04-01-accounts-outgoing-caller-ids delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/OutgoingCallerIds/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an outgoing-caller-id belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds/{Sid}.json
# operationId: FetchOutgoingCallerId
export def "2010-04-01-accounts-outgoing-caller-ids get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, phone_number: string, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/OutgoingCallerIds/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the caller-id
#
# POST /2010-04-01/Accounts/{AccountSid}/OutgoingCallerIds/{Sid}.json
# operationId: UpdateOutgoingCallerId
export def "2010-04-01-accounts-outgoing-caller-ids update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, phone_number: string, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/OutgoingCallerIds/{sid}.json"))
  let body = {"FriendlyName": $friendly_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of queues belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Queues.json
# operationId: ListQueue
export def "2010-04-01-accounts-queuesjson list-queue" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, queues: table<account_sid: string, average_wait_time: int, current_size: int, date_created: string, date_updated: string, friendly_name: string, max_size: int, sid: string, uri: string>, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Queues.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a queue
#
# POST /2010-04-01/Accounts/{AccountSid}/Queues.json
# operationId: CreateQueue
export def "2010-04-01-accounts-queuesjson create-queue" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A descriptive string that you created to describe this resource. It can be up to 64 characters long.
  --max-size: int # The maximum number of calls allowed to be in the queue. The default is 1000. The maximum is 5000.
]: any -> record<account_sid: string, average_wait_time: int, current_size: int, date_created: string, date_updated: string, friendly_name: string, max_size: int, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Queues.json"))
  let body = {"FriendlyName": $friendly_name, "MaxSize": $max_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve the members of the queue
#
# GET /2010-04-01/Accounts/{AccountSid}/Queues/{QueueSid}/Members.json
# operationId: ListMember
export def "2010-04-01-accounts-queues-membersjson list-member" [
  account_sid: string
  queue_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, queue_members: table<call_sid: string, date_enqueued: string, position: int, queue_sid: string, uri: string, wait_time: int>, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, queue_sid: $queue_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Queues/{queue_sid}/Members.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific member from the queue
#
# GET /2010-04-01/Accounts/{AccountSid}/Queues/{QueueSid}/Members/{CallSid}.json
# operationId: FetchMember
export def "2010-04-01-accounts-queues-members get" [
  account_sid: string
  queue_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<call_sid: string, date_enqueued: string, position: int, queue_sid: string, uri: string, wait_time: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, queue_sid: $queue_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Queues/{queue_sid}/Members/{call_sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Dequeue a member from a queue and have the member's call begin executing the TwiML document at that URL
#
# POST /2010-04-01/Accounts/{AccountSid}/Queues/{QueueSid}/Members/{CallSid}.json
# operationId: UpdateMember
export def "2010-04-01-accounts-queues-members update" [
  account_sid: string
  queue_sid: string
  call_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --method: string@method-completer # How to pass the update request data. Can be `GET` or `POST` and the default is `POST`. `POST` sends the data as encoded form data and `GET` sends the data as query parameters. (format: http-method)
  --body-url: string # The absolute URL of the Queue resource. (format: uri)
]: any -> record<call_sid: string, date_enqueued: string, position: int, queue_sid: string, uri: string, wait_time: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, queue_sid: $queue_sid, call_sid: $call_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Queues/{queue_sid}/Members/{call_sid}.json"))
  let body = {"Method": $method, "Url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an empty queue
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Queues/{Sid}.json
# operationId: DeleteQueue
export def "2010-04-01-accounts-queues delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Queues/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of a queue identified by the QueueSid
#
# GET /2010-04-01/Accounts/{AccountSid}/Queues/{Sid}.json
# operationId: FetchQueue
export def "2010-04-01-accounts-queues get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, average_wait_time: int, current_size: int, date_created: string, date_updated: string, friendly_name: string, max_size: int, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Queues/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the queue with the new parameters
#
# POST /2010-04-01/Accounts/{AccountSid}/Queues/{Sid}.json
# operationId: UpdateQueue
export def "2010-04-01-accounts-queues update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you created to describe this resource. It can be up to 64 characters long.
  --max-size: int # The maximum number of calls allowed to be in the queue. The default is 1000. The maximum is 5000.
]: any -> record<account_sid: string, average_wait_time: int, current_size: int, date_created: string, date_updated: string, friendly_name: string, max_size: int, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Queues/{sid}.json"))
  let body = {"FriendlyName": $friendly_name, "MaxSize": $max_size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of recordings belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings.json
# operationId: ListRecording
export def "2010-04-01-accounts-recordingsjson list-recording" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created: string # Only include recordings that were created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read recordings that were created on this date. You can also specify an inequality, such as `DateCreated<=YYYY-MM-DD`, to read recordings that were created on or before midnight of this date, and `DateCreated>=YYYY-MM-DD` to read recordings that were created on or after midnight of this date. (format: date-time)
  --date-created: string # Only include recordings that were created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read recordings that were created on this date. You can also specify an inequality, such as `DateCreated<=YYYY-MM-DD`, to read recordings that were created on or before midnight of this date, and `DateCreated>=YYYY-MM-DD` to read recordings that were created on or after midnight of this date. (format: date-time)
  --date-created: string # Only include recordings that were created on this date. Specify a date as `YYYY-MM-DD` in GMT, for example: `2009-07-06`, to read recordings that were created on this date. You can also specify an inequality, such as `DateCreated<=YYYY-MM-DD`, to read recordings that were created on or before midnight of this date, and `DateCreated>=YYYY-MM-DD` to read recordings that were created on or after midnight of this date. (format: date-time)
  --call-sid: string # The [Call](https://www.twilio.com/docs/voice/api/call-resource) SID of the resources to read.
  --conference-sid: string # The Conference SID that identifies the conference associated with the recording to read.
  --include-soft-deleted: oneof<nothing, bool> # A boolean parameter indicating whether to retrieve soft deleted recordings or not. Recordings metadata are kept after deletion for a retention period of 40 days.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, recordings: table<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, media_url: string, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, subresource_uris: record, uri: string>, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "DateCreated" $date_created "scalar") (serialize-qp "DateCreated<" $date_created "scalar") (serialize-qp "DateCreated>" $date_created "scalar") (serialize-qp "CallSid" $call_sid "scalar") (serialize-qp "ConferenceSid" $conference_sid "scalar") (serialize-qp "IncludeSoftDeleted" $include_soft_deleted "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Recordings.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}/Transcriptions.json
#
# operationId: ListRecordingTranscription
export def "2010-04-01-accounts-recordings-transcriptionsjson list-recording-transcription" [
  account_sid: string
  recording_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, transcriptions: table<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string>, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, recording_sid: $recording_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Recordings/{recording_sid}/Transcriptions.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}/Transcriptions/{Sid}.json
#
# operationId: DeleteRecordingTranscription
export def "2010-04-01-accounts-recordings-transcriptions delete" [
  account_sid: string
  recording_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, recording_sid: $recording_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Recordings/{recording_sid}/Transcriptions/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}/Transcriptions/{Sid}.json
#
# operationId: FetchRecordingTranscription
export def "2010-04-01-accounts-recordings-transcriptions get" [
  account_sid: string
  recording_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, recording_sid: $recording_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Recordings/{recording_sid}/Transcriptions/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of results belonging to the recording
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults.json
# operationId: ListRecordingAddOnResult
export def "2010-04-01-accounts-recordings-add-on-resultsjson list-recording-add-on-result" [
  account_sid: string
  reference_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<add_on_results: table<account_sid: string, add_on_configuration_sid: string, add_on_sid: string, date_completed: string, date_created: string, date_updated: string, reference_sid: string, sid: string, status: string, subresource_uris: record>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, reference_sid: $reference_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Recordings/{reference_sid}/AddOnResults.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of payloads belonging to the AddOnResult
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads.json
# operationId: ListRecordingAddOnResultPayload
export def "2010-04-01-accounts-recordings-add-on-results-payloadsjson list-recording-add-on-result-payload" [
  account_sid: string
  reference_sid: string
  add_on_result_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, payloads: table<account_sid: string, add_on_configuration_sid: string, add_on_result_sid: string, add_on_sid: string, content_type: string, date_created: string, date_updated: string, label: string, reference_sid: string, sid: string, subresource_uris: record>, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, reference_sid: $reference_sid, add_on_result_sid: $add_on_result_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Recordings/{reference_sid}/AddOnResults/{add_on_result_sid}/Payloads.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a payload from the result along with all associated Data
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads/{Sid}.json
# operationId: DeleteRecordingAddOnResultPayload
export def "2010-04-01-accounts-recordings-add-on-results-payloads delete" [
  account_sid: string
  reference_sid: string
  add_on_result_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, reference_sid: $reference_sid, add_on_result_sid: $add_on_result_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Recordings/{reference_sid}/AddOnResults/{add_on_result_sid}/Payloads/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of a result payload
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{AddOnResultSid}/Payloads/{Sid}.json
# operationId: FetchRecordingAddOnResultPayload
export def "2010-04-01-accounts-recordings-add-on-results-payloads get" [
  account_sid: string
  reference_sid: string
  add_on_result_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, add_on_configuration_sid: string, add_on_result_sid: string, add_on_sid: string, content_type: string, date_created: string, date_updated: string, label: string, reference_sid: string, sid: string, subresource_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, reference_sid: $reference_sid, add_on_result_sid: $add_on_result_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Recordings/{reference_sid}/AddOnResults/{add_on_result_sid}/Payloads/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a result and purge all associated Payloads
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{Sid}.json
# operationId: DeleteRecordingAddOnResult
export def "2010-04-01-accounts-recordings-add-on-results delete" [
  account_sid: string
  reference_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, reference_sid: $reference_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Recordings/{reference_sid}/AddOnResults/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of an AddOnResult
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{ReferenceSid}/AddOnResults/{Sid}.json
# operationId: FetchRecordingAddOnResult
export def "2010-04-01-accounts-recordings-add-on-results get" [
  account_sid: string
  reference_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, add_on_configuration_sid: string, add_on_sid: string, date_completed: string, date_created: string, date_updated: string, reference_sid: string, sid: string, status: string, subresource_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, reference_sid: $reference_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Recordings/{reference_sid}/AddOnResults/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a recording from your account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Recordings/{Sid}.json
# operationId: DeleteRecording
export def "2010-04-01-accounts-recordings delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Recordings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of a recording
#
# GET /2010-04-01/Accounts/{AccountSid}/Recordings/{Sid}.json
# operationId: FetchRecording
export def "2010-04-01-accounts-recordings get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-soft-deleted: oneof<nothing, bool> # A boolean parameter indicating whether to retrieve soft deleted recordings or not. Recordings metadata are kept after deletion for a retention period of 40 days.
]: nothing -> record<account_sid: string, api_version: string, call_sid: string, channels: int, conference_sid: string, date_created: string, date_updated: string, duration: string, encryption_details: any, error_code: int, media_url: string, price: string, price_unit: string, sid: string, source: string, start_time: string, status: string, subresource_uris: record, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "IncludeSoftDeleted" $include_soft_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Recordings/{sid}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get All Credential Lists
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists.json
# operationId: ListSipCredentialList
export def "2010-04-01-accounts-sip-credential-listsjson list-sip-credential-list" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<credential_lists: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/CredentialLists.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Credential List
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists.json
# operationId: CreateSipCredentialList
export def "2010-04-01-accounts-sip-credential-listsjson create-sip-credential-list" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A human readable descriptive text that describes the CredentialList, up to 64 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/CredentialLists.json"))
  let body = {"FriendlyName": $friendly_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of credentials.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials.json
# operationId: ListSipCredential
export def "2010-04-01-accounts-sip-credential-lists-credentialsjson list" [
  account_sid: string
  credential_list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<credentials: table<account_sid: string, credential_list_sid: string, date_created: string, date_updated: string, sid: string, uri: string, username: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, credential_list_sid: $credential_list_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/CredentialLists/{credential_list_sid}/Credentials.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new credential resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials.json
# operationId: CreateSipCredential
export def "2010-04-01-accounts-sip-credential-lists-credentialsjson create" [
  account_sid: string
  credential_list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # The password that the username will use when authenticating SIP requests. The password must be a minimum of 12 characters, contain at least 1 digit, and have mixed case. (eg `IWasAtSignal2018`)
  username: string # The username that will be passed when authenticating SIP requests. The username should be sent in response to Twilio's challenge of the initial INVITE. It can be up to 32 characters long.
]: any -> record<account_sid: string, credential_list_sid: string, date_created: string, date_updated: string, sid: string, uri: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, credential_list_sid: $credential_list_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/CredentialLists/{credential_list_sid}/Credentials.json"))
  let body = {"Password": $password, "Username": $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a credential resource.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials/{Sid}.json
# operationId: DeleteSipCredential
export def "2010-04-01-accounts-sip-credential-lists-credentials delete" [
  account_sid: string
  credential_list_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, credential_list_sid: $credential_list_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/CredentialLists/{credential_list_sid}/Credentials/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a single credential.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials/{Sid}.json
# operationId: FetchSipCredential
export def "2010-04-01-accounts-sip-credential-lists-credentials get" [
  account_sid: string
  credential_list_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, credential_list_sid: string, date_created: string, date_updated: string, sid: string, uri: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, credential_list_sid: $credential_list_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/CredentialLists/{credential_list_sid}/Credentials/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a credential resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{CredentialListSid}/Credentials/{Sid}.json
# operationId: UpdateSipCredential
export def "2010-04-01-accounts-sip-credential-lists-credentials update" [
  account_sid: string
  credential_list_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # The password that the username will use when authenticating SIP requests. The password must be a minimum of 12 characters, contain at least 1 digit, and have mixed case. (eg `IWasAtSignal2018`)
]: any -> record<account_sid: string, credential_list_sid: string, date_created: string, date_updated: string, sid: string, uri: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, credential_list_sid: $credential_list_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/CredentialLists/{credential_list_sid}/Credentials/{sid}.json"))
  let body = {"Password": $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a Credential List
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{Sid}.json
# operationId: DeleteSipCredentialList
export def "2010-04-01-accounts-sip-credential-lists delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/CredentialLists/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Credential List
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{Sid}.json
# operationId: FetchSipCredentialList
export def "2010-04-01-accounts-sip-credential-lists get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/CredentialLists/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Credential List
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/CredentialLists/{Sid}.json
# operationId: UpdateSipCredentialList
export def "2010-04-01-accounts-sip-credential-lists update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A human readable descriptive text for a CredentialList, up to 64 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/CredentialLists/{sid}.json"))
  let body = {"FriendlyName": $friendly_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of domains belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains.json
# operationId: ListSipDomain
export def "2010-04-01-accounts-sip-domainsjson list-sip-domain" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<domains: table<account_sid: string, api_version: string, auth_type: string, byoc_trunk_sid: string, date_created: string, date_updated: string, domain_name: string, emergency_caller_sid: string, emergency_calling_enabled: bool, friendly_name: string, secure: bool, sid: string, sip_registration: bool, subresource_uris: record, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Domain
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains.json
# operationId: CreateSipDomain
export def "2010-04-01-accounts-sip-domainsjson create-sip-domain" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --byoc-trunk-sid: string # The SID of the BYOC Trunk(Bring Your Own Carrier) resource that the Sip Domain will be associated with.
  domain_name: string # The unique address you reserve on Twilio to which you route your SIP traffic. Domain names can contain letters, digits, and "-" and must end with `sip.twilio.com`.
  --emergency-caller-sid: string # Whether an emergency caller sid is configured for the domain. If present, this phone number will be used as the callback for the emergency call.
  --emergency-calling-enabled: oneof<nothing, bool> # Whether emergency calling is enabled for the domain. If enabled, allows emergency calls on the domain from phone numbers with validated addresses.
  --friendly-name: string # A descriptive string that you created to describe the resource. It can be up to 64 characters long.
  --secure: oneof<nothing, bool> # Whether secure SIP is enabled for the domain. If enabled, TLS will be enforced and SRTP will be negotiated on all incoming calls to this sip domain.
  --sip-registration: oneof<nothing, bool> # Whether to allow SIP Endpoints to register with the domain to receive calls. Can be `true` or `false`. `true` allows SIP Endpoints to register with the domain to receive calls, `false` does not.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs while retrieving or executing the TwiML from `voice_url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method we should use to call `voice_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-status-callback-method: string@voice-status-callback-method-completer # The HTTP method we should use to call `voice_status_callback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-status-callback-url: string # The URL that we should call to pass status parameters (such as call ended) to your application. (format: uri)
  --voice-url: string # The URL we should when the domain receives a call. (format: uri)
]: any -> record<account_sid: string, api_version: string, auth_type: string, byoc_trunk_sid: string, date_created: string, date_updated: string, domain_name: string, emergency_caller_sid: string, emergency_calling_enabled: bool, friendly_name: string, secure: bool, sid: string, sip_registration: bool, subresource_uris: record, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains.json"))
  let body = {"ByocTrunkSid": $byoc_trunk_sid, "DomainName": $domain_name, "EmergencyCallerSid": $emergency_caller_sid, "EmergencyCallingEnabled": $emergency_calling_enabled, "FriendlyName": $friendly_name, "Secure": $secure, "SipRegistration": $sip_registration, "VoiceFallbackMethod": $voice_fallback_method, "VoiceFallbackUrl": $voice_fallback_url, "VoiceMethod": $voice_method, "VoiceStatusCallbackMethod": $voice_status_callback_method, "VoiceStatusCallbackUrl": $voice_status_callback_url, "VoiceUrl": $voice_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of credential list mappings belonging to the domain used in the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings.json
# operationId: ListSipAuthCallsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-credential-list-mappingsjson list-sip-auth-calls-credential-list-mapping" [
  account_sid: string
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<contents: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/Auth/Calls/CredentialListMappings.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new credential list mapping resource
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings.json
# operationId: CreateSipAuthCallsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-credential-list-mappingsjson create-sip-auth-calls-credential-list-mapping" [
  account_sid: string
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  credential_list_sid: string # The SID of the CredentialList resource to map to the SIP domain.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/Auth/Calls/CredentialListMappings.json"))
  let body = {"CredentialListSid": $credential_list_sid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a credential list mapping from the requested domain
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings/{Sid}.json
# operationId: DeleteSipAuthCallsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-credential-list-mappings delete" [
  account_sid: string
  domain_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/Auth/Calls/CredentialListMappings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific instance of a credential list mapping
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/CredentialListMappings/{Sid}.json
# operationId: FetchSipAuthCallsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-credential-list-mappings get" [
  account_sid: string
  domain_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/Auth/Calls/CredentialListMappings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of IP Access Control List mappings belonging to the domain used in the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings.json
# operationId: ListSipAuthCallsIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-ip-access-control-list-mappingsjson list-sip-auth-calls-ip-access-control-list-mapping" [
  account_sid: string
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<contents: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/Auth/Calls/IpAccessControlListMappings.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new IP Access Control List mapping
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings.json
# operationId: CreateSipAuthCallsIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-ip-access-control-list-mappingsjson create-sip-auth-calls-ip-access-control-list-mapping" [
  account_sid: string
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ip_access_control_list_sid: string # The SID of the IpAccessControlList resource to map to the SIP domain.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/Auth/Calls/IpAccessControlListMappings.json"))
  let body = {"IpAccessControlListSid": $ip_access_control_list_sid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an IP Access Control List mapping from the requested domain
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings/{Sid}.json
# operationId: DeleteSipAuthCallsIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-ip-access-control-list-mappings delete" [
  account_sid: string
  domain_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/Auth/Calls/IpAccessControlListMappings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific instance of an IP Access Control List mapping
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Calls/IpAccessControlListMappings/{Sid}.json
# operationId: FetchSipAuthCallsIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-auth-calls-ip-access-control-list-mappings get" [
  account_sid: string
  domain_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/Auth/Calls/IpAccessControlListMappings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of credential list mappings belonging to the domain used in the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings.json
# operationId: ListSipAuthRegistrationsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-registrations-credential-list-mappingsjson list-sip-auth-registrations-credential-list-mapping" [
  account_sid: string
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<contents: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/Auth/Registrations/CredentialListMappings.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new credential list mapping resource
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings.json
# operationId: CreateSipAuthRegistrationsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-registrations-credential-list-mappingsjson create-sip-auth-registrations-credential-list-mapping" [
  account_sid: string
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  credential_list_sid: string # The SID of the CredentialList resource to map to the SIP domain.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/Auth/Registrations/CredentialListMappings.json"))
  let body = {"CredentialListSid": $credential_list_sid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a credential list mapping from the requested domain
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings/{Sid}.json
# operationId: DeleteSipAuthRegistrationsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-registrations-credential-list-mappings delete" [
  account_sid: string
  domain_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/Auth/Registrations/CredentialListMappings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific instance of a credential list mapping
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/Auth/Registrations/CredentialListMappings/{Sid}.json
# operationId: FetchSipAuthRegistrationsCredentialListMapping
export def "2010-04-01-accounts-sip-domains-auth-registrations-credential-list-mappings get" [
  account_sid: string
  domain_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/Auth/Registrations/CredentialListMappings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Read multiple CredentialListMapping resources from an account.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings.json
# operationId: ListSipCredentialListMapping
export def "2010-04-01-accounts-sip-domains-credential-list-mappingsjson list-sip-credential-list-mapping" [
  account_sid: string
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<credential_list_mappings: table<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>, end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/CredentialListMappings.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a CredentialListMapping resource for an account.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings.json
# operationId: CreateSipCredentialListMapping
export def "2010-04-01-accounts-sip-domains-credential-list-mappingsjson create-sip-credential-list-mapping" [
  account_sid: string
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  credential_list_sid: string # A 34 character string that uniquely identifies the CredentialList resource to map to the SIP domain.
]: any -> record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/CredentialListMappings.json"))
  let body = {"CredentialListSid": $credential_list_sid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a CredentialListMapping resource from an account.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings/{Sid}.json
# operationId: DeleteSipCredentialListMapping
export def "2010-04-01-accounts-sip-domains-credential-list-mappings delete" [
  account_sid: string
  domain_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/CredentialListMappings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a single CredentialListMapping resource from an account.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/CredentialListMappings/{Sid}.json
# operationId: FetchSipCredentialListMapping
export def "2010-04-01-accounts-sip-domains-credential-list-mappings get" [
  account_sid: string
  domain_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/CredentialListMappings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of IpAccessControlListMapping resources.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings.json
# operationId: ListSipIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-ip-access-control-list-mappingsjson list-sip-ip-access-control-list-mapping" [
  account_sid: string
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, ip_access_control_list_mappings: table<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/IpAccessControlListMappings.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new IpAccessControlListMapping resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings.json
# operationId: CreateSipIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-ip-access-control-list-mappingsjson create-sip-ip-access-control-list-mapping" [
  account_sid: string
  domain_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ip_access_control_list_sid: string # The unique id of the IP access control list to map to the SIP domain.
]: any -> record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/IpAccessControlListMappings.json"))
  let body = {"IpAccessControlListSid": $ip_access_control_list_sid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an IpAccessControlListMapping resource.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings/{Sid}.json
# operationId: DeleteSipIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-ip-access-control-list-mappings delete" [
  account_sid: string
  domain_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/IpAccessControlListMappings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an IpAccessControlListMapping resource.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{DomainSid}/IpAccessControlListMappings/{Sid}.json
# operationId: FetchSipIpAccessControlListMapping
export def "2010-04-01-accounts-sip-domains-ip-access-control-list-mappings get" [
  account_sid: string
  domain_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, domain_sid: string, friendly_name: string, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, domain_sid: $domain_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{domain_sid}/IpAccessControlListMappings/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an instance of a Domain
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{Sid}.json
# operationId: DeleteSipDomain
export def "2010-04-01-accounts-sip-domains delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of a Domain
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{Sid}.json
# operationId: FetchSipDomain
export def "2010-04-01-accounts-sip-domains get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, api_version: string, auth_type: string, byoc_trunk_sid: string, date_created: string, date_updated: string, domain_name: string, emergency_caller_sid: string, emergency_calling_enabled: bool, friendly_name: string, secure: bool, sid: string, sip_registration: bool, subresource_uris: record, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the attributes of a domain
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/Domains/{Sid}.json
# operationId: UpdateSipDomain
export def "2010-04-01-accounts-sip-domains update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --byoc-trunk-sid: string # The SID of the BYOC Trunk(Bring Your Own Carrier) resource that the Sip Domain will be associated with.
  --domain-name: string # The unique address you reserve on Twilio to which you route your SIP traffic. Domain names can contain letters, digits, and "-" and must end with `sip.twilio.com`.
  --emergency-caller-sid: string # Whether an emergency caller sid is configured for the domain. If present, this phone number will be used as the callback for the emergency call.
  --emergency-calling-enabled: oneof<nothing, bool> # Whether emergency calling is enabled for the domain. If enabled, allows emergency calls on the domain from phone numbers with validated addresses.
  --friendly-name: string # A descriptive string that you created to describe the resource. It can be up to 64 characters long.
  --secure: oneof<nothing, bool> # Whether secure SIP is enabled for the domain. If enabled, TLS will be enforced and SRTP will be negotiated on all incoming calls to this sip domain.
  --sip-registration: oneof<nothing, bool> # Whether to allow SIP Endpoints to register with the domain to receive calls. Can be `true` or `false`. `true` allows SIP Endpoints to register with the domain to receive calls, `false` does not.
  --voice-fallback-method: string@voice-fallback-method-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-fallback-url: string # The URL that we should call when an error occurs while retrieving or executing the TwiML requested by `voice_url`. (format: uri)
  --voice-method: string@voice-method-completer # The HTTP method we should use to call `voice_url` (format: http-method)
  --voice-status-callback-method: string@voice-status-callback-method-completer # The HTTP method we should use to call `voice_status_callback_url`. Can be: `GET` or `POST`. (format: http-method)
  --voice-status-callback-url: string # The URL that we should call to pass status parameters (such as call ended) to your application. (format: uri)
  --voice-url: string # The URL we should call when the domain receives a call. (format: uri)
]: any -> record<account_sid: string, api_version: string, auth_type: string, byoc_trunk_sid: string, date_created: string, date_updated: string, domain_name: string, emergency_caller_sid: string, emergency_calling_enabled: bool, friendly_name: string, secure: bool, sid: string, sip_registration: bool, subresource_uris: record, uri: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_status_callback_method: string, voice_status_callback_url: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/Domains/{sid}.json"))
  let body = {"ByocTrunkSid": $byoc_trunk_sid, "DomainName": $domain_name, "EmergencyCallerSid": $emergency_caller_sid, "EmergencyCallingEnabled": $emergency_calling_enabled, "FriendlyName": $friendly_name, "Secure": $secure, "SipRegistration": $sip_registration, "VoiceFallbackMethod": $voice_fallback_method, "VoiceFallbackUrl": $voice_fallback_url, "VoiceMethod": $voice_method, "VoiceStatusCallbackMethod": $voice_status_callback_method, "VoiceStatusCallbackUrl": $voice_status_callback_url, "VoiceUrl": $voice_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of IpAccessControlLists that belong to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists.json
# operationId: ListSipIpAccessControlList
export def "2010-04-01-accounts-sip-ip-access-control-listsjson list-sip-ip-access-control-list" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, ip_access_control_lists: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/IpAccessControlLists.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new IpAccessControlList resource
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists.json
# operationId: CreateSipIpAccessControlList
export def "2010-04-01-accounts-sip-ip-access-control-listsjson create-sip-ip-access-control-list" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A human readable descriptive text that describes the IpAccessControlList, up to 255 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/IpAccessControlLists.json"))
  let body = {"FriendlyName": $friendly_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Read multiple IpAddress resources.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses.json
# operationId: ListSipIpAddress
export def "2010-04-01-accounts-sip-ip-access-control-lists-ip-addressesjson list-sip-ip-address" [
  account_sid: string
  ip_access_control_list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, ip_addresses: table<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_access_control_list_sid: string, ip_address: string, sid: string, uri: string>, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid, ip_access_control_list_sid: $ip_access_control_list_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/IpAccessControlLists/{ip_access_control_list_sid}/IpAddresses.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new IpAddress resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses.json
# operationId: CreateSipIpAddress
export def "2010-04-01-accounts-sip-ip-access-control-lists-ip-addressesjson create-sip-ip-address" [
  account_sid: string
  ip_access_control_list_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cidr-prefix-length: int # An integer representing the length of the CIDR prefix to use with this IP address when accepting traffic. By default the entire IP address is used.
  friendly_name: string # A human readable descriptive text for this resource, up to 255 characters long.
  ip_address: string # An IP address in dotted decimal notation from which you want to accept traffic. Any SIP requests from this IP address will be allowed by Twilio. IPv4 only supported today.
]: any -> record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_access_control_list_sid: string, ip_address: string, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, ip_access_control_list_sid: $ip_access_control_list_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/IpAccessControlLists/{ip_access_control_list_sid}/IpAddresses.json"))
  let body = {"CidrPrefixLength": $cidr_prefix_length, "FriendlyName": $friendly_name, "IpAddress": $ip_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an IpAddress resource.
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses/{Sid}.json
# operationId: DeleteSipIpAddress
export def "2010-04-01-accounts-sip-ip-access-control-lists-ip-addresses delete-sip-ip-address" [
  account_sid: string
  ip_access_control_list_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, ip_access_control_list_sid: $ip_access_control_list_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/IpAccessControlLists/{ip_access_control_list_sid}/IpAddresses/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Read one IpAddress resource.
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses/{Sid}.json
# operationId: FetchSipIpAddress
export def "2010-04-01-accounts-sip-ip-access-control-lists-ip-addresses get-sip-ip-address" [
  account_sid: string
  ip_access_control_list_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_access_control_list_sid: string, ip_address: string, sid: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, ip_access_control_list_sid: $ip_access_control_list_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/IpAccessControlLists/{ip_access_control_list_sid}/IpAddresses/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an IpAddress resource.
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{IpAccessControlListSid}/IpAddresses/{Sid}.json
# operationId: UpdateSipIpAddress
export def "2010-04-01-accounts-sip-ip-access-control-lists-ip-addresses update-sip-ip-address" [
  account_sid: string
  ip_access_control_list_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cidr-prefix-length: int # An integer representing the length of the CIDR prefix to use with this IP address when accepting traffic. By default the entire IP address is used.
  --friendly-name: string # A human readable descriptive text for this resource, up to 255 characters long.
  --ip-address: string # An IP address in dotted decimal notation from which you want to accept traffic. Any SIP requests from this IP address will be allowed by Twilio. IPv4 only supported today.
]: any -> record<account_sid: string, cidr_prefix_length: int, date_created: string, date_updated: string, friendly_name: string, ip_access_control_list_sid: string, ip_address: string, sid: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, ip_access_control_list_sid: $ip_access_control_list_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/IpAccessControlLists/{ip_access_control_list_sid}/IpAddresses/{sid}.json"))
  let body = {"CidrPrefixLength": $cidr_prefix_length, "FriendlyName": $friendly_name, "IpAddress": $ip_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an IpAccessControlList from the requested account
#
# DELETE /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{Sid}.json
# operationId: DeleteSipIpAccessControlList
export def "2010-04-01-accounts-sip-ip-access-control-lists delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/IpAccessControlLists/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific instance of an IpAccessControlList
#
# GET /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{Sid}.json
# operationId: FetchSipIpAccessControlList
export def "2010-04-01-accounts-sip-ip-access-control-lists get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/IpAccessControlLists/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rename an IpAccessControlList
#
# POST /2010-04-01/Accounts/{AccountSid}/SIP/IpAccessControlLists/{Sid}.json
# operationId: UpdateSipIpAccessControlList
export def "2010-04-01-accounts-sip-ip-access-control-lists update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A human readable descriptive text, up to 255 characters long.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sid: string, subresource_uris: record, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SIP/IpAccessControlLists/{sid}.json"))
  let body = {"FriendlyName": $friendly_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of short-codes belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/SMS/ShortCodes.json
# operationId: ListShortCode
export def "2010-04-01-accounts-sms-short-codesjson list-short-code" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # The string that identifies the ShortCode resources to read.
  --short-code: string # Only show the ShortCode resources that match this pattern. You can specify partial numbers and use '*' as a wildcard for any digit.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, short_codes: table<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, short_code: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, uri: string>, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "ShortCode" $short_code "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SMS/ShortCodes.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of a short code
#
# GET /2010-04-01/Accounts/{AccountSid}/SMS/ShortCodes/{Sid}.json
# operationId: FetchShortCode
export def "2010-04-01-accounts-sms-short-codes get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, short_code: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SMS/ShortCodes/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a short code with the following parameters
#
# POST /2010-04-01/Accounts/{AccountSid}/SMS/ShortCodes/{Sid}.json
# operationId: UpdateShortCode
export def "2010-04-01-accounts-sms-short-codes update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API version to use to start a new TwiML session. Can be: `2010-04-01` or `2008-08-01`.
  --friendly-name: string # A descriptive string that you created to describe this resource. It can be up to 64 characters long. By default, the `FriendlyName` is the short code.
  --sms-fallback-method: string@sms-fallback-method-completer # The HTTP method that we should use to call the `sms_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --sms-fallback-url: string # The URL that we should call if an error occurs while retrieving or executing the TwiML from `sms_url`. (format: uri)
  --sms-method: string@sms-method-completer # The HTTP method we should use when calling the `sms_url`. Can be: `GET` or `POST`. (format: http-method)
  --sms-url: string # The URL we should call when receiving an incoming SMS message to this short code. (format: uri)
]: any -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, friendly_name: string, short_code: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SMS/ShortCodes/{sid}.json"))
  let body = {"ApiVersion": $api_version, "FriendlyName": $friendly_name, "SmsFallbackMethod": $sms_fallback_method, "SmsFallbackUrl": $sms_fallback_url, "SmsMethod": $sms_method, "SmsUrl": $sms_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /2010-04-01/Accounts/{AccountSid}/SigningKeys.json
#
# operationId: ListSigningKey
export def "2010-04-01-accounts-signing-keysjson list-signing-key" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, signing_keys: table<date_created: string, date_updated: string, friendly_name: string, sid: string>, start: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SigningKeys.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Signing Key for the account making the request.
#
# POST /2010-04-01/Accounts/{AccountSid}/SigningKeys.json
# operationId: CreateNewSigningKey
export def "2010-04-01-accounts-signing-keysjson create-new-signing-key" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> record<date_created: string, date_updated: string, friendly_name: string, secret: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SigningKeys.json"))
  let body = {"FriendlyName": $friendly_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /2010-04-01/Accounts/{AccountSid}/SigningKeys/{Sid}.json
#
# operationId: DeleteSigningKey
export def "2010-04-01-accounts-signing-keys delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SigningKeys/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/SigningKeys/{Sid}.json
#
# operationId: FetchSigningKey
export def "2010-04-01-accounts-signing-keys get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SigningKeys/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /2010-04-01/Accounts/{AccountSid}/SigningKeys/{Sid}.json
#
# operationId: UpdateSigningKey
export def "2010-04-01-accounts-signing-keys update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string
]: any -> record<date_created: string, date_updated: string, friendly_name: string, sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/SigningKeys/{sid}.json"))
  let body = {"FriendlyName": $friendly_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a new token for ICE servers
#
# POST /2010-04-01/Accounts/{AccountSid}/Tokens.json
# operationId: CreateToken
export def "2010-04-01-accounts-tokensjson create-token" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ttl: int # The duration in seconds for which the generated credentials are valid. The default value is 86400 (24 hours).
]: any -> record<account_sid: string, date_created: string, date_updated: string, ice_servers: table<credential: string, url: string, urls: string, username: string>, password: string, ttl: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Tokens.json"))
  let body = {"Ttl": $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of transcriptions belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Transcriptions.json
# operationId: ListTranscription
export def "2010-04-01-accounts-transcriptionsjson list-transcription" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, transcriptions: table<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string>, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Transcriptions.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a transcription from the account used to make the request
#
# DELETE /2010-04-01/Accounts/{AccountSid}/Transcriptions/{Sid}.json
# operationId: DeleteTranscription
export def "2010-04-01-accounts-transcriptions delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Transcriptions/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an instance of a Transcription
#
# GET /2010-04-01/Accounts/{AccountSid}/Transcriptions/{Sid}.json
# operationId: FetchTranscription
export def "2010-04-01-accounts-transcriptions get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, api_version: string, date_created: string, date_updated: string, duration: string, price: float, price_unit: string, recording_sid: string, sid: string, status: string, transcription_text: string, type: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Transcriptions/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of usage-records belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records.json
# operationId: ListUsageRecord
export def "2010-04-01-accounts-usage-recordsjson list-usage-record" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $category "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "IncludeSubaccounts" $include_subaccounts "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Records.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/AllTime.json
#
# operationId: ListUsageRecordAllTime
export def "2010-04-01-accounts-usage-records-all-timejson list-usage-record-all-time" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $category "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "IncludeSubaccounts" $include_subaccounts "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Records/AllTime.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Daily.json
#
# operationId: ListUsageRecordDaily
export def "2010-04-01-accounts-usage-records-dailyjson list-usage-record-daily" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $category "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "IncludeSubaccounts" $include_subaccounts "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Records/Daily.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/LastMonth.json
#
# operationId: ListUsageRecordLastMonth
export def "2010-04-01-accounts-usage-records-last-monthjson list-usage-record-last-month" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $category "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "IncludeSubaccounts" $include_subaccounts "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Records/LastMonth.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Monthly.json
#
# operationId: ListUsageRecordMonthly
export def "2010-04-01-accounts-usage-records-monthlyjson list-usage-record-monthly" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $category "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "IncludeSubaccounts" $include_subaccounts "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Records/Monthly.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/ThisMonth.json
#
# operationId: ListUsageRecordThisMonth
export def "2010-04-01-accounts-usage-records-this-monthjson list-usage-record-this-month" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $category "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "IncludeSubaccounts" $include_subaccounts "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Records/ThisMonth.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Today.json
#
# operationId: ListUsageRecordToday
export def "2010-04-01-accounts-usage-records-todayjson list-usage-record-today" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $category "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "IncludeSubaccounts" $include_subaccounts "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Records/Today.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Yearly.json
#
# operationId: ListUsageRecordYearly
export def "2010-04-01-accounts-usage-records-yearlyjson list-usage-record-yearly" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $category "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "IncludeSubaccounts" $include_subaccounts "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Records/Yearly.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /2010-04-01/Accounts/{AccountSid}/Usage/Records/Yesterday.json
#
# operationId: ListUsageRecordYesterday
export def "2010-04-01-accounts-usage-records-yesterdayjson list-usage-record-yesterday" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The [usage category](https://www.twilio.com/docs/usage/api/usage-record#usage-categories) of the UsageRecord resources to read. Only UsageRecord resources in the specified category are retrieved.
  --start-date: string # Only include usage that has occurred on or after this date. Specify the date in GMT and format as `YYYY-MM-DD`. You can also specify offsets from the current date, such as: `-30days`, which will set the start date to be 30 days before the current date. (format: date)
  --end-date: string # Only include usage that occurred on or before this date. Specify the date in GMT and format as `YYYY-MM-DD`.  You can also specify offsets from the current date, such as: `+30days`, which will set the end date to 30 days from the current date. (format: date)
  --include-subaccounts: oneof<nothing, bool> # Whether to include usage from the master account and all its subaccounts. Can be: `true` (the default) to include usage from the master account and all subaccounts or `false` to retrieve usage from only the specified account.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_records: table<account_sid: string, api_version: string, as_of: string, category: string, count: string, count_unit: string, description: string, end_date: string, price: float, price_unit: string, start_date: string, subresource_uris: record, uri: string, usage: string, usage_unit: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Category" $category "scalar") (serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "IncludeSubaccounts" $include_subaccounts "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Records/Yesterday.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of usage-triggers belonging to the account used to make the request
#
# GET /2010-04-01/Accounts/{AccountSid}/Usage/Triggers.json
# operationId: ListUsageTrigger
export def "2010-04-01-accounts-usage-triggersjson list-usage-trigger" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --recurring: string@recurring-completer # The frequency of recurring UsageTriggers to read. Can be: `daily`, `monthly`, or `yearly` to read recurring UsageTriggers. An empty value or a value of `alltime` reads non-recurring UsageTriggers.
  --trigger-by: string@trigger-by-completer # The trigger field of the UsageTriggers to read.  Can be: `count`, `usage`, or `price` as described in the [UsageRecords documentation](https://www.twilio.com/docs/usage/api/usage-record#usage-count-price).
  --usage-category: string@usage-category-completer # The usage category of the UsageTriggers to read. Must be a supported [usage categories](https://www.twilio.com/docs/usage/api/usage-record#usage-categories).
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<end: int, first_page_uri: string, next_page_uri: string, page: int, page_size: int, previous_page_uri: string, start: int, uri: string, usage_triggers: table<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let qp = [(serialize-qp "Recurring" $recurring "scalar") (serialize-qp "TriggerBy" $trigger_by "scalar") (serialize-qp "UsageCategory" $usage_category "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Triggers.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new UsageTrigger
#
# POST /2010-04-01/Accounts/{AccountSid}/Usage/Triggers.json
# operationId: CreateUsageTrigger
export def "2010-04-01-accounts-usage-triggersjson create-usage-trigger" [
  account_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-method: string@callback-method-completer # The HTTP method we should use to call `callback_url`. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  callback_url: string # The URL we should call using `callback_method` when the trigger fires. (format: uri)
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --recurring: string@recurring-completer
  --trigger-by: string@trigger-by-completer
  trigger_value: string # The usage value at which the trigger should fire.  For convenience, you can use an offset value such as `+30` to specify a trigger_value that is 30 units more than the current usage value. Be sure to urlencode a `+` as `%2B`.
  usage_category: string@usage-category-completer
]: any -> record<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Triggers.json"))
  let body = {"CallbackMethod": $callback_method, "CallbackUrl": $callback_url, "FriendlyName": $friendly_name, "Recurring": $recurring, "TriggerBy": $trigger_by, "TriggerValue": $trigger_value, "UsageCategory": $usage_category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /2010-04-01/Accounts/{AccountSid}/Usage/Triggers/{Sid}.json
#
# operationId: DeleteUsageTrigger
export def "2010-04-01-accounts-usage-triggers delete" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Triggers/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch and instance of a usage-trigger
#
# GET /2010-04-01/Accounts/{AccountSid}/Usage/Triggers/{Sid}.json
# operationId: FetchUsageTrigger
export def "2010-04-01-accounts-usage-triggers get" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Triggers/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an instance of a usage trigger
#
# POST /2010-04-01/Accounts/{AccountSid}/Usage/Triggers/{Sid}.json
# operationId: UpdateUsageTrigger
export def "2010-04-01-accounts-usage-triggers update" [
  account_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-method: string@callback-method-completer # The HTTP method we should use to call `callback_url`. Can be: `GET` or `POST` and the default is `POST`. (format: http-method)
  --callback-url: string # The URL we should call using `callback_method` when the trigger fires. (format: uri)
  --friendly-name: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
]: any -> record<account_sid: string, api_version: string, callback_method: string, callback_url: string, current_value: string, date_created: string, date_fired: string, date_updated: string, friendly_name: string, recurring: string, sid: string, trigger_by: string, trigger_value: string, uri: string, usage_category: string, usage_record_uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({account_sid: $account_sid, sid: $sid} | format pattern "/2010-04-01/Accounts/{account_sid}/Usage/Triggers/{sid}.json"))
  let body = {"CallbackMethod": $callback_method, "CallbackUrl": $callback_url, "FriendlyName": $friendly_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch the account specified by the provided Account Sid
#
# GET /2010-04-01/Accounts/{Sid}.json
# operationId: FetchAccount
export def "2010-04-01-accounts get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({sid: $sid} | format pattern "/2010-04-01/Accounts/{sid}.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the properties of a given Account
#
# POST /2010-04-01/Accounts/{Sid}.json
# operationId: UpdateAccount
export def "2010-04-01-accounts update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # Update the human-readable description of this Account
  --status: string@status-completer
]: any -> record<auth_token: string, date_created: string, date_updated: string, friendly_name: string, owner_account_sid: string, sid: string, status: string, subresource_uris: record, type: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.twilio.com")
  let full_url = (build-url $base ({sid: $sid} | format pattern "/2010-04-01/Accounts/{sid}.json"))
  let body = {"FriendlyName": $friendly_name, "Status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
