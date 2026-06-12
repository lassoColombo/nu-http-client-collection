# Auto-generated client for Brevo API v3.0.0
# Source: https://raw.githubusercontent.com/xdev-software/brevo-java-client/develop/openapi/openapi.yml
# Auth: --token flag or $env.BREVO_API_TOKEN

const BASE_URL = "https://api.brevo.com/v3"
const DEFAULT_AUTH = "api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BREVO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-key" => { {headers: {api-key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.brevo.com/v3"] }
def auth-scheme-completer [] { ["api-key"] }

# Completers for enum parameters
def type-completer [] { ["classic" "trigger"] }
def status-completer [] { ["archive" "draft" "inProcess" "inReview" "queued" "sent" "suspended"] }
def statistics-completer [] { ["globalStats" "linksStats" "statsByDomain"] }
def sort-completer [] { ["asc" "desc"] }
def excludeHtmlContent-completer [] { ["false" "true"] }
def winnerCriteria-completer [] { ["click" "open"] }
def statistics-completer-1 [] { ["globalStats" "linksStats" "statsByBrowser" "statsByDevice" "statsByDomain"] }
def status-completer-1 [] { ["archive" "darchive" "draft" "queued" "replicate" "replicateTemplate" "sent" "suspended"] }
def language-completer [] { ["de" "en" "es" "fr" "it" "pt"] }
def recipientsType-completer [] { ["all" "clickers" "hardBounces" "nonClickers" "nonOpeners" "openers" "softBounces" "unsubscribed"] }
def event-completer [] { ["blocked" "bounces" "clicks" "deferred" "delivered" "error" "hardBounces" "invalid" "loadedByProxy" "opened" "requests" "softBounces" "spam" "unsubscribed"] }
def status-completer-2 [] { ["inProgress" "processed" "queued"] }
def identifierType-completer [] { ["contact_id" "email_id" "ext_id" "landline_number_id" "phone_id" "whatsapp_id"] }
def type-completer-1 [] { ["boolean" "category" "date" "float" "id" "multiple-choice" "text" "user"] }
def association-completer [] { ["false" "true"] }
def status-completer-3 [] { ["archive" "draft" "inProcess" "queued" "sent" "suspended"] }
def recipientsType-completer-1 [] { ["all" "answered" "delivered" "hardBounces" "softBounces" "unsubscribed"] }
def type-completer-2 [] { ["marketing" "transactional"] }
def event-completer-1 [] { ["accepted" "blocked" "bounces" "delivered" "hardBounces" "rejected" "replies" "sent" "skipped" "softBounces" "unsubscription"] }
def campaignStatus-completer [] { ["scheduled" "suspended"] }
def source-completer [] { ["Automation" "Conversations"] }
def category-completer [] { ["MARKETING" "UTILITY"] }
def sort-field-completer [] { ["created_at" "name" "updated_at"] }
def sortField-completer [] { ["createdAt" "updatedAt"] }
def version-completer [] { ["active" "draft"] }
def sortField-completer-1 [] { ["created_at" "name" "updated_at"] }
def balanceAvailabilityDurationModifier-completer [] { ["endOfPeriod" "noModification" "startOfPeriod"] }
def balanceAvailabilityDurationUnit-completer [] { ["day" "month" "week" "year"] }
def balanceOptionAmountOvertakingStrategy-completer [] { ["partial" "strict"] }
def balanceOptionCreditRounding-completer [] { ["lower" "natural" "upper"] }
def balanceOptionDebitRounding-completer [] { ["lower" "natural" "upper"] }
def unit-completer [] { ["AUD" "BRL" "CAD" "CHF" "CLP" "EUR" "GBP" "INR" "JPY" "MAD" "MXN" "MYR" "PEN" "POINTS" "RON" "SGD" "USD"] }
def constraintType-completer [] { ["amount" "transaction"] }
def durationUnit-completer [] { ["day" "month" "week" "year"] }
def transactionType-completer [] { ["credit" "debit"] }
def upgradeStrategy-completer [] { ["membership_anniversary" "real_time" "tier_anniversary"] }
def downgradeStrategy-completer [] { ["membership_anniversary" "real_time" "tier_anniversary"] }
def type-completer-3 [] { ["inbound" "marketing" "transactional"] }
def channel-completer [] { ["email" "sms"] }
def event-completer-2 [] { ["allEvents" "blocked" "click" "deferred" "delivered" "error" "hardBounce" "invalid" "invalid_parameter" "loadedByProxy" "missing_parameter" "opened" "request" "softBounce" "spam" "uniqueOpened" "unsubscribed"] }
def all-features-access-completer [] { ["false" "true"] }
def target-completer [] { ["automation" "contacts" "email_campaign" "email_transactional" "landing_pages" "senders" "sms_campaign" "sms_transactional"] }
def attributeType-completer [] { ["boolean" "date" "multi-choice" "number" "single-select" "text" "user"] }
def objectType-completer [] { ["companies" "deals"] }
def filterstatus-completer [] { ["done" "undone"] }
def filterdate-completer [] { ["overdue" "range" "today" "tomorrow" "week"] }
def entity-completer [] { ["companies" "contacts" "deals"] }
def sortBy-completer [] { ["createdAt" "expirationDate" "remainingCoupons"] }
def event-completer-3 [] { ["delivered" "error" "read" "reply" "sent" "soft-bounce" "unsubscribe"] }
def authType-completer [] { ["basic" "noAuth" "token"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "email-campaigns list" } } | get name | first)
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

# Return all your created email campaigns
#
# GET /emailCampaigns
# operationId: getEmailCampaigns
export def "email-campaigns list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Filter on the type of the campaigns
  --status: string@status-completer # Filter on the status of the campaign
  --statistics: string@statistics-completer # Filter on the type of statistics required. Example **globalStats** value will only fetch globalStats info of the campaign in returned response.This option only returns data for events occurred in the last 6 months.For older campaigns, it’s advisable to use the **Get Campaign Report** endpoint.
  --startDate: string # **Mandatory if endDate is used**. Starting (urlencoded) UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) to filter the sent email campaigns. **Prefer to pass your timezone in date-time format for accurate result** ( only available if either 'status' not passed and if passed is set to 'sent' )
  --endDate: string # **Mandatory if startDate is used**. Ending (urlencoded) UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) to filter the sent email campaigns. **Prefer to pass your timezone in date-time format for accurate result** ( only available if either 'status' not passed and if passed is set to 'sent' )
  --limit: int # Number of documents per page (format: int64, default: 50)
  --offset: int # Index of the first document in the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
  --excludeHtmlContent: oneof<nothing, bool> # Use this flag to exclude htmlContent from the response body. If set to **true**, htmlContent field will be returned as empty string in the response body
]: nothing -> record<campaigns: list<record>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "statistics" $statistics "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "excludeHtmlContent" $excludeHtmlContent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/emailCampaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an email campaign
#
# POST /emailCampaigns
# operationId: createEmailCampaign
# --sender shape: {name?: string, email?: string, id?: int}
# --recipients shape: {exclusionListIds?: list, listIds?: list, segmentIds?: list, exclusionSegmentIds?: list}
# --emailExpirationDate shape: {duration?: int, unit?: "days"|"weeks"|"months"}
export def "email-campaigns createEmailCampaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Tag of the campaign (e.g. Newsletter)
  sender: record # Sender details including id or email and name (_optional_). Only one of either Sender's email or Sender's ID shall be passed in one request at a time. For example: **{"name":"xyz", "email":"example@abc.com"}** **{"name":"xyz", "id":123}** — shape: {name?: string, email?: string, id?: int}
  name: string # Name of the campaign (e.g. Newsletter - May 2017)
  --htmlContent: string # Mandatory if htmlUrl and templateId are empty. Body of the message (HTML).  (e.g. <!DOCTYPE html> <html> <body> <h1>Confirm you email</h1> <p>Please confirm your email address by clicking on the link below</p> </body> </html>)
  --htmlUrl: string # **Mandatory if htmlContent and templateId are empty**. Url to the message (HTML). For example: **https://html.domain.com**  (format: url, e.g. https://html.domain.com)
  --templateId: int # **Mandatory if htmlContent and htmlUrl are empty**. Id of the transactional email template with status _active_. Used to copy only its content fetched from htmlContent/htmlUrl to an email campaign for RSS feature.  (format: int64)
  --scheduledAt: string # Sending UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result**. If sendAtBestTime is set to true, your campaign will be sent according to the date passed (ignoring the time part). For example: **2017-06-01T12:30:00+02:00**  (e.g. 2017-06-01T12:30:00+02:00)
  --subject: string # Subject of the campaign. **Mandatory if abTesting is false**. Ignored if abTesting is true.  (e.g. Discover the New Collection !)
  --previewText: string # Preview text or preheader of the email campaign (e.g. Thanks for your order!)
  --replyTo: string # Email on which the campaign recipients will be able to reply to (format: email, e.g. support@myshop.com)
  --toField: string # To personalize the **To** Field. If you want to include the first name and last name of your recipient, add **{FNAME} {LNAME}**. These contact attributes must already exist in your Brevo account. If input parameter **params** used please use **{{contact.FNAME}} {{contact.LNAME}}** for personalization  (e.g. {FNAME} {LNAME})
  --recipients: record # Segment ids and List ids to include/exclude from campaign — shape: {exclusionListIds?: list, listIds?: list, segmentIds?: list, exclusionSegmentIds?: list}
  --attachmentUrl: string # Absolute url of the attachment (no local file). Extension allowed: #### xlsx, xls, ods, docx, docm, doc, csv, pdf, txt, gif, jpg, jpeg, png, tif, tiff, rtf, bmp, cgm, css, shtml, html, htm, zip, xml, ppt, pptx, tar, ez, ics, mobi, msg, pub and eps  (format: url, e.g. https://attachment.domain.com)
  --inlineImageActivation: oneof<nothing, bool> # Use true to embedded the images in your email. Final size of the email should be less than **4MB**. Campaigns with embedded images can _not be sent to more than 5000 contacts_  (default: false, e.g. true)
  --mirrorActive: oneof<nothing, bool> # Use true to enable the mirror link (e.g. true)
  --footer: string # Footer of the email campaign (e.g. [DEFAULT_FOOTER])
  --header: string # Header of the email campaign (e.g. [DEFAULT_HEADER])
  --utmCampaign: string # Customize the utm_campaign value. If this field is empty, the campaign name will be used. Only alphanumeric characters and spaces are allowed (e.g. NL_05_2017)
  --params: record # Pass the set of attributes to customize the type classic campaign. For example: **{"FNAME":"Joe", "LNAME":"Doe"}**. Only available if **type** is **classic**. It's considered only if campaign is in _New Template Language format_. The New Template Language is dependent on the values of **subject, htmlContent/htmlUrl, sender.name & toField**  (e.g. {FNAME: Joe, LNAME: Doe})
  --sendAtBestTime: oneof<nothing, bool> # Set this to true if you want to send your campaign at best time. (default: false, e.g. true)
  --abTesting: oneof<nothing, bool> # Status of A/B Test. abTesting = false means it is disabled & abTesting = true means it is enabled. **subjectA, subjectB, splitRule, winnerCriteria & winnerDelay** will be considered when abTesting is set to true. subjectA & subjectB are mandatory together & subject if passed is ignored. **Can be set to true only if sendAtBestTime is false**. You will be able to set up two subject lines for your campaign and send them to a random sample of your total recipients. Half of the test group will receive version A, and the other half will receive version B  (default: false, e.g. true)
  --subjectA: string # Subject A of the campaign. **Mandatory if abTesting = true**. subjectA & subjectB should have unique value  (e.g. Discover the New Collection!)
  --subjectB: string # Subject B of the campaign. **Mandatory if abTesting = true**. subjectA & subjectB should have unique value  (e.g. Want to discover the New Collection?)
  --splitRule: int # Add the size of your test groups. **Mandatory if abTesting = true & 'recipients' is passed**. We'll send version A and B to a random sample of recipients, and then the winning version to everyone else  (format: int64, e.g. 50)
  --winnerCriteria: string@winnerCriteria-completer # Choose the metrics that will determinate the winning version. **Mandatory if _splitRule_ >= 1 and < 50**. If splitRule = 50, `winnerCriteria` is ignored if passed  (e.g. open)
  --winnerDelay: int # Choose the duration of the test in hours. Maximum is 7 days, pass 24*7 = 168 hours. The winning version will be sent at the end of the test. **Mandatory if _splitRule_ >= 1 and < 50**. If splitRule = 50, `winnerDelay` is ignored if passed  (format: int64, e.g. 50)
  --ipWarmupEnable: oneof<nothing, bool> # **Available for dedicated ip clients**. Set this to true if you wish to warm up your ip.  (default: false, e.g. true)
  --initialQuota: int # **Mandatory if ipWarmupEnable is set to true**. Set an initial quota greater than 1 for warming up your ip. We recommend you set a value of 3000.  (format: int64, e.g. 3000)
  --increaseRate: int # **Mandatory if ipWarmupEnable is set to true**. Set a percentage increase rate for warming up your ip. We recommend you set the increase rate to 30% per day. If you want to send the same number of emails every day, set the daily increase value to 0%.  (format: int64, e.g. 70)
  --unsubscriptionPageId: string # Enter an unsubscription page id. The page id is a 24 digit alphanumeric id that can be found in the URL when editing the page. If not entered, then the default unsubscription page will be used.  (e.g. 62cbb7fabbe85021021aac52)
  --updateFormId: string # **Mandatory if templateId is used containing the {{ update_profile }} tag**. Enter an update profile form id. The form id is a 24 digit alphanumeric id that can be found in the URL when editing the form. If not entered, then the default update profile form will be used.  (e.g. 6313436b9ad40e23b371d095)
  --emailExpirationDate: record # To reduce your carbon footprint, set an expiration date for your email. If supported, it will be automatically deleted from the recipient’s inbox, saving storage space and energy. Learn more about setting an email expiration date. For reference , ``https://help.brevo.com/hc/en-us/articles/4413566705298-Create-an-email-campaign`` — shape: {duration?: int, unit?: "days"|"weeks"|"months"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emailCampaigns")
  let body = {tag: $tag, sender: $sender, name: $name, htmlContent: $htmlContent, htmlUrl: $htmlUrl, templateId: $templateId, scheduledAt: $scheduledAt, subject: $subject, previewText: $previewText, replyTo: $replyTo, toField: $toField, recipients: $recipients, attachmentUrl: $attachmentUrl, inlineImageActivation: $inlineImageActivation, mirrorActive: $mirrorActive, footer: $footer, header: $header, utmCampaign: $utmCampaign, params: $params, sendAtBestTime: $sendAtBestTime, abTesting: $abTesting, subjectA: $subjectA, subjectB: $subjectB, splitRule: $splitRule, winnerCriteria: $winnerCriteria, winnerDelay: $winnerDelay, ipWarmupEnable: $ipWarmupEnable, initialQuota: $initialQuota, increaseRate: $increaseRate, unsubscriptionPageId: $unsubscriptionPageId, updateFormId: $updateFormId, emailExpirationDate: $emailExpirationDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an email campaign report
#
# GET /emailCampaigns/{campaignId}
# operationId: getEmailCampaign
export def "email-campaigns get" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --statistics: string@statistics-completer-1 # Filter on the type of statistics required. Example **globalStats** value will only fetch globalStats info of the campaign in returned response.
]: nothing -> record<recipients: record, statistics: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statistics" $statistics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/emailCampaigns/($campaignId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an email campaign
#
# PUT /emailCampaigns/{campaignId}
# operationId: updateEmailCampaign
# --sender shape: {name?: string, email?: string, id?: int}
# --recipients shape: {exclusionListIds?: list, listIds?: list, segmentIds?: list, exclusionSegmentIds?: list}
# --emailExpirationDate shape: {duration?: int, unit?: "days"|"weeks"|"months"}
export def "email-campaigns updateEmailCampaign" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Tag of the campaign (e.g. Newsletter)
  --sender: record # Sender details including id or email and name (optional). Only one of either Sender's email or Sender's ID shall be passed in one request at a time. For example: **{"name":"xyz", "email":"example@abc.com"}** **{"name":"xyz", "id":123}** — shape: {name?: string, email?: string, id?: int}
  --name: string # Name of the campaign (e.g. Newsletter - May 2017)
  --htmlContent: string # Body of the message (HTML version). If the campaign is designed using Drag & Drop editor via HTML content, then the design page will not have Drag & Drop editor access for that campaign. **REQUIRED if htmlUrl is empty**  (e.g. <!DOCTYPE html> <html> <body> <h1>Confirm you email</h1> <p>Please confirm your email address by clicking on the link below</p> </body> </html>)
  --htmlUrl: string # Url which contents the body of the email message. **REQUIRED if htmlContent is empty**  (format: url, e.g. https://html.domain.com)
  --scheduledAt: string # UTC date-time on which the campaign has to run (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.** If sendAtBestTime is set to true, your campaign will be sent according to the date passed (ignoring the time part).  (e.g. 2017-06-01T12:30:00+02:00)
  --subject: string # Subject of the campaign (e.g. Discover the New Collection !)
  --previewText: string # Preview text or preheader of the email campaign (e.g. Thanks for your order!)
  --replyTo: string # Email on which campaign recipients will be able to reply to (format: email, e.g. support@myshop.com)
  --toField: string # To personalize the **To** Field. If you want to include the first name and last name of your recipient, add **{FNAME} {LNAME}**. These contact attributes must already exist in your Brevo account. If input parameter **params** used please use **{{contact.FNAME}} {{contact.LNAME}}** for personalization  (e.g. {FNAME} {LNAME})
  --recipients: record # Segment ids and List ids to include/exclude from campaign — shape: {exclusionListIds?: list, listIds?: list, segmentIds?: list, exclusionSegmentIds?: list}
  --attachmentUrl: string # Absolute url of the attachment (no local file). Extension allowed: #### xlsx, xls, ods, docx, docm, doc, csv, pdf, txt, gif, jpg, jpeg, png, tif, tiff, rtf, bmp, cgm, css, shtml, html, htm, zip, xml, ppt, pptx, tar, ez, ics, mobi, msg, pub and eps'  (format: url, e.g. https://attachment.domain.com)
  --inlineImageActivation: oneof<nothing, bool> # Status of inline image. inlineImageActivation = false means image can’t be embedded, & inlineImageActivation = true means image can be embedded, in the email. You cannot send a campaign of more than **4MB** with images embedded in the email. Campaigns with the images embedded in the email _must be sent to less than 5000 contacts_.  (default: false, e.g. true)
  --mirrorActive: oneof<nothing, bool> # Status of mirror links in campaign. mirrorActive = false means mirror links are deactivated, & mirrorActive = true means mirror links are activated, in the campaign (e.g. true)
  --recurring: oneof<nothing, bool> # **FOR TRIGGER ONLY !** Type of trigger campaign.recurring = false means contact can receive the same Trigger campaign only once, & recurring = true means contact can receive the same Trigger campaign several times  (default: false, e.g. false)
  --footer: string # Footer of the email campaign (e.g. [DEFAULT_FOOTER])
  --header: string # Header of the email campaign (e.g. [DEFAULT_HEADER])
  --utmCampaign: string # Customize the utm_campaign value. If this field is empty, the campaign name will be used. Only alphanumeric characters and spaces are allowed (e.g. NL_05_2017)
  --params: record # Pass the set of attributes to customize the type classic campaign. For example: **{"FNAME":"Joe", "LNAME":"Doe"}**. Only available if **type** is **classic**. It's considered only if campaign is in _New Template Language format_. The New Template Language is dependent on the values of **subject, htmlContent/htmlUrl, sender.name & toField**  (e.g. {FNAME: Joe, LNAME: Doe})
  --sendAtBestTime: oneof<nothing, bool> # Set this to true if you want to send your campaign at best time. Note:- **if true, warmup ip will be disabled.**  (e.g. true)
  --abTesting: oneof<nothing, bool> # Status of A/B Test. abTesting = false means it is disabled & abTesting = true means it is enabled. **subjectA, subjectB, splitRule, winnerCriteria & winnerDelay** will be considered when abTesting is set to true. subjectA & subjectB are mandatory together & subject if passed is ignored. **Can be set to true only if sendAtBestTime is false**. You will be able to set up two subject lines for your campaign and send them to a random sample of your total recipients. Half of the test group will receive version A, and the other half will receive version B  (default: false, e.g. true)
  --subjectA: string # Subject A of the campaign. **Mandatory if abTesting = true**. subjectA & subjectB should have unique value  (e.g. Discover the New Collection!)
  --subjectB: string # Subject B of the campaign. **Mandatory if abTesting = true**. subjectA & subjectB should have unique value  (e.g. Want to discover the New Collection?)
  --splitRule: int # Add the size of your test groups. **Mandatory if abTesting = true & 'recipients' is passed**. We'll send version A and B to a random sample of recipients, and then the winning version to everyone else  (format: int64, e.g. 50)
  --winnerCriteria: string@winnerCriteria-completer # Choose the metrics that will determinate the winning version. **Mandatory if _splitRule_ >= 1 and < 50**. If splitRule = 50, `winnerCriteria` is ignored if passed  (e.g. open)
  --winnerDelay: int # Choose the duration of the test in hours. Maximum is 7 days, pass 24*7 = 168 hours. The winning version will be sent at the end of the test. **Mandatory if _splitRule_ >= 1 and < 50**. If splitRule = 50, `winnerDelay` is ignored if passed  (format: int64, e.g. 50)
  --ipWarmupEnable: oneof<nothing, bool> # **Available for dedicated ip clients**. Set this to true if you wish to warm up your ip.  (default: false, e.g. true)
  --initialQuota: int # Set an initial quota greater than 1 for warming up your ip. We recommend you set a value of 3000.  (format: int64, e.g. 3000)
  --increaseRate: int # Set a percentage increase rate for warming up your ip. We recommend you set the increase rate to 30% per day. If you want to send the same number of emails every day, set the daily increase value to 0%.  (format: int64, e.g. 70)
  --unsubscriptionPageId: string # Enter an unsubscription page id. The page id is a 24 digit alphanumeric id that can be found in the URL when editing the page.  (e.g. 62cbb7fabbe85021021aac52)
  --updateFormId: string # **Mandatory if templateId is used containing the {{ update_profile }} tag**. Enter an update profile form id. The form id is a 24 digit alphanumeric id that can be found in the URL when editing the form.  (e.g. 6313436b9ad40e23b371d095)
  --emailExpirationDate: record # To reduce your carbon footprint, set an expiration date for your email. If supported, it will be automatically deleted from the recipient’s inbox, saving storage space and energy. — shape: {duration?: int, unit?: "days"|"weeks"|"months"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emailCampaigns/($campaignId)")
  let body = {tag: $tag, sender: $sender, name: $name, htmlContent: $htmlContent, htmlUrl: $htmlUrl, scheduledAt: $scheduledAt, subject: $subject, previewText: $previewText, replyTo: $replyTo, toField: $toField, recipients: $recipients, attachmentUrl: $attachmentUrl, inlineImageActivation: $inlineImageActivation, mirrorActive: $mirrorActive, recurring: $recurring, footer: $footer, header: $header, utmCampaign: $utmCampaign, params: $params, sendAtBestTime: $sendAtBestTime, abTesting: $abTesting, subjectA: $subjectA, subjectB: $subjectB, splitRule: $splitRule, winnerCriteria: $winnerCriteria, winnerDelay: $winnerDelay, ipWarmupEnable: $ipWarmupEnable, initialQuota: $initialQuota, increaseRate: $increaseRate, unsubscriptionPageId: $unsubscriptionPageId, updateFormId: $updateFormId, emailExpirationDate: $emailExpirationDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an email campaign
#
# DELETE /emailCampaigns/{campaignId}
# operationId: deleteEmailCampaign
export def "email-campaigns delete" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emailCampaigns/($campaignId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send an email campaign immediately, based on campaignId
#
# POST /emailCampaigns/{campaignId}/sendNow
# operationId: sendEmailCampaignNow
export def "email-campaigns-send-now sendEmailCampaignNow" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emailCampaigns/($campaignId)/sendNow")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send an email campaign to your test list
#
# POST /emailCampaigns/{campaignId}/sendTest
# operationId: sendTestEmail
export def "email-campaigns-send-test sendTestEmail" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emailTo: list # List of the email addresses of the recipients whom you wish to send the test mail. _If left empty, the test mail will be sent to your entire test list. You can not send more than 50 test emails per day_.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emailCampaigns/($campaignId)/sendTest")
  let body = {emailTo: $emailTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an email campaign status
#
# PUT /emailCampaigns/{campaignId}/status
# operationId: updateCampaignStatus
export def "email-campaigns-status updateCampaignStatus" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Note:- **replicateTemplate** status will be available **only for template type campaigns.**
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emailCampaigns/($campaignId)/status")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send the report of a campaign
#
# POST /emailCampaigns/{campaignId}/sendReport
# operationId: sendReport
# --email shape: {to: list, body: string}
export def "email-campaigns-send-report sendReport" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # Language of email content for campaign report sending. (default: fr, e.g. en)
  email: record # Custom attributes for the report email. — shape: {to: list, body: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emailCampaigns/($campaignId)/sendReport")
  let body = {language: $language, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an A/B test email campaign results
#
# GET /emailCampaigns/{campaignId}/abTestCampaignResult
# operationId: getAbTestCampaignResult
export def "email-campaigns-ab-test-campaign-result get" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<winningVersion: string, winningCriteria: string, winningSubjectLine: string, openRate: string, clickRate: string, winningVersionRate: string, statistics: record<openers: record<Version_A: string, Version_B: string>, clicks: record<Version_A: string, Version_B: string>, unsubscribed: record<Version_A: string, Version_B: string>, hardBounces: record<Version_A: string, Version_B: string>, softBounces: record<Version_A: string, Version_B: string>, complaints: record<Version_A: string, Version_B: string>>, clickedLinks: record<Version_A: list<record>, Version_B: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emailCampaigns/($campaignId)/abTestCampaignResult")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a shared template url
#
# GET /emailCampaigns/{campaignId}/sharedUrl
# operationId: getSharedTemplateUrl
export def "email-campaigns-shared-url get" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sharedUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emailCampaigns/($campaignId)/sharedUrl")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export the recipients of an email campaign
#
# POST /emailCampaigns/{campaignId}/exportRecipients
# operationId: emailExportRecipients
export def "email-campaigns-export-recipients emailExportRecipients" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notifyURL: string # Webhook called once the export process is finished. For reference, https://help.brevo.com/hc/en-us/articles/360007666479 (format: url, e.g. http://requestb.in/173lyyx1)
  recipientsType: string@recipientsType-completer # Type of recipients to export for a campaign (e.g. openers)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/emailCampaigns/($campaignId)/exportRecipients")
  let body = {notifyURL: $notifyURL, recipientsType: $recipientsType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload an image to your account's image gallery
#
# POST /emailCampaigns/images
# operationId: uploadImageToGallery
export def "email-campaigns-images uploadImageToGallery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  imageUrl: string # The absolute url of the image (**no local file**). Maximum allowed size for image is **2MB**. Allowed extensions for images are: #### jpeg, jpg, png, bmp, gif.  (e.g. https://somedomain.com/image1.jpg)
  --name: string # Name of the image. (e.g. nature.jpg)
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/emailCampaigns/images")
  let body = {imageUrl: $imageUrl, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a transactional email
#
# POST /smtp/email
# operationId: sendTransacEmail
# --sender shape: {name?: string, email?: string, id?: int}
# --to item shape: {email: string, name?: string}
# --bcc item shape: {email: string, name?: string}
# --cc item shape: {email: string, name?: string}
# --replyTo shape: {email: string, name?: string}
# --attachment item shape: {url?: string, content?: string, name?: string}
# --messageVersions item shape: {to: list, params?: record, bcc?: list, cc?: list, replyTo?: record, subject?: string, htmlContent?: string, textContent?: string}
export def "smtp-email sendTransacEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sender: record # **Mandatory if `templateId` is not passed**. Pass name (_optional_) and email or id of sender from which emails will be sent. **`name` will be ignored if passed along with sender `id`**. For example, **{"name":"Mary from MyShop", "email":"no-reply@myshop.com"}** **{"id":2}** — shape: {name?: string, email?: string, id?: int}
  --body-to: list # **Mandatory if messageVersions are not passed, ignored if messageVersions are passed** List of email addresses and names (_optional_) of the recipients. For example, **[{"name":"Jimmy", "email":"jimmy98@example.com"}, {"name":"Joe", "email":"joe@example.com"}]** — item shape: {email: string, name?: string}
  --bcc: list # List of email addresses and names (_optional_) of the recipients in bcc — item shape: {email: string, name?: string}
  --cc: list # List of email addresses and names (_optional_) of the recipients in cc — item shape: {email: string, name?: string}
  --htmlContent: string # HTML body of the message. **Mandatory if 'templateId' is not passed, ignored if 'templateId' is passed**  (e.g. <!DOCTYPE html> <html> <body> <h1>Confirm you email</h1> <p>Please confirm your email address by clicking on the link below</p> </body> </html>)
  --textContent: string # Plain Text body of the message. **Ignored if 'templateId' is passed**  (e.g. Please confirm your email address by clicking on the link https://text.domain.com)
  --subject: string # Subject of the message. **Mandatory if 'templateId' is not passed**  (e.g. Login Email confirmation)
  --replyTo: record # Email (**required**), along with name (_optional_), on which transactional mail recipients will be able to reply back. For example, **{"email":"ann6533@example.com", "name":"Ann"}** — shape: {email: string, name?: string}
  --attachment: list # Pass the _absolute URL_ (**no local file**) or the _base64 content_ of the attachment along with the attachment name. **Mandatory if attachment content is passed**. For example, **[{"url":"https://attachment.domain.com/myAttachmentFromUrl.jpg", "name":"myAttachmentFromUrl.jpg"}, {"content":"base64 example content", "name":"myAttachmentFromBase64.jpg"}]**. Allowed extensions for attachment file: #### xlsx, xls, ods, docx, docm, doc, csv, pdf, txt, gif, jpg, jpeg, png, tif, tiff, rtf, bmp, cgm, css, shtml, html, htm, zip, xml, ppt, pptx, tar, ez, ics, mobi, msg, pub, eps, odt, mp3, m4a, m4v, wma, ogg, flac, wav, aif, aifc, aiff, mp4, mov, avi, mkv, mpeg, mpg, wmv, pkpass and xlsm. If `templateId` is passed and is in New Template Language format then both attachment url and content are accepted. If template is in Old template Language format, then `attachment` is ignored — item shape: {url?: string, content?: string, name?: string}
  --headers: record # Pass the set of custom headers (_not the standard headers_) that shall be sent along the mail headers in the original email. **'sender.ip'** header can be set (**only for dedicated ip users**) to mention the IP to be used for sending transactional emails. Headers are allowed in `This-Case-Only` (i.e. words separated by hyphen with first letter of each word in capital letter), they will be converted to such case styling if not in this format in the request payload. For example, **{"sender.ip":"1.2.3.4", "X-Mailin-custom":"some_custom_header", "idempotencyKey":"abc-123"}**.  (e.g. {sender.ip: 1.2.3.4, X-Mailin-custom: some_custom_header, idempotencyKey: abc-123})
  --templateId: int # Id of the template. (format: int64, e.g. 2)
  --params: record # Pass the set of attributes to customize the template. For example, **{"FNAME":"Joe", "LNAME":"Doe"}**. It's **considered only if template is in New Template Language format**.  (e.g. {FNAME: Joe, LNAME: Doe})
  --messageVersions: list # You can customize and send out multiple versions of a mail. **templateId** can be customized only if global parameter contains templateId. **htmlContent and textContent** can be customized only if any of the two, htmlContent or textContent, is present in global parameters. Some global parameters such as **to(mandatory), bcc, cc, replyTo, subject** can also be customized specific to each version. Total number of recipients in one API request must not exceed 2000. However, you can still pass upto 99 recipients maximum in one message version. The size of individual params in all the messageVersions shall not exceed **100 KB** limit and that of cumulative params shall not exceed **1000 KB**. You can follow this **step-by-step guide** on how to use **messageVersions** to batch send emails - **https://developers.brevo.com/docs/batch-send-transactional-emails** — item shape: {to: list, params?: record, bcc?: list, cc?: list, replyTo?: record, subject?: string, htmlContent?: string, textContent?: string}
  --tags: list # Tag your emails to find them more easily
  --scheduledAt: string # UTC date-time on which the email has to schedule (YYYY-MM-DDTHH:mm:ss.SSSZ). Prefer to pass your timezone in date-time format for scheduling. There can be an expected delay of +5 minutes in scheduled email delivery. (format: date-time, e.g. 2022-04-05T12:30:00+02:00)
  --batchId: string # Valid UUIDv4 batch id to identify the scheduled batches transactional email. If not passed we will create a valid UUIDv4 batch id at our end. (e.g. 5c6cfa04-eed9-42c2-8b5c-6d470d978e9d)
  --preheader: string # A short summary that appears next to the subject line in the recipient’s inbox. This preview text gives recipients a quick idea of what the email is about before they open it.
]: any -> record<messageId: string, messageIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/smtp/email")
  let body = {sender: $sender, to: $body_to, bcc: $bcc, cc: $cc, htmlContent: $htmlContent, textContent: $textContent, subject: $subject, replyTo: $replyTo, attachment: $attachment, headers: $headers, templateId: $templateId, params: $params, messageVersions: $messageVersions, tags: $tags, scheduledAt: $scheduledAt, batchId: $batchId, preheader: $preheader} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the list of transactional emails on the basis of allowed filters
#
# GET /smtp/emails
# operationId: getTransacEmailsList
export def "smtp-emails list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # **Mandatory if templateId and messageId are not passed in query filters.** Email address to which transactional email has been sent.
  --templateId: int # **Mandatory if email and messageId are not passed in query filters.** Id of the template that was used to compose transactional email.  (format: int64)
  --messageId: string # **Mandatory if templateId and email are not passed in query filters.** Message ID of the transactional email sent.
  --startDate: string # **Mandatory if endDate is used.** Starting date (YYYY-MM-DD) from which you want to fetch the list. **Maximum time period that can be selected is one month**.
  --endDate: string # **Mandatory if startDate is used.** Ending date (YYYY-MM-DD) till which you want to fetch the list. **Maximum time period that can be selected is one month.**
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
  --limit: int # Number of documents returned per page (format: int64, default: 500)
  --offset: int # Index of the first document in the page (format: int64, default: 0)
]: nothing -> record<count: int, transactionalEmails: table<email: string, subject: string, templateId: int, messageId: string, uuid: string, date: string, from: string, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "templateId" $templateId "scalar") (serialize-qp "messageId" $messageId "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/smtp/emails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the personalized content of a sent transactional email
#
# GET /smtp/emails/{uuid}
# operationId: getTransacEmailContent
export def "smtp-emails get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, subject: string, templateId: int, date: string, events: table<name: string, time: string>, body: string, attachmentCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smtp/emails/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an SMTP transactional log
#
# DELETE /smtp/log/{identifier}
export def "smtp-log delete" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smtp/log/($identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of email templates
#
# GET /smtp/templates
# operationId: getSmtpTemplates
export def "smtp-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --templateStatus: oneof<nothing, bool> # Filter on the status of the template. Active = true, inactive = false
  --limit: int # Number of documents returned per page (format: int64, default: 50)
  --offset: int # Index of the first document in the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<count: int, templates: table<id: int, name: string, subject: string, isActive: bool, testSent: bool, sender: record, replyTo: string, toField: string, tag: string, htmlContent: string, createdAt: string, modifiedAt: string, doiTemplate: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "templateStatus" $templateStatus "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/smtp/templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an email template
#
# POST /smtp/templates
# operationId: createSmtpTemplate
# --sender shape: {name?: string, email?: string, id?: int}
export def "smtp-templates createSmtpTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Tag of the template (e.g. OrderConfirmation)
  sender: record # Sender details including id or email and name (_optional_). Only one of either Sender's email or Sender's ID shall be passed in one request at a time. For example: **{"name":"xyz", "email":"example@abc.com"}** **{"name":"xyz", "id":123}** — shape: {name?: string, email?: string, id?: int}
  templateName: string # Name of the template (e.g. Order Confirmation - EN)
  --htmlContent: string # Body of the message (HTML version). The field must have more than 10 characters. **REQUIRED if htmlUrl is empty**  (e.g. The order n°xxxxx has been confirmed. Thanks for your purchase)
  --htmlUrl: string # Url which contents the body of the email message. REQUIRED if htmlContent is empty (format: url, e.g. https://html.domain.com)
  subject: string # Subject of the template (e.g. Thanks for your purchase !)
  --replyTo: string # Email on which campaign recipients will be able to reply to (format: email, e.g. support@myshop.com)
  --toField: string # To personalize the **To** Field. If you want to include the first name and last name of your recipient, add **{FNAME} {LNAME}**. These contact attributes must already exist in your Brevo account. If input parameter **params** used please use **{{contact.FNAME}} {{contact.LNAME}}** for personalization  (e.g. {FNAME} {LNAME})
  --attachmentUrl: string # Absolute url of the attachment (**no local file**). Extension allowed: #### xlsx, xls, ods, docx, docm, doc, csv, pdf, txt, gif, jpg, jpeg, png, tif, tiff, rtf, bmp, cgm, css, shtml, html, htm, zip, xml, ppt, pptx, tar, ez, ics, mobi, msg, pub and eps'  (format: url, e.g. https://attachment.domain.com)
  --isActive: oneof<nothing, bool> # Status of template. isActive = true means template is active and isActive = false means template is inactive (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/smtp/templates")
  let body = {tag: $tag, sender: $sender, templateName: $templateName, htmlContent: $htmlContent, htmlUrl: $htmlUrl, subject: $subject, replyTo: $replyTo, toField: $toField, attachmentUrl: $attachmentUrl, isActive: $isActive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the template information
#
# GET /smtp/templates/{templateId}
# operationId: getSmtpTemplate
export def "smtp-templates get" [
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, subject: string, isActive: bool, testSent: bool, sender: record<name: string, email: string, id: string>, replyTo: string, toField: string, tag: string, htmlContent: string, createdAt: string, modifiedAt: string, doiTemplate: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smtp/templates/($templateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an email template
#
# PUT /smtp/templates/{templateId}
# operationId: updateSmtpTemplate
# --sender shape: {name?: string, email?: string, id?: int}
export def "smtp-templates updateSmtpTemplate" [
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tag: string # Tag of the template (e.g. OrderConfirmation)
  --sender: record # Sender details including id or email and name (_optional_). Only one of either Sender's email or Sender's ID shall be passed in one request at a time. For example: **{"name":"xyz", "email":"example@abc.com"}** **{"name":"xyz", "id":123}** — shape: {name?: string, email?: string, id?: int}
  --templateName: string # Name of the template (e.g. Order Confirmation - EN)
  --htmlContent: string # **Required if htmlUrl is empty**. If the template is designed using Drag & Drop editor via HTML content, then the design page will not have Drag & Drop editor access for that template. Body of the message (HTML must have more than 10 characters)  (e.g. The order n°xxxxx has been confirmed. Thanks for your purchase)
  --htmlUrl: string # **Required if htmlContent is empty**. URL to the body of the email (HTML)  (format: url, e.g. https://html.domain.com)
  --subject: string # Subject of the email (e.g. Thanks for your purchase !)
  --replyTo: string # Email on which campaign recipients will be able to reply to (format: email, e.g. support@myshop.com)
  --toField: string # To personalize the **To** Field. If you want to include the first name and last name of your recipient, add **{FNAME} {LNAME}**. These contact attributes must already exist in your Brevo account. If input parameter **params** used please use **{{contact.FNAME}} {{contact.LNAME}}** for personalization  (e.g. {FNAME} {LNAME})
  --attachmentUrl: string # Absolute url of the attachment (**no local file**). Extensions allowed: #### xlsx, xls, ods, docx, docm, doc, csv, pdf, txt, gif, jpg, jpeg, png, tif, tiff, rtf, bmp, cgm, css, shtml, html, htm, zip, xml, ppt, pptx, tar, ez, ics, mobi, msg, pub and eps  (format: url, e.g. https://attachment.domain.com)
  --isActive: oneof<nothing, bool> # Status of the template. isActive = false means template is inactive, isActive = true means template is active (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smtp/templates/($templateId)")
  let body = {tag: $tag, sender: $sender, templateName: $templateName, htmlContent: $htmlContent, htmlUrl: $htmlUrl, subject: $subject, replyTo: $replyTo, toField: $toField, attachmentUrl: $attachmentUrl, isActive: $isActive} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an inactive email template
#
# DELETE /smtp/templates/{templateId}
# operationId: deleteSmtpTemplate
export def "smtp-templates delete" [
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smtp/templates/($templateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send a template to your test list
#
# POST /smtp/templates/{templateId}/sendTest
# operationId: sendTestTemplate
export def "smtp-templates-send-test sendTestTemplate" [
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emailTo: list # List of the email addresses of the recipients whom you wish to send the test mail. _If left empty, the test mail will be sent to your entire test list. You can not send more than 50 test emails per day_.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smtp/templates/($templateId)/sendTest")
  let body = {emailTo: $emailTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate the rendered preview of transactional template
#
# POST /smtp/template/preview
# operationId: templatePreview
export def "smtp-template-preview templatePreview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  templateId: int # ID of the template to preview (e.g. 22)
  --email: string # Email of the contact.(Required if params not provided) (format: email, e.g. john.doe@example.com)
  --params: record # Key-value pairs of dynamic parameters for template rendering.(Required if email not provided) for example **{"Firstname":"John", "Lastname":"Doe"}** (e.g. {firstname: John, lastname: Doe})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/smtp/template/preview")
  let body = {templateId: $templateId, email: $email, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get your transactional email activity aggregated over a period of time
#
# GET /smtp/statistics/aggregatedReport
# operationId: getAggregatedSmtpReport
export def "smtp-statistics-aggregated-report get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # **Mandatory if endDate is used.** Starting date of the report (YYYY-MM-DD). Must be lower than equal to endDate
  --endDate: string # **Mandatory if startDate is used.** Ending date of the report (YYYY-MM-DD). Must be greater than equal to startDate
  --days: int # Number of days in the past including today (positive integer). _Not compatible with 'startDate' and 'endDate'_  (format: int64)
  --tag: string # Tag of the emails
]: nothing -> record<range: string, requests: int, delivered: int, hardBounces: int, softBounces: int, clicks: int, uniqueClicks: int, opens: int, uniqueOpens: int, spamReports: int, blocked: int, invalid: int, unsubscribed: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/smtp/statistics/aggregatedReport" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get your transactional email activity aggregated per day
#
# GET /smtp/statistics/reports
# operationId: getSmtpReport
export def "smtp-statistics-reports get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of documents returned per page (format: int64, default: 10)
  --offset: int # Index of the first document on the page (format: int64, default: 0)
  --startDate: string # **Mandatory if endDate is used.** Starting date of the report (YYYY-MM-DD)
  --endDate: string # **Mandatory if startDate is used.** Ending date of the report (YYYY-MM-DD)
  --days: int # Number of days in the past including today (positive integer). _Not compatible with 'startDate' and 'endDate'_  (format: int64)
  --tag: string # Tag of the emails
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<reports: table<date: string, requests: int, delivered: int, hardBounces: int, softBounces: int, clicks: int, uniqueClicks: int, opens: int, uniqueOpens: int, spamReports: int, blocked: int, invalid: int, unsubscribed: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/smtp/statistics/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all your transactional email activity (unaggregated events)
#
# GET /smtp/statistics/events
# operationId: getEmailEventReport
export def "smtp-statistics-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number limitation for the result returned (format: int64, default: 2500)
  --offset: int # Beginning point in the list to retrieve from. (format: int64, default: 0)
  --startDate: string # **Mandatory if endDate is used.** Starting date of the report (YYYY-MM-DD). Must be lower than equal to endDate
  --endDate: string # **Mandatory if startDate is used.** Ending date of the report (YYYY-MM-DD). Must be greater than equal to startDate
  --days: int # Number of days in the past including today (positive integer). _Not compatible with 'startDate' and 'endDate'_  (format: int64)
  --email: string # Filter the report for a specific email addresses (format: email)
  --event: string@event-completer # Filter the report for a specific event type
  --tags: string # Filter the report for tags (serialized and urlencoded array). To pass multiple tags, a format of string separated by commas is used such as **"one, two, three"**
  --messageId: string # Filter on a specific message id
  --templateId: int # Filter on a specific template id (format: int64)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<events: table<email: string, date: string, subject: string, messageId: string, event: string, reason: string, tag: string, ip: string, link: string, from: string, templateId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "messageId" $messageId "scalar") (serialize-qp "templateId" $templateId "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/smtp/statistics/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unblock or resubscribe a transactional contact
#
# DELETE /smtp/blockedContacts/{email}
export def "smtp-blocked-contacts delete" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smtp/blockedContacts/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of blocked or unsubscribed transactional contacts
#
# GET /smtp/blockedContacts
# operationId: getTransacBlockedContacts
export def "smtp-blocked-contacts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # **Mandatory if endDate is used.** Starting date (YYYY-MM-DD) from which you want to fetch the blocked or unsubscribed contacts
  --endDate: string # **Mandatory if startDate is used.** Ending date (YYYY-MM-DD) till which you want to fetch the blocked or unsubscribed contacts
  --limit: int # Number of documents returned per page (format: int64, default: 50)
  --offset: int # Index of the first document on the page (format: int64, default: 0)
  --senders: list # Comma separated list of emails of the senders from which contacts are blocked or unsubscribed
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<count: int, contacts: table<email: string, senderEmail: string, reason: record, blockedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "senders" $senders "csv") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/smtp/blockedContacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of blocked domains
#
# GET /smtp/blockedDomains
# operationId: getBlockedDomains
export def "smtp-blocked-domains get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domains: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/smtp/blockedDomains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new domain to the list of blocked domains
#
# POST /smtp/blockedDomains
# operationId: blockNewDomain
export def "smtp-blocked-domains blockNewDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  domain: string # name of the domain to be blocked (e.g. example.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/smtp/blockedDomains")
  let body = {domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unblock an existing domain from the list of blocked domains
#
# DELETE /smtp/blockedDomains/{domain}
# operationId: deleteBlockedDomain
export def "smtp-blocked-domains delete" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smtp/blockedDomains/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete hardbounces
#
# POST /smtp/deleteHardbounces
# operationId: deleteHardbounces
export def "smtp-delete-hardbounces post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # Starting date (YYYY-MM-DD) of the time period for deletion. The hardbounces occurred after this date will be deleted. Must be less than or equal to the endDate (e.g. 2016-12-31)
  --endDate: string # Ending date (YYYY-MM-DD) of the time period for deletion. The hardbounces until this date will be deleted. Must be greater than or equal to the startDate (e.g. 2017-01-31)
  --contactEmail: string # Target a specific email address (format: email, e.g. alex76@example.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/smtp/deleteHardbounces")
  let body = {startDate: $startDate, endDate: $endDate, contactEmail: $contactEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fetch scheduled emails by batchId or messageId
#
# GET /smtp/emailStatus/{identifier}
# operationId: getScheduledEmailById
export def "smtp-email-status get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # Mandatory if `endDate` is used. Starting date (YYYY-MM-DD) from which you want to fetch the list. Can be maximum 30 days older tha current date. (format: date, e.g. 2022-02-02)
  --endDate: string # Mandatory if `startDate` is used. Ending date (YYYY-MM-DD) till which you want to fetch the list. Maximum time period that can be selected is one month. (format: date, e.g. 2022-03-02)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed. Not valid when identifier is `messageId`. (default: desc)
  --status: string@status-completer-2 # Filter the records by `status` of the scheduled email batch or message. Not valid when identifier is `messageId`.
  --limit: int # Number of documents returned per page. Not valid when identifier is `messageId`. (format: int64, default: 100, e.g. 100)
  --offset: int # Index of the first document on the page.  Not valid when identifier is `messageId`. (format: int64, default: 0, e.g. 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/smtp/emailStatus/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete scheduled emails by batchId or messageId
#
# DELETE /smtp/email/{identifier}
# operationId: deleteScheduledEmailById
export def "smtp-email delete" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smtp/email/($identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the contacts
#
# GET /contacts
# operationId: getContacts
export def "contacts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of documents per page (format: int64, default: 50)
  --offset: int # Index of the first document of the page (format: int64, default: 0)
  --modifiedSince: string # Filter (urlencoded) the contacts modified after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.**
  --createdSince: string # Filter (urlencoded) the contacts created after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.**
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
  --segmentId: int # Id of the segment. **Either listIds or segmentId can be passed.** (format: int64)
  --listIds: list # Ids of the list. **Either listIds or segmentId can be passed.**
  --filter: string # Filter the contacts on the basis of attributes. **Allowed operator: equals. For multiple-choice options, the filter will apply an AND condition between the options. For category attributes, the filter will work with both id and value. (e.g. filter=equals(FIRSTNAME,"Antoine"), filter=equals(B1, true), filter=equals(DOB, "1989-11-23"), filter=equals(GENDER, "1"), filter=equals(GENDER, "MALE"), filter=equals(COUNTRY,"USA, INDIA")**
]: nothing -> record<contacts: list<record>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "createdSince" $createdSince "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "segmentId" $segmentId "scalar") (serialize-qp "listIds" $listIds "multi") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a contact
#
# POST /contacts
# operationId: createContact
export def "contacts createContact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Email address of the user. **Mandatory if "ext_id"  & "SMS" field is not passed.**  (format: email, e.g. elly@example.com)
  --ext-id: string # Pass your own Id to create a contact. (e.g. externalId)
  --attributes: record # Pass the set of attributes and their values. The attribute's parameter should be passed in capital letter while creating a contact. Values that don't match the attribute type (e.g. text or string in a date attribute) will be ignored. **These attributes must be present in your Brevo account.**. For eg: **{"FNAME":"Elly", "LNAME":"Roger", "COUNTRIES":["India","China"]}**  (e.g. {FNAME: Elly, LNAME: Roger, COUNTRIES: [India, China]})
  --emailBlacklisted: oneof<nothing, bool> # Set this field to blacklist the contact for emails (emailBlacklisted = true) (e.g. false)
  --smsBlacklisted: oneof<nothing, bool> # Set this field to blacklist the contact for SMS (smsBlacklisted = true) (e.g. false)
  --listIds: list # Ids of the lists to add the contact to
  --updateEnabled: oneof<nothing, bool> # Facilitate to update the existing contact in the same request (updateEnabled = true) (default: false, e.g. false)
  --smtpBlacklistSender: list # transactional email forbidden sender for contact. Use only for email Contact ( only available if updateEnabled = true )
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts")
  let body = {email: $email, ext_id: $ext_id, attributes: $attributes, emailBlacklisted: $emailBlacklisted, smsBlacklisted: $smsBlacklisted, listIds: $listIds, updateEnabled: $updateEnabled, smtpBlacklistSender: $smtpBlacklistSender} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Contact via DOI (Double-Opt-In) Flow
#
# POST /contacts/doubleOptinConfirmation
# operationId: createDoiContact
export def "contacts-double-optin-confirmation createDoiContact" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Email address where the confirmation email will be sent. This email address will be the identifier for all other contact attributes. (format: email, e.g. elly@example.com)
  --attributes: record # Pass the set of attributes and their values. **These attributes must be present in your Brevo account**. For eg. **{'FNAME':'Elly', 'LNAME':'Roger', 'COUNTRIES':['India','China']}**  (e.g. {FNAME: Elly, LNAME: Roger, COUNTRIES: [India, China]})
  includeListIds: list # Lists under user account where contact should be added
  --excludeListIds: list # Lists under user account where contact should not be added
  templateId: int # Id of the Double opt-in (DOI) template (format: int64, e.g. 2)
  redirectionUrl: string # URL of the web page that user will be redirected to after clicking on the double opt in URL. When editing your DOI template you can reference this URL by using the tag **{{ params.DOIurl }}**.  (format: url, e.g. http://requestb.in/173lyyx1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/doubleOptinConfirmation")
  let body = {email: $email, attributes: $attributes, includeListIds: $includeListIds, excludeListIds: $excludeListIds, templateId: $templateId, redirectionUrl: $redirectionUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a contact's details
#
# GET /contacts/{identifier}
# operationId: getContactInfo
export def "contacts get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identifierType: string@identifierType-completer # email_id for Email, phone_id for SMS attribute, contact_id for ID of the contact, ext_id for EXT_ID attribute, whatsapp_id for WHATSAPP attribute, landline_number_id for LANDLINE_NUMBER attribute
  --startDate: string # **Mandatory if endDate is used.** Starting date (YYYY-MM-DD) of the statistic events specific to campaigns. Must be lower than equal to endDate
  --endDate: string # **Mandatory if startDate is used.** Ending date (YYYY-MM-DD) of the statistic events specific to campaigns. Must be greater than equal to startDate.
]: nothing -> record<email: string, id: int, emailBlacklisted: bool, smsBlacklisted: bool, createdAt: string, modifiedAt: string, listIds: list<int>, listUnsubscribed: list<int>, attributes: record, statistics: record<messagesSent: list<record>, hardBounces: list<record>, softBounces: list<record>, complaints: list<record>, unsubscriptions: record<userUnsubscription: list, adminUnsubscription: list>, opened: list<record>, clicked: list<record>, transacAttributes: list<record>, delivered: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a contact
#
# DELETE /contacts/{identifier}
# operationId: deleteContact
export def "contacts delete" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identifierType: string@identifierType-completer # email_id for Email, contact_id for ID of the contact, ext_id for EXT_ID attribute, phone_id for SMS attribute, whatsapp_id for WHATSAPP attribute, landline_number_id for LANDLINE_NUMBER attribute
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a contact
#
# PUT /contacts/{identifier}
# operationId: updateContact
export def "contacts updateContact" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identifierType: string@identifierType-completer # email_id for Email, contact_id for ID of the contact, ext_id for EXT_ID attribute, phone_id for SMS attribute, whatsapp_id for WHATSAPP attribute, landline_number_id for LANDLINE attribute
  --attributes: record # Pass the set of attributes to be updated. **These attributes must be present in your account**. To update existing email address of a contact with the new one please pass EMAIL in attributes. For example, **{ "EMAIL":"newemail@domain.com", "FNAME":"Ellie", "LNAME":"Roger", "COUNTRIES":["India","China"]}**. The attribute's parameter should be passed in capital letter while updating a contact. Values that don't match the attribute type (e.g. text or string in a date attribute) will be ignored. Keep in mind transactional attributes can be updated the same way as normal attributes. Mobile Number in **SMS** field should be passed with proper country code. For example: **{"SMS":"+91xxxxxxxxxx"} or {"SMS":"0091xxxxxxxxxx"}**  (e.g. {EMAIL: newemail@domain.com, FNAME: Ellie, LNAME: Roger, COUNTRIES: [India, China]})
  --ext-id: string # Pass your own Id to update ext_id of a contact. (e.g. updateExternalId)
  --emailBlacklisted: oneof<nothing, bool> # Set/unset this field to blacklist/allow the contact for emails (emailBlacklisted = true) (e.g. false)
  --smsBlacklisted: oneof<nothing, bool> # Set/unset this field to blacklist/allow the contact for SMS (smsBlacklisted = true) (e.g. true)
  --listIds: list # Ids of the lists to add the contact to
  --unlinkListIds: list # Ids of the lists to remove the contact from
  --smtpBlacklistSender: list # transactional email forbidden sender for contact. Use only for email Contact
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/($identifier)" $qp)
  let body = {attributes: $attributes, ext_id: $ext_id, emailBlacklisted: $emailBlacklisted, smsBlacklisted: $smsBlacklisted, listIds: $listIds, unlinkListIds: $unlinkListIds, smtpBlacklistSender: $smtpBlacklistSender} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update multiple contacts
#
# POST /contacts/batch
# operationId: updateBatchContacts
# --contacts item shape: {email?: string, id?: int, sms?: string, ext_id?: string, attributes?: record, emailBlacklisted?: bool, smsBlacklisted?: bool, listIds?: list, unlinkListIds?: list, smtpBlacklistSender?: list}
export def "contacts-batch updateBatchContacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contacts: list # List of contacts to be updated — item shape: {email?: string, id?: int, sms?: string, ext_id?: string, attributes?: record, emailBlacklisted?: bool, smsBlacklisted?: bool, listIds?: list, unlinkListIds?: list, smtpBlacklistSender?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/batch")
  let body = {contacts: $contacts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get email campaigns' statistics for a contact
#
# GET /contacts/{identifier}/campaignStats
# operationId: getContactStats
export def "contacts-campaign-stats get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # **Mandatory if endDate is used.** Starting date (YYYY-MM-DD) of the statistic events specific to campaigns. Must be lower than equal to endDate
  --endDate: string # **Mandatory if startDate is used.** Ending date (YYYY-MM-DD) of the statistic events specific to campaigns. Must be greater than equal to startDate. Maximum difference between startDate and endDate should not be greater than 90 days
]: nothing -> record<messagesSent: table<campaignId: int, eventTime: string>, hardBounces: table<campaignId: int, eventTime: string>, softBounces: table<campaignId: int, eventTime: string>, complaints: table<campaignId: int, eventTime: string>, unsubscriptions: record<userUnsubscription: list<record>, adminUnsubscription: list<record>>, opened: table<campaignId: int, count: int, eventTime: string, ip: string>, clicked: table<campaignId: int, links: list>, transacAttributes: table<orderDate: string, orderPrice: float, orderId: int>, delivered: table<campaignId: int, eventTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/($identifier)/campaignStats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all attributes
#
# GET /contacts/attributes
# operationId: getAttributes
export def "contacts-attributes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attributes: table<name: string, category: string, type: string, enumeration: list, calculatedValue: string, multiCategoryOptions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/attributes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update contact attribute
#
# PUT /contacts/attributes/{attributeCategory}/{attributeName}
# operationId: updateAttribute
# --enumeration item shape: {value: int, label: string}
export def "contacts-attributes updateAttribute" [
  attributeCategory: string
  attributeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # Value of the attribute to update. **Use only if the attribute's category is 'calculated' or 'global'**  (e.g. COUNT[BLACKLISTED,BLACKLISTED,<,NOW()])
  --enumeration: list # List of the values and labels that the attribute can take. **Use only if the attribute's category is "category"**. None of the category options can exceed max 200 characters. For example, **[{"value":1, "label":"male"}, {"value":2, "label":"female"}]** — item shape: {value: int, label: string}
  --multiCategoryOptions: list # Use this option to add multiple-choice attributes options only if the attribute's category is "normal". **This option is specifically designed for updating multiple-choice attributes. None of the multicategory options can exceed max 200 characters.** For example: **["USA","INDIA"]**
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/attributes/($attributeCategory)/($attributeName)")
  let body = {value: $value, enumeration: $enumeration, multiCategoryOptions: $multiCategoryOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create contact attribute
#
# POST /contacts/attributes/{attributeCategory}/{attributeName}
# operationId: createAttribute
# --enumeration item shape: {value: int, label: string}
export def "contacts-attributes createAttribute" [
  attributeCategory: string
  attributeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # Value of the attribute. **Use only if the attribute's category is 'calculated' or 'global'**  (e.g. COUNT[BLACKLISTED,BLACKLISTED,<,NOW()])
  --isRecurring: oneof<nothing, bool> # Type of the attribute. **Use only if the attribute's category is 'calculated' or 'global'**  (e.g. true)
  --enumeration: list # List of values and labels that the attribute can take. **Use only if the attribute's category is "category"**. None of the category options can exceed max 200 characters. For example: **[{"value":1, "label":"male"}, {"value":2, "label":"female"}]** — item shape: {value: int, label: string}
  --multiCategoryOptions: list # List of options you want to add for multiple-choice attribute. **Use only if the attribute's category is "normal" and attribute's type is "multiple-choice". None of the multicategory options can exceed max 200 characters.** For example: **["USA","INDIA"]**
  --type: string@type-completer-1 # Type of the attribute. **Use only if the attribute's category is 'normal', 'category' or 'transactional'** Type **user and multiple-choice** is only available if the category is **normal** attribute Type **id** is only available if the category is **transactional** attribute Type **category** is only available if the category is **category** attribute  (e.g. text)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/attributes/($attributeCategory)/($attributeName)")
  let body = {value: $value, isRecurring: $isRecurring, enumeration: $enumeration, multiCategoryOptions: $multiCategoryOptions, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an attribute
#
# DELETE /contacts/attributes/{attributeCategory}/{attributeName}
# operationId: deleteAttribute
export def "contacts-attributes delete-by-attributeCategory-attributeName" [
  attributeCategory: string
  attributeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/attributes/($attributeCategory)/($attributeName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a multiple-choice attribute option
#
# DELETE /contacts/attributes/{attributeType}/{multipleChoiceAttribute}/{multipleChoiceAttributeOption}
# operationId: deleteMultiAttributeOptions
export def "contacts-attributes delete-by-attributeType-multipleChoiceAttribute-multipleChoiceAttributeOption" [
  attributeType: string
  multipleChoiceAttribute: string
  multipleChoiceAttributeOption: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/attributes/($attributeType)/($multipleChoiceAttribute)/($multipleChoiceAttributeOption)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all folders
#
# GET /contacts/folders
# operationId: getFolders
export def "contacts-folders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of documents per page (format: int64, default: 10)
  --offset: int # Index of the first document of the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<folders: list<record>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts/folders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a folder
#
# POST /contacts/folders
# operationId: createFolder
export def "contacts-folders createFolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the folder (e.g. Wordpress Contacts)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/folders")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a folder's details
#
# GET /contacts/folders/{folderId}
# operationId: getFolder
export def "contacts-folders get" [
  folderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, totalBlacklisted: int, totalSubscribers: int, uniqueSubscribers: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/folders/($folderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a folder
#
# PUT /contacts/folders/{folderId}
# operationId: updateFolder
export def "contacts-folders updateFolder" [
  folderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the folder (e.g. Wordpress Contacts)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/folders/($folderId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a folder (and all its lists)
#
# DELETE /contacts/folders/{folderId}
# operationId: deleteFolder
export def "contacts-folders delete" [
  folderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/folders/($folderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get lists in a folder
#
# GET /contacts/folders/{folderId}/lists
# operationId: getFolderLists
export def "contacts-folders-lists get" [
  folderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of documents per page (format: int64, default: 10)
  --offset: int # Index of the first document of the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<lists: list<record>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/folders/($folderId)/lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the lists
#
# GET /contacts/lists
# operationId: getLists
export def "contacts-lists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of documents per page (format: int64, default: 10)
  --offset: int # Index of the first document of the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<lists: list<record>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts/lists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a list
#
# POST /contacts/lists
# operationId: createList
export def "contacts-lists createList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the list (e.g. Magento Customer - ES)
  folderId: int # Id of the parent folder in which this list is to be created (format: int64, e.g. 2)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/lists")
  let body = {name: $name, folderId: $folderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list's details
#
# GET /contacts/lists/{listId}
# operationId: getList
export def "contacts-lists get" [
  listId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # **Mandatory if endDate is used**. Ending (urlencoded) UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) to aggregate the sent email campaigns for a specific list id. **Prefer to pass your timezone in date-time format for accurate result**
  --endDate: string # **Mandatory if startDate is used**. Ending (urlencoded) UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) to aggregate the sent email campaigns for a specific list id. **Prefer to pass your timezone in date-time format for accurate result**
]: nothing -> record<id: int, name: string, totalBlacklisted: int, totalSubscribers: int, uniqueSubscribers: int, folderId: int, createdAt: string, campaignStats: table<campaignId: int, stats: record>, dynamicList: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/lists/($listId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a list
#
# PUT /contacts/lists/{listId}
# operationId: updateList
export def "contacts-lists updateList" [
  listId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the list. Either of the two parameters (name, folderId) can be updated at a time. (e.g. Magento Customer - ES)
  --folderId: int # Id of the folder in which the list is to be moved. Either of the two parameters (name, folderId) can be updated at a time. (format: int64, e.g. 2)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/lists/($listId)")
  let body = {name: $name, folderId: $folderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a list
#
# DELETE /contacts/lists/{listId}
# operationId: deleteList
export def "contacts-lists delete" [
  listId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/lists/($listId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the segments
#
# GET /contacts/segments
# operationId: getSegments
export def "contacts-segments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of documents per page (format: int64, default: 10)
  --offset: int # Index of the first document of the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<segments: list<record>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts/segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get contacts in a list
#
# GET /contacts/lists/{listId}/contacts
# operationId: getContactsFromList
export def "contacts-lists-contacts get" [
  listId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --modifiedSince: string # Filter (urlencoded) the contacts modified after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.**
  --limit: int # Number of documents per page (format: int64, default: 50)
  --offset: int # Index of the first document of the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<contacts: list<record>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/contacts/lists/($listId)/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add existing contacts to a list
#
# POST /contacts/lists/{listId}/contacts/add
# operationId: addContactToList
export def "contacts-lists-contacts-add addContactToList" [
  listId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: list # Emails to add to a list. You can pass a **maximum of 150 emails** for addition in one request. **_If you need to add the emails in bulk, please prefer /contacts/import api._**
  --ids: list # IDs to add to a list. You can pass a **maximum of 150 IDs** for addition in one request. **_If you need to add the emails in bulk, please prefer /contacts/import api._**
  --extIds: list # EXT_ID attributes to add to a list. You can pass a **maximum of 150 EXT_ID attributes** for addition in one request. **_If you need to add the emails in bulk, please prefer /contacts/import api._**
]: any -> record<contacts: record<success: any, failure: any, total: int, processId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/lists/($listId)/contacts/add")
  let body = {emails: $emails, ids: $ids, extIds: $extIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a contact from a list
#
# POST /contacts/lists/{listId}/contacts/remove
# operationId: removeContactFromList
export def "contacts-lists-contacts-remove removeContactFromList" [
  listId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emails: list # **Required if 'all' is false and 'ids', 'extIds' are empty.** Emails to remove from a list. You can pass a **maximum of 150 emails** for removal in one request.
  --ids: list # **Required if 'all' is false and 'emails', 'extIds' are empty.** IDs to remove from a list. You can pass a **maximum of 150 IDs** for removal in one request.
  --all: oneof<nothing, bool> # **Required if 'emails', 'extIds' and 'ids' are empty.** Remove all existing contacts from a list. A process will be created in this scenario. You can fetch the process details to know about the progress  (e.g. true)
  --extIds: list # **Required if 'all' is false, 'ids' and 'emails' are empty.** EXT_ID attributes to remove from a list. You can pass a **maximum of 150 EXT_ID attributes** for removal in one request.
]: any -> record<contacts: record<success: any, failure: any, total: int, processId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/contacts/lists/($listId)/contacts/remove")
  let body = {emails: $emails, ids: $ids, all: $all, extIds: $extIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export contacts
#
# POST /contacts/export
# operationId: requestContactExport
# --customContactFilter shape: {actionForContacts?: "allContacts"|"subscribed"|"unsubscribed"|"unsubscribedPerList", actionForEmailCampaigns?: "openers"|"nonOpeners"|"clickers"|"nonClickers"|"unsubscribed"|"hardBounces"|"softBounces", actionForSmsCampaigns?: "hardBounces"|"softBounces"|"unsubscribed", listId?: int, segmentId?: int, emailCampaignId?: int, smsCampaignId?: int}
export def "contacts-export requestContactExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exportAttributes: list # List of all the attributes that you want to export. **These attributes must be present in your contact database. It is required if exportMandatoryAttributes is set false. ** For example: **['fname', 'lname', 'email']**
  customContactFilter: record # Set the filter for the contacts to be exported. — shape: {actionForContacts?: "allContacts"|"subscribed"|"unsubscribed"|"unsubscribedPerList", actionForEmailCampaigns?: "openers"|"nonOpeners"|"clickers"|"nonClickers"|"unsubscribed"|"hardBounces"|"softBounces", actionForSmsCampaigns?: "hardBounces"|"softBounces"|"unsubscribed", listId?: int, segmentId?: int, emailCampaignId?: int, smsCampaignId?: int}
  --notifyUrl: string # Webhook that will be called once the export process is finished. For reference, https://help.brevo.com/hc/en-us/articles/360007666479 (format: url, e.g. http://requestb.in/173lyyx1)
  --disableNotification: oneof<nothing, bool> # To avoid generating the email notification upon contact export, pass **true** (default: false, e.g. false)
  --exportMandatoryAttributes: oneof<nothing, bool> # To export mandatory attributes like EMAIL, ADDED_TIME, MODIFIED_TIME (default: true, e.g. false)
  --exportSubscriptionStatus: list # Export subscription status of contacts for email & sms marketting. Pass email_marketing to obtain the marketing email subscription status & sms_marketing to retrieve the marketing SMS status of the contact.
  --exportMetadata: list # Export metadata of contacts such as _listIds, ADDED_TIME, MODIFIED_TIME.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/export")
  let body = {exportAttributes: $exportAttributes, customContactFilter: $customContactFilter, notifyUrl: $notifyUrl, disableNotification: $disableNotification, exportMandatoryAttributes: $exportMandatoryAttributes, exportSubscriptionStatus: $exportSubscriptionStatus, exportMetadata: $exportMetadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Import contacts
#
# POST /contacts/import
# operationId: importContacts
# --jsonBody item shape: {email?: string, attributes?: record}
# --newList shape: {listName?: string, folderId?: int}
export def "contacts-import importContacts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fileUrl: string # **Mandatory if fileBody and jsonBody is not defined.** URL of the file to be imported (**no local file**). Possible file formats: #### .txt, .csv, .json  (format: url, e.g. https://importfile.domain.com)
  --fileBody: string # **Mandatory if fileUrl and jsonBody is not defined.** CSV content to be imported. Use semicolon to separate multiple attributes. **Maximum allowed file body size is 10MB** . However we recommend a safe limit of around 8 MB to avoid the issues caused due to increase of file body size while parsing. Please use fileUrl instead to import bigger files.  (e.g. NAME;SURNAME;EMAIL Smith;John;john.smith@example.com Roger;Ellie;ellie36@example.com)
  --jsonBody: list # **Mandatory if fileUrl and fileBody is not defined.** JSON content to be imported. **Maximum allowed json body size is 10MB** . However we recommend a safe limit of around 8 MB to avoid the issues caused due to increase of json body size while parsing. Please use fileUrl instead to import bigger files. — item shape: {email?: string, attributes?: record}
  --listIds: list # **Mandatory if newList is not defined.** Ids of the lists in which the contacts shall be imported. For example, **[2, 4, 7]**.
  --notifyUrl: string # URL that will be called once the import process is finished. For reference, https://help.brevo.com/hc/en-us/articles/360007666479 (format: url, e.g. http://requestb.in/173lyyx1)
  --newList: record # To create a new list and import the contacts into it, pass the listName and an optional folderId. — shape: {listName?: string, folderId?: int}
  --emailBlacklist: oneof<nothing, bool> # To blacklist all the contacts for email (default: false, e.g. false)
  --disableNotification: oneof<nothing, bool> # To disable email notification (default: false, e.g. false)
  --smsBlacklist: oneof<nothing, bool> # To blacklist all the contacts for sms (default: false, e.g. false)
  --updateExistingContacts: oneof<nothing, bool> # To facilitate the choice to update the existing contacts (default: true, e.g. true)
  --emptyContactsAttributes: oneof<nothing, bool> # To facilitate the choice to erase any attribute of the existing contacts with empty value. emptyContactsAttributes = true means the empty fields in your import will erase any attribute that currently contain data in Brevo, & emptyContactsAttributes = false means the empty fields will not affect your existing data ( **only available if `updateExistingContacts` set to true **)  (default: false, e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/contacts/import")
  let body = {fileUrl: $fileUrl, fileBody: $fileBody, jsonBody: $jsonBody, listIds: $listIds, notifyUrl: $notifyUrl, newList: $newList, emailBlacklist: $emailBlacklist, disableNotification: $disableNotification, smsBlacklist: $smsBlacklist, updateExistingContacts: $updateExistingContacts, emptyContactsAttributes: $emptyContactsAttributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create/Update object records in bulk
#
# POST /objects/{object_type}/batch/upsert
# operationId: upsertrecords
export def "objects-batch-upsert upsertrecords" [
  object_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  records: list # List of object records to be upsert. Each record can have attributes, identifiers, and associations.
]: any -> record<processId: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/objects/($object_type)/batch/upsert")
  let body = {records: $records} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the list of object records and total records count for an object.
#
# GET /objects/{object_type}/records
# operationId: getrecords
export def "objects-records getrecords" [
  object_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of records returned per page (format: int64)
  --page-num: int # Page number for pagination. It's used to fetch the object records on a provided page number. Must be a valid positive integer. (format: int64)
  --qp-sort: string@sort-completer # Sort order, must be 'asc' or 'desc'. Default to 'desc' if not provided. (default: desc)
  --association: string@association-completer # Whether to include associations, must be 'true' or 'false'. Default to 'false' if not provided.
]: nothing -> record<count: int, records: table<createdAt: string, updatedAt: string, identifiers: record, attributes: record, associations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page_num" $page_num "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "association" $association "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/objects/($object_type)/records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the information for all your created SMS campaigns
#
# GET /smsCampaigns
# operationId: getSmsCampaigns
export def "sms-campaigns list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-3 # Status of campaign.
  --startDate: string # **Mandatory if endDate is used.** Starting (urlencoded) UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) to filter the sent sms campaigns. **Prefer to pass your timezone in date-time format for accurate result** ( only available if either 'status' not passed and if passed is set to 'sent' )
  --endDate: string # **Mandatory if startDate is used.** Ending (urlencoded) UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) to filter the sent sms campaigns. **Prefer to pass your timezone in date-time format for accurate result** ( only available if either 'status' not passed and if passed is set to 'sent' )
  --limit: int # Number limitation for the result returned (format: int64, default: 500)
  --offset: int # Beginning point in the list to retrieve from. (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<campaigns: list<record>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/smsCampaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an SMS campaign
#
# POST /smsCampaigns
# operationId: createSmsCampaign
# --recipients shape: {listIds: list, exclusionListIds?: list}
export def "sms-campaigns createSmsCampaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the campaign (e.g. Spring Promo Code)
  sender: string # Name of the sender. **The number of characters is limited to 11 for alphanumeric characters and 15 for numeric characters**  (e.g. MyShop)
  content: string # Content of the message. The **maximum characters used per SMS is 160**, if used more than that, it will be counted as more than one SMS  (e.g. Get a discount by visiting our NY store and saying : Happy Spring!)
  --recipients: record # shape: {listIds: list, exclusionListIds?: list}
  --scheduledAt: string # UTC date-time on which the campaign has to run (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.**  (e.g. 2017-05-05T12:30:00+02:00)
  --unicodeEnabled: oneof<nothing, bool> # Format of the message. It indicates whether the content should be treated as unicode or not.  (default: false, e.g. true)
  --organisationPrefix: string # A recognizable prefix will ensure your audience knows who you are. Recommended by U.S. carriers. This will be added as your Brand Name before the message content. **Prefer verifying maximum length of 160 characters including this prefix in message content to avoid multiple sending of same sms.** (e.g. MyCompany)
  --unsubscribeInstruction: string # Instructions to unsubscribe from future communications. Recommended by U.S. carriers. Must include **STOP** keyword. This will be added as instructions after the end of message content. **Prefer verifying maximum length of 160 characters including this instructions in message content to avoid multiple sending of same sms.** (e.g. send Stop if you want to unsubscribe.)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/smsCampaigns")
  let body = {name: $name, sender: $sender, content: $content, recipients: $recipients, scheduledAt: $scheduledAt, unicodeEnabled: $unicodeEnabled, organisationPrefix: $organisationPrefix, unsubscribeInstruction: $unsubscribeInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an SMS campaign
#
# GET /smsCampaigns/{campaignId}
# operationId: getSmsCampaign
export def "sms-campaigns get" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, status: string, content: string, scheduledAt: string, sender: string, createdAt: string, modifiedAt: string, recipients: record, statistics: record> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smsCampaigns/($campaignId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an SMS campaign
#
# PUT /smsCampaigns/{campaignId}
# operationId: updateSmsCampaign
# --recipients shape: {listIds: list, exclusionListIds?: list}
export def "sms-campaigns updateSmsCampaign" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the campaign (e.g. Spring Promo Code)
  --sender: string # Name of the sender. **The number of characters is limited to 11 for alphanumeric characters and 15 for numeric characters**  (e.g. MyShop)
  --content: string # Content of the message. The **maximum characters used per SMS is 160**, if used more than that, it will be counted as more than one SMS  (e.g. Get a discount by visiting our NY store and saying : Happy Spring!)
  --recipients: record # shape: {listIds: list, exclusionListIds?: list}
  --scheduledAt: string # UTC date-time on which the campaign has to run (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.**  (e.g. 2017-05-05T12:30:00+02:00)
  --unicodeEnabled: oneof<nothing, bool> # Format of the message. It indicates whether the content should be treated as unicode or not.  (default: false, e.g. true)
  --organisationPrefix: string # A recognizable prefix will ensure your audience knows who you are. Recommended by U.S. carriers. This will be added as your Brand Name before the message content. **Prefer verifying maximum length of 160 characters including this prefix in message content to avoid multiple sending of same sms.** (e.g. MyCompany)
  --unsubscribeInstruction: string # Instructions to unsubscribe from future communications. Recommended by U.S. carriers. Must include **STOP** keyword. This will be added as instructions after the end of message content. **Prefer verifying maximum length of 160 characters including this instructions in message content to avoid multiple sending of same sms.** (e.g. send Stop if you want to unsubscribe.)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smsCampaigns/($campaignId)")
  let body = {name: $name, sender: $sender, content: $content, recipients: $recipients, scheduledAt: $scheduledAt, unicodeEnabled: $unicodeEnabled, organisationPrefix: $organisationPrefix, unsubscribeInstruction: $unsubscribeInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an SMS campaign
#
# DELETE /smsCampaigns/{campaignId}
# operationId: deleteSmsCampaign
export def "sms-campaigns delete" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smsCampaigns/($campaignId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send your SMS campaign immediately
#
# POST /smsCampaigns/{campaignId}/sendNow
# operationId: sendSmsCampaignNow
export def "sms-campaigns-send-now sendSmsCampaignNow" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smsCampaigns/($campaignId)/sendNow")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a campaign's status
#
# PUT /smsCampaigns/{campaignId}/status
# operationId: updateSmsCampaignStatus
export def "sms-campaigns-status updateSmsCampaignStatus" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Note:- **replicateTemplate** status will be available **only for template type campaigns.**
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smsCampaigns/($campaignId)/status")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a test SMS campaign
#
# POST /smsCampaigns/{campaignId}/sendTest
# operationId: sendTestSms
export def "sms-campaigns-send-test sendTestSms" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --phoneNumber: string # Mobile number of the recipient with the country code. This number **must belong to one of your contacts in Brevo account and must not be blacklisted**  (e.g. 33689965433)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smsCampaigns/($campaignId)/sendTest")
  let body = {phoneNumber: $phoneNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Export an SMS campaign's recipients
#
# POST /smsCampaigns/{campaignId}/exportRecipients
# operationId: requestSmsRecipientExport
export def "sms-campaigns-export-recipients requestSmsRecipientExport" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notifyURL: string # URL that will be called once the export process is finished. For reference, https://help.brevo.com/hc/en-us/articles/360007666479 (format: url, e.g. http://requestb.in/173lyyx1)
  recipientsType: string@recipientsType-completer-1 # Filter the recipients based on how they interacted with the campaign (e.g. answered)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smsCampaigns/($campaignId)/exportRecipients")
  let body = {notifyURL: $notifyURL, recipientsType: $recipientsType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send an SMS campaign's report
#
# POST /smsCampaigns/{campaignId}/sendReport
# operationId: sendSmsReport
# --email shape: {to: list, body: string}
export def "sms-campaigns-send-report sendSmsReport" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # Language of email content for campaign report sending. (default: fr, e.g. en)
  email: record # Custom attributes for the report email. — shape: {to: list, body: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/smsCampaigns/($campaignId)/sendReport")
  let body = {language: $language, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send SMS message asynchronously to a mobile number
#
# POST /transactionalSMS/send
# operationId: sendAsyncTransactionalSms
export def "transactional-sms-send sendAsyncTransactionalSms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sender: string # Name of the sender. **The number of characters is limited to 11 for alphanumeric characters and 15 for numeric characters**  (e.g. MyShop)
  recipient: string # Mobile number to send SMS with the country code (e.g. 33689965433)
  content: string # Content of the message. If more than **160 characters** long, will be sent as multiple text messages  (e.g. Enter this code:CCJJG8 to validate your account)
  --type: string@type-completer-2 # Type of the SMS. Marketing SMS messages are those sent typically with marketing content. Transactional SMS messages are sent to individuals and are triggered in response to some action, such as a sign-up, purchase, etc. (default: transactional, e.g. marketing)
  --tag: string # A tag can have two types of values, either a string or an array of strings. (e.g. "tag1" OR ["tag1", "tag2"])
  --webUrl: string # Webhook to call for each event triggered by the message (delivered etc.) (format: url, e.g. http://requestb.in/173lyyx1)
  --unicodeEnabled: oneof<nothing, bool> # Format of the message. It indicates whether the content should be treated as unicode or not.  (default: false, e.g. true)
  --organisationPrefix: string # A recognizable prefix will ensure your audience knows who you are. Recommended by U.S. carriers. This will be added as your Brand Name before the message content. **Prefer verifying maximum length of 160 characters including this prefix in message content to avoid multiple sending of same sms.** (e.g. MyCompany)
]: any -> record<messageId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactionalSMS/send")
  let body = {sender: $sender, recipient: $recipient, content: $content, type: $type, tag: $tag, webUrl: $webUrl, unicodeEnabled: $unicodeEnabled, organisationPrefix: $organisationPrefix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send SMS message to a mobile number
#
# POST /transactionalSMS/sms
# operationId: sendTransacSms
export def "transactional-sms-sms sendTransacSms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sender: string # Name of the sender. **The number of characters is limited to 11 for alphanumeric characters and 15 for numeric characters**  (e.g. MyShop)
  recipient: string # Mobile number to send SMS with the country code (e.g. 33689965433)
  content: string # Content of the message. If more than **160 characters** long, will be sent as multiple text messages  (e.g. Enter this code:CCJJG8 to validate your account)
  --type: string@type-completer-2 # Type of the SMS. Marketing SMS messages are those sent typically with marketing content. Transactional SMS messages are sent to individuals and are triggered in response to some action, such as a sign-up, purchase, etc. (default: transactional, e.g. marketing)
  --tag: string # A tag can have two types of values, either a string or an array of strings. (e.g. "tag1" OR ["tag1", "tag2"])
  --webUrl: string # Webhook to call for each event triggered by the message (delivered etc.) (format: url, e.g. http://requestb.in/173lyyx1)
  --unicodeEnabled: oneof<nothing, bool> # Format of the message. It indicates whether the content should be treated as unicode or not.  (default: false, e.g. true)
  --organisationPrefix: string # A recognizable prefix will ensure your audience knows who you are. Recommended by U.S. carriers. This will be added as your Brand Name before the message content. **Prefer verifying maximum length of 160 characters including this prefix in message content to avoid multiple sending of same sms.** (e.g. MyCompany)
]: any -> record<reference: string, messageId: int, smsCount: int, usedCredits: float, remainingCredits: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactionalSMS/sms")
  let body = {sender: $sender, recipient: $recipient, content: $content, type: $type, tag: $tag, webUrl: $webUrl, unicodeEnabled: $unicodeEnabled, organisationPrefix: $organisationPrefix} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get your SMS activity aggregated over a period of time
#
# GET /transactionalSMS/statistics/aggregatedReport
# operationId: getTransacAggregatedSmsReport
export def "transactional-sms-statistics-aggregated-report get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # **Mandatory if endDate is used.** Starting date (YYYY-MM-DD) of the report
  --endDate: string # **Mandatory if startDate is used.** Ending date (YYYY-MM-DD) of the report
  --days: int # Number of days in the past including today (positive integer). **Not compatible with startDate and endDate**  (format: int64)
  --tag: string # Filter on a tag
]: nothing -> record<range: string, requests: int, delivered: int, hardBounces: int, softBounces: int, blocked: int, unsubscribed: int, replied: int, accepted: int, rejected: int, skipped: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactionalSMS/statistics/aggregatedReport" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get your SMS activity aggregated per day
#
# GET /transactionalSMS/statistics/reports
# operationId: getTransacSmsReport
export def "transactional-sms-statistics-reports get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # **Mandatory if endDate is used.** Starting date (YYYY-MM-DD) of the report
  --endDate: string # **Mandatory if startDate is used.** Ending date (YYYY-MM-DD) of the report
  --days: int # Number of days in the past including today (positive integer). **Not compatible with 'startDate' and 'endDate'**  (format: int64)
  --tag: string # Filter on a tag
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<reports: table<date: string, requests: int, delivered: int, hardBounces: int, softBounces: int, blocked: int, unsubscribed: int, replied: int, accepted: int, rejected: int, skipped: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactionalSMS/statistics/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all your SMS activity (unaggregated events)
#
# GET /transactionalSMS/statistics/events
# operationId: getSmsEvents
export def "transactional-sms-statistics-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of documents per page (format: int64, default: 50)
  --startDate: string # **Mandatory if endDate is used.** Starting date (YYYY-MM-DD) of the report
  --endDate: string # **Mandatory if startDate is used.** Ending date (YYYY-MM-DD) of the report
  --offset: int # Index of the first document of the page (format: int64, default: 0)
  --days: int # Number of days in the past including today (positive integer). **Not compatible with 'startDate' and 'endDate'**  (format: int64)
  --phoneNumber: string # Filter the report for a specific phone number
  --event: string@event-completer-1 # Filter the report for specific events
  --tags: string # Filter the report for specific tags passed as a serialized urlencoded array
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<events: table<phoneNumber: string, date: string, messageId: string, event: string, reason: string, reply: string, tag: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "phoneNumber" $phoneNumber "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactionalSMS/statistics/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a WhatsApp campaign
#
# GET /whatsappCampaigns/{campaignId}
# operationId: getWhatsAppCampaign
export def "whatsapp-campaigns get" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, campaignName: string, campaignStatus: string, scheduledAt: string, senderNumber: string, stats: record<sent: int, delivered: int, read: int, unsubscribe: int, notSent: int>, template: record<name: string, category: string, language: string, contains_button: bool, display_header: bool, header_type: string, components: list<record>, header_variables: list<record>, body_variables: list<record>, button_type: string, hide_footer: bool>, createdAt: string, modifiedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whatsappCampaigns/($campaignId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a WhatsApp campaign
#
# DELETE /whatsappCampaigns/{campaignId}
# operationId: deleteWhatsAppCampaign
export def "whatsapp-campaigns delete" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whatsappCampaigns/($campaignId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a WhatsApp campaign
#
# PUT /whatsappCampaigns/{campaignId}
# operationId: updateWhatsAppCampaign
# --recipients shape: {excludedListIds?: list, listIds?: list, segments?: list}
export def "whatsapp-campaigns updateWhatsAppCampaign" [
  campaignId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --campaignName: string # Name of the campaign (e.g. Test WhatsApp)
  --campaignStatus: string@campaignStatus-completer # Status of the campaign (default: scheduled, e.g. scheduled)
  --rescheduleFor: string # Reschedule the sending UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) of campaign. **Prefer to pass your timezone in date-time format for accurate result.For example: **2017-06-01T12:30:00+02:00** Use this field to update the scheduledAt of any existing draft or scheduled WhatsApp campaign.  (e.g. 2017-06-01T12:30:00+02:00)
  --recipients: record # Segment ids and List ids to include/exclude from campaign — shape: {excludedListIds?: list, listIds?: list, segments?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whatsappCampaigns/($campaignId)")
  let body = {campaignName: $campaignName, campaignStatus: $campaignStatus, rescheduleFor: $rescheduleFor, recipients: $recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return all your created WhatsApp templates
#
# GET /whatsappCampaigns/template-list
# operationId: getWhatsAppTemplates
export def "whatsapp-campaigns-template-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # **Mandatory if endDate is used**. Starting (urlencoded) UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) to filter the templates created. **Prefer to pass your timezone in date-time format for accurate result**
  --endDate: string # **Mandatory if startDate is used**. Ending (urlencoded) UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) to filter the templates created. **Prefer to pass your timezone in date-time format for accurate result**
  --limit: int # Number of documents per page (format: int64, default: 50)
  --offset: int # Index of the first document in the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record modification. Default order is **descending** if `sort` is not passed (default: desc)
  --qp-source: string@source-completer # source of the template
]: nothing -> record<templates: table<id: int, name: string, status: string, language: string, category: string, errorReason: string, createdAt: string, modifiedAt: string>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whatsappCampaigns/template-list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create and Send a WhatsApp campaign
#
# POST /whatsappCampaigns
# operationId: createWhatsAppCampaign
# --recipients shape: {excludedListIds?: list, listIds?: list, segments?: list}
export def "whatsapp-campaigns createWhatsAppCampaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the WhatsApp campaign creation (e.g. Test Campaign)
  templateId: int # Id of the WhatsApp template in **approved** state (e.g. 19)
  scheduledAt: string # Sending UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.For example: **2017-06-01T12:30:00+02:00**  (e.g. 2017-06-01T12:30:00+02:00)
  recipients: record # Segment ids and List ids to include/exclude from campaign — shape: {excludedListIds?: list, listIds?: list, segments?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whatsappCampaigns")
  let body = {name: $name, templateId: $templateId, scheduledAt: $scheduledAt, recipients: $recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return all your created WhatsApp campaigns
#
# GET /whatsappCampaigns
# operationId: getWhatsAppCampaigns
export def "whatsapp-campaigns list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # **Mandatory if endDate is used**. Starting (urlencoded) UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) to filter the WhatsApp campaigns created. **Prefer to pass your timezone in date-time format for accurate result**
  --endDate: string # **Mandatory if startDate is used**. Ending (urlencoded) UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) to filter the WhatsApp campaigns created. **Prefer to pass your timezone in date-time format for accurate result**
  --limit: int # Number of documents per page (format: int64, default: 50)
  --offset: int # Index of the first document in the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record modification. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<campaigns: table<id: int, campaignName: string, templateId: string, campaignStatus: string, scheduledAt: string, errorReason: string, invalidatedContacts: int, readPercentage: float, stats: record, createdAt: string, modifiedAt: string>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whatsappCampaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a WhatsApp template
#
# POST /whatsappCampaigns/template
# operationId: createWhatsAppTemplate
export def "whatsapp-campaigns-template createWhatsAppTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the template (e.g. Test template)
  language: string # Language of the template. For Example : **en** for English  (e.g. en)
  category: string@category-completer # Category of the template (e.g. MARKETING)
  --mediaUrl: string # Absolute url of the media file **(no local file)** for the header. **Use this field in you want to add media in Template header and headerText is empty**. Allowed extensions for media files are: #### jpeg | png | mp4 | pdf  (e.g. https://attachment.domain.com)
  bodyText: string # Body of the template. **Maximum allowed characters are 1024** (e.g. making it look like readable English)
  --headerText: string # Text content of the header in the template. **Maximum allowed characters are 45** **Use this field to add text content in template header and if mediaUrl is empty**  (e.g. Test WhatsApp campaign)
  --body-source: string@source-completer # source of the template
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whatsappCampaigns/template")
  let body = {name: $name, language: $language, category: $category, mediaUrl: $mediaUrl, bodyText: $bodyText, headerText: $headerText, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send your WhatsApp template for approval
#
# POST /whatsappCampaigns/template/approval/{templateId}
# operationId: sendWhatsAppTemplateApproval
export def "whatsapp-campaigns-template-approval sendWhatsAppTemplateApproval" [
  templateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/whatsappCampaigns/template/approval/($templateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get your WhatsApp API account information
#
# GET /whatsappCampaigns/config
# operationId: getWhatsAppConfig
export def "whatsapp-campaigns-config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<whatsappBusinessAccountId: string, sendingLimit: string, phoneNumberQuality: string, whatsappBusinessAccountStatus: string, businessStatus: string, phoneNumberNameStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whatsappCampaigns/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get loyalty program list
#
# GET /loyalty/config/programs
# operationId: getLPList
export def "loyalty-config-programs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of documents per page
  --offset: int # Index of the first document in the page
  --sort-field: string@sort-field-completer # Sort documents by field
  --qp-sort: string # Sort documents by field
]: nothing -> record<items: table<codeCount: int, createdAt: string, description: string, documentId: string, id: string, meta: record, name: string, pattern: string, state: string, subscriptionGeneratorId: string, subscriptionPoolId: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/loyalty/config/programs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create loyalty program
#
# POST /loyalty/config/programs
# operationId: createNewLP
export def "loyalty-config-programs createNewLP" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Optional description of the loyalty program (max 256 chars).
  --documentId: string # Optional unique document ID.
  --meta: record # Optional metadata related to the loyalty program.
  name: string # Required name of the loyalty program (max 128 chars).
]: any -> record<codeCount: int, createdAt: string, description: string, documentId: string, id: string, meta: record, name: string, pattern: string, state: string, subscriptionGeneratorId: string, subscriptionPoolId: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/loyalty/config/programs")
  let body = {description: $description, documentId: $documentId, meta: $meta, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get loyalty program Info
#
# GET /loyalty/config/programs/{pid}
# operationId: getLoyaltyProgramInfo
export def "loyalty-config-programs get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<codeCount: int, createdAt: string, description: string, documentId: string, id: string, meta: record, name: string, pattern: string, state: string, subscriptionGeneratorId: string, subscriptionPoolId: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/config/programs/($pid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update loyalty program
#
# PUT /loyalty/config/programs/{pid}
# operationId: updateLoyaltyProgram
export def "loyalty-config-programs updateLoyaltyProgram" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Loyalty Program name
  --description: string # Loyalty Program description
  --meta: record # Loyalty Program meta data
]: any -> record<codeCount: int, createdAt: string, description: string, documentId: string, id: string, meta: record, name: string, pattern: string, state: string, subscriptionGeneratorId: string, subscriptionPoolId: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/config/programs/($pid)")
  let body = {name: $name, description: $description, meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Partially update loyalty program
#
# PATCH /loyalty/config/programs/{pid}
# operationId: partiallyUpdateLoyaltyProgram
export def "loyalty-config-programs partiallyUpdateLoyaltyProgram" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Loyalty Program name
  --description: string # Loyalty Program description
  --meta: record # Loyalty Program meta data
]: any -> record<codeCount: int, createdAt: string, description: string, documentId: string, id: string, meta: record, name: string, pattern: string, state: string, subscriptionGeneratorId: string, subscriptionPoolId: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/config/programs/($pid)")
  let body = {name: $name, description: $description, meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Loyalty Program
#
# DELETE /loyalty/config/programs/{pid}
# operationId: deleteLoyaltyProgram
export def "loyalty-config-programs delete" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/config/programs/($pid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Publish loyalty program
#
# POST /loyalty/config/programs/{pid}/publish
# operationId: publishLoyaltyProgram
export def "loyalty-config-programs-publish publishLoyaltyProgram" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/config/programs/($pid)/publish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create subscription
#
# POST /loyalty/config/programs/{pid}/subscriptions
# operationId: subscribeToLoyaltyProgram
export def "loyalty-config-programs-subscriptions subscribeToLoyaltyProgram" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  contactId: int # Required contact ID; must be greater than 0.
  --creationDate: string # Optional custom date-time format.
  --loyaltySubscriptionId: string # Optional subscription ID (max length 64).
]: any -> record<contactId: int, createdAt: string, loyaltyProgramId: string, loyaltySubscriptionId: string, organizationId: int, updatedAt: string, versionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/config/programs/($pid)/subscriptions")
  let body = {contactId: $contactId, creationDate: $creationDate, loyaltySubscriptionId: $loyaltySubscriptionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create subscription member
#
# POST /loyalty/config/programs/{pid}/subscription-members
# operationId: subscribeMemberToASubscription
export def "loyalty-config-programs-subscription-members subscribeMemberToASubscription" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contactId: int # Required if LoyaltySubscriptionId is not provided, must be greater than 0
  --loyaltySubscriptionId: string # Required if ContactId is not provided, max length 64
  memberContactIds: list # Required, each item must be greater than or equal to 1
]: any -> record<createdAt: string, memberContactIds: list<int>, organizationId: int, ownerContactId: int, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/config/programs/($pid)/subscription-members")
  let body = {contactId: $contactId, loyaltySubscriptionId: $loyaltySubscriptionId, memberContactIds: $memberContactIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete subscription member
#
# DELETE /loyalty/config/programs/{pid}/subscription-members
# operationId: deleteContactMembers
export def "loyalty-config-programs-subscription-members delete" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --memberContactIds: string # Comma-separated list of member contact IDs to delete from the subscription.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "memberContactIds" $memberContactIds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/config/programs/($pid)/subscription-members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Subscription Data
#
# GET /loyalty/config/programs/{pid}/account-info
# operationId: getParameterSubscriptionInfo
export def "loyalty-config-programs-account-info get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contactId: string # The contact ID to filter by.
  --params: string # A list of filter parameters for querying the subscription info.
  --loyaltySubscriptionId: string # The loyalty subscription ID to filter by.
]: nothing -> record<balance: record<balances: list<record>, contactId: int, loyaltyProgramId: string>, members: table<createdAt: string, memberContactId: int, updatedAt: string>, reward: table<code: string, contactId: int, createdAt: string, expirationDate: string, id: string, loyaltyProgramId: string, meta: record, rewardId: string, updatedAt: string>, tier: table<contactId: int, createdAt: string, groupId: string, loyaltyProgramId: string, meta: record, tierId: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contactId" $contactId "scalar") (serialize-qp "params" $params "scalar") (serialize-qp "loyaltySubscriptionId" $loyaltySubscriptionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/config/programs/($pid)/account-info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get code count
#
# GET /loyalty/offer/programs/{pid}/code-pools/{cpid}/codes-count
# operationId: getCodeCount
export def "loyalty-offer-programs-code-pools-codes-count get" [
  pid: string
  cpid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/offer/programs/($pid)/code-pools/($cpid)/codes-count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get voucher for a contact
#
# GET /loyalty/offer/programs/{pid}/vouchers
export def "loyalty-offer-programs-vouchers get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Page size (default: 25)
  --offset: int # Pagination offset (default: 0)
  --qp-sort: string@sort-completer # Sort order (default: desc)
  --sortField: string@sortField-completer # Sort field (default: updatedAt)
  --contactId: int # Contact ID
  --metadata-key-value: string # Metadata value for a Key filter
  --rewardId: string # Reward ID
]: nothing -> record<contactId: int, contactRewards: table<code: string, consumedAt: string, createdAt: string, expirationDate: string, id: string, meta: record, rewardId: string, unit: string, updatedAt: string, value: float>, count: int, loyaltyProgramId: string, loyaltySubscriptionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "contactId" $contactId "scalar") (serialize-qp "metadata_key_value" $metadata_key_value "scalar") (serialize-qp "rewardId" $rewardId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/offer/programs/($pid)/vouchers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Reward Page API
#
# GET /loyalty/offer/programs/{pid}/offers
export def "loyalty-offer-programs-offers get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Page size (default: 25)
  --offset: int # Pagination offset (default: 0)
  --state: string # State of the reward (default: all)
  --version: string@version-completer # Version (default: draft)
]: nothing -> record<items: table<createdAt: string, endDate: string, id: string, loyaltyProgramId: string, name: string, publicImage: string, startDate: string, state: string, updatedAt: string>, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/offer/programs/($pid)/offers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a reward
#
# POST /loyalty/offer/programs/{pid}/offers
# operationId: createReward
export def "loyalty-offer-programs-offers createReward" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Internal name of the reward
  --publicDescription: string # Public facing description of the reward
  --publicImage: string # URL of the public image for the reward (format: uri)
  --publicName: string # Public facing name of the reward
]: any -> record<createdAt: string, id: string, loyaltyProgramId: string, name: string, publicDescription: string, publicImage: string, publicName: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/offer/programs/($pid)/offers")
  let body = {name: $name, publicDescription: $publicDescription, publicImage: $publicImage, publicName: $publicName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get reward information
#
# GET /loyalty/offer/programs/{pid}/rewards/{rid}
export def "loyalty-offer-programs-rewards get" [
  pid: string
  rid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string@version-completer # Version (default: draft)
]: nothing -> record<attributionPerConsumer: int, balanceDefinitionId: string, code: string, codeCount: int, codeGeneratorId: string, codePoolId: string, config: string, createdAt: string, disabledAt: string, endDate: string, expirationDate: string, expirationModifier: string, expirationUnit: string, expirationValue: int, generator: record<createdAt: string, description: string, id: string, name: string, pattern: string, updatedAt: string>, id: string, limits: table<createdAt: string, durationUnit: string, durationValue: int, limitValue: int, rewardLimitId: string, slidingSchedule: bool, type: string, updatedAt: string>, loyaltyProgramId: string, meta: record, name: string, products: table<createdAt: string, imageRef: string, productId: string, value: string>, publicDescription: string, publicImage: string, publicName: string, redeemPerConsumer: int, redeemRules: list<string>, rewardConfigs: record<attribution: string, code: string, value: string>, rule: record<condition: record<and: list, lhs: record, op: string, or: list, rhs: record>, createdAt: string, description: string, event: record<name: string, source: string>, isInternal: bool, loyaltyProgramId: string, loyaltyVersionId: int, meta: record, name: string, results: list<record>, ruleId: string, ruleType: string, updatedAt: string>, startDate: string, subtractBalanceDefinitionId: string, subtractBalanceStrategy: string, subtractBalanceValue: int, subtractTotalBalance: bool, totalAttribution: int, totalRedeem: int, triggerId: string, unit: string, updatedAt: string, value: float, valueType: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/offer/programs/($pid)/rewards/($rid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a voucher
#
# POST /loyalty/offer/programs/{pid}/rewards/attribute
# operationId: createVoucher
export def "loyalty-offer-programs-rewards-attribute createVoucher" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: float # Value of the selected reward config (format: float64)
  --code: string # Code generated to attribute reward to a contact
  --contactId: int # Contact to attribute the reward (format: int64)
  --expirationDate: string # Reward expiration date
  --loyaltySubscriptionId: string # One of contactId or loyaltySubscriptionId is required
  --meta: record # Offer meta information (key/value object)
  rewardId: string # Reward id (format: uuid)
]: any -> record<value: float, code: string, consumedAt: string, contactId: int, createdAt: string, expirationDate: string, id: string, loyaltyProgramId: string, meta: record, rewardId: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/offer/programs/($pid)/rewards/attribute")
  let body = {value: $value, code: $code, contactId: $contactId, expirationDate: $expirationDate, loyaltySubscriptionId: $loyaltySubscriptionId, meta: $meta, rewardId: $rewardId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create redeem voucher request
#
# POST /loyalty/offer/programs/{pid}/rewards/redeem
# operationId: redeemVoucher
export def "loyalty-offer-programs-rewards-redeem redeemVoucher" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributedRewardId: string # Unique identifier for the attributed reward (format: uuid)
  --code: string # Redemption code for the reward
  --contactId: int # Unique identifier for the contact (format: int64)
  --loyaltySubscriptionId: string # Identifier for the loyalty subscription
  --meta: record # Additional metadata associated with the redeem request
  --order: any # Order details for the redemption
  --rewardId: string # Unique identifier for the reward (format: uuid)
  --ttl: int # Time to live in seconds for the redemption request
]: any -> record<cancelledAt: string, completedAt: string, contactId: int, createdAt: string, debitTransactionId: string, expiresAt: string, id: string, loyaltyProgramId: string, meta: record, rejectReason: string, rejectedAt: string, rewardAttributionId: string, status: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/offer/programs/($pid)/rewards/redeem")
  let body = {attributedRewardId: $attributedRewardId, code: $code, contactId: $contactId, loyaltySubscriptionId: $loyaltySubscriptionId, meta: $meta, order: $order, rewardId: $rewardId, ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete redeem voucher request
#
# POST /loyalty/offer/programs/{pid}/rewards/redeem/{tid}/complete
# operationId: completeRedeemTransaction
export def "loyalty-offer-programs-rewards-redeem-complete completeRedeemTransaction" [
  pid: string
  tid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cancelledAt: string, completedAt: string, contactId: int, createdAt: string, debitTransactionId: string, expiresAt: string, id: string, loyaltyProgramId: string, meta: record, rejectReason: string, rejectedAt: string, rewardAttributionId: string, status: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/offer/programs/($pid)/rewards/redeem/($tid)/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke vouchers
#
# DELETE /loyalty/offer/programs/{pid}/rewards/revoke
# operationId: revokeVouchers
export def "loyalty-offer-programs-rewards-revoke revokeVouchers" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributedRewardIds: string # Reward Attribution IDs (comma seperated)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributedRewardIds" $attributedRewardIds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/offer/programs/($pid)/rewards/revoke" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate a reward
#
# POST /loyalty/offer/programs/{pid}/rewards/validate
# operationId: validateReward
export def "loyalty-offer-programs-rewards-validate validateReward" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributedRewardId: string # Unique identifier for the attributed reward (format: uuid)
  --code: string # Validation code for the reward
  --contactId: int # Unique identifier for the contact (format: int64)
  --loyaltySubscriptionId: string # Identifier for the loyalty subscription
  --pointOfSellId: string # Identifier for the point of sale
  --rewardId: string # Unique identifier for the reward (format: uuid)
]: any -> record<authorize: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/offer/programs/($pid)/rewards/validate")
  let body = {attributedRewardId: $attributedRewardId, code: $code, contactId: $contactId, loyaltySubscriptionId: $loyaltySubscriptionId, pointOfSellId: $pointOfSellId, rewardId: $rewardId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get balance definition list
#
# GET /loyalty/balance/programs/{pid}/balance-definitions
# operationId: getBalanceDefinitionList
export def "loyalty-balance-programs-balance-definitions list" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit the number of records returned (default: 200)
  --offset: int # Offset to paginate records (default: 0)
  --sortField: string@sortField-completer-1 # Field to sort by (default: updated_at)
  --qp-sort: string@sort-completer # Sort direction (default: desc)
  --version: string@version-completer # Version (default: draft)
]: nothing -> record<items: table<balanceAvailabilityDurationModifier: string, balanceAvailabilityDurationUnit: string, balanceAvailabilityDurationValue: int, balanceExpirationDate: string, balanceOptionAmountOvertakingStrategy: string, balanceOptionCreditRounding: string, balanceOptionDebitRounding: string, createdAt: string, deletedAt: string, description: string, id: string, imageRef: string, maxAmount: float, maxCreditAmountLimit: float, maxDebitAmountLimit: float, meta: record, minAmount: float, name: string, unit: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/balance-definitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create balance definition
#
# POST /loyalty/balance/programs/{pid}/balance-definitions
export def "loyalty-balance-programs-balance-definitions post" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --balanceAvailabilityDurationModifier: string@balanceAvailabilityDurationModifier-completer # Defines when the balance expires within the selected duration.
  --balanceAvailabilityDurationUnit: string@balanceAvailabilityDurationUnit-completer # Unit of time for balance validity.
  --balanceAvailabilityDurationValue: int # Number of time units before the balance expires.
  --balanceExpirationDate: string # Fixed expiration date (`dd/mm` format) as an alternative to duration-based expiry. (format: date)
  --balanceOptionAmountOvertakingStrategy: string@balanceOptionAmountOvertakingStrategy-completer # Defines whether partial credit is allowed when reaching max balance.
  --balanceOptionCreditRounding: string@balanceOptionCreditRounding-completer # Defines rounding strategy for credit transactions.
  --balanceOptionDebitRounding: string@balanceOptionDebitRounding-completer # Defines rounding strategy for debit transactions.
  --description: string # Short description of the balance definition.
  --imageRef: string # URL of an optional image reference.
  --maxAmount: float # Maximum allowable balance amount.
  --maxCreditAmountLimit: float # Maximum credit allowed per operation.
  --maxDebitAmountLimit: float # Maximum debit allowed per operation.
  --meta: record # Additional metadata for the balance definition.
  --minAmount: float # Minimum allowable balance amount.
  name: string # Name of the balance definition.
  unit: string@unit-completer # Unit of balance measurement.
]: any -> record<balanceAvailabilityDurationModifier: string, balanceAvailabilityDurationUnit: string, balanceAvailabilityDurationValue: int, balanceExpirationDate: string, balanceOptionAmountOvertakingStrategy: string, balanceOptionCreditRounding: string, balanceOptionDebitRounding: string, createdAt: string, deletedAt: string, description: string, id: string, imageRef: string, maxAmount: float, maxCreditAmountLimit: float, maxDebitAmountLimit: float, meta: record, minAmount: float, name: string, unit: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/balance-definitions")
  let body = {balanceAvailabilityDurationModifier: $balanceAvailabilityDurationModifier, balanceAvailabilityDurationUnit: $balanceAvailabilityDurationUnit, balanceAvailabilityDurationValue: $balanceAvailabilityDurationValue, balanceExpirationDate: $balanceExpirationDate, balanceOptionAmountOvertakingStrategy: $balanceOptionAmountOvertakingStrategy, balanceOptionCreditRounding: $balanceOptionCreditRounding, balanceOptionDebitRounding: $balanceOptionDebitRounding, description: $description, imageRef: $imageRef, maxAmount: $maxAmount, maxCreditAmountLimit: $maxCreditAmountLimit, maxDebitAmountLimit: $maxDebitAmountLimit, meta: $meta, minAmount: $minAmount, name: $name, unit: $unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get balance definition
#
# GET /loyalty/balance/programs/{pid}/balance-definitions/{bdid}
# operationId: getBalanceDefinition
export def "loyalty-balance-programs-balance-definitions get" [
  pid: string
  bdid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string@version-completer # Version (default: draft)
]: nothing -> record<balanceAvailabilityDurationModifier: string, balanceAvailabilityDurationUnit: string, balanceAvailabilityDurationValue: int, balanceExpirationDate: string, balanceOptionAmountOvertakingStrategy: string, balanceOptionCreditRounding: string, balanceOptionDebitRounding: string, createdAt: string, deletedAt: string, description: string, id: string, imageRef: string, maxAmount: float, maxCreditAmountLimit: float, maxDebitAmountLimit: float, meta: record, minAmount: float, name: string, unit: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/balance-definitions/($bdid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update balance definition
#
# PUT /loyalty/balance/programs/{pid}/balance-definitions/{bdid}
# operationId: updateBalanceDefinition
export def "loyalty-balance-programs-balance-definitions updateBalanceDefinition" [
  pid: string
  bdid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --balanceAvailabilityDurationModifier: string@balanceAvailabilityDurationModifier-completer # Defines when the balance expires within the selected duration.
  --balanceAvailabilityDurationUnit: string@balanceAvailabilityDurationUnit-completer # Unit of time for balance validity.
  --balanceAvailabilityDurationValue: int # Number of time units before the balance expires.
  --balanceExpirationDate: string # Expiration date (`dd/mm` format) or empty if not applicable.
  --balanceOptionAmountOvertakingStrategy: string@balanceOptionAmountOvertakingStrategy-completer # Defines whether partial credit is allowed when reaching max balance.
  --balanceOptionCreditRounding: string@balanceOptionCreditRounding-completer # Rounding strategy for credit transactions.
  --balanceOptionDebitRounding: string@balanceOptionDebitRounding-completer # Rounding strategy for debit transactions.
  --description: string # Short description of the balance definition.
  --imageRef: string # URL of an optional image reference.
  --maxAmount: float # Maximum allowable balance amount.
  --maxCreditAmountLimit: float # Maximum credit allowed per operation.
  --maxDebitAmountLimit: float # Maximum debit allowed per operation.
  --meta: record # Optional metadata for the balance definition.
  --minAmount: float # Minimum allowable balance amount.
  name: string # Name of the balance definition.
  unit: string@unit-completer # Unit of balance measurement.
]: any -> record<balanceAvailabilityDurationModifier: string, balanceAvailabilityDurationUnit: string, balanceAvailabilityDurationValue: int, balanceExpirationDate: string, balanceOptionAmountOvertakingStrategy: string, balanceOptionCreditRounding: string, balanceOptionDebitRounding: string, createdAt: string, deletedAt: string, description: string, id: string, imageRef: string, maxAmount: float, maxCreditAmountLimit: float, maxDebitAmountLimit: float, meta: record, minAmount: float, name: string, unit: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/balance-definitions/($bdid)")
  let body = {balanceAvailabilityDurationModifier: $balanceAvailabilityDurationModifier, balanceAvailabilityDurationUnit: $balanceAvailabilityDurationUnit, balanceAvailabilityDurationValue: $balanceAvailabilityDurationValue, balanceExpirationDate: $balanceExpirationDate, balanceOptionAmountOvertakingStrategy: $balanceOptionAmountOvertakingStrategy, balanceOptionCreditRounding: $balanceOptionCreditRounding, balanceOptionDebitRounding: $balanceOptionDebitRounding, description: $description, imageRef: $imageRef, maxAmount: $maxAmount, maxCreditAmountLimit: $maxCreditAmountLimit, maxDebitAmountLimit: $maxDebitAmountLimit, meta: $meta, minAmount: $minAmount, name: $name, unit: $unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete balance definition
#
# DELETE /loyalty/balance/programs/{pid}/balance-definitions/{bdid}
# operationId: deleteBalanceDefinition
export def "loyalty-balance-programs-balance-definitions delete" [
  pid: string
  bdid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/balance-definitions/($bdid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create balance limits
#
# POST /loyalty/balance/programs/{pid}/balance-definitions/{bdid}/limits
# operationId: createBalanceLimit
export def "loyalty-balance-programs-balance-definitions-limits createBalanceLimit" [
  pid: string
  bdid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  constraintType: string@constraintType-completer # Defines whether the limit applies to transaction count or amount.
  durationUnit: string@durationUnit-completer # Unit of time for which the limit is applicable.
  durationValue: int # Number of time units for the balance limit.
  --slidingSchedule: oneof<nothing, bool> # Determines if the limit resets on a rolling schedule.
  transactionType: string@transactionType-completer # Specifies whether the limit applies to credit or debit transactions.
  value: int # Maximum allowed value for the specified constraint type.
]: any -> record<balanceDefinitionId: string, constraintType: string, createdAt: string, durationUnit: string, durationValue: int, id: string, slidingSchedule: bool, transactionType: string, updatedAt: string, value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/balance-definitions/($bdid)/limits")
  let body = {constraintType: $constraintType, durationUnit: $durationUnit, durationValue: $durationValue, slidingSchedule: $slidingSchedule, transactionType: $transactionType, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get balance limits
#
# GET /loyalty/balance/programs/{pid}/balance-definitions/{bdid}/limits/{blid}
# operationId: getBalanceLimit
export def "loyalty-balance-programs-balance-definitions-limits get" [
  pid: string
  bdid: string
  blid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string@version-completer # Version (default: draft)
]: nothing -> record<balanceDefinitionId: string, constraintType: string, createdAt: string, durationUnit: string, durationValue: int, id: string, slidingSchedule: bool, transactionType: string, updatedAt: string, value: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/balance-definitions/($bdid)/limits/($blid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete balance limit
#
# DELETE /loyalty/balance/programs/{pid}/balance-definitions/{bdid}/limits/{blid}
# operationId: deleteBalanceLimit
export def "loyalty-balance-programs-balance-definitions-limits delete" [
  pid: string
  bdid: string
  blid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/balance-definitions/($bdid)/limits/($blid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates balance limit
#
# PUT /loyalty/balance/programs/{pid}/balance-definitions/{bdid}/limits/{blid}
# operationId: updateBalanceLimit
export def "loyalty-balance-programs-balance-definitions-limits updateBalanceLimit" [
  pid: string
  bdid: string
  blid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  constraintType: string@constraintType-completer # Defines whether the limit applies to transaction count or amount.
  durationUnit: string@durationUnit-completer # Unit of time for which the limit is applicable.
  durationValue: int # Number of time units for the balance limit.
  --slidingSchedule: oneof<nothing, bool> # Determines if the limit resets on a rolling schedule.
  transactionType: string@transactionType-completer # Specifies whether the limit applies to credit or debit transactions.
  value: int # Maximum allowed value for the specified constraint type.
]: any -> record<balanceDefinitionId: string, constraintType: string, createdAt: string, durationUnit: string, durationValue: int, id: string, slidingSchedule: bool, transactionType: string, updatedAt: string, value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/balance-definitions/($bdid)/limits/($blid)")
  let body = {constraintType: $constraintType, durationUnit: $durationUnit, durationValue: $durationValue, slidingSchedule: $slidingSchedule, transactionType: $transactionType, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get subscription balances
#
# GET /loyalty/balance/programs/{pid}/subscriptions/{cid}/balances
# operationId: getSubscriptionBalances
export def "loyalty-balance-programs-subscriptions-balances get" [
  cid: string
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balance: table<balanceDefinitionId: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/subscriptions/($cid)/balances")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create subscription balances
#
# POST /loyalty/balance/programs/{pid}/subscriptions/{cid}/balances
export def "loyalty-balance-programs-subscriptions-balances post" [
  pid: string
  cid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  balanceDefinitionId: string # Unique identifier (UUID) of the balance definition associated with the new balance.
]: any -> record<amount: float, balanceDefinitionId: string, consumedAt: string, contactId: int, createdAt: string, expiresAt: string, id: string, loyaltyProgramId: string, organizationId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/subscriptions/($cid)/balances")
  let body = {balanceDefinitionId: $balanceDefinitionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get balance list
#
# GET /loyalty/balance/programs/{pid}/contact-balances
# operationId: getContactBalances
export def "loyalty-balance-programs-contact-balances get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balanceDefinitionId: string, balances: table<contactId: int, loyaltySubscriptionId: string, updatedAt: string, value: float>, count: int, loyaltyProgramId: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/contact-balances")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new transaction
#
# POST /loyalty/balance/programs/{pid}/transactions
# operationId: beginTransaction
export def "loyalty-balance-programs-transactions beginTransaction" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --LoyaltySubscriptionId: string # Unique identifier for the loyalty subscription (required unless `contactId` is provided).
  amount: float # Transaction amount (must be provided).
  --autoComplete: oneof<nothing, bool> # Whether the transaction should be automatically completed.
  balanceDefinitionId: string # Unique identifier (UUID) of the associated balance definition.
  --balanceExpiryInMinutes: int # Optional expiry time for the balance in minutes (must be greater than 0 if provided).
  --contactId: int # Unique identifier of the contact involved in the transaction (required unless `LoyaltySubscriptionId` is provided).
  --eventTime: string # Optional timestamp specifying when the transaction occurred.
  --meta: record # Optional metadata associated with the transaction.
  --ttl: int # Optional time-to-live for the transaction (must be greater than 0 if provided).
]: any -> record<amount: float, balanceDefinitionId: string, cancelledAt: string, completedAt: string, contactId: int, createdAt: string, eventTime: string, expirationDate: string, id: string, loyaltyProgramId: string, meta: record, rejectReason: string, rejectedAt: string, status: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/transactions")
  let body = {LoyaltySubscriptionId: $LoyaltySubscriptionId, amount: $amount, autoComplete: $autoComplete, balanceDefinitionId: $balanceDefinitionId, balanceExpiryInMinutes: $balanceExpiryInMinutes, contactId: $contactId, eventTime: $eventTime, meta: $meta, ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete transaction
#
# POST /loyalty/balance/programs/{pid}/transactions/{tid}/complete
# operationId: completeTransaction
export def "loyalty-balance-programs-transactions-complete completeTransaction" [
  pid: string
  tid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: float, balanceDefinitionId: string, cancelledAt: string, completedAt: string, contactId: int, createdAt: string, eventTime: string, expirationDate: string, id: string, loyaltyProgramId: string, meta: record, rejectReason: string, rejectedAt: string, status: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/transactions/($tid)/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel transaction
#
# POST /loyalty/balance/programs/{pid}/transactions/{tid}/cancel
# operationId: cancelTransaction
export def "loyalty-balance-programs-transactions-cancel cancelTransaction" [
  pid: string
  tid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: float, balanceDefinitionId: string, cancelledAt: string, completedAt: string, contactId: int, createdAt: string, eventTime: string, expirationDate: string, id: string, loyaltyProgramId: string, meta: record, rejectReason: string, rejectedAt: string, status: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/transactions/($tid)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create balance order
#
# POST /loyalty/balance/programs/{pid}/create-order
# operationId: createBalanceOrder
export def "loyalty-balance-programs-create-order createBalanceOrder" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: float # Order amount (must be non-zero).
  balanceDefinitionId: string # Unique identifier (UUID) of the associated balance definition.
  contactId: int # Unique identifier of the contact placing the order (must be ≥ 1).
  dueAt: string # RFC3339 timestamp specifying when the order is due.
  --expiresAt: string # Optional RFC3339 timestamp defining order expiration.
  --meta: record # Optional metadata associated with the order.
  --body-source: string # Specifies the origin of the order (`engine` or `user`).
]: any -> record<amount: float, balanceDefinitionId: string, contactId: int, createdAt: string, dueAt: string, expiresAt: string, id: string, loyaltyProgramId: string, meta: record, processedAt: string, transactionid: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/create-order")
  let body = {amount: $amount, balanceDefinitionId: $balanceDefinitionId, contactId: $contactId, dueAt: $dueAt, expiresAt: $expiresAt, meta: $meta, source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Active Balances API
#
# GET /loyalty/balance/programs/{pid}/active-balance
export def "loyalty-balance-programs-active-balance get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit
  --offset: int # Offset
  --sort-field: string # Sort Field
  --qp-sort: string # Sort Order
  --contact-id: int # Contact ID
  --balance-definition-id: string # Balance Definition ID (format: uuid)
]: nothing -> record<balanceDefinitionId: string, constraintType: string, createdAt: string, durationUnit: string, durationValue: int, id: string, slidingSchedule: bool, transactionType: string, updatedAt: string, value: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "balance_definition_id" $balance_definition_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/active-balance" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Transaction History API
#
# GET /loyalty/balance/programs/{pid}/transaction-history
export def "loyalty-balance-programs-transaction-history get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limit the number of records returned (default: 20)
  --offset: int # Skip a number of records (default: 0)
  --sort-field: string@sort-field-completer # Field to sort by (default: created_at)
  --qp-sort: string@sort-completer # Sort order, either asc or desc (default: desc)
  --contact-id: int # Contact ID (default: 0)
  --balance-definition-id: string # Balance Definition ID (format: uuid)
  --filters: list # Filters to apply
]: nothing -> record<balanceDefinitionId: string, contactId: int, count: int, loyaltyProgramId: string, transactionHistory: table<amount: float, balanceExpirationDate: string, cancelledAt: string, completedAt: string, createdAt: string, id: string, meta: record, rejectReason: string, rejectedAt: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort_field" $sort_field "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "balance_definition_id" $balance_definition_id "scalar") (serialize-qp "filters" $filters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/balance/programs/($pid)/transaction-history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a tier group
#
# POST /loyalty/tier/programs/{pid}/tier-groups
# operationId: createTierGroup
export def "loyalty-tier-programs-tier-groups createTierGroup" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the tier group
  --upgradeStrategy: string@upgradeStrategy-completer # Select real_time to upgrade tier on real time balance updates. Select membership_anniversary to upgrade tier on subscription anniversary. Select tier_anniversary to upgrade tier on tier anniversary. (default: real_time)
  --downgradeStrategy: string@downgradeStrategy-completer # Select real_time to downgrade tier on real time balance updates. Select membership_anniversary to downgrade tier on subscription anniversary. Select tier_anniversary to downgrade tier on tier anniversary. (default: real_time)
  --tierOrder: list # Order of the tiers in the group in ascending order
]: any -> record<id: string, name: string, tierOrder: list<string>, loyaltyProgramId: string, upgradeStrategy: string, downgradeStrategy: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/tier/programs/($pid)/tier-groups")
  let body = {name: $name, upgradeStrategy: $upgradeStrategy, downgradeStrategy: $downgradeStrategy, tierOrder: $tierOrder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List tier groups
#
# GET /loyalty/tier/programs/{pid}/tier-groups
# operationId: getListOfTierGroups
export def "loyalty-tier-programs-tier-groups list" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string@version-completer # Select 'active' to retrieve list of all tier groups which are live for clients. Select draft to retrieve list of all non deleted tier groups. (default: draft)
]: nothing -> record<items: table<id: string, name: string, tierOrder: list, loyaltyProgramId: string, upgradeStrategy: string, downgradeStrategy: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/tier/programs/($pid)/tier-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update tier group
#
# PUT /loyalty/tier/programs/{pid}/tier-groups/{gid}
# operationId: updateTierGroup
export def "loyalty-tier-programs-tier-groups updateTierGroup" [
  pid: string
  gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the tier group
  tierOrder: list # Order of the tiers in the group in ascending order (e.g. [])
  upgradeStrategy: string@upgradeStrategy-completer # Select real_time to upgrade tier on real time balance updates. Select membership_anniversary to upgrade tier on subscription anniversary. Select tier_anniversary to upgrade tier on tier anniversary. (default: real_time)
  downgradeStrategy: string@downgradeStrategy-completer # Select real_time to downgrade tier on real time balance updates. Select membership_anniversary to downgrade tier on subscription anniversary. Select tier_anniversary to downgrade tier on tier anniversary. (default: real_time)
]: any -> record<id: string, name: string, tierOrder: list<string>, loyaltyProgramId: string, upgradeStrategy: string, downgradeStrategy: string, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/tier/programs/($pid)/tier-groups/($gid)")
  let body = {name: $name, tierOrder: $tierOrder, upgradeStrategy: $upgradeStrategy, downgradeStrategy: $downgradeStrategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete tier group
#
# DELETE /loyalty/tier/programs/{pid}/tier-groups/{gid}
# operationId: deleteTierGroup
export def "loyalty-tier-programs-tier-groups delete" [
  pid: string
  gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/tier/programs/($pid)/tier-groups/($gid)")
  let accept_val = "aplication/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tier group
#
# GET /loyalty/tier/programs/{pid}/tier-groups/{gid}
# operationId: getTierGroup
export def "loyalty-tier-programs-tier-groups get" [
  pid: string
  gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string@version-completer # Select active to retrieve active version of tier group. Select draft to retrieve latest changes in tier group. (default: draft)
]: nothing -> record<id: string, name: string, tierOrder: list<string>, loyaltyProgramId: string, upgradeStrategy: string, downgradeStrategy: string, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/tier/programs/($pid)/tier-groups/($gid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tiers
#
# GET /loyalty/tier/programs/{pid}/tiers
# operationId: getLoyaltyProgramTier
export def "loyalty-tier-programs-tiers get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string@version-completer # Select 'active' to retrieve list of all tiers which are live for clients. Select draft to retrieve list of all non deleted tiers. (default: draft)
]: nothing -> record<items: table<tierId: string, name: string, imageRef: string, loyaltyProgramId: string, groupId: string, createdAt: string, updatedAt: string, accessConditions: list, tierRewards: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/loyalty/tier/programs/($pid)/tiers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a tier
#
# POST /loyalty/tier/programs/{pid}/tier-groups/{gid}/tiers
# operationId: createTierForTierGroup
# --accessConditions item shape: {balanceDefinitionId?: string, minimumValue?: int}
# --tierRewards item shape: {rewardId?: string}
export def "loyalty-tier-programs-tier-groups-tiers createTierForTierGroup" [
  pid: string
  gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the tier to be created
  --imageRef: string # Image of the tier
  accessConditions: list # item shape: {balanceDefinitionId?: string, minimumValue?: int}
  --tierRewards: list # item shape: {rewardId?: string}
]: any -> record<tierId: string, name: string, imageRef: string, loyaltyProgramId: string, groupId: string, createdAt: string, updatedAt: string, accessConditions: table<balanceDefinitionId: string, minimumValue: int, createdAt: string, updatedAt: string>, tierRewards: table<rewardId: string, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/tier/programs/($pid)/tier-groups/($gid)/tiers")
  let body = {name: $name, imageRef: $imageRef, accessConditions: $accessConditions, tierRewards: $tierRewards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete tier
#
# DELETE /loyalty/tier/programs/{pid}/tiers/{tid}
# operationId: deleteTier
export def "loyalty-tier-programs-tiers delete" [
  pid: string
  tid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/tier/programs/($pid)/tiers/($tid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update tier
#
# PUT /loyalty/tier/programs/{pid}/tiers/{tid}
# operationId: updateTier
# --accessConditions item shape: {balanceDefinitionId?: string, minimumValue?: int}
# --tierRewards item shape: {rewardId?: string}
export def "loyalty-tier-programs-tiers updateTier" [
  pid: string
  tid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the tier to be created
  --imageRef: string # Image of the tier
  accessConditions: list # item shape: {balanceDefinitionId?: string, minimumValue?: int}
  tierRewards: list # item shape: {rewardId?: string}
]: any -> record<tierId: string, name: string, imageRef: string, loyaltyProgramId: string, groupId: string, createdAt: string, updatedAt: string, accessConditions: table<balanceDefinitionId: string, minimumValue: int, createdAt: string, updatedAt: string>, tierRewards: table<rewardId: string, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/tier/programs/($pid)/tiers/($tid)")
  let body = {name: $name, imageRef: $imageRef, accessConditions: $accessConditions, tierRewards: $tierRewards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Assign a tier
#
# POST /loyalty/tier/programs/{pid}/contacts/{cid}/tiers/{tid}
# operationId: addSubscriptionToTier
export def "loyalty-tier-programs-contacts-tiers addSubscriptionToTier" [
  pid: string
  cid: string
  tid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, loyaltyProgramId: string, groupId: string, contactId: int, meta: record, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/loyalty/tier/programs/($pid)/contacts/($cid)/tiers/($tid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of all your senders
#
# GET /senders
# operationId: getSenders
export def "senders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ip: string # Filter your senders for a specific ip. **Available for dedicated IP usage only**
  --domain: string # Filter your senders for a specific domain
]: nothing -> record<senders: table<id: int, name: string, email: string, active: bool, ips: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ip" $ip "scalar") (serialize-qp "domain" $domain "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/senders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new sender
#
# POST /senders
# operationId: createSender
# --ips item shape: {ip: string, domain: string, weight?: int}
export def "senders createSender" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # From Name to use for the sender (e.g. Newsletter)
  email: string # From email to use for the sender. A verification email will be sent to this address. (format: email, e.g. newsletter@mycompany.com)
  --ips: list # **Mandatory in case of dedicated IP**. IPs to associate to the sender — item shape: {ip: string, domain: string, weight?: int}
]: any -> record<id: int, spfError: bool, dkimError: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/senders")
  let body = {name: $name, email: $email, ips: $ips} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a sender
#
# PUT /senders/{senderId}
# operationId: updateSender
# --ips item shape: {ip: string, domain: string, weight?: int}
export def "senders updateSender" [
  senderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # From Name to update the sender (e.g. Newsletter)
  --email: string # From Email to update the sender (format: email, e.g. newsletter@mycompany.com)
  --ips: list # **Only in case of dedicated IP**. IPs to associate to the sender. If passed, will replace all the existing IPs. — item shape: {ip: string, domain: string, weight?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($senderId)")
  let body = {name: $name, email: $email, ips: $ips} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a sender
#
# DELETE /senders/{senderId}
# operationId: deleteSender
export def "senders delete" [
  senderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($senderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate Sender using OTP
#
# PUT /senders/{senderId}/validate
# operationId: validateSenderByOTP
export def "senders-validate validateSenderByOTP" [
  senderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  otp: int # 6 digit OTP received on email (e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($senderId)/validate")
  let body = {otp: $otp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all the dedicated IPs for a sender
#
# GET /senders/{senderId}/ips
# operationId: getIpsFromSender
export def "senders-ips get" [
  senderId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ips: table<id: int, ip: string, domain: string, weight: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/($senderId)/ips")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the dedicated IPs for your account
#
# GET /senders/ips
# operationId: getIps
export def "senders-ips list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ips: table<id: int, ip: string, active: bool, domain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/senders/ips")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of all your domains
#
# GET /senders/domains
# operationId: getDomains
export def "senders-domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domains: table<id: int, domain_name: string, authenticated: bool, verified: bool, ip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/senders/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new domain
#
# POST /senders/domains
# operationId: createDomain
export def "senders-domains createDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Domain name (e.g. mycompany.com)
]: any -> record<id: int, domain_name: string, domain_provider: string, message: string, dns_records: record<dkim_record: record<type: string, value: string, host_name: string, status: bool>, brevo_code: record<type: string, value: string, host_name: string, status: bool>, dmarc_record: record<type: string, value: string, host_name: string, status: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/senders/domains")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a domain
#
# DELETE /senders/domains/{domainName}
# operationId: deleteDomain
export def "senders-domains delete" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/domains/($domainName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Validate domain configuration
#
# GET /senders/domains/{domainName}
# operationId: getDomainConfiguration
export def "senders-domains get" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain: string, verified: bool, authenticated: bool, dns_records: record<dkim_record: record<type: string, value: string, host_name: string, status: bool>, brevo_code: record<type: string, value: string, host_name: string, status: bool>, dmarc_record: record<type: string, value: string, host_name: string, status: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/domains/($domainName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Authenticate a domain
#
# PUT /senders/domains/{domainName}/authenticate
# operationId: authenticateDomain
export def "senders-domains-authenticate authenticateDomain" [
  domainName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain_name: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/senders/domains/($domainName)/authenticate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all webhooks
#
# GET /webhooks
# operationId: getWebhooks
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-3 # Filter on webhook type (default: transactional)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of webhook creation (default: desc)
]: nothing -> record<webhooks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /webhooks
# operationId: createWebhook
export def "webhooks createWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # URL of the webhook (format: url, e.g. http://requestb.in/173lyyx1)
  --description: string # Description of the webhook (e.g. Webhook triggered on unsubscription)
  events: list # - Events triggering the webhook. Possible values for **Transactional** type webhook: #### `sent` OR `request`, `delivered`, `hardBounce`, `softBounce`, `blocked`, `spam`, `invalid`, `deferred`, `click`, `opened`, `uniqueOpened` and `unsubscribed` - Possible values for **Marketing** type webhook: #### `spam`, `opened`, `click`, `hardBounce`, `softBounce`, `unsubscribed`, `listAddition` & `delivered` - Possible values for **Inbound** type webhook: #### `inboundEmailProcessed` - Possible values for type **Transactional** and channel **SMS** #### `accepted`,`delivered`,`softBounce`,`hardBounce`,`unsubscribe`,`reply`, `subscribe`,`sent`,`blacklisted`,`skip` - Possible values for type **Marketing**  channel **SMS** #### `sent`,`delivered`,`softBounce`,`hardBounce`,`unsubscribe`,`reply`, `subscribe`,`skip`
  --type: string@type-completer-3 # Type of the webhook (default: transactional, e.g. marketing)
  --channel: string@channel-completer # channel of webhook (default: email, e.g. sms)
  --domain: string # Inbound domain of webhook, required in case of event type `inbound` (e.g. example.com)
  --batched: oneof<nothing, bool> # Batching configuration of the webhook, we send batched webhooks if its true (e.g. true)
  --body-auth: record # Authentication header to be send with the webhook requests (e.g. {type: bearer, token: test-auth-token1234})
  --headers: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let body = {url: $body_url, description: $description, events: $events, type: $type, channel: $channel, domain: $domain, batched: $batched, auth: $body_auth, headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a webhook details
#
# GET /webhooks/{webhookId}
# operationId: getWebhook
export def "webhooks get" [
  webhookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<url: string, id: int, description: string, events: list<string>, type: string, channel: string, createdAt: string, modifiedAt: string, batched: bool, auth: record, headers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PUT /webhooks/{webhookId}
# operationId: updateWebhook
export def "webhooks updateWebhook" [
  webhookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # URL of the webhook (format: url, e.g. http://requestb.in/173lyyx1)
  --description: string # Description of the webhook (e.g. Webhook triggered on contact hardbounce)
  --events: list # - Events triggering the webhook. Possible values for **Transactional** type webhook: #### `sent` OR `request`, `delivered`, `hardBounce`, `softBounce`, `blocked`, `spam`, `invalid`, `deferred`, `click`, `opened`, `uniqueOpened` and `unsubscribed` - Possible values for **Marketing** type webhook: #### `spam`, `opened`, `click`, `hardBounce`, `softBounce`, `unsubscribed`, `listAddition` & `delivered` - Possible values for **Inbound** type webhook: #### `inboundEmailProcessed`
  --domain: string # Inbound domain of webhook, used in case of event type `inbound` (e.g. example.com)
  --batched: oneof<nothing, bool> # Batching configuration of the webhook, we send batched webhooks if its true (e.g. true)
  --body-auth: record # Authentication header to be send with the webhook requests (e.g. {type: bearer, token: test-auth-token1234})
  --headers: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let body = {url: $body_url, description: $description, events: $events, domain: $domain, batched: $batched, auth: $body_auth, headers: $headers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /webhooks/{webhookId}
# operationId: deleteWebhook
export def "webhooks delete" [
  webhookId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export all webhook events
#
# POST /webhooks/export
# operationId: exportWebhooksHistory
export def "webhooks-export exportWebhooksHistory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --days: int # Number of days in the past including today (positive integer). _Not compatible with 'startDate' and 'endDate'_ (e.g. 7)
  --startDate: string # Mandatory if endDate is used. Starting date of the history (YYYY-MM-DD). Must be lower than equal to endDate (e.g. 2023-02-13)
  --endDate: string # Mandatory if startDate is used. Ending date of the report (YYYY-MM-DD). Must be greater than equal to startDate (e.g. 2023-02-17)
  --body-sort: string # Sorting order of records (asc or desc) (e.g. desc)
  --type: string@type-completer-2 # Filter the history based on webhook type (e.g. transactional)
  --event: string@event-completer-2 # Filter the history for a specific event type (e.g. request)
  --notifyURL: string # Webhook URL to receive CSV file link (e.g. https://brevo.com)
  --webhookId: int # Filter the history for a specific webhook id (e.g. 2345)
  --email: string # Filter the history for a specific email (e.g. example@brevo.com)
  --messageId: int # Filter the history for a specific message id. Applicable only for transactional webhooks. (e.g. <23befbae-1505-47a8-bd27-e30ef739f32c@fr.sib>)
]: any -> record<processId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks/export")
  let body = {days: $days, startDate: $startDate, endDate: $endDate, sort: $body_sort, type: $type, event: $event, notifyURL: $notifyURL, webhookId: $webhookId, email: $email, messageId: $messageId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get your account information, plan and credits details
#
# GET /account
# operationId: getAccount
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<plan: table<type: string, creditsType: string, credits: float, startDate: string, endDate: string>, relay: record<enabled: bool, data: record<userName: string, relay: string, port: int>>, marketingAutomation: record<key: string, enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user activity logs
#
# GET /organization/activities
# operationId: getAccountActivity
export def "organization-activities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startDate: string # Mandatory if endDate is used. Enter start date in UTC date (YYYY-MM-DD) format to filter the activity in your account. Maximum time period that can be selected is one month. Additionally, you can retrieve activity logs from the past 12 months from the date of your search.
  --endDate: string # Mandatory if startDate is used. Enter end date in UTC date (YYYY-MM-DD) format to filter the activity in your account. Maximum time period that can be selected is one month.
  --email: string # Enter the user's email address to filter their activity in the account.
  --limit: int # Number of documents per page (format: int64, default: 10)
  --offset: int # Index of the first document in the page. (format: int64, default: 0)
]: nothing -> record<logs: table<action: string, date: string, user_email: string, user_ip: string, user_agent: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of all your users
#
# GET /organization/invited/users
# operationId: getInvitedUsersList
export def "organization-invited-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<users: table<email: string, is_owner: string, status: string, feature_access: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization/invited/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check user permission
#
# GET /organization/user/{email}/permissions
# operationId: getUserPermission
export def "organization-user-permissions get" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, status: string, privileges: table<feature: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/user/($email)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke user permission
#
# PUT /organization/user/invitation/revoke/{email}
# operationId: putRevokeUserPermission
export def "organization-user-invitation-revoke put" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, credit_notes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/user/invitation/revoke/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resend / Cancel invitation
#
# PUT /organization/user/invitation/{action}/{email}
# operationId: putresendcancelinvitation
export def "organization-user-invitation putresendcancelinvitation" [
  action: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string, credit_notes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/user/invitation/($action)/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send invitation to user
#
# POST /organization/user/invitation/send
# operationId: inviteuser
# --privileges item shape: {feature?: "email_campaigns"|"sms_campaigns"|"contacts"|"templates"|"workflows"|"landing_pages"|"transactional_emails"|"smtp_api"|"user_management"|"sales_platform"|"phone"|"conversations"|"senders_domains_dedicated_ips"|"push_notifications"|"companies", permissions?: list}
export def "organization-user-invitation-send inviteuser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Email address for the organization (format: email, e.g. inviteuser@example.com)
  --all-features-access: oneof<nothing, bool> # All access to the features (e.g. true)
  privileges: list # item shape: {feature?: "email_campaigns"|"sms_campaigns"|"contacts"|"templates"|"workflows"|"landing_pages"|"transactional_emails"|"smtp_api"|"user_management"|"sales_platform"|"phone"|"conversations"|"senders_domains_dedicated_ips"|"push_notifications"|"companies", permissions?: list}
]: any -> record<status: string, invoice_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization/user/invitation/send")
  let body = {email: $email, all_features_access: $all_features_access, privileges: $privileges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update permission for a user
#
# POST /organization/user/update/permissions
# operationId: EditUserPermission
# --privileges item shape: {feature?: "email_campaigns"|"sms_campaigns"|"contacts"|"templates"|"workflows"|"landing_pages"|"transactional_emails"|"smtp_api"|"user_management"|"sales_platform"|"phone"|"conversations"|"senders_domains_dedicated_ips"|"push_notifications"|"companies", permissions?: list}
export def "organization-user-update-permissions EditUserPermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Email address for the organization (format: email, e.g. inviteuser@example.com)
  --all-features-access: oneof<nothing, bool> # All access to the features (e.g. true)
  privileges: list # item shape: {feature?: "email_campaigns"|"sms_campaigns"|"contacts"|"templates"|"workflows"|"landing_pages"|"transactional_emails"|"smtp_api"|"user_management"|"sales_platform"|"phone"|"conversations"|"senders_domains_dedicated_ips"|"push_notifications"|"companies", permissions?: list}
]: any -> record<status: string, credit_notes: list<string>, invoice_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization/user/update/permissions")
  let body = {email: $email, all_features_access: $all_features_access, privileges: $privileges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return all the processes for your account
#
# GET /processes
# operationId: getProcesses
export def "processes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number limitation for the result returned (format: int64, default: 10)
  --offset: int # Beginning point in the list to retrieve from. (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<processes: table<id: int, status: string, name: string, export_url: string>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/processes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return the informations for a process
#
# GET /processes/{processId}
# operationId: getProcess
export def "processes get" [
  processId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, status: string, name: string, export_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/processes/($processId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of all the events for the received emails.
#
# GET /inbound/events
# operationId: getInboundEmailEvents
export def "inbound-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sender: string # Email address of the sender.
  --startDate: string # Mandatory if endDate is used. Starting date (YYYY-MM-DD or YYYY-MM-DDTHH:mm:ss.SSSZ) from which you want to fetch the list. Maximum time period that can be selected is one month. (format: datetime)
  --endDate: string # Mandatory if startDate is used. Ending date (YYYY-MM-DD or YYYY-MM-DDTHH:mm:ss.SSSZ) till which you want to fetch the list. Maximum time period that can be selected is one month. (format: datetime)
  --limit: int # Number of documents returned per page (format: int64, default: 100)
  --offset: int # Index of the first document on the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation (default: desc)
]: nothing -> record<events: table<uuid: string, date: string, sender: string, recipient: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sender" $sender "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/inbound/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch all events history for one particular received email.
#
# GET /inbound/events/{uuid}
# operationId: getInboundEmailEventsByUuid
export def "inbound-events get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<receivedAt: string, deliveredAt: string, recipient: string, sender: string, messageId: string, subject: string, attachments: table<name: string, contentType: string, contentId: string, contentLength: int>, logs: table<date: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/inbound/events/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve inbound attachment with download token.
#
# GET /inbound/attachments/{downloadToken}
# operationId: getInboundEmailAttachment
export def "inbound-attachments get" [
  downloadToken: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/inbound/attachments/($downloadToken)")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of all the sub-accounts of the master account.
#
# GET /corporate/subAccount
export def "corporate-sub-account list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Index of the first sub-account in the page
  --limit: int # Number of sub-accounts to be displayed on each page
]: nothing -> record<count: int, subAccounts: table<id: int, companyName: string, active: bool, createdAt: int, groups: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/corporate/subAccount" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new sub-account under a master account.
#
# POST /corporate/subAccount
export def "corporate-sub-account post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  companyName: string # Set the name of the sub-account company
  email: string # Email address for the organization
  --language: string@language-completer # Set the language of the sub-account
  --timezone: string # Set the timezone of the sub-account
  --groupIds: list # Set the group(s) for the sub-account
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/subAccount")
  let body = {companyName: $companyName, email: $email, language: $language, timezone: $timezone, groupIds: $groupIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get sub-account details
#
# GET /corporate/subAccount/{id}
export def "corporate-sub-account get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, email: string, companyName: string, groups: table<id: string, name: string>, planInfo: record<credits: record<emails: record, sms: record, wpSubscribers: record, whatsapp: record, externalFeeds: record>, features: record<inbox: record, landingPage: record, users: record, salesUsers: record>, planType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporate/subAccount/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a sub-account
#
# DELETE /corporate/subAccount/{id}
export def "corporate-sub-account delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporate/subAccount/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update sub-account plan
#
# PUT /corporate/subAccount/{id}/plan
# --credits shape: {email?: int, sms?: float, wpSubscribers?: int, externalFeeds?: float, whatsapp?: float}
# --features shape: {users?: int, landingPage?: int, inbox?: int, salesUsers?: int}
export def "corporate-sub-account-plan put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --credits: record # Credit details to update — shape: {email?: int, sms?: float, wpSubscribers?: int, externalFeeds?: float, whatsapp?: float}
  --features: record # Features details to update — shape: {users?: int, landingPage?: int, inbox?: int, salesUsers?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporate/subAccount/($id)/plan")
  let body = {credits: $credits, features: $features} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update sub-accounts plan
#
# PUT /corporate/subAccounts/plan
# --credits shape: {email?: int, sms?: float, wpSubscribers?: int, externalFeeds?: float, whatsapp?: float}
# --features shape: {users?: int, landingPage?: int, salesUsers?: int}
export def "corporate-sub-accounts-plan put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subAccountIds: list # List of sub-account ids
  --credits: record # Credit details to update — shape: {email?: int, sms?: float, wpSubscribers?: int, externalFeeds?: float, whatsapp?: float}
  --features: record # Features details to update — shape: {users?: int, landingPage?: int, salesUsers?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/subAccounts/plan")
  let body = {subAccountIds: $subAccountIds, credits: $credits, features: $features} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate SSO token to access admin account
#
# POST /corporate/ssoToken
export def "corporate-sso-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User email of admin account (e.g. vipin+ent-user@brevo.com)
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/ssoToken")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate SSO token to access sub-account
#
# POST /corporate/subAccount/ssoToken
export def "corporate-sub-account-sso-token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # Id of the sub-account organization (format: int64, e.g. 3232323)
  --email: string # User email of sub-account organization (e.g. vipin+subaccount@brevo.com)
  --target: string@target-completer # **Set target after login success** * **automation** - Redirect to Automation after login * **email_campaign** - Redirect to Email Campaign after login * **contacts** - Redirect to Contacts after login * **landing_pages** - Redirect to Landing Pages after login * **email_transactional** - Redirect to Email Transactional after login * **senders** - Redirect to Senders after login * **sms_campaign** - Redirect to Sms Campaign after login * **sms_transactional** - Redirect to Sms Transactional after login  (e.g. contacts)
  --body-url: string # Set the full target URL after login success. The user will land directly on this target URL after login (e.g. https://app.brevo.com/senders/domain/list)
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/subAccount/ssoToken")
  let body = {id: $id, email: $email, target: $target, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the details of requested master account
#
# GET /corporate/masterAccount
export def "corporate-master-account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, companyName: string, id: int, currencyCode: string, timezone: string, billingInfo: record<email: string, companyName: string, name: record<givenName: string, familyName: string>, address: record<streetAddress: string, locality: string, postalCode: string, stateCode: string, countryCode: string>>, planInfo: record<currencyCode: string, nextBillingAt: int, price: float, planPeriod: string, subAccounts: int, features: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/masterAccount")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an API key for a sub-account
#
# POST /corporate/subAccount/key
export def "corporate-sub-account-key post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: int # Id of the sub-account organization (format: int64, e.g. 3232323)
  name: string # Name of the API key (e.g. My Api Key)
]: any -> record<status: string, key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/subAccount/key")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Enable/disable sub-account application(s)
#
# PUT /corporate/subAccount/{id}/applications/toggle
export def "corporate-sub-account-applications-toggle put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --inbox: oneof<nothing, bool> # Set this field to enable or disable Inbox on the sub-account / Not applicable on ENTv2
  --whatsapp: oneof<nothing, bool> # Set this field to enable or disable Whatsapp campaigns on the sub-account
  --automation: oneof<nothing, bool> # Set this field to enable or disable Automation on the sub-account
  --email-campaigns: oneof<nothing, bool> # Set this field to enable or disable Email Campaigns on the sub-account
  --sms-campaigns: oneof<nothing, bool> # Set this field to enable or disable SMS Marketing on the sub-account
  --landing-pages: oneof<nothing, bool> # Set this field to enable or disable Landing pages on the sub-account
  --transactional-emails: oneof<nothing, bool> # Set this field to enable or disable Transactional Email on the sub-account
  --transactional-sms: oneof<nothing, bool> # Set this field to enable or disable Transactional SMS on the sub-account
  --facebook-ads: oneof<nothing, bool> # Set this field to enable or disable Facebook ads on the sub-account
  --web-push: oneof<nothing, bool> # Set this field to enable or disable Web Push on the sub-account
  --meetings: oneof<nothing, bool> # Set this field to enable or disable Meetings on the sub-account
  --conversations: oneof<nothing, bool> # Set this field to enable or disable Conversations on the sub-account
  --crm: oneof<nothing, bool> # Set this field to enable or disable Sales CRM on the sub-account
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporate/subAccount/($id)/applications/toggle")
  let body = {inbox: $inbox, whatsapp: $whatsapp, automation: $automation, email-campaigns: $email_campaigns, sms-campaigns: $sms_campaigns, landing-pages: $landing_pages, transactional-emails: $transactional_emails, transactional-sms: $transactional_sms, facebook-ads: $facebook_ads, web-push: $web_push, meetings: $meetings, conversations: $conversations, crm: $crm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a group of sub-accounts
#
# POST /corporate/group
export def "corporate-group post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  groupName: string # The name of the group of sub-accounts (e.g. My group)
  --subAccountIds: list # Pass the list of sub-account Ids to be included in the group (e.g. [234322, 325553, 893432])
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/group")
  let body = {groupName: $groupName, subAccountIds: $subAccountIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List of all IPs
#
# GET /corporate/ip
export def "corporate-ip get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<ip: string, domain: string, transactional: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/ip")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate an IP to sub-accounts
#
# POST /corporate/subAccount/ip/associate
export def "corporate-sub-account-ip-associate post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ip: string # IP address (e.g. 103.11.32.88)
  ids: list # Pass the list of sub-account Ids to be associated with the IP address (e.g. [234322, 325553, 893432])
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/subAccount/ip/associate")
  let body = {ip: $ip, ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Dissociate an IP to sub-accounts
#
# PUT /corporate/subAccount/ip/dissociate
export def "corporate-sub-account-ip-dissociate put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ip: string # IP address (e.g. 103.11.32.88)
  ids: list # Pass the list of sub-account Ids to be dissociated from the IP address (e.g. [234322, 325553, 893432])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/subAccount/ip/dissociate")
  let body = {ip: $ip, ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET a group details
#
# GET /corporate/group/{id}
export def "corporate-group get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<group: record<id: string, groupName: string, createdAt: string>, sub_accounts: table<id: int, companyName: string, createdAt: string>, users: table<email: string, lastName: string, firstName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporate/group/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a group of sub-accounts
#
# PUT /corporate/group/{id}
export def "corporate-group put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groupName: string # The name of the group of sub-accounts (e.g. My group)
  --subAccountIds: list # Pass the list of sub-account Ids to be included in the group (e.g. [234322, 325553, 893432])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporate/group/($id)")
  let body = {groupName: $groupName, subAccountIds: $subAccountIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a group
#
# DELETE /corporate/group/{id}
export def "corporate-group delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporate/group/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete sub-account from group
#
# PUT /corporate/group/unlink/{groupId}/subAccounts
export def "corporate-group-unlink-sub-accounts put" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  subAccountIds: list # List of sub-account ids (e.g. [423432, 234323, 87678])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporate/group/unlink/($groupId)/subAccounts")
  let body = {subAccountIds: $subAccountIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send invitation to an admin user
#
# POST /corporate/user/invitation/send
# operationId: inviteAdminUser
# --privileges item shape: {feature?: "my_plan"|"api"|"user_management"|"app_management"|"sub_organization_groups"|"create_sub_organizations"|"manage_sub_organizations"|"analytics"|"security", permissions?: list}
export def "corporate-user-invitation-send inviteAdminUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Email address for the organization (format: email, e.g. inviteuser@example.com)
  --all-features-access: oneof<nothing, bool> # All access to the features (e.g. true)
  --groupIds: list # Ids of Group (e.g. [2baxxxxxxxxxxxxxxxxxxxxxcaa, 65axxxxxxxxxxxxxxxxxxxxxc5a])
  privileges: list # item shape: {feature?: "my_plan"|"api"|"user_management"|"app_management"|"sub_organization_groups"|"create_sub_organizations"|"manage_sub_organizations"|"analytics"|"security", permissions?: list}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/user/invitation/send")
  let body = {email: $email, all_features_access: $all_features_access, groupIds: $groupIds, privileges: $privileges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resend / cancel admin user invitation
#
# PUT /corporate/user/invitation/{action}/{email}
export def "corporate-user-invitation put" [
  action: string
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporate/user/invitation/($action)/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke an admin user
#
# DELETE /corporate/user/revoke/{email}
export def "corporate-user-revoke delete" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporate/user/revoke/($email)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of all admin users
#
# GET /corporate/invited/users
# operationId: getCorporateInvitedUsersList
export def "corporate-invited-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<users: table<groups: record, email: string, is_owner: string, status: string, feature_access: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/invited/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check admin user permissions
#
# GET /corporate/user/{email}/permissions
# operationId: getCorporateUserPermission
export def "corporate-user-permissions get" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, status: string, groups: table<id: string, name: string>, feature_access: record<api_keys: list<string>, my_plan: list<string>, user_management: list<string>, apps_management: list<string>, sub_organization_groups: list<string>, create_sub_organizations: list<string>, manage_sub_organizations: list<string>, analytics: list<string>, security: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporate/user/($email)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change admin user permissions
#
# PUT /corporate/user/{email}/permissions
# --privileges item shape: {feature?: "user_management"|"api"|"my_plan"|"apps_management"|"analytics"|"sub_organization_groups"|"create_sub_organizations"|"manage_sub_organizations"|"security", permissions?: list}
export def "corporate-user-permissions put" [
  email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --all-features-access: oneof<nothing, bool> # All access to the features (e.g. true)
  privileges: list # item shape: {feature?: "user_management"|"api"|"my_plan"|"apps_management"|"analytics"|"sub_organization_groups"|"create_sub_organizations"|"manage_sub_organizations"|"security", permissions?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporate/user/($email)/permissions")
  let body = {all_features_access: $all_features_access, privileges: $privileges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the list of groups
#
# GET /corporate/groups
# operationId: getSubAccountGroups
export def "corporate-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, groupName: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Companies
#
# GET /companies
export def "companies list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: string # Filter by attrbutes. If you have filter for owner on your side please send it as {"attributes.owner":"6299dcf3874a14eacbc65c46"}
  --linkedContactsIds: int # Filter by linked contacts ids (format: int64)
  --linkedDealsIds: string # Filter by linked Deals ids (format: objectID)
  --modifiedSince: string # Filter (urlencoded) the contacts modified after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). Prefer to pass your timezone in date-time format for accurate result.
  --createdSince: string # Filter (urlencoded) the contacts created after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). Prefer to pass your timezone in date-time format for accurate result.
  --page: int # Index of the first document of the page (format: int64)
  --limit: int # Number of documents per page (format: int64)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order. Default order is **descending** by creation if `sort` is not passed
  --sortBy: string # The field used to sort field names.
]: nothing -> record<items: table<id: string, attributes: record, linkedContactsIds: list, linkedDealsIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar") (serialize-qp "linkedContactsIds" $linkedContactsIds "scalar") (serialize-qp "linkedDealsIds" $linkedDealsIds "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "createdSince" $createdSince "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/companies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a company
#
# POST /companies
export def "companies post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of company (e.g. company)
  --attributes: record # Attributes for company creation (e.g. {domain: https://example.com, industry: Fabric, owner: 60e68d60582a3b006f524197})
  --countryCode: int # Country code if phone_number is passed in attributes. (format: int64, e.g. 91)
  --linkedContactsIds: list # Contact ids to be linked with company (e.g. [1, 2, 3])
  --linkedDealsIds: list # Deal ids to be linked with company (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991, 61a5ce58c5d4795761045992])
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/companies")
  let body = {name: $name, attributes: $attributes, countryCode: $countryCode, linkedContactsIds: $linkedContactsIds, linkedDealsIds: $linkedDealsIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a company
#
# GET /companies/{id}
export def "companies get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, attributes: record, linkedContactsIds: list<int>, linkedDealsIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a company
#
# DELETE /companies/{id}
export def "companies delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a company
#
# PATCH /companies/{id}
export def "companies patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of company (e.g. company)
  --attributes: record # Attributes for company update (e.g. {category: label_2, domain: xyz, date: 2022-05-04T00:00:00+05:30, industry: flipkart, number_of_contacts: 1, number_of_employees: 100, owner: 5b1a17d914b73d35a76ca0c7, phone_number: 81718441912, revenue: 10000.34222})
  --countryCode: int # Country code if phone_number is passed in attributes. (format: int64, e.g. 91)
  --linkedContactsIds: list # Warning - Using PATCH on linkedContactIds replaces the list of linked contacts. Omitted IDs will be removed. (e.g. [1, 2, 3])
  --linkedDealsIds: list # Warning - Using PATCH on linkedDealsIds replaces the list of linked contacts. Omitted IDs will be removed. (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991, 61a5ce58c5d4795761045992])
]: any -> record<id: string, attributes: record, linkedContactsIds: list<int>, linkedDealsIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/($id)")
  let body = {name: $name, attributes: $attributes, countryCode: $countryCode, linkedContactsIds: $linkedContactsIds, linkedDealsIds: $linkedDealsIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a company/deal attribute
#
# POST /crm/attributes
export def "crm-attributes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label: string # The label for the attribute (max 50 characters, cannot be empty) (e.g. Attribute Label)
  attributeType: string@attributeType-completer # The type of attribute (must be one of the defined enums) (e.g. single-select)
  --description: string # A description of the attribute (e.g. This is a sample attribute description.)
  --optionsLabels: list # Options for multi-choice or single-select attributes (e.g. [Option 1, Option 2, Option 3])
  objectType: string@objectType-completer # The type of object the attribute belongs to (prefilled with `companies` or `deal`, mandatory) (e.g. companies,deal)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crm/attributes")
  let body = {label: $label, attributeType: $attributeType, description: $description, optionsLabels: $optionsLabels, objectType: $objectType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get company attributes
#
# GET /crm/attributes/companies
export def "crm-attributes-companies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<internalName: string, label: string, attributeTypeName: string, attributeOptions: list<record>, isRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crm/attributes/companies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Link and Unlink company with contact and deal
#
# PATCH /companies/link-unlink/{id}
export def "companies-link-unlink patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --linkContactIds: list # Contact ids for contacts to be linked with company (e.g. [1, 2, 3])
  --unlinkContactIds: list # Contact ids for contacts to be unlinked from company (e.g. [4, 5, 6])
  --linkDealsIds: list # Deal ids for deals to be linked with company (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991, 61a5ce58c5d4795761045992])
  --unlinkDealsIds: list # Deal ids for deals to be unlinked from company (e.g. [61a5ce58c5d4795761045994, 61a5ce58c5d479576104595, 61a5ce58c5d4795761045996])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/companies/link-unlink/($id)")
  let body = {linkContactIds: $linkContactIds, unlinkContactIds: $unlinkContactIds, linkDealsIds: $linkDealsIds, unlinkDealsIds: $unlinkDealsIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Import companies(creation and updation)
#
# POST /companies/import
export def "companies-import post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # The CSV file to upload.The file should have the first row as the mapping attribute. Some default attribute names are (a) company_id [brevo mongoID to update deals] (b) associated_contact (c) associated_deal (f) any other attribute with internal name  (format: binary, e.g. false)
  --mapping: record # The mapping options in JSON format. Here is an example of the JSON structure: ```json {   "link_entities": true, // Determines whether to link related entities during the import process   "unlink_entities": false, // Determines whether to unlink related entities during the import process   "update_existing_records": true, // Determines whether to update based on company ID or treat every row as create   "unset_empty_attributes": false // Determines whether to unset a specific attribute during update if the values input is blank } ```
]: any -> record<processId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/companies/import")
  let body = {file: $file, mapping: $mapping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get pipeline stages
#
# GET /crm/pipeline/details
# DEPRECATED
@deprecated
export def "crm-pipeline-details list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pipeline_name: string, pipeline: string, stages: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crm/pipeline/details")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a pipeline
#
# GET /crm/pipeline/details/{pipelineID}
export def "crm-pipeline-details get" [
  pipelineID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<pipeline_name: string, pipeline: string, stages: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/pipeline/details/($pipelineID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pipelines
#
# GET /crm/pipeline/details/all
export def "crm-pipeline-details-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<pipeline_name: string, pipeline: string, stages: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crm/pipeline/details/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get deal attributes
#
# GET /crm/attributes/deals
export def "crm-attributes-deals get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<internalName: string, label: string, attributeTypeName: string, attributeOptions: list<record>, isRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crm/attributes/deals")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all deals
#
# GET /crm/deals
export def "crm-deals list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filtersattributesdeal-name: string # Filter by attributes. If you have a filter for the owner on your end, please send it as filters[attributes.deal_owner] and utilize the account email for the filtering.
  --filterslinkedCompaniesIds: string # Filter by linked companies ids
  --filterslinkedContactsIds: string # Filter by linked companies ids
  --modifiedSince: string # Filter (urlencoded) the contacts modified after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). Prefer to pass your timezone in date-time format for accurate result.
  --createdSince: string # Filter (urlencoded) the contacts created after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). Prefer to pass your timezone in date-time format for accurate result.
  --offset: int # Index of the first document of the page (format: int64)
  --limit: int # Number of documents per page (format: int64)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order. Default order is **descending** by creation if `sort` is not passed
]: nothing -> record<items: table<id: string, attributes: record, linkedContactsIds: list, linkedCompaniesIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters[attributes.deal_name]" $filtersattributesdeal_name "scalar") (serialize-qp "filters[linkedCompaniesIds]" $filterslinkedCompaniesIds "scalar") (serialize-qp "filters[linkedContactsIds]" $filterslinkedContactsIds "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "createdSince" $createdSince "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crm/deals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a deal
#
# POST /crm/deals
export def "crm-deals post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of deal (e.g. Deal: Connect with company)
  --attributes: record # Attributes for deal creation  To assign owner of a Deal you can send attributes.deal_owner and utilize the account email or ID.  If you want to create a deal on a specific pipeline and stage you can use the following attributes `pipeline` and `deal_stage`.  Pipeline and deal_stage are ids you can fetch using this endpoint `/crm/pipeline/details/{pipelineID}`  (e.g. {deal_owner: 6093d2425a9b436e9519d034, amount: 12})
  --linkedContactsIds: list # Contact ids to be linked with deal (e.g. [1, 2, 3])
  --linkedCompaniesIds: list # Company ids to be linked with deal (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991, 61a5ce58c5d4795761045992])
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crm/deals")
  let body = {name: $name, attributes: $attributes, linkedContactsIds: $linkedContactsIds, linkedCompaniesIds: $linkedCompaniesIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a deal
#
# GET /crm/deals/{id}
export def "crm-deals get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, attributes: record, linkedContactsIds: list<int>, linkedCompaniesIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/deals/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a deal
#
# DELETE /crm/deals/{id}
export def "crm-deals delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/deals/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a deal
#
# PATCH /crm/deals/{id}
export def "crm-deals patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of deal (e.g. Deal: Connect with client)
  --attributes: record # Attributes for deal update  To assign owner of a Deal you can send attributes.deal_owner and utilize the account email or ID.  If you wish to update the pipeline of a deal you need to provide the `pipeline` and the `deal_stage`  Pipeline and deal_stage are ids you can fetch using this endpoint `/crm/pipeline/details/{pipelineID}`  (e.g. {deal_owner: 6093d2425a9b436e9519d034, amount: 12})
  --linkedContactIds: list # Warning - Using PATCH on linkedContactIds replaces the list of linked contacts. Omitted IDs will be removed. (e.g. [1, 2, 3])
  --linkedCompaniesIds: list # Warning - Using PATCH on linkedCompaniesIds replaces the list of linked contacts. Omitted IDs will be removed. (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991, 61a5ce58c5d4795761045992])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/deals/($id)")
  let body = {name: $name, attributes: $attributes, linkedContactIds: $linkedContactIds, linkedCompaniesIds: $linkedCompaniesIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Link and Unlink a deal with contacts and companies
#
# PATCH /crm/deals/link-unlink/{id}
export def "crm-deals-link-unlink patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --linkContactIds: list # Contact ids for contacts to be linked with deal (e.g. [1, 2, 3])
  --unlinkContactIds: list # Contact ids for contacts to be unlinked from deal (e.g. [4, 5, 6])
  --linkCompanyIds: list # Company ids to be linked with deal (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991, 61a5ce58c5d4795761045992])
  --unlinkCompanyIds: list # Company ids to be unlinked from deal (e.g. [61a5ce58c5d4795761045994, 61a5ce58c5d479576104595, 61a5ce58c5d4795761045996])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/deals/link-unlink/($id)")
  let body = {linkContactIds: $linkContactIds, unlinkContactIds: $unlinkContactIds, linkCompanyIds: $linkCompanyIds, unlinkCompanyIds: $unlinkCompanyIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Import deals(creation and updation)
#
# POST /crm/deals/import
export def "crm-deals-import post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # The CSV file to upload.The file should have the first row as the mapping attribute. Some default attribute names are (a) deal_id [brevo mongoID to update deals] (b) associated_contact (c) associated_company (f) any other attribute with internal name  (format: binary, e.g. false)
  --mapping: record # The mapping options in JSON format. Here is an example of the JSON structure:   ```json {   "link_entities": true, // Determines whether to link related entities during the import process   "unlink_entities": false, // Determines whether to unlink related entities during the import process   "update_existing_records": true, // Determines whether to update based on company ID or treat every row as create   "unset_empty_attributes": false // Determines whether to unset a specific attribute during update if the values input is blank }  ```
]: any -> record<processId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crm/deals/import")
  let body = {file: $file, mapping: $mapping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get all task types
#
# GET /crm/tasktypes
export def "crm-tasktypes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crm/tasktypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tasks
#
# GET /crm/tasks
export def "crm-tasks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filtertype: string # Filter by task type (ID)
  --filterstatus: string@filterstatus-completer # Filter by task status
  --filterdate: string@filterdate-completer # Filter by date
  --filterassignTo: string # Filter by the "assignTo" ID. You can utilize account emails for the "assignTo" attribute.
  --filtercontacts: string # Filter by contact ids
  --filterdeals: string # Filter by deals ids
  --filtercompanies: string # Filter by companies ids
  --dateFrom: int # dateFrom to date range filter type (timestamp in milliseconds)
  --dateTo: int # dateTo to date range filter type (timestamp in milliseconds)
  --offset: int # Index of the first document of the page (format: int64)
  --limit: int # Number of documents per page (format: int64, default: 50)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order. Default order is **descending** by creation if `sort` is not passed
  --sortBy: string # The field used to sort field names. (e.g. name)
]: nothing -> record<items: table<id: string, taskTypeId: string, name: string, contactsIds: list, dealsIds: list, companiesIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[type]" $filtertype "scalar") (serialize-qp "filter[status]" $filterstatus "scalar") (serialize-qp "filter[date]" $filterdate "scalar") (serialize-qp "filter[assignTo]" $filterassignTo "scalar") (serialize-qp "filter[contacts]" $filtercontacts "scalar") (serialize-qp "filter[deals]" $filterdeals "scalar") (serialize-qp "filter[companies]" $filtercompanies "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crm/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a task
#
# POST /crm/tasks
# --reminder shape: {value: int, unit: "minutes"|"hours"|"weeks"|"days", types: list}
export def "crm-tasks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of task (e.g. Task: Connect with client)
  --duration: int # Duration of task in milliseconds [1 minute = 60000 ms] (format: int64, e.g. 600000)
  taskTypeId: string # Id for type of task e.g Call / Email / Meeting etc. (e.g. 61a5cd07ca1347c82306ad09)
  date: string # Task due date and time (format: date-time, e.g. 2021-11-01T17:44:54.668Z)
  --notes: string # Notes added to a task (e.g. In communication with client for resolution of queries.)
  --done: oneof<nothing, bool> # Task marked as done (e.g. false)
  --assignToId: string # To assign a task to a user you can use either the account email or ID. (e.g. 5faab4b7f195bb3c4c31e62a)
  --contactsIds: list # Contact ids for contacts linked to this task (e.g. [1, 2, 3])
  --dealsIds: list # Deal ids for deals a task is linked to (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991, 61a5ce58c5d4795761045992])
  --companiesIds: list # Companies ids for companies a task is linked to (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991, 61a5ce58c5d4795761045992])
  --reminder: record # Task reminder date/time for a task — shape: {value: int, unit: "minutes"|"hours"|"weeks"|"days", types: list}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crm/tasks")
  let body = {name: $name, duration: $duration, taskTypeId: $taskTypeId, date: $date, notes: $notes, done: $done, assignToId: $assignToId, contactsIds: $contactsIds, dealsIds: $dealsIds, companiesIds: $companiesIds, reminder: $reminder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a task
#
# GET /crm/tasks/{id}
export def "crm-tasks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, taskTypeId: string, name: string, contactsIds: list<int>, dealsIds: list<string>, companiesIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/tasks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a task
#
# DELETE /crm/tasks/{id}
export def "crm-tasks delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/tasks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a task
#
# PATCH /crm/tasks/{id}
# --reminder shape: {value: int, unit: "minutes"|"hours"|"weeks"|"days", types: list}
export def "crm-tasks patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of task (e.g. Task: Connect with client)
  --duration: int # Duration of task in milliseconds [1 minute = 60000 ms] (format: int64, e.g. 600000)
  --taskTypeId: string # Id for type of task e.g Call / Email / Meeting etc. (e.g. 61a5cd07ca1347c82306ad09)
  --date: string # Task date/time (format: date-time, e.g. 2021-11-01T17:44:54.668Z)
  --notes: string # Notes added to a task (e.g. In communication with client for resolution of queries.)
  --done: oneof<nothing, bool> # Task marked as done (e.g. false)
  --assignToId: string # To assign a task to a user you can use either the account email or ID. (e.g. 5faab4b7f195bb3c4c31e62a)
  --contactsIds: list # Contact ids for contacts linked to this task (e.g. [1, 2, 3])
  --dealsIds: list # Deal ids for deals a task is linked to (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991, 61a5ce58c5d4795761045992])
  --companiesIds: list # Companies ids for companies a task is linked to (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991, 61a5ce58c5d4795761045992])
  --reminder: record # Task reminder date/time for a task — shape: {value: int, unit: "minutes"|"hours"|"weeks"|"days", types: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/tasks/($id)")
  let body = {name: $name, duration: $duration, taskTypeId: $taskTypeId, date: $date, notes: $notes, done: $done, assignToId: $assignToId, contactsIds: $contactsIds, dealsIds: $dealsIds, companiesIds: $companiesIds, reminder: $reminder} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all notes
#
# GET /crm/notes
export def "crm-notes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity: string@entity-completer # Filter by note entity type
  --entityIds: string # Filter by note entity IDs
  --dateFrom: int # dateFrom to date range filter type (timestamp in milliseconds)
  --dateTo: int # dateTo to date range filter type (timestamp in milliseconds)
  --offset: int # Index of the first document of the page (format: int64)
  --limit: int # Number of documents per page (format: int64, default: 50)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order. Default order is **descending** by creation if `sort` is not passed
]: nothing -> table<id: string, text: string, contactIds: list<int>, dealIds: list<string>, authorId: record, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity" $entity "scalar") (serialize-qp "entityIds" $entityIds "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crm/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a note
#
# POST /crm/notes
export def "crm-notes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # Text content of a note (e.g. In communication with client for resolution of queries.)
  --contactIds: list # Contact Ids linked to a note (e.g. [247, 1, 2])
  --dealIds: list # Deal Ids linked to a note (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991])
  --companyIds: list # Company Ids linked to a note (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991])
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crm/notes")
  let body = {text: $text, contactIds: $contactIds, dealIds: $dealIds, companyIds: $companyIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a note
#
# GET /crm/notes/{id}
export def "crm-notes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, text: string, contactIds: list<int>, dealIds: list<string>, authorId: record, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/notes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a note
#
# PATCH /crm/notes/{id}
export def "crm-notes patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # Text content of a note (e.g. In communication with client for resolution of queries.)
  --contactIds: list # Contact Ids linked to a note (e.g. [247, 1, 2])
  --dealIds: list # Deal Ids linked to a note (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991])
  --companyIds: list # Company Ids linked to a note (e.g. [61a5ce58c5d4795761045990, 61a5ce58c5d4795761045991])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/notes/($id)")
  let body = {text: $text, contactIds: $contactIds, dealIds: $dealIds, companyIds: $companyIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a note
#
# DELETE /crm/notes/{id}
export def "crm-notes delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/notes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all files
#
# GET /crm/files
export def "crm-files list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity: string@entity-completer # Filter by file entity type
  --entityIds: string # Filter by file entity IDs
  --dateFrom: int # dateFrom to date range filter type (timestamp in milliseconds)
  --dateTo: int # dateTo to date range filter type (timestamp in milliseconds)
  --offset: int # Index of the first document of the page (format: int64)
  --limit: int # Number of documents per page (format: int64, default: 50)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order. Default order is **descending** by creation if `sort` is not passed
]: nothing -> table<name: string, authorId: string, contactId: int, dealId: string, companyId: string, size: int, createdAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entity" $entity "scalar") (serialize-qp "entityIds" $entityIds "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/crm/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a file
#
# POST /crm/files
export def "crm-files post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # File data to create a file. (format: binary)
  --dealId: string
  --contactId: int # format: int64
  --companyId: string
]: any -> record<name: string, authorId: string, contactId: int, dealId: string, companyId: string, size: int, createdAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/crm/files")
  let body = {file: $file, dealId: $dealId, contactId: $contactId, companyId: $companyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Download a file
#
# GET /crm/files/{id}
export def "crm-files get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fileUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/files/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a file
#
# DELETE /crm/files/{id}
export def "crm-files delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/files/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get file details
#
# GET /crm/files/{id}/data
export def "crm-files-data get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, authorId: string, contactId: int, dealId: string, companyId: string, size: int, createdAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/crm/files/($id)/data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send a message as an agent
#
# POST /conversations/messages
export def "conversations-messages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  visitorId: any # visitor’s ID received <a href="https://developers.brevo.com/docs/conversations-webhooks">from a webhook</a> or generated by you to <a href="https://developers.brevo.com/docs/customize-the-widget#identifying-existing-users">bind existing user account to Conversations</a>
  text: any # message text
  --agentId: any # agent ID. It can be found on agent’s page or received <a href="https://developers.brevo.com/docs/conversations-webhooks">from a webhook</a>. Alternatively, you can use `agentEmail` + `agentName` + `receivedFrom` instead (all 3 fields required).
  --receivedFrom: any # mark your messages to distinguish messages created by you from the others.
  --agentEmail: any # agent email. When sending messages from a standalone system, it’s hard to maintain a 1-to-1 relationship between the users of both systems. In this case, an agent can be specified by their email address.
  --agentName: any # agent name
]: any -> record<id: string, type: string, text: string, subject: string, html: string, rawUnsafeHtml: string, visitorId: string, agentId: string, agentName: string, createdAt: int, isPushed: bool, isTrigger: bool, isMissed: bool, isMissedByVisitor: bool, agentUserpic: string, receivedFrom: string, file: record<filename: string, size: int, isImage: bool, url: string, imageInfo: record<width: int, height: int, previewUrl: string>>, from: record<email: string, name: string>, to: table<email: string, name: string>, replyTo: record<email: string, name: string>, cc: table<email: string, name: string>, bcc: table<email: string, name: string>, sourceMessageId: string, forwardedToSourceStatus: record<isSuccess: bool, error: string>, integrations: record, isBot: bool, attachments: table<fileName: string, isInline: string, inlineId: string, url: string, isImage: bool, size: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/messages")
  let body = {visitorId: $visitorId, text: $text, agentId: $agentId, receivedFrom: $receivedFrom, agentEmail: $agentEmail, agentName: $agentName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a message
#
# GET /conversations/messages/{id}
export def "conversations-messages get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, type: string, text: string, subject: string, html: string, rawUnsafeHtml: string, visitorId: string, agentId: string, agentName: string, createdAt: int, isPushed: bool, isTrigger: bool, isMissed: bool, isMissedByVisitor: bool, agentUserpic: string, receivedFrom: string, file: record<filename: string, size: int, isImage: bool, url: string, imageInfo: record<width: int, height: int, previewUrl: string>>, from: record<email: string, name: string>, to: table<email: string, name: string>, replyTo: record<email: string, name: string>, cc: table<email: string, name: string>, bcc: table<email: string, name: string>, sourceMessageId: string, forwardedToSourceStatus: record<isSuccess: bool, error: string>, integrations: record, isBot: bool, attachments: table<fileName: string, isInline: string, inlineId: string, url: string, isImage: bool, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/messages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a message sent by an agent
#
# PUT /conversations/messages/{id}
export def "conversations-messages put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # edited message text
]: any -> record<id: string, type: string, text: string, subject: string, html: string, rawUnsafeHtml: string, visitorId: string, agentId: string, agentName: string, createdAt: int, isPushed: bool, isTrigger: bool, isMissed: bool, isMissedByVisitor: bool, agentUserpic: string, receivedFrom: string, file: record<filename: string, size: int, isImage: bool, url: string, imageInfo: record<width: int, height: int, previewUrl: string>>, from: record<email: string, name: string>, to: table<email: string, name: string>, replyTo: record<email: string, name: string>, cc: table<email: string, name: string>, bcc: table<email: string, name: string>, sourceMessageId: string, forwardedToSourceStatus: record<isSuccess: bool, error: string>, integrations: record, isBot: bool, attachments: table<fileName: string, isInline: string, inlineId: string, url: string, isImage: bool, size: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/messages/($id)")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a message sent by an agent
#
# DELETE /conversations/messages/{id}
export def "conversations-messages delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/messages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send an automated message to a visitor
#
# POST /conversations/pushedMessages
export def "conversations-pushed-messages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  visitorId: any # visitor’s ID received <a href="https://developers.brevo.com/docs/conversations-webhooks">from a webhook</a> or generated by you to <a href="https://developers.brevo.com/docs/customize-the-widget#identifying-existing-users">bind existing user account to Conversations</a>
  text: any # message text
  --agentId: any # agent ID. It can be found on agent’s page or received <a href="https://developers.brevo.com/docs/conversations-webhooks">from a webhook</a>.
  --groupId: any # group ID. It can be found on group’s page.
]: any -> record<id: string, type: string, text: string, subject: string, html: string, rawUnsafeHtml: string, visitorId: string, agentId: string, agentName: string, createdAt: int, isPushed: bool, isTrigger: bool, isMissed: bool, isMissedByVisitor: bool, agentUserpic: string, receivedFrom: string, file: record<filename: string, size: int, isImage: bool, url: string, imageInfo: record<width: int, height: int, previewUrl: string>>, from: record<email: string, name: string>, to: table<email: string, name: string>, replyTo: record<email: string, name: string>, cc: table<email: string, name: string>, bcc: table<email: string, name: string>, sourceMessageId: string, forwardedToSourceStatus: record<isSuccess: bool, error: string>, integrations: record, isBot: bool, attachments: table<fileName: string, isInline: string, inlineId: string, url: string, isImage: bool, size: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/pushedMessages")
  let body = {visitorId: $visitorId, text: $text, agentId: $agentId, groupId: $groupId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an automated message
#
# GET /conversations/pushedMessages/{id}
export def "conversations-pushed-messages get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, type: string, text: string, subject: string, html: string, rawUnsafeHtml: string, visitorId: string, agentId: string, agentName: string, createdAt: int, isPushed: bool, isTrigger: bool, isMissed: bool, isMissedByVisitor: bool, agentUserpic: string, receivedFrom: string, file: record<filename: string, size: int, isImage: bool, url: string, imageInfo: record<width: int, height: int, previewUrl: string>>, from: record<email: string, name: string>, to: table<email: string, name: string>, replyTo: record<email: string, name: string>, cc: table<email: string, name: string>, bcc: table<email: string, name: string>, sourceMessageId: string, forwardedToSourceStatus: record<isSuccess: bool, error: string>, integrations: record, isBot: bool, attachments: table<fileName: string, isInline: string, inlineId: string, url: string, isImage: bool, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/pushedMessages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an automated message
#
# PUT /conversations/pushedMessages/{id}
export def "conversations-pushed-messages put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # edited message text
]: any -> record<id: string, type: string, text: string, subject: string, html: string, rawUnsafeHtml: string, visitorId: string, agentId: string, agentName: string, createdAt: int, isPushed: bool, isTrigger: bool, isMissed: bool, isMissedByVisitor: bool, agentUserpic: string, receivedFrom: string, file: record<filename: string, size: int, isImage: bool, url: string, imageInfo: record<width: int, height: int, previewUrl: string>>, from: record<email: string, name: string>, to: table<email: string, name: string>, replyTo: record<email: string, name: string>, cc: table<email: string, name: string>, bcc: table<email: string, name: string>, sourceMessageId: string, forwardedToSourceStatus: record<isSuccess: bool, error: string>, integrations: record, isBot: bool, attachments: table<fileName: string, isInline: string, inlineId: string, url: string, isImage: bool, size: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/pushedMessages/($id)")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an automated message
#
# DELETE /conversations/pushedMessages/{id}
export def "conversations-pushed-messages delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/pushedMessages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets agent’s status to online for 2-3 minutes
#
# POST /conversations/agentOnlinePing
export def "conversations-agent-online-ping post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agentId: any # agent ID. It can be found on agent’s page or received <a href="https://developers.brevo.com/docs/conversations-webhooks">from a webhook</a>. Alternatively, you can use `agentEmail` + `agentName` + `receivedFrom` instead (all 3 fields required).
  --receivedFrom: any # mark your messages to distinguish messages created by you from the others.
  --agentEmail: any # agent email. When sending online pings from a standalone system, it’s hard to maintain a 1-to-1 relationship between the users of both systems. In this case, an agent can be specified by their email address. If there’s no agent with the specified email address in your Brevo organization, a dummy agent will be created automatically.
  --agentName: any # agent name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/agentOnlinePing")
  let body = {agentId: $agentId, receivedFrom: $receivedFrom, agentEmail: $agentEmail, agentName: $agentName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Activate the eCommerce app
#
# POST /ecommerce/activate
export def "ecommerce-activate post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ecommerce/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set the ISO 4217 compliant display currency code for your Brevo account
#
# POST /ecommerce/config/displayCurrency
# operationId: setConfigDisplayCurrency
export def "ecommerce-config-display-currency setConfigDisplayCurrency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # ISO 4217 compliant display currency code (e.g. EUR)
]: any -> record<code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ecommerce/config/displayCurrency")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the ISO 4217 compliant display currency code for your Brevo account
#
# GET /ecommerce/config/displayCurrency
export def "ecommerce-config-display-currency get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ecommerce/config/displayCurrency")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attribution metrics for one or more Brevo campaigns or workflows
#
# GET /ecommerce/attribution/metrics
export def "ecommerce-attribution-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --periodFrom: string # When getting metrics for a specific period, define the starting datetime in RFC3339 format (format: date-time, e.g. 2022-01-02T00:00:00Z)
  --periodTo: string # When getting metrics for a specific period, define the end datetime in RFC3339 format (format: date-time, e.g. 2022-01-03T00:00:00Z)
  --emailCampaignId: list # The email campaign ID(s) to get metrics for
  --smsCampaignId: list # The SMS campaign ID(s) to get metrics for
  --automationWorkflowEmailId: list # The automation workflow ID(s) to get email attribution metrics for
  --automationWorkflowSmsId: list # The automation workflow ID(s) to get SMS attribution metrics for
]: nothing -> record<results: table<id: string, conversionSource: string, ordersCount: float, revenue: float, averageBasket: float>, totals: record<ordersCount: float, revenue: float, averageBasket: float>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodFrom" $periodFrom "scalar") (serialize-qp "periodTo" $periodTo "scalar") (serialize-qp "emailCampaignId[]" $emailCampaignId "multi") (serialize-qp "smsCampaignId[]" $smsCampaignId "multi") (serialize-qp "automationWorkflowEmailId[]" $automationWorkflowEmailId "multi") (serialize-qp "automationWorkflowSmsId[]" $automationWorkflowSmsId "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/ecommerce/attribution/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get detailed attribution metrics for a single Brevo campaign or workflow
#
# GET /ecommerce/attribution/metrics/{conversionSource}/{conversionSourceId}
export def "ecommerce-attribution-metrics get-by-conversionSource-conversionSourceId" [
  conversionSource: string
  conversionSourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, conversionSource: string, ordersCount: float, revenue: float, averageBasket: float, newCustomersCount: float> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/attribution/metrics/($conversionSource)/($conversionSourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attributed product sales for a single Brevo campaign or workflow
#
# GET /ecommerce/attribution/products/{conversionSource}/{conversionSourceId}
export def "ecommerce-attribution-products get" [
  conversionSource: string
  conversionSourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<products: table<id: string, name: string, sku: string, price: float, url: string, imageUrl: string, ordersCount: int, revenue: float>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/ecommerce/attribution/products/($conversionSource)/($conversionSourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get order details
#
# GET /orders
# operationId: getOrders
export def "orders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of documents per page (format: int64, default: 50)
  --offset: int # Index of the first document in the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
  --modifiedSince: string # Filter (urlencoded) the orders modified after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.**
  --createdSince: string # Filter (urlencoded) the orders created after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.**
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "createdSince" $createdSince "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Managing the status of the order
#
# POST /orders/status
# operationId: createOrder
# --identifiers shape: {ext_id?: string, loyalty_subscription_id?: string, phone_id?: string, email_id?: string}
# --products item shape: {productId: string, quantity: float, variantId?: string, price: float}
# --billing shape: {address?: string, city?: string, countryCode?: string, country?: string, phone?: string, postCode?: string, paymentMethod?: string, region?: string}
export def "orders-status createOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Unique ID of the order. (e.g. 14)
  createdAt: string # Event occurrence UTC date-time (YYYY-MM-DDTHH:mm:ssZ), when order is actually created. (e.g. 2021-07-29T20:59:23.383Z)
  updatedAt: string # Event updated UTC date-time (YYYY-MM-DDTHH:mm:ssZ), when the status of the order is actually changed/updated. (e.g. 2021-07-30T10:59:23.383Z)
  status: string # State of the order. (e.g. completed)
  amount: float # Total amount of the order, including all shipping expenses, tax and the price of items. (e.g. 308.42)
  --storeId: string # ID of store where the order is placed (e.g. ST-21)
  --identifiers: record # Identifies the contact associated with the order. — shape: {ext_id?: string, loyalty_subscription_id?: string, phone_id?: string, email_id?: string}
  products: list # item shape: {productId: string, quantity: float, variantId?: string, price: float}
  --billing: record # Billing details of an order. — shape: {address?: string, city?: string, countryCode?: string, country?: string, phone?: string, postCode?: string, paymentMethod?: string, region?: string}
  --coupons: list # Coupons applied to the order. Stored case insensitive. (e.g. [EASTER15OFF])
  --metaInfo: record # Meta data of order to store additional detal such as custom message, customer type, source. (e.g. {order_source: Website, gift_message: Happy Birthday!, customer_loyalty_tier: Gold})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/status")
  let body = {id: $id, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, amount: $amount, storeId: $storeId, identifiers: $identifiers, products: $products, billing: $billing, coupons: $coupons, metaInfo: $metaInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create orders in batch
#
# POST /orders/status/batch
# operationId: createBatchOrder
# --orders item shape: {id: string, createdAt: string, updatedAt: string, status: string, amount: float, storeId?: string, identifiers?: record, products: list, billing?: record, coupons?: list, metaInfo?: record}
export def "orders-status-batch createBatchOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  orders: list # array of order objects — item shape: {id: string, createdAt: string, updatedAt: string, status: string, amount: float, storeId?: string, identifiers?: record, products: list, billing?: record, coupons?: list, metaInfo?: record}
  --notifyUrl: string # Notify Url provided by client to get the status of batch request (e.g. https://en.wikipedia.org/wiki/Webhook)
  --historical: oneof<nothing, bool> # Defines wether you want your orders to be considered as live data or as historical data (import of past data, synchronising data). True: orders will not trigger any automation workflows. False: orders will trigger workflows as usual. (default: true, e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/status/batch")
  let body = {orders: $orders, notifyUrl: $notifyUrl, historical: $historical} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an event
#
# POST /events
# operationId: createEvent
# --identifiers shape: {email_id?: string, phone_id?: string, whatsapp_id?: string, landline_number_id?: string, ext_id?: string}
export def "events createEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  event_name: string # The name of the event that occurred. This is how you will find your event in Brevo. Limited to 255 characters, alphanumerical characters and - _ only. (e.g. video_played)
  --event-date: string # Timestamp of when the event occurred (e.g. "2024-01-24T17:39:57+01:00"). If no value is passed, the timestamp of the event creation is used. (e.g. 2024-02-06T20:59:23.383Z)
  identifiers: record # Identifies the contact associated with the event. At least one identifier is required. — shape: {email_id?: string, phone_id?: string, whatsapp_id?: string, landline_number_id?: string, ext_id?: string}
  --contact-properties: record # Properties defining the state of the contact associated to this event. Useful to update contact attributes defined in your contacts database while passing the event. For example: **"FIRSTNAME": "Jane" , "AGE": 37** (e.g. {AGE: 32, GENDER: FEMALE})
  --event-properties: record # Properties of the event. Top level properties and nested properties can be used to better segment contacts and personalise workflow conditions. The following field type are supported: string, number, boolean (true/false), date (Timestamp e.g. "2024-01-24T17:39:57+01:00"). Keys are limited to 255 characters, alphanumerical characters and - _ only. Size is limited to 50Kb. (e.g. {video_title: Brevo — The most approachable CRM suite, vide_description: Create your free account today!, duration: 142, autoplayed: false, upload_date: 2023-11-24T12:09:10+01:00})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/events")
  let body = {event_name: $event_name, event_date: $event_date, identifiers: $identifiers, contact_properties: $contact_properties, event_properties: $event_properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return all your categories
#
# GET /categories
# operationId: getCategories
export def "categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of documents per page (format: int64, default: 50)
  --offset: int # Index of the first document in the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
  --ids: list # Filter by category ids
  --name: string # Filter by category name
  --modifiedSince: string # Filter (urlencoded) the categories modified after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.**
  --createdSince: string # Filter (urlencoded) the categories created after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.**
]: nothing -> record<categories: list<record>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "ids" $ids "multi") (serialize-qp "name" $name "scalar") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "createdSince" $createdSince "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create/Update a category
#
# POST /categories
# operationId: createUpdateCategory
export def "categories createUpdateCategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Unique Category ID as saved in the shop  (format: email, e.g. CAT123)
  --name: string # **Mandatory in case of creation**. Name of the Category, as displayed in the shop  (e.g. Electronics)
  --body-url: string # URL to the category (e.g. http://mydomain.com/category/electronics)
  --updateEnabled: oneof<nothing, bool> # Facilitate to update the existing category in the same request (updateEnabled = true) (default: false, e.g. false)
  --deletedAt: string # UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) of the category deleted from the shop's database (e.g. 2017-05-12T12:30:00Z)
  --isDeleted: oneof<nothing, bool> # category deleted from the shop's database (e.g. true)
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/categories")
  let body = {id: $id, name: $name, url: $body_url, updateEnabled: $updateEnabled, deletedAt: $deletedAt, isDeleted: $isDeleted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a category details
#
# GET /categories/{id}
# operationId: getCategoryInfo
export def "categories get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, createdAt: string, modifiedAt: string, url: string, isDeleted: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/categories/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create categories in batch
#
# POST /categories/batch
# operationId: createUpdateBatchCategory
# --categories item shape: {id: string, name?: string, url?: string, deletedAt?: string, isDeleted?: bool}
export def "categories-batch createUpdateBatchCategory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  categories: list # array of categories objects — item shape: {id: string, name?: string, url?: string, deletedAt?: string, isDeleted?: bool}
  --updateEnabled: oneof<nothing, bool> # Facilitate to update the existing categories in the same request (updateEnabled = true)
]: any -> record<createdCount: int, updatedCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/categories/batch")
  let body = {categories: $categories, updateEnabled: $updateEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Return all your products
#
# GET /products
# operationId: getProducts
export def "products list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of documents per page (format: int64, default: 50)
  --offset: int # Index of the first document in the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
  --ids: list # Filter by product ids
  --name: string # Filter by product name, minimum 3 characters should be present for search
  --pricelte: float # Price filter for products less than and equals to particular amount
  --pricegte: float # Price filter for products greater than and equals to particular amount
  --pricelt: float # Price filter for products less than particular amount
  --pricegt: float # Price filter for products greater than particular amount
  --priceeq: float # Price filter for products equals to particular amount
  --pricene: float # Price filter for products not equals to particular amount
  --categories: list # Filter by product categories
  --modifiedSince: string # Filter (urlencoded) the orders modified after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.**
  --createdSince: string # Filter (urlencoded) the orders created after a given UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ). **Prefer to pass your timezone in date-time format for accurate result.**
]: nothing -> record<products: list<record>, count: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "ids" $ids "multi") (serialize-qp "name" $name "scalar") (serialize-qp "price[lte]" $pricelte "scalar") (serialize-qp "price[gte]" $pricegte "scalar") (serialize-qp "price[lt]" $pricelt "scalar") (serialize-qp "price[gt]" $pricegt "scalar") (serialize-qp "price[eq]" $priceeq "scalar") (serialize-qp "price[ne]" $pricene "scalar") (serialize-qp "categories" $categories "multi") (serialize-qp "modifiedSince" $modifiedSince "scalar") (serialize-qp "createdSince" $createdSince "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create/Update a product
#
# POST /products
# operationId: createUpdateProduct
export def "products createUpdateProduct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # Product ID for which you requested the details (format: string, e.g. P11)
  name: string # Mandatory in case of creation**. Name of the product for which you requested the details (format: string, e.g. Iphone 11)
  --body-url: string # URL to the product (format: string, e.g. http://mydomain.com/product/electronics/product1)
  --imageUrl: string # Absolute URL to the cover image of the product (format: string, e.g. http://mydomain.com/product-absoulte-url/img.jpeg)
  --sku: string # Product identifier from the shop (format: string)
  --price: float # Price of the product (format: float)
  --categories: list # Category ID-s of the product
  --parentId: string # Parent product id of the product (format: string)
  --metaInfo: record # Meta data of product such as description, vendor, producer, stock level. The size of cumulative metaInfo shall not exceed **1000 KB**. Maximum length of metaInfo object can be 20. (e.g. {description: Shoes for sports, brand: addidas})
  --updateEnabled: oneof<nothing, bool> # Facilitate to update the existing category in the same request (updateEnabled = true) (default: false, e.g. false)
  --deletedAt: string # UTC date-time (YYYY-MM-DDTHH:mm:ss.SSSZ) of the product deleted from the shop's database
  --isDeleted: oneof<nothing, bool> # product deleted from the shop's database (e.g. true)
  --stock: float # Current stock value of the product from the shop's database (e.g. 100)
]: any -> record<id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products")
  let body = {id: $id, name: $name, url: $body_url, imageUrl: $imageUrl, sku: $sku, price: $price, categories: $categories, parentId: $parentId, metaInfo: $metaInfo, updateEnabled: $updateEnabled, deletedAt: $deletedAt, isDeleted: $isDeleted, stock: $stock} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a product's details
#
# GET /products/{id}
# operationId: getProductInfo
export def "products get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, createdAt: string, modifiedAt: string, url: string, imageUrl: string, sku: string, price: float, categories: list<string>, parentId: string, s3Original: string, s3ThumbAnalytics: string, s3ThumbEditor: string, metaInfo: record, isDeleted: bool, stock: float> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/products/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create products in batch
#
# POST /products/batch
# operationId: createUpdateBatchProducts
# --products item shape: {id: string, name: string, url?: string, imageUrl?: string, sku?: string, price?: float, categories?: list, parentId?: string, metaInfo?: record, deletedAt?: string, isDeleted?: bool, stock?: float}
export def "products-batch createUpdateBatchProducts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  products: list # array of products objects — item shape: {id: string, name: string, url?: string, imageUrl?: string, sku?: string, price?: float, categories?: list, parentId?: string, metaInfo?: record, deletedAt?: string, isDeleted?: bool, stock?: float}
  --updateEnabled: oneof<nothing, bool> # Facilitate to update the existing categories in the same request (updateEnabled = true)
]: any -> record<createdCount: int, updatedCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/products/batch")
  let body = {products: $products, updateEnabled: $updateEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all your coupon collections
#
# GET /couponCollections
# operationId: getCouponCollections
export def "coupon-collections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of documents returned per page (format: int64, default: 50)
  --offset: int # Index of the first document on the page (format: int64, default: 0)
  --qp-sort: string@sort-completer # Sort the results by creation time in ascending/descending order (default: desc)
  --sortBy: string@sortBy-completer # The field used to sort coupon collections (default: createdAt)
]: nothing -> record<id: string, name: string, defaultCoupon: string, createdAt: string, totalCoupons: int, remainingCoupons: int, expirationDate: string, remainingDaysAlert: int, remainingCouponsAlert: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/couponCollections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create а coupon collection
#
# POST /couponCollections
# operationId: createCouponCollection
export def "coupon-collections createCouponCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the coupons collection (e.g. 10%OFF)
  defaultCoupon: string # Default coupons collection name (e.g. Winter)
  --expirationDate: string # Specify an expiration date for the coupon collection in RFC3339 format. Use null to remove the expiration date. (format: date-time, e.g. 2022-01-02T00:00:00Z)
  --remainingDaysAlert: int # Send a notification alert (email) when the remaining days until the expiration date are equal or fall bellow this number. Use null to disable alerts. (e.g. 5)
  --remainingCouponsAlert: int # Send a notification alert (email) when the remaining coupons count is equal or fall bellow this number. Use null to disable alerts. (e.g. 5)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/couponCollections")
  let body = {name: $name, defaultCoupon: $defaultCoupon, expirationDate: $expirationDate, remainingDaysAlert: $remainingDaysAlert, remainingCouponsAlert: $remainingCouponsAlert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a coupon collection by id
#
# GET /couponCollections/{id}
# operationId: getCouponCollection
export def "coupon-collections get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, defaultCoupon: string, createdAt: string, totalCoupons: int, remainingCoupons: int, expirationDate: string, remainingDaysAlert: int, remainingCouponsAlert: int> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/couponCollections/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a coupon collection by id
#
# PATCH /couponCollections/{id}
# operationId: updateCouponCollection
export def "coupon-collections updateCouponCollection" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --defaultCoupon: string # A default coupon to be used in case there are no coupons left (e.g. 10 OFF)
  --expirationDate: string # Specify an expiration date for the coupon collection in RFC3339 format. Use null to remove the expiration date. (format: date-time, e.g. 2024-01-01T00:00:00Z)
  --remainingDaysAlert: int # Send a notification alert (email) when the remaining days until the expiration date are equal or fall bellow this number. Use null to disable alerts. (e.g. 5)
  --remainingCouponsAlert: int # Send a notification alert (email) when the remaining coupons count is equal or fall bellow this number. Use null to disable alerts. (e.g. 5)
]: any -> record<id: string, name: string, defaultCoupon: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/couponCollections/($id)")
  let body = {defaultCoupon: $defaultCoupon, expirationDate: $expirationDate, remainingDaysAlert: $remainingDaysAlert, remainingCouponsAlert: $remainingCouponsAlert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create coupons for a coupon collection
#
# POST /coupons
# operationId: createCoupons
export def "coupons createCoupons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  collectionId: string # The id of the coupon collection for which the coupons will be created (format: uuidv4, e.g. 23befbae-1505-47a8-bd27-e30ef739f32c)
  coupons: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/coupons")
  let body = {collectionId: $collectionId, coupons: $coupons} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a WhatsApp message
#
# POST /whatsapp/sendMessage
# operationId: sendWhatsappMessage
export def "whatsapp-send-message sendWhatsappMessage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --templateId: int # ID of the template to send (e.g. 123)
  --senderNumber: string # WhatsApp Number with country code. Example, 85264318721 (format: mobile, e.g. 919876543210)
  --params: record # Pass the set of attributes to customize the template. For example, {"FNAME":"Joe", "LNAME":"Doe"}. (e.g. {FNAME: Joe, LNAME: Doe})
  --contactNumbers: list # List of phone numbers of the contacts
  --text: string # Text to be sent as message body (will be overridden if templateId is passed in the same request) (e.g. Hi! There i am a message)
]: any -> record<messageId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whatsapp/sendMessage")
  let body = {templateId: $templateId, senderNumber: $senderNumber, params: $params, contactNumbers: $contactNumbers, text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all your WhatsApp activity (unaggregated events)
#
# GET /whatsapp/statistics/events
# operationId: getWhatsappEventReport
export def "whatsapp-statistics-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number limitation for the result returned (format: int64, default: 2500)
  --offset: int # Beginning point in the list to retrieve from (format: int64, default: 0)
  --startDate: string # **Mandatory if endDate is used.** Starting date of the report (YYYY-MM-DD). Must be lower than equal to endDate
  --endDate: string # **Mandatory if startDate is used.** Ending date of the report (YYYY-MM-DD). Must be greater than equal to startDate
  --days: int # Number of days in the past including today (positive integer). _Not compatible with 'startDate' and 'endDate'_  (format: int64)
  --contactNumber: string # Filter results for specific contact (WhatsApp Number with country code. Example, 85264318721) (format: mobile)
  --event: string@event-completer-3 # Filter the report for a specific event type
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed (default: desc)
]: nothing -> record<events: table<contactNumber: string, date: string, messageId: string, event: string, reason: string, body: string, mediaUrl: string, senderNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "days" $days "scalar") (serialize-qp "contactNumber" $contactNumber "scalar") (serialize-qp "event" $event "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whatsapp/statistics/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch all external feeds
#
# GET /feeds
# operationId: getAllExternalFeeds
export def "feeds list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Can be used to filter records by search keyword on feed name (e.g. search)
  --startDate: string # Mandatory if `endDate` is used. Starting date (YYYY-MM-DD) from which you want to fetch the list. Can be maximum 30 days older than current date. (format: date, e.g. 2022-09-04)
  --endDate: string # Mandatory if `startDate` is used. Ending date (YYYY-MM-DD) till which you want to fetch the list. Maximum time period that can be selected is one month. (format: date, e.g. 2022-10-01)
  --qp-sort: string@sort-completer # Sort the results in the ascending/descending order of record creation. Default order is **descending** if `sort` is not passed. (default: desc)
  --authType: string@authType-completer # Filter the records by `authType` of the feed.
  --limit: int # Number of documents returned per page. (format: int64, default: 50, e.g. 100)
  --offset: int # Index of the first document on the page. (format: int64, default: 0, e.g. 0)
]: nothing -> record<count: int, feeds: table<id: string, name: string, url: string, authType: string, username: string, password: string, token: string, headers: list, maxRetries: int, cache: bool, createdAt: string, modifiedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "authType" $authType "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/feeds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an external feed
#
# POST /feeds
# operationId: createExternalFeed
# --headers item shape: {name?: string, value?: string}
export def "feeds createExternalFeed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the feed (e.g. New feed)
  --body-url: string # URL of the feed (format: url, e.g. http://requestb.in/173lyyx1)
  --authType: string@authType-completer # Auth type of the feed:  * `basic`  * `token`  * `noAuth`  (default: noAuth)
  --username: string # Username for authType `basic` (e.g. user)
  --password: string # Password for authType `basic` (e.g. password)
  --body-token: string # Token for authType `token` (e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c)
  --headers: list # Custom headers for the feed (e.g. [{name: header1, value: value1}, {name: header2, value: value2}]) — item shape: {name?: string, value?: string}
  --maxRetries: int # Maximum number of retries on the feed url (default: 5, e.g. 5)
  --cache: oneof<nothing, bool> # Toggle caching of feed url response (default: false, e.g. true)
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/feeds")
  let body = {name: $name, url: $body_url, authType: $authType, username: $username, password: $password, token: $body_token, headers: $headers, maxRetries: $maxRetries, cache: $cache} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an external feed by UUID
#
# GET /feeds/{uuid}
# operationId: getExternalFeedByUUID
export def "feeds get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, name: string, url: string, authType: string, username: string, password: string, token: string, headers: table<name: string, value: string>, maxRetries: int, cache: bool, createdAt: string, modifiedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/feeds/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an external feed
#
# PUT /feeds/{uuid}
# operationId: updateExternalFeed
# --headers item shape: {name?: string, value?: string}
export def "feeds updateExternalFeed" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the feed (e.g. New feed)
  --body-url: string # URL of the feed (format: url, e.g. http://requestb.in/173lyyx1)
  --authType: string@authType-completer # Auth type of the feed:  * `basic`  * `token`  * `noAuth`
  --username: string # Username for authType `basic` (e.g. user)
  --password: string # Password for authType `basic` (e.g. password)
  --body-token: string # Token for authType `token` (e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c)
  --headers: list # Custom headers for the feed (e.g. [{name: header1, value: value1}, {name: header2, value: value2}]) — item shape: {name?: string, value?: string}
  --maxRetries: int # Maximum number of retries on the feed url (default: 5, e.g. 5)
  --cache: oneof<nothing, bool> # Toggle caching of feed url response (default: false, e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/feeds/($uuid)")
  let body = {name: $name, url: $body_url, authType: $authType, username: $username, password: $password, token: $body_token, headers: $headers, maxRetries: $maxRetries, cache: $cache} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an external feed
#
# DELETE /feeds/{uuid}
# operationId: deleteExternalFeed
export def "feeds delete" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/feeds/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a payment request
#
# POST /payments/requests
# operationId: createPaymentRequest
# --cart shape: {currency: "EUR", specificAmount: int}
# --notification shape: {channel: "email", text: string}
# --configuration shape: {customSuccessUrl: string}
export def "payments-requests createPaymentRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reference: string # Reference of the payment request, it will appear on the payment page.  (e.g. Invoice #INV0001)
  cart: record # Specify the payment currency and amount. — shape: {currency: "EUR", specificAmount: int}
  contactId: int # Brevo ID of the contact requested to pay.  (format: int64, e.g. 43)
  --description: string # description of payment request  (e.g. Shipping Cost for sending bottles to NYC)
  --notification: record # Optional. Use this object if you want to let Brevo send an email to the contact, with the payment request URL. If empty, no notifications (message and reminders) will be sent. — shape: {channel: "email", text: string}
  --configuration: any # Optional. Redirect contact to a custom success page once payment is successful. If empty the default Brevo page will be displayed once a payment is validated — shape: {customSuccessUrl: string}
]: any -> record<id: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payments/requests")
  let body = {reference: $reference, cart: $cart, contactId: $contactId, description: $description, notification: $notification, configuration: $configuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get payment request details
#
# GET /payments/requests/{id}
# operationId: getPaymentRequest
export def "payments-requests get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<reference: string, status: string, configuration: record<customSuccessUrl: string>, contactId: int, numberOfRemindersSent: int, cart: record<currency: string, specificAmount: int>, notification: record<channel: string, text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/requests/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a payment request.
#
# DELETE /payments/requests/{id}
# operationId: deletePaymentRequest
export def "payments-requests delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payments/requests/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
