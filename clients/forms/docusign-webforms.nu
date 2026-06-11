# Auto-generated client for Web Forms API version 1.1 v1.1.0
# Source: https://raw.githubusercontent.com/docusign/OpenAPI-Specifications/master/webforms.rest.swagger-v1.1.0.json
# Auth: --token flag or $env.WEB_FORMS_API_VERSION_1_1_TOKEN

const BASE_URL = "https://apps-d.docusign.com/api/webforms"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WEB_FORMS_API_VERSION_1_1_TOKEN | default "" }
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
def base-url-completer [] { ["https://apps-d.docusign.com/api/webforms"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def user-filter-completer [] { ["all" "created_by_me" "owned_by_me" "shared_with_me"] }
def state-completer [] { ["active" "draft"] }
def authenticationMethod-completer [] { ["Biometric" "Email" "HTTPBasicAuth" "Kerberos" "KnowledgeBasedAuth" "None" "PaperDocuments" "Password" "RSASecureID" "SSLMutualAuth" "SingleSignOn_CASiteminder" "SingleSignOn_InfoCard" "SingleSignOn_MicrosoftActiveDirectory" "SingleSignOn_Other" "SingleSignOn_Passport" "SingleSignOn_SAML" "Smartcard" "X509Certificate"] }
def sendOption-completer [] { ["now"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v11-accounts-forms ListForms" } } | get name | first)
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

# Returns a list of web form configurations.
#
# GET /v1.1/accounts/{accountId}/forms
# operationId: WebForm_ListForms
export def "v11-accounts-forms ListForms" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-filter: string@user-filter-completer # Set to `owned_by_me` to return only forms owned by the authenticated user. By default, all forms are returned. (default: all)
  --is-standalone: string@bool-completer # Set to `true` or `false` to filter by whether forms are [stand-alone (not tied to a template)](https://support.docusign.com/s/document-item?bundleId=yff1696971835267&topicId=gua1698120920620.html). By default, all forms are returned.
  --is-published: string@bool-completer # When `true`, only published forms are returned. By default, published and unpublished forms are both returned.
  --sort-by: string # Sorts the results. You can sort by the time that the web forms were created or last modified, in descending or ascending order. Valid values:  * `lastModifiedDateTime:desc` (default) * `lastModifiedDateTime:asc` * `createdDateTime:desc` * `createdDateTime:asc`
  --search: string # When set, filters results by whether each web form configuration contains the given text in its `formProperties.name` property.
  --start-position: string # The zero-based index of the result from which to start returning results.  Use with `count` to limit the number of results.  The default value is 0.
  --count: string # The maximum number of results to return.  Use `start_position` to specify the number of results to skip.
]: nothing -> record<items: table<id: string, accountId: string, isPublished: bool, isEnabled: bool, isUploaded: bool, hasDraftChanges: bool, formState: string, formProperties: record, formMetadata: record>, resultSetSize: float, totalSetSize: float, startPosition: float, endPosition: float, nextUrl: string, previousUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_filter" $user_filter "scalar") (serialize-qp "is_standalone" $is_standalone "scalar") (serialize-qp "is_published" $is_published "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "start_position" $start_position "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1.1/accounts/($accountId)/forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a web form configuration.
#
# GET /v1.1/accounts/{accountId}/forms/{formId}
# operationId: WebForm_GetForm
export def "v11-accounts-forms GetForm" [
  accountId: string
  formId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer # The state of the web form configuration. Valid values:  - `active` - `draft` (default: draft)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1.1/accounts/($accountId)/forms/($formId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the instances of a given web form configuration.
#
# GET /v1.1/accounts/{accountId}/forms/{formId}/instances
# operationId: WebFormInstance_ListInstances
export def "v11-accounts-forms-instances ListInstances" [
  accountId: string
  formId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-user-id: string # A unique identifier for a user from the client's system. This value can be anything your backend system would use to track individual form instances, such as employee IDs, email addresses, or surrogate key values.
]: nothing -> record<items: table<formUrl: string, instanceToken: string, tokenExpirationDateTime: string, id: string, formId: string, accountId: string, clientUserId: string, tags: list, status: string, envelopes: list, instanceMetadata: record, formValues: record, recipients: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_user_id" $client_user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1.1/accounts/($accountId)/forms/($formId)/instances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a web form instance.
#
# POST /v1.1/accounts/{accountId}/forms/{formId}/instances
# operationId: WebFormInstance_CreateInstance
# --recipients item shape: {roleName: string, name: string, email: string, phoneNumber?: record}
export def "v11-accounts-forms-instances CreateInstance" [
  accountId: string
  formId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --formValues: record # Key-value pairs of data used to create a form instance. (e.g. {Textbox_Name: First Last, Email_primary: example@example.com, Date_birth: 2020-01-01, Number_age: 52, Select_state: California, Radio_Gender: Female, Checkbox_hobbies: [singing, dancing], ID_card_attachment: {documentName: id_card.pdf}})
  --clientUserId: string # A unique identifier for a user that should originate from client's system. This value can be anything your backend system would use to track individual form instances. Examples include employee IDs, email addresses, surrogate key values, etc. (e.g. customer_id@domain.com)
  --authenticationInstant: string # A sender-generated value that indicates the date and time that the signer was authenticated.
  --authenticationMethod: string@authenticationMethod-completer # A value that most closely matches the technique your application used to authenticate the recipient / signer. (e.g. Email)
  --assertionId: string # A unique identifier of the authentication event executed by the client application. (e.g. client-12345)
  --securityDomain: string # The domain in which the user authenticated.
  --returnUrl: string # The url to which the user is redirected after the signing is completed (e.g. http://www.thankyoupage.com)
  --expirationOffset: int # Specify the number of hours after which the form instance expires. For example, if the form expiration is set to 5 days, you should specify 120. The default value is 720 hours (30 days). (format: int64, e.g. 120)
  --sendOption: string@sendOption-completer # e.g. now
  --recipients: list # item shape: {roleName: string, name: string, email: string, phoneNumber?: record}
  --tags: list # Set this metadata to help your application identify the web form instance. The default value is `[]`.   Example value: `["Client A", "Agreement Category B"]`  This property is **optional.** (e.g. [loan_application, finance_dept])
]: any -> record<formUrl: string, instanceToken: string, tokenExpirationDateTime: string, id: string, formId: string, accountId: string, clientUserId: string, tags: list<string>, status: string, envelopes: table<id: string, createdDateTime: string>, instanceMetadata: record<expirationDateTime: string, createdDateTime: string, createdBy: record<userId: string, userName: string>, lastModifiedDateTime: string, lastModifiedBy: record<userId: string, userName: string>, submittedDateTime: string, instanceSource: string>, formValues: record, recipients: table<recipientViewId: string, instanceRecipientStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1.1/accounts/($accountId)/forms/($formId)/instances")
  let body = {formValues: $formValues, clientUserId: $clientUserId, authenticationInstant: $authenticationInstant, authenticationMethod: $authenticationMethod, assertionId: $assertionId, securityDomain: $securityDomain, returnUrl: $returnUrl, expirationOffset: $expirationOffset, sendOption: $sendOption, recipients: $recipients, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a secure web form instance.
#
# GET /v1.1/accounts/{accountId}/forms/{formId}/instances/{instanceId}
# operationId: WebFormInstance_GetInstance
export def "v11-accounts-forms-instances GetInstance" [
  accountId: string
  formId: string
  instanceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<formUrl: string, instanceToken: string, tokenExpirationDateTime: string, id: string, formId: string, accountId: string, clientUserId: string, tags: list<string>, status: string, envelopes: table<id: string, createdDateTime: string>, instanceMetadata: record<expirationDateTime: string, createdDateTime: string, createdBy: record<userId: string, userName: string>, lastModifiedDateTime: string, lastModifiedBy: record<userId: string, userName: string>, submittedDateTime: string, instanceSource: string>, formValues: record, recipients: table<recipientViewId: string, instanceRecipientStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1.1/accounts/($accountId)/forms/($formId)/instances/($instanceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refreshes the instance token.
#
# POST /v1.1/accounts/{accountId}/forms/{formId}/instances/{instanceId}/refresh
# operationId: WebFormInstance_RefreshToken
export def "v11-accounts-forms-instances-refresh RefreshToken" [
  accountId: string
  formId: string
  instanceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<formUrl: string, instanceToken: string, tokenExpirationDateTime: string, id: string, formId: string, accountId: string, clientUserId: string, tags: list<string>, status: string, envelopes: table<id: string, createdDateTime: string>, instanceMetadata: record<expirationDateTime: string, createdDateTime: string, createdBy: record<userId: string, userName: string>, lastModifiedDateTime: string, lastModifiedBy: record<userId: string, userName: string>, submittedDateTime: string, instanceSource: string>, formValues: record, recipients: table<recipientViewId: string, instanceRecipientStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1.1/accounts/($accountId)/forms/($formId)/instances/($instanceId)/refresh")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
