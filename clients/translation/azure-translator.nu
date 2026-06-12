# Auto-generated client for Translator Text Client v3.0
# Source: https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/TranslatorText/stable/v3.0/TranslatorText.json
# Auth: --token flag or $env.TRANSLATOR_TEXT_CLIENT_TOKEN

const BASE_URL = "https://api.cognitive.microsofttranslator.com"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TRANSLATOR_TEXT_CLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "ocp-apim-subscription-key" => { {headers: {Ocp-Apim-Subscription-Key: $token_val}, query: ""} }
    "ocp-apim-subscription-region" => { {headers: {Ocp-Apim-Subscription-Region: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.cognitive.microsofttranslator.com"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "ocp-apim-subscription-region"] }

# Completers for enum parameters
def textType-completer [] { ["html" "plain"] }
def profanityAction-completer [] { ["Deleted" "Marked" "NoAction"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "break-sentence BreakSentence" } } | get name | first)
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

# Identifies the position of sentence boundaries in a piece of text.
#
# POST /BreakSentence
# operationId: Translator_BreakSentence
export def "break-sentence BreakSentence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Version of the API requested by the client. Value must be **3.0**. (default: 3.0)
  --Language: string # Language tag of the language of the input text. If not specified, Translator will apply automatic language detection.
  --Script: string # Script identifier of the script used by the input text. If a script is not specified, the default script of the language will be assumed.
  --X-ClientTraceId: string # A client-generated GUID to uniquely identify the request. Note that you can omit this header if you include the trace ID in the query string using a query parameter named ClientTraceId.
  --body: record
]: any -> table<sentLen: list<int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "Language" $Language "scalar") (serialize-qp "Script" $Script "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BreakSentence" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-ClientTraceId": $X_ClientTraceId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Identifies the language of a string of text.
#
# POST /Detect
# operationId: Translator_Detect
export def "detect Detect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Version of the API requested by the client. Value must be **3.0**. (default: 3.0)
  --X-ClientTraceId: string # A client-generated GUID to uniquely identify the request. Note that you can omit this header if you include the trace ID in the query string using a query parameter named ClientTraceId.
  --body: record
]: any -> table<text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Detect" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-ClientTraceId": $X_ClientTraceId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Provides alternative translations for a word and a small number of idiomatic phrases. Each translation has a `part-of-speech` and a list of `back-translations`. The back-translations enable a user to understand the translation in context. The Dictionary Example operation allows further drill down to see example uses of each translation pair.
#
# POST /Dictionary/Lookup
# operationId: Translator_DictionaryLookup
export def "dictionary-lookup DictionaryLookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Version of the API requested by the client. Value must be **3.0**. (default: 3.0)
  --qp-from: string # Specifies the language of the input text. The source language must be one of the supported languages included in the `dictionary` scope.
  --qp-to: string # Specifies the language of the output text. The target language must be one of the supported languages included in the `dictionary` scope of the Languages resource.
  --X-ClientTraceId: string # A client-generated GUID to uniquely identify the request. Note that you can omit this header if you include the trace ID in the query string using a query parameter named ClientTraceId.
  --body: record
]: any -> table<normalizedSource: string, displaySource: string, translations: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Dictionary/Lookup" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-ClientTraceId": $X_ClientTraceId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Provides examples that show how terms in the dictionary are used in context. This operation is used in tandem with `Dictionary lookup`.
#
# POST /Dictionary/Examples
# operationId: Translator_DictionaryExamples
export def "dictionary-examples DictionaryExamples" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Version of the API requested by the client. Value must be **3.0**. (default: 3.0)
  --qp-from: string # Specifies the language of the input text. The source language must be one of the supported languages included in the `dictionary` scope.
  --qp-to: string # Specifies the language of the output text. The target language must be one of the supported languages included in the `dictionary` scope.
  --X-ClientTraceId: string # A client-generated GUID to uniquely identify the request. Note that you can omit this header if you include the trace ID in the query string using a query parameter named ClientTraceId.
  --body: record
]: any -> table<normalizedSource: string, normalizedTarget: string, examples: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Dictionary/Examples" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-ClientTraceId": $X_ClientTraceId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the set of languages currently supported by other operations of the Translator Text API. **Authentication is not required to get language resources.**  # Response Body A client uses the `scope` query parameter to define which groups of languages it is interested in. * `scope=translation` provides languages supported to translate text from one language to another language. * `scope=transliteration` provides capabilities for converting text in one language from one script to another script. * `scope=dictionary` provides language pairs for which `Dictionary` operations return data.  A client may retrieve several groups simultaneously by specifying a comma-separated list of names. For example, `scope=translation,transliteration,dictionary` would return supported languages for all groups.  A successful response is a JSON object with one property for each requested group. The value for each property is as follows.  * `translation` property   The value of the `translation` property is a dictionary of (key, value) pairs. Each key is a BCP 47 language tag. A key identifies a language for which text can be translated to or translated from. The value associated with the key is a JSON object with properties that describe the language   * `name-` Display name of the language in the locale requested via `Accept-Language` header.   * `nativeName-` Display name of the language in the locale native for this language.   * `dir-` Directionality, which is `rtl` for right-to-left languages or `ltr` for left-to-right languages. ```json {   "translation": {   ...   "fr": {   "name": "French",   "nativeName": "Français",   "dir": "ltr"   }, ...  } } ``` * `transliteration` property   The value of the `transliteration` property is a dictionary of (key, value) pairs. Each key is a BCP 47 language tag. A key identifies a language for which text can be converted from one script to another script. The value associated with the key is a JSON object with properties that describe the language and its supported scripts   * `name-` Display name of the language in the locale requested via `Accept-Language` header.   * `nativeName-` Display name of the language in the locale native for this language.   * `scripts-` List of scripts to convert from. Each element of the `scripts` list has properties-     * `code-` Code identifying the script.     * `name-` Display name of the script in the locale requested via `Accept-Language` header.     * `nativeName-` Display name of the language in the locale native for the language.     * `dir-` Directionality, which is `rtl` for right-to-left languages or `ltr` for left-to-right languages.     * `toScripts-` List of scripts available to convert text to. Each element of the `toScripts` list has properties `code`, `name`, `nativeName`, and `dir` as described earlier.  ```json {   "transliteration": {     ...     "ja": {       "name": "Japanese",       "nativeName": "日本語",       "scripts": [         {           "code": "Jpan",           "name": "Japanese",           "nativeName": "日本語",           "dir": "ltr",           "toScripts": [             {               "code": "Latn",               "name": "Latin",               "nativeName": "ラテン語",               "dir": "ltr"             }           ]         },         {           "code": "Latn",           "name": "Latin",           "nativeName": "ラテン語",           "dir": "ltr",           "toScripts": [           {             "code": "Jpan",             "name": "Japanese",             "nativeName": "日本語",             "dir": "ltr"           }           ]         }       ]     },   ...   } }  ``` * `dictionary` property The value of the `dictionary` property is a dictionary of (key, value) pairs. Each key is a BCP 47 language tag. The key identifies a language for which alternative translations and back-translations are available. The value is a JSON object that describes the source language and the target languages with available translations.   * `name-` Display name of the source language in the locale requested via `Accept-Language` header.   * `nativeName-` Display name of the language in the locale native for this language.   * `dir-` Directionality, which is `rtl` for right-to-left languages or `ltr` for left-to-right languages.   * `translations-` List of languages with alterative translations and examples for the query expressed in the source language. Each element of the `translations` list has properties     * `name-` Display name of the target language in the locale requested via `Accept-Language` header.     * `nativeName-` Display name of the target language in the locale native for the target language.     * `dir-` Directionality, which is `rtl` for right-to-left languages or `ltr` for left-to-right languages.     * `code-` Language code identifying the target language.  ```json  "es": {   "name": "Spanish",   "nativeName": "Español",   "dir": "ltr",   "translations": [     {       "name": "English",       "nativeName": "English",       "dir": "ltr",       "code": "en"     }   ] },  ```  The structure of the response object will not change without a change in the version of the API. For the same version of the API, the list of available languages may change over time because Microsoft Translator continually extends the list of languages supported by its services.  The list of supported languages will not change frequently. To save network bandwidth and improve responsiveness, a client application should consider caching language resources and the corresponding entity tag (`ETag`). Then, the client application can periodically (for example, once every 24 hours) query the service to fetch the latest set of supported languages. Passing the current `ETag` value in an `If-None-Match` header field will allow the service to optimize the response. If the resource has not been modified, the service will return status code 304 and an empty response body.   # Response Header ETag - Current value of the entity tag for the requested groups of supported languages. To make subsequent requests more efficient, the client may send the `ETag` value in an `If-None-Match` header field.  X-RequestId - Value generated by the service to identify the request. It is used for troubleshooting purposes.       
#
# GET /Languages
# operationId: Translator_Languages
export def "languages Languages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Version of the API requested by the client. Value must be **3.0**. (default: 3.0)
  --scope: list # A comma-separated list of names defining the group of languages to return. Allowed group names are- `translation`, `transliteration` and `dictionary`. If no scope is given, then all groups are returned, which is equivalent to passing `scope=translation,transliteration,dictionary`. To decide which set of supported languages is appropriate for your scenario, see the description of the response object.
  --Accept-Language: string # The language to use for user interface strings. Some of the fields in the response are names of languages or names of regions. Use this parameter to define the language in which these names are returned. The language is specified by providing a well-formed BCP 47 language tag. For instance, use the value `fr` to request names in French or use the value `zh-Hant` to request names in Chinese Traditional. Names are provided in the English language when a target language is not specified or when localization is not available.
  --X-ClientTraceId: string # A client-generated GUID to uniquely identify the request. Note that you can omit this header if you include the trace ID in the query string using a query parameter named ClientTraceId.
]: nothing -> record<translation: record<languageCode: record<name: string, nativeName: string, dir: string>>, transliteration: record<languageCode: record<name: string, nativeName: string, scripts: list>>, dictionary: record<languageCode: record<name: string, nativeName: string, dir: string, translations: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "scope" $scope "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/Languages" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language, "X-ClientTraceId": $X_ClientTraceId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Translates text into one or more languages.
#
# POST /translate
# operationId: Translator_Translate
export def "translate Translate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Version of the API requested by the client. Value must be **3.0**. (default: 3.0)
  --qp-from: string # Specifies the language of the input text. Find which languages are available to translate from by using the languages method. If the `from` parameter is not specified, automatic language detection is applied to determine the source language.
  --qp-to: list # Specifies the language of the output text. Find which languages are available to translate to by using the languages method. For example, use `to=de` to translate to German.   It's possible to translate to multiple languages simultaneously by repeating the `to` parameter in the query string. For example, use `to=de&to=it` to translate to German and Italian in the same request.
  --textType: string@textType-completer # Defines whether the text being translated is plain text or HTML text. Any HTML needs to be a well-formed, complete HTML element. Possible values are `plain` (default) or `html`
  --category: string # A string specifying the category (domain) of the translation. This parameter retrieves translations from a customized system built with Custom Translator. Default value is `general`.
  --profanityAction: string@profanityAction-completer # Specifies how profanities should be treated in translations. Possible values are: `NoAction` (default), `Marked` or `Deleted`. ### Handling Profanity Normally the Translator service will retain profanity that is present in the source in the translation. The degree of profanity and the context that makes words profane differ between cultures, and as a result the degree of profanity in the target language may be amplified or reduced.  If you want to avoid getting profanity in the translation, regardless of the presence of profanity in the source text, you can use the profanity filtering option. The option allows you to choose whether you want to see profanity deleted, whether you want to mark profanities with appropriate tags (giving you the option to add your own post-processing), or you want no action taken. The accepted values of `ProfanityAction` are `Deleted`, `Marked` and `NoAction` (default).  | ProfanityAction | Action                                                                    | | ----------      | ----------                                                                | | `NoAction`      | This is the default behavior. Profanity will pass from source to target.  | |                 | Example Source (Japanese)- 彼はジャッカスです。                           | |                 | Example Translation (English)- He is a jackass.                           | |                 |                                                                           | | `Deleted`       | Profane words will be removed from the output without replacement.        | |                 | Example Source (Japanese)- 彼はジャッカスです。                           | |                 | Example Translation (English)- He is a.                                   | | `Marked`        | Profane words are replaced by a marker in the output. The marker depends on the `ProfanityMarker` parameter. |                 | For `ProfanityMarker=Asterisk`, profane words are replaced with `***`     | |                 | Example Source (Japanese)- 彼はジャッカスです。                           | |                 | Example Translation (English)- He is a ***.                               | |                 | For `ProfanityMarker=Tag`, profane words are surrounded by XML tags <profanity> and </profanity> |                 | Example Source (Japanese)- 彼はジャッカスです。                           | |                 | Example Translation (English)- He is a <profanity>jackass</profanity>.
  --profanityMarker: string # Specifies how profanities should be marked in translations. Possible values are- `Asterisk` (default) or `Tag`.
  --includeAlignment: oneof<nothing, bool> # Specifies whether to include alignment projection from source text to translated text. Possible values are- `true` or `false` (default).
  --includeSentenceLength: oneof<nothing, bool> # Specifies whether to include sentence boundaries for the input text and the translated text. Possible values are- `true` or `false` (default).
  --suggestedFrom: string # Specifies a fallback language if the language of the input text can't be identified. Language auto-detection is applied when the `from` parameter is omitted. If detection fails, the `suggestedFrom` language will be assumed.
  --fromScript: string # Specifies the script of the input text. Supported scripts are available from the languages method
  --toScript: list # Specifies the script of the translated text. Supported scripts are available from the languages method
  --X-ClientTraceId: string # A client-generated GUID to uniquely identify the request. Note that you can omit this header if you include the trace ID in the query string using a query parameter named ClientTraceId.
  --body: record
]: any -> table<detectedLanguage: record<language: string, score: int>, translations: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "csv") (serialize-qp "textType" $textType "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "profanityAction" $profanityAction "scalar") (serialize-qp "profanityMarker" $profanityMarker "scalar") (serialize-qp "includeAlignment" $includeAlignment "scalar") (serialize-qp "includeSentenceLength" $includeSentenceLength "scalar") (serialize-qp "suggestedFrom" $suggestedFrom "scalar") (serialize-qp "fromScript" $fromScript "scalar") (serialize-qp "toScript" $toScript "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/translate" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-ClientTraceId": $X_ClientTraceId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Converts the text of a language in one script into another type of script. Example-  Japanese script "こんにちは" Same word in Latin script "konnichiha"
#
# POST /transliterate
# operationId: Translator_Transliterate
export def "transliterate Transliterate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # Version of the API requested by the client. Value must be **3.0**. (default: 3.0)
  --language: string # Specifies the language of the text to convert from one script to another. Possible languages are listed in the `transliteration` scope obtained by querying the service for its supported languages.
  --fromScript: string # Specifies the script used by the input text. Lookup supported languages using the `transliteration` scope, to find input scripts available for the selected language.
  --toScript: string # Specifies the output script. Lookup supported languages using the `transliteration` scope, to find output scripts available for the selected combination of input language and input script.
  --X-ClientTraceId: string # A client-generated GUID to uniquely identify the request. Note that you can omit this header if you include the trace ID in the query string using a query parameter named ClientTraceId.
  --body: record
]: any -> table<text: string, script: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "fromScript" $fromScript "scalar") (serialize-qp "toScript" $toScript "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transliterate" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-ClientTraceId": $X_ClientTraceId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
