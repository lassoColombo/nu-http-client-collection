# Auto-generated client for Telegram Bot API v5.0.0
# Source: https://api.apis.guru/v2/specs/telegram.org/5.0.0/openapi.json
# Auth: --token flag or $env.TELEGRAM_BOT_API_TOKEN

const BASE_URL = "https://api.telegram.org/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TELEGRAM_BOT_API_TOKEN | default "" }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://api.telegram.org/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def emoji-completer [] { ["⚽" "🎯" "🎰" "🎲" "🏀"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "add-sticker-to-set create" } } | get name | first)
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

# Use this method to add a new sticker to a set created by the bot. You **must** use exactly one of the fields *png\_sticker* or *tgs\_sticker*. Animated stickers can be added to animated sticker sets and only to them. Animated sticker sets can have up to 50 stickers. Static sticker sets can have up to 120 stickers. Returns *True* on success.
#
# POST /addStickerToSet
# Docs: https://core.telegram.org/bots/api/#addstickertoset
# --mask_position shape: {point: "forehead"|"eyes"|"mouth"|"chin", scale: float, x_shift: float, y_shift: float}
export def "add-sticker-to-set create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  emojis: string # One or more emoji corresponding to the sticker
  --mask-position: record # This object describes the position on faces where a mask should be placed by default. — shape: {point: "forehead"|"eyes"|"mouth"|"chin", scale: float, x_shift: float, y_shift: float}
  name: string # Sticker set name
  --png-sticker: any # **PNG** image with the sticker, must be up to 512 kilobytes in size, dimensions must not exceed 512px, and either width or height must be exactly 512px. Pass a *file\_id* as a String to send a file that already exists on the Telegram servers, pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --tgs-sticker: any # This object represents the contents of a file to be uploaded. Must be posted using multipart/form-data in the usual way that files are uploaded via the browser.
  user_id: int # User identifier of sticker set owner
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/addStickerToSet")
  let req_body = {"emojis": $emojis, "mask_position": $mask_position, "name": $name, "png_sticker": $png_sticker, "tgs_sticker": $tgs_sticker, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to send answers to callback queries sent from [inline keyboards](/bots#inline-keyboards-and-on-the-fly-updating). The answer will be displayed to the user as a notification at the top of the chat screen or as an alert. On success, *True* is returned. Alternatively, the user can be redirected to the specified Game URL. For this option to work, you must first create a game for your bot via [@Botfather](https://t.me/botfather) and accept the terms. Otherwise, you may use links like `t.me/your_bot?start=XXXX` that open your bot with a parameter.
#
# POST /answerCallbackQuery
# Docs: https://core.telegram.org/bots/api/#answercallbackquery
export def "answer-callback-query create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-time: int # The maximum amount of time in seconds that the result of the callback query may be cached client-side. Telegram apps will support caching starting in version 3.14. Defaults to 0. (default: 0)
  callback_query_id: string # Unique identifier for the query to be answered
  --show-alert: oneof<nothing, bool> # If *true*, an alert will be shown by the client instead of a notification at the top of the chat screen. Defaults to *false*. (default: false)
  --text: string # Text of the notification. If not specified, nothing will be shown to the user, 0-200 characters
  --url: string # URL that will be opened by the user's client. If you have created a [Game](https://core.telegram.org/bots/api/#game) and accepted the conditions via [@Botfather](https://t.me/botfather), specify the URL that opens your game — note that this will only work if the query comes from a [*callback\_game*](https://core.telegram.org/bots/api/#inlinekeyboardbutton) button. Otherwise, you may use links like `t.me/your_bot?start=XXXX` that open your bot with a parameter.
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/answerCallbackQuery")
  let req_body = {"cache_time": $cache_time, "callback_query_id": $callback_query_id, "show_alert": $show_alert, "text": $text, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to send answers to an inline query. On success, *True* is returned. No more than **50** results per query are allowed.
#
# POST /answerInlineQuery
# Docs: https://core.telegram.org/bots/api/#answerinlinequery
export def "answer-inline-query create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cache-time: int # The maximum amount of time in seconds that the result of the inline query may be cached on the server. Defaults to 300. (default: 300)
  inline_query_id: string # Unique identifier for the answered query
  --is-personal: oneof<nothing, bool> # Pass *True*, if results may be cached on the server side only for the user that sent the query. By default, results may be returned to any user who sends the same query
  --next-offset: string # Pass the offset that a client should send in the next query with the same text to receive more results. Pass an empty string if there are no more results or if you don't support pagination. Offset length can't exceed 64 bytes.
  results: list # A JSON-serialized array of results for the inline query
  --switch-pm-parameter: string # [Deep-linking](/bots#deep-linking) parameter for the /start message sent to the bot when user presses the switch button. 1-64 characters, only `A-Z`, `a-z`, `0-9`, `_` and `-` are allowed. *Example:* An inline bot that sends YouTube videos can ask the user to connect the bot to their YouTube account to adapt search results accordingly. To do this, it displays a 'Connect your YouTube account' button above the results, or even before showing any. The user presses the button, switches to a private chat with the bot and, in doing so, passes a start parameter that instructs the bot to return an oauth link. Once done, the bot can offer a [*switch\_inline*](https://core.telegram.org/bots/api/#inlinekeyboardmarkup) button so that the user can easily return to the chat where they wanted to use the bot's inline capabilities.
  --switch-pm-text: string # If passed, clients will display a button with specified text that switches the user to a private chat with the bot and sends the bot a start message with the parameter *switch\_pm\_parameter*
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/answerInlineQuery")
  let req_body = {"cache_time": $cache_time, "inline_query_id": $inline_query_id, "is_personal": $is_personal, "next_offset": $next_offset, "results": $results, "switch_pm_parameter": $switch_pm_parameter, "switch_pm_text": $switch_pm_text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Once the user has confirmed their payment and shipping details, the Bot API sends the final confirmation in the form of an [Update](https://core.telegram.org/bots/api/#update) with the field *pre\_checkout\_query*. Use this method to respond to such pre-checkout queries. On success, True is returned. **Note:** The Bot API must receive an answer within 10 seconds after the pre-checkout query was sent.
#
# POST /answerPreCheckoutQuery
# Docs: https://core.telegram.org/bots/api/#answerprecheckoutquery
export def "answer-pre-checkout-query create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --error-message: string # Required if *ok* is *False*. Error message in human readable form that explains the reason for failure to proceed with the checkout (e.g. "Sorry, somebody just bought the last of our amazing black T-shirts while you were busy filling out your payment details. Please choose a different color or garment!"). Telegram will display this message to the user.
  --ok: oneof<nothing, bool> # Specify *True* if everything is alright (goods are available, etc.) and the bot is ready to proceed with the order. Use *False* if there are any problems.
  pre_checkout_query_id: string # Unique identifier for the query to be answered
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/answerPreCheckoutQuery")
  let req_body = {"error_message": $error_message, "ok": $ok, "pre_checkout_query_id": $pre_checkout_query_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# If you sent an invoice requesting a shipping address and the parameter *is\_flexible* was specified, the Bot API will send an [Update](https://core.telegram.org/bots/api/#update) with a *shipping\_query* field to the bot. Use this method to reply to shipping queries. On success, True is returned.
#
# POST /answerShippingQuery
# Docs: https://core.telegram.org/bots/api/#answershippingquery
# --shipping_options item shape: {id: string, prices: list, title: string}
export def "answer-shipping-query create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --error-message: string # Required if *ok* is False. Error message in human readable form that explains why it is impossible to complete the order (e.g. "Sorry, delivery to your desired address is unavailable'). Telegram will display this message to the user.
  --ok: oneof<nothing, bool> # Specify True if delivery to the specified address is possible and False if there are any problems (for example, if delivery to the specified address is not possible)
  --shipping-options: list # Required if *ok* is True. A JSON-serialized array of available shipping options. — item shape: {id: string, prices: list, title: string}
  shipping_query_id: string # Unique identifier for the query to be answered
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/answerShippingQuery")
  let req_body = {"error_message": $error_message, "ok": $ok, "shipping_options": $shipping_options, "shipping_query_id": $shipping_query_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to close the bot instance before moving it from one local server to another. You need to delete the webhook before calling this method to ensure that the bot isn't launched again after server restart. The method will return error 429 in the first 10 minutes after the bot is launched. Returns *True* on success. Requires no parameters.
#
# POST /close
# Docs: https://core.telegram.org/bots/api/#close
export def "close create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ok: bool, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/close")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use this method to copy messages of any kind. The method is analogous to the method [forwardMessages](https://core.telegram.org/bots/api/#forwardmessages), but the copied message doesn't have a link to the original message. Returns the [MessageId](https://core.telegram.org/bots/api/#messageid) of the sent message on success.
#
# POST /copyMessage
# Docs: https://core.telegram.org/bots/api/#copymessage
# --caption_entities item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
export def "copy-message create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  --caption: string # New caption for media, 0-1024 characters after entities parsing. If not specified, the original caption is kept
  --caption-entities: list # List of special entities that appear in the new caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  from_chat_id: any # Unique identifier for the chat where the original message was sent (or channel username in the format `@channelusername`)
  message_id: int # Message identifier in the chat specified in *from\_chat\_id*
  --parse-mode: string # Mode for parsing entities in the new caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
]: any -> record<ok: bool, result: record<message_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/copyMessage")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "caption": $caption, "caption_entities": $caption_entities, "chat_id": $chat_id, "disable_notification": $disable_notification, "from_chat_id": $from_chat_id, "message_id": $message_id, "parse_mode": $parse_mode, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to create a new sticker set owned by a user. The bot will be able to edit the sticker set thus created. You **must** use exactly one of the fields *png\_sticker* or *tgs\_sticker*. Returns *True* on success.
#
# POST /createNewStickerSet
# Docs: https://core.telegram.org/bots/api/#createnewstickerset
# --mask_position shape: {point: "forehead"|"eyes"|"mouth"|"chin", scale: float, x_shift: float, y_shift: float}
export def "create-new-sticker-set create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contains-masks: oneof<nothing, bool> # Pass *True*, if a set of mask stickers should be created
  emojis: string # One or more emoji corresponding to the sticker
  --mask-position: record # This object describes the position on faces where a mask should be placed by default. — shape: {point: "forehead"|"eyes"|"mouth"|"chin", scale: float, x_shift: float, y_shift: float}
  name: string # Short name of sticker set, to be used in `t.me/addstickers/` URLs (e.g., *animals*). Can contain only english letters, digits and underscores. Must begin with a letter, can't contain consecutive underscores and must end in *“\_by\_”*. *<bot\_username>* is case insensitive. 1-64 characters.
  --png-sticker: any # **PNG** image with the sticker, must be up to 512 kilobytes in size, dimensions must not exceed 512px, and either width or height must be exactly 512px. Pass a *file\_id* as a String to send a file that already exists on the Telegram servers, pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --tgs-sticker: any # This object represents the contents of a file to be uploaded. Must be posted using multipart/form-data in the usual way that files are uploaded via the browser.
  title: string # Sticker set title, 1-64 characters
  user_id: int # User identifier of created sticker set owner
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/createNewStickerSet")
  let req_body = {"contains_masks": $contains_masks, "emojis": $emojis, "mask_position": $mask_position, "name": $name, "png_sticker": $png_sticker, "tgs_sticker": $tgs_sticker, "title": $title, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to delete a chat photo. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns *True* on success.
#
# POST /deleteChatPhoto
# Docs: https://core.telegram.org/bots/api/#deletechatphoto
export def "delete-chat-photo create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteChatPhoto")
  let req_body = {"chat_id": $chat_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to delete a group sticker set from a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Use the field *can\_set\_sticker\_set* optionally returned in [getChat](https://core.telegram.org/bots/api/#getchat) requests to check if the bot can use this method. Returns *True* on success.
#
# POST /deleteChatStickerSet
# Docs: https://core.telegram.org/bots/api/#deletechatstickerset
export def "delete-chat-sticker-set create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteChatStickerSet")
  let req_body = {"chat_id": $chat_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to delete a message, including service messages, with the following limitations: \- A message can only be deleted if it was sent less than 48 hours ago. \- A dice message in a private chat can only be deleted if it was sent more than 24 hours ago. \- Bots can delete outgoing messages in private chats, groups, and supergroups. \- Bots can delete incoming messages in private chats. \- Bots granted *can\_post\_messages* permissions can delete outgoing messages in channels. \- If the bot is an administrator of a group, it can delete any message there. \- If the bot has *can\_delete\_messages* permission in a supergroup or a channel, it can delete any message there. Returns *True* on success.
#
# POST /deleteMessage
# Docs: https://core.telegram.org/bots/api/#deletemessage
export def "delete-message create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  message_id: int # Identifier of the message to delete
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteMessage")
  let req_body = {"chat_id": $chat_id, "message_id": $message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to delete a sticker from a set created by the bot. Returns *True* on success.
#
# POST /deleteStickerFromSet
# Docs: https://core.telegram.org/bots/api/#deletestickerfromset
export def "delete-sticker-from-set create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  sticker: string # File identifier of the sticker
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteStickerFromSet")
  let req_body = {"sticker": $sticker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to remove webhook integration if you decide to switch back to [getUpdates](https://core.telegram.org/bots/api/#getupdates). Returns *True* on success.
#
# POST /deleteWebhook
# Docs: https://core.telegram.org/bots/api/#deletewebhook
export def "delete-webhook create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --drop-pending-updates: oneof<nothing, bool> # Pass *True* to drop all pending updates
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteWebhook")
  let req_body = {"drop_pending_updates": $drop_pending_updates} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to edit captions of messages. On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api/#message) is returned, otherwise *True* is returned.
#
# POST /editMessageCaption
# Docs: https://core.telegram.org/bots/api/#editmessagecaption
# --caption_entities item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
# --reply_markup shape: {inline_keyboard: list}
export def "edit-message-caption create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --caption: string # New caption of the message, 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  --chat-id: any # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the message to edit
  --parse-mode: string # Mode for parsing entities in the message caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
]: any -> record<ok: bool, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/editMessageCaption")
  let req_body = {"caption": $caption, "caption_entities": $caption_entities, "chat_id": $chat_id, "inline_message_id": $inline_message_id, "message_id": $message_id, "parse_mode": $parse_mode, "reply_markup": $reply_markup} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to edit live location messages. A location can be edited until its *live\_period* expires or editing is explicitly disabled by a call to [stopMessageLiveLocation](https://core.telegram.org/bots/api/#stopmessagelivelocation). On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api/#message) is returned, otherwise *True* is returned.
#
# POST /editMessageLiveLocation
# Docs: https://core.telegram.org/bots/api/#editmessagelivelocation
# --reply_markup shape: {inline_keyboard: list}
export def "edit-message-live-location create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: any # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --heading: int # Direction in which the user is moving, in degrees. Must be between 1 and 360 if specified.
  --horizontal-accuracy: float # The radius of uncertainty for the location, measured in meters; 0-1500
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  latitude: float # Latitude of new location
  longitude: float # Longitude of new location
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the message to edit
  --proximity-alert-radius: int # Maximum distance for proximity alerts about approaching another chat member, in meters. Must be between 1 and 100000 if specified.
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
]: any -> record<ok: bool, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/editMessageLiveLocation")
  let req_body = {"chat_id": $chat_id, "heading": $heading, "horizontal_accuracy": $horizontal_accuracy, "inline_message_id": $inline_message_id, "latitude": $latitude, "longitude": $longitude, "message_id": $message_id, "proximity_alert_radius": $proximity_alert_radius, "reply_markup": $reply_markup} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to edit animation, audio, document, photo, or video messages. If a message is part of a message album, then it can be edited only to an audio for audio albums, only to a document for document albums and to a photo or a video otherwise. When an inline message is edited, a new file can't be uploaded. Use a previously uploaded file via its file\_id or specify a URL. On success, if the edited message was sent by the bot, the edited [Message](https://core.telegram.org/bots/api/#message) is returned, otherwise *True* is returned.
#
# POST /editMessageMedia
# Docs: https://core.telegram.org/bots/api/#editmessagemedia
# --reply_markup shape: {inline_keyboard: list}
export def "edit-message-media create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: any # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  media: any # This object represents the content of a media message to be sent. It should be one of
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the message to edit
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
]: any -> record<ok: bool, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/editMessageMedia")
  let req_body = {"chat_id": $chat_id, "inline_message_id": $inline_message_id, "media": $media, "message_id": $message_id, "reply_markup": $reply_markup} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to edit only the reply markup of messages. On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api/#message) is returned, otherwise *True* is returned.
#
# POST /editMessageReplyMarkup
# Docs: https://core.telegram.org/bots/api/#editmessagereplymarkup
# --reply_markup shape: {inline_keyboard: list}
export def "edit-message-reply-markup create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: any # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the message to edit
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
]: any -> record<ok: bool, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/editMessageReplyMarkup")
  let req_body = {"chat_id": $chat_id, "inline_message_id": $inline_message_id, "message_id": $message_id, "reply_markup": $reply_markup} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to edit text and [game](https://core.telegram.org/bots/api/#games) messages. On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api/#message) is returned, otherwise *True* is returned.
#
# POST /editMessageText
# Docs: https://core.telegram.org/bots/api/#editmessagetext
# --entities item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
# --reply_markup shape: {inline_keyboard: list}
export def "edit-message-text create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: any # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-web-page-preview: oneof<nothing, bool> # Disables link previews for links in this message
  --entities: list # List of special entities that appear in message text, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the message to edit
  --parse-mode: string # Mode for parsing entities in the message text. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
  text: string # New text of the message, 1-4096 characters after entities parsing
]: any -> record<ok: bool, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/editMessageText")
  let req_body = {"chat_id": $chat_id, "disable_web_page_preview": $disable_web_page_preview, "entities": $entities, "inline_message_id": $inline_message_id, "message_id": $message_id, "parse_mode": $parse_mode, "reply_markup": $reply_markup, "text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to generate a new invite link for a chat; any previously generated link is revoked. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns the new invite link as *String* on success.
#
# POST /exportChatInviteLink
# Docs: https://core.telegram.org/bots/api/#exportchatinvitelink
export def "export-chat-invite-link create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
]: any -> record<ok: bool, result: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/exportChatInviteLink")
  let req_body = {"chat_id": $chat_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to forward messages of any kind. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /forwardMessage
# Docs: https://core.telegram.org/bots/api/#forwardmessage
export def "forward-message create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  from_chat_id: any # Unique identifier for the chat where the original message was sent (or channel username in the format `@channelusername`)
  message_id: int # Message identifier in the chat specified in *from\_chat\_id*
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/forwardMessage")
  let req_body = {"chat_id": $chat_id, "disable_notification": $disable_notification, "from_chat_id": $from_chat_id, "message_id": $message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to get up to date information about the chat (current name of the user for one-on-one conversations, current username of a user, group or channel, etc.). Returns a [Chat](https://core.telegram.org/bots/api/#chat) object on success.
#
# POST /getChat
# Docs: https://core.telegram.org/bots/api/#getchat
export def "get-chat create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
]: any -> record<ok: bool, result: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record<address: string, location: record>, permissions: record<can_add_web_page_previews: bool, can_change_info: bool, can_invite_users: bool, can_pin_messages: bool, can_send_media_messages: bool, can_send_messages: bool, can_send_other_messages: bool, can_send_polls: bool>, photo: record<big_file_id: string, big_file_unique_id: string, small_file_id: string, small_file_unique_id: string>, pinned_message: record<animation: record, audio: record, author_signature: string, caption: string, caption_entities: list, channel_chat_created: bool, chat: any, connected_website: string, contact: record, date: int, delete_chat_photo: bool, dice: record, document: record, edit_date: int, entities: list, forward_date: int, forward_from: record, forward_from_chat: any, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record, game: record, group_chat_created: bool, invoice: record, left_chat_member: record, location: record, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list, new_chat_photo: list, new_chat_title: string, passport_data: record, photo: list, pinned_message: any, poll: record, proximity_alert_triggered: record, reply_markup: record, reply_to_message: any, sender_chat: any, sticker: record, successful_payment: record, supergroup_chat_created: bool, text: string, venue: record, via_bot: record, video: record, video_note: record, voice: record>, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getChat")
  let req_body = {"chat_id": $chat_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to get a list of administrators in a chat. On success, returns an Array of [ChatMember](https://core.telegram.org/bots/api/#chatmember) objects that contains information about all chat administrators except other bots. If the chat is a group or a supergroup and no administrators were appointed, only the creator will be returned.
#
# POST /getChatAdministrators
# Docs: https://core.telegram.org/bots/api/#getchatadministrators
export def "get-chat-administrators create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
]: any -> record<ok: bool, result: table<can_add_web_page_previews: bool, can_be_edited: bool, can_change_info: bool, can_delete_messages: bool, can_edit_messages: bool, can_invite_users: bool, can_pin_messages: bool, can_post_messages: bool, can_promote_members: bool, can_restrict_members: bool, can_send_media_messages: bool, can_send_messages: bool, can_send_other_messages: bool, can_send_polls: bool, custom_title: string, is_anonymous: bool, is_member: bool, status: string, until_date: int, user: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getChatAdministrators")
  let req_body = {"chat_id": $chat_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to get information about a member of a chat. Returns a [ChatMember](https://core.telegram.org/bots/api/#chatmember) object on success.
#
# POST /getChatMember
# Docs: https://core.telegram.org/bots/api/#getchatmember
export def "get-chat-member create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
  user_id: int # Unique identifier of the target user
]: any -> record<ok: bool, result: record<can_add_web_page_previews: bool, can_be_edited: bool, can_change_info: bool, can_delete_messages: bool, can_edit_messages: bool, can_invite_users: bool, can_pin_messages: bool, can_post_messages: bool, can_promote_members: bool, can_restrict_members: bool, can_send_media_messages: bool, can_send_messages: bool, can_send_other_messages: bool, can_send_polls: bool, custom_title: string, is_anonymous: bool, is_member: bool, status: string, until_date: int, user: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getChatMember")
  let req_body = {"chat_id": $chat_id, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to get the number of members in a chat. Returns *Int* on success.
#
# POST /getChatMembersCount
# Docs: https://core.telegram.org/bots/api/#getchatmemberscount
export def "get-chat-members-count create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
]: any -> record<ok: bool, result: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getChatMembersCount")
  let req_body = {"chat_id": $chat_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to get basic info about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a [File](https://core.telegram.org/bots/api/#file) object is returned. The file can then be downloaded via the link `https://api.telegram.org/file/bot/<file_path>`, where `<file_path>` is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling [getFile](https://core.telegram.org/bots/api/#getfile) again.
#
# POST /getFile
# Docs: https://core.telegram.org/bots/api/#getfile
export def "get-file create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file_id: string # File identifier to get info about
]: any -> record<ok: bool, result: record<file_id: string, file_path: string, file_size: int, file_unique_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getFile")
  let req_body = {"file_id": $file_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to get data for high score tables. Will return the score of the specified user and several of their neighbors in a game. On success, returns an *Array* of [GameHighScore](https://core.telegram.org/bots/api/#gamehighscore) objects. This method will currently return scores for the target user, plus two of their closest neighbors on each side. Will also return the top three users if the user and his neighbors are not among them. Please note that this behavior is subject to change.
#
# POST /getGameHighScores
# Docs: https://core.telegram.org/bots/api/#getgamehighscores
export def "get-game-high-scores create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: int # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the sent message
  user_id: int # Target user id
]: any -> record<ok: bool, result: table<position: int, score: int, user: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getGameHighScores")
  let req_body = {"chat_id": $chat_id, "inline_message_id": $inline_message_id, "message_id": $message_id, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# A simple method for testing your bot's auth token. Requires no parameters. Returns basic information about the bot in form of a [User](https://core.telegram.org/bots/api/#user) object.
#
# POST /getMe
# Docs: https://core.telegram.org/bots/api/#getme
export def "get-me create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ok: bool, result: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getMe")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use this method to get the current list of the bot's commands. Requires no parameters. Returns Array of [BotCommand](https://core.telegram.org/bots/api/#botcommand) on success.
#
# POST /getMyCommands
# Docs: https://core.telegram.org/bots/api/#getmycommands
export def "get-my-commands create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ok: bool, result: table<command: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getMyCommands")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use this method to get a sticker set. On success, a [StickerSet](https://core.telegram.org/bots/api/#stickerset) object is returned.
#
# POST /getStickerSet
# Docs: https://core.telegram.org/bots/api/#getstickerset
export def "get-sticker-set create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Name of the sticker set
]: any -> record<ok: bool, result: record<contains_masks: bool, is_animated: bool, name: string, stickers: list<record>, thumb: record<file_id: string, file_size: int, file_unique_id: string, height: int, width: int>, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getStickerSet")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to receive incoming updates using long polling ([wiki](https://en.wikipedia.org/wiki/Push_technology#Long_polling)). An Array of [Update](https://core.telegram.org/bots/api/#update) objects is returned.
#
# POST /getUpdates
# Docs: https://core.telegram.org/bots/api/#getupdates
export def "get-updates create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-updates: list<string> # A JSON-serialized list of the update types you want your bot to receive. For example, specify [“message”, “edited\_channel\_post”, “callback\_query”] to only receive updates of these types. See [Update](https://core.telegram.org/bots/api/#update) for a complete list of available update types. Specify an empty list to receive all updates regardless of type (default). If not specified, the previous setting will be used. Please note that this parameter doesn't affect updates created before the call to the getUpdates, so unwanted updates may be received for a short period of time.
  --limit: int # Limits the number of updates to be retrieved. Values between 1-100 are accepted. Defaults to 100. (default: 100)
  --offset: int # Identifier of the first update to be returned. Must be greater by one than the highest among the identifiers of previously received updates. By default, updates starting with the earliest unconfirmed update are returned. An update is considered confirmed as soon as [getUpdates](https://core.telegram.org/bots/api/#getupdates) is called with an *offset* higher than its *update\_id*. The negative offset can be specified to retrieve updates starting from *-offset* update from the end of the updates queue. All previous updates will forgotten.
  --timeout: int # Timeout in seconds for long polling. Defaults to 0, i.e. usual short polling. Should be positive, short polling should be used for testing purposes only. (default: 0)
]: any -> record<ok: bool, result: table<callback_query: record, channel_post: record, chosen_inline_result: record, edited_channel_post: record, edited_message: record, inline_query: record, message: record, poll: record, poll_answer: record, pre_checkout_query: record, shipping_query: record, update_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getUpdates")
  let req_body = {"allowed_updates": $allowed_updates, "limit": $limit, "offset": $offset, "timeout": $timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to get a list of profile pictures for a user. Returns a [UserProfilePhotos](https://core.telegram.org/bots/api/#userprofilephotos) object.
#
# POST /getUserProfilePhotos
# Docs: https://core.telegram.org/bots/api/#getuserprofilephotos
export def "get-user-profile-photos create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Limits the number of photos to be retrieved. Values between 1-100 are accepted. Defaults to 100. (default: 100)
  --offset: int # Sequential number of the first photo to be returned. By default, all photos are returned.
  user_id: int # Unique identifier of the target user
]: any -> record<ok: bool, result: record<photos: list<list>, total_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getUserProfilePhotos")
  let req_body = {"limit": $limit, "offset": $offset, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to get current webhook status. Requires no parameters. On success, returns a [WebhookInfo](https://core.telegram.org/bots/api/#webhookinfo) object. If the bot is using [getUpdates](https://core.telegram.org/bots/api/#getupdates), will return an object with the *url* field empty.
#
# POST /getWebhookInfo
# Docs: https://core.telegram.org/bots/api/#getwebhookinfo
export def "get-webhook-info create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ok: bool, result: record<allowed_updates: list<string>, has_custom_certificate: bool, ip_address: string, last_error_date: int, last_error_message: string, max_connections: int, pending_update_count: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getWebhookInfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use this method to kick a user from a group, a supergroup or a channel. In the case of supergroups and channels, the user will not be able to return to the group on their own using invite links, etc., unless [unbanned](https://core.telegram.org/bots/api/#unbanchatmember) first. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns *True* on success.
#
# POST /kickChatMember
# Docs: https://core.telegram.org/bots/api/#kickchatmember
export def "kick-chat-member create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target group or username of the target supergroup or channel (in the format `@channelusername`)
  --until-date: int # Date when the user will be unbanned, unix time. If user is banned for more than 366 days or less than 30 seconds from the current time they are considered to be banned forever
  user_id: int # Unique identifier of the target user
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/kickChatMember")
  let req_body = {"chat_id": $chat_id, "until_date": $until_date, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method for your bot to leave a group, supergroup or channel. Returns *True* on success.
#
# POST /leaveChat
# Docs: https://core.telegram.org/bots/api/#leavechat
export def "leave-chat create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/leaveChat")
  let req_body = {"chat_id": $chat_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to log out from the cloud Bot API server before launching the bot locally. You **must** log out the bot before running it locally, otherwise there is no guarantee that the bot will receive updates. After a successful call, you can immediately log in on a local server, but will not be able to log in back to the cloud Bot API server for 10 minutes. Returns *True* on success. Requires no parameters.
#
# POST /logOut
# Docs: https://core.telegram.org/bots/api/#logout
export def "log-out create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ok: bool, result: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/logOut")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use this method to add a message to the list of pinned messages in a chat. If the chat is not a private chat, the bot must be an administrator in the chat for this to work and must have the 'can\_pin\_messages' admin right in a supergroup or 'can\_edit\_messages' admin right in a channel. Returns *True* on success.
#
# POST /pinChatMessage
# Docs: https://core.telegram.org/bots/api/#pinchatmessage
export def "pin-chat-message create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Pass *True*, if it is not necessary to send a notification to all chat members about the new pinned message. Notifications are always disabled in channels and private chats.
  message_id: int # Identifier of a message to pin
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pinChatMessage")
  let req_body = {"chat_id": $chat_id, "disable_notification": $disable_notification, "message_id": $message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to promote or demote a user in a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Pass *False* for all boolean parameters to demote a user. Returns *True* on success.
#
# POST /promoteChatMember
# Docs: https://core.telegram.org/bots/api/#promotechatmember
export def "promote-chat-member create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --can-change-info: oneof<nothing, bool> # Pass True, if the administrator can change chat title, photo and other settings
  --can-delete-messages: oneof<nothing, bool> # Pass True, if the administrator can delete messages of other users
  --can-edit-messages: oneof<nothing, bool> # Pass True, if the administrator can edit messages of other users and can pin messages, channels only
  --can-invite-users: oneof<nothing, bool> # Pass True, if the administrator can invite new users to the chat
  --can-pin-messages: oneof<nothing, bool> # Pass True, if the administrator can pin messages, supergroups only
  --can-post-messages: oneof<nothing, bool> # Pass True, if the administrator can create channel posts, channels only
  --can-promote-members: oneof<nothing, bool> # Pass True, if the administrator can add new administrators with a subset of their own privileges or demote administrators that he has promoted, directly or indirectly (promoted by administrators that were appointed by him)
  --can-restrict-members: oneof<nothing, bool> # Pass True, if the administrator can restrict, ban or unban chat members
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --is-anonymous: oneof<nothing, bool> # Pass *True*, if the administrator's presence in the chat is hidden
  user_id: int # Unique identifier of the target user
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/promoteChatMember")
  let req_body = {"can_change_info": $can_change_info, "can_delete_messages": $can_delete_messages, "can_edit_messages": $can_edit_messages, "can_invite_users": $can_invite_users, "can_pin_messages": $can_pin_messages, "can_post_messages": $can_post_messages, "can_promote_members": $can_promote_members, "can_restrict_members": $can_restrict_members, "chat_id": $chat_id, "is_anonymous": $is_anonymous, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to restrict a user in a supergroup. The bot must be an administrator in the supergroup for this to work and must have the appropriate admin rights. Pass *True* for all permissions to lift restrictions from a user. Returns *True* on success.
#
# POST /restrictChatMember
# Docs: https://core.telegram.org/bots/api/#restrictchatmember
# --permissions shape: {can_add_web_page_previews?: bool, can_change_info?: bool, can_invite_users?: bool, can_pin_messages?: bool, can_send_media_messages?: bool, can_send_messages?: bool, can_send_other_messages?: bool, can_send_polls?: bool}
export def "restrict-chat-member create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
  permissions: record # Describes actions that a non-administrator user is allowed to take in a chat. — shape: {can_add_web_page_previews?: bool, can_change_info?: bool, can_invite_users?: bool, can_pin_messages?: bool, can_send_media_messages?: bool, can_send_messages?: bool, can_send_other_messages?: bool, can_send_polls?: bool}
  --until-date: int # Date when restrictions will be lifted for the user, unix time. If user is restricted for more than 366 days or less than 30 seconds from the current time, they are considered to be restricted forever
  user_id: int # Unique identifier of the target user
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restrictChatMember")
  let req_body = {"chat_id": $chat_id, "permissions": $permissions, "until_date": $until_date, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to send animation files (GIF or H.264/MPEG-4 AVC video without sound). On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned. Bots can currently send animation files of up to 50 MB in size, this limit may be changed in the future.
#
# POST /sendAnimation
# Docs: https://core.telegram.org/bots/api/#sendanimation
# --caption_entities item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
export def "send-animation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  animation: any # Animation to send. Pass a file\_id as String to send an animation that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get an animation from the Internet, or upload a new animation using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --caption: string # Animation caption (may also be used when resending animation by *file\_id*), 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --duration: int # Duration of sent animation in seconds
  --height: int # Animation height
  --parse-mode: string # Mode for parsing entities in the animation caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --thumb: any # Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file\_attach\_name>” if the thumbnail was uploaded using multipart/form-data under <file\_attach\_name>. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --width: int # Animation width
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendAnimation")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "animation": $animation, "caption": $caption, "caption_entities": $caption_entities, "chat_id": $chat_id, "disable_notification": $disable_notification, "duration": $duration, "height": $height, "parse_mode": $parse_mode, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id, "thumb": $thumb, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to send audio files, if you want Telegram clients to display them in the music player. Your audio must be in the .MP3 or .M4A format. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned. Bots can currently send audio files of up to 50 MB in size, this limit may be changed in the future. For sending voice messages, use the [sendVoice](https://core.telegram.org/bots/api/#sendvoice) method instead.
#
# POST /sendAudio
# Docs: https://core.telegram.org/bots/api/#sendaudio
# --caption_entities item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
export def "send-audio create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  audio: any # Audio file to send. Pass a file\_id as String to send an audio file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get an audio file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --caption: string # Audio caption, 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --duration: int # Duration of the audio in seconds
  --parse-mode: string # Mode for parsing entities in the audio caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --performer: string # Performer
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --thumb: any # Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file\_attach\_name>” if the thumbnail was uploaded using multipart/form-data under <file\_attach\_name>. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --title: string # Track name
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendAudio")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "audio": $audio, "caption": $caption, "caption_entities": $caption_entities, "chat_id": $chat_id, "disable_notification": $disable_notification, "duration": $duration, "parse_mode": $parse_mode, "performer": $performer, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id, "thumb": $thumb, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status). Returns *True* on success. Example: The [ImageBot](https://t.me/imagebot) needs some time to process a request and upload the image. Instead of sending a text message along the lines of “Retrieving image, please wait…”, the bot may use [sendChatAction](https://core.telegram.org/bots/api/#sendchataction) with *action* = *upload\_photo*. The user will see a “sending photo” status for the bot. We only recommend using this method when a response from the bot will take a **noticeable** amount of time to arrive.
#
# POST /sendChatAction
# Docs: https://core.telegram.org/bots/api/#sendchataction
export def "send-chat-action create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  action: string # Type of action to broadcast. Choose one, depending on what the user is about to receive: *typing* for [text messages](https://core.telegram.org/bots/api/#sendmessage), *upload\_photo* for [photos](https://core.telegram.org/bots/api/#sendphoto), *record\_video* or *upload\_video* for [videos](https://core.telegram.org/bots/api/#sendvideo), *record\_voice* or *upload\_voice* for [voice notes](https://core.telegram.org/bots/api/#sendvoice), *upload\_document* for [general files](https://core.telegram.org/bots/api/#senddocument), *find\_location* for [location data](https://core.telegram.org/bots/api/#sendlocation), *record\_video\_note* or *upload\_video\_note* for [video notes](https://core.telegram.org/bots/api/#sendvideonote).
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendChatAction")
  let req_body = {"action": $action, "chat_id": $chat_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to send phone contacts. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendContact
# Docs: https://core.telegram.org/bots/api/#sendcontact
export def "send-contact create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  first_name: string # Contact's first name
  --last-name: string # Contact's last name
  phone_number: string # Contact's phone number
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --vcard: string # Additional data about the contact in the form of a [vCard](https://en.wikipedia.org/wiki/VCard), 0-2048 bytes
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendContact")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "chat_id": $chat_id, "disable_notification": $disable_notification, "first_name": $first_name, "last_name": $last_name, "phone_number": $phone_number, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id, "vcard": $vcard} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to send an animated emoji that will display a random value. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendDice
# Docs: https://core.telegram.org/bots/api/#senddice
export def "send-dice create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --emoji: string@emoji-completer # Emoji on which the dice throw animation is based. Currently, must be one of “”, “”, “”, “”, or “”. Dice can have values 1-6 for “” and “”, values 1-5 for “” and “”, and values 1-64 for “”. Defaults to “” (default: 🎲)
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendDice")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "chat_id": $chat_id, "disable_notification": $disable_notification, "emoji": $emoji, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to send general files. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned. Bots can currently send files of any type of up to 50 MB in size, this limit may be changed in the future.
#
# POST /sendDocument
# Docs: https://core.telegram.org/bots/api/#senddocument
# --caption_entities item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
export def "send-document create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  --caption: string # Document caption (may also be used when resending documents by *file\_id*), 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-content-type-detection: oneof<nothing, bool> # Disables automatic server-side content type detection for files uploaded using multipart/form-data
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  document: any # File to send. Pass a file\_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --parse-mode: string # Mode for parsing entities in the document caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --thumb: any # Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file\_attach\_name>” if the thumbnail was uploaded using multipart/form-data under <file\_attach\_name>. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendDocument")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "caption": $caption, "caption_entities": $caption_entities, "chat_id": $chat_id, "disable_content_type_detection": $disable_content_type_detection, "disable_notification": $disable_notification, "document": $document, "parse_mode": $parse_mode, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id, "thumb": $thumb} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to send a game. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendGame
# Docs: https://core.telegram.org/bots/api/#sendgame
# --reply_markup shape: {inline_keyboard: list}
export def "send-game create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: int # Unique identifier for the target chat
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  game_short_name: string # Short name of the game, serves as the unique identifier for the game. Set up your games via [Botfather](https://t.me/botfather).
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
  --reply-to-message-id: int # If the message is a reply, ID of the original message
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendGame")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "chat_id": $chat_id, "disable_notification": $disable_notification, "game_short_name": $game_short_name, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to send invoices. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendInvoice
# Docs: https://core.telegram.org/bots/api/#sendinvoice
# --prices item shape: {amount: int, label: string}
# --reply_markup shape: {inline_keyboard: list}
export def "send-invoice create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: int # Unique identifier for the target private chat
  currency: string # Three-letter ISO 4217 currency code, see [more on currencies](/bots/payments#supported-currencies)
  description: string # Product description, 1-255 characters
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --is-flexible: oneof<nothing, bool> # Pass *True*, if the final price depends on the shipping method
  --need-email: oneof<nothing, bool> # Pass *True*, if you require the user's email address to complete the order
  --need-name: oneof<nothing, bool> # Pass *True*, if you require the user's full name to complete the order
  --need-phone-number: oneof<nothing, bool> # Pass *True*, if you require the user's phone number to complete the order
  --need-shipping-address: oneof<nothing, bool> # Pass *True*, if you require the user's shipping address to complete the order
  payload: string # Bot-defined invoice payload, 1-128 bytes. This will not be displayed to the user, use for your internal processes.
  --photo-height: int # Photo height
  --photo-size: int # Photo size
  --photo-url: string # URL of the product photo for the invoice. Can be a photo of the goods or a marketing image for a service. People like it better when they see what they are paying for.
  --photo-width: int # Photo width
  prices: list # Price breakdown, a JSON-serialized list of components (e.g. product price, tax, discount, delivery cost, delivery tax, bonus, etc.) — item shape: {amount: int, label: string}
  --provider-data: string # A JSON-serialized data about the invoice, which will be shared with the payment provider. A detailed description of required fields should be provided by the payment provider.
  provider_token: string # Payments provider token, obtained via [Botfather](https://t.me/botfather)
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --send-email-to-provider: oneof<nothing, bool> # Pass *True*, if user's email address should be sent to provider
  --send-phone-number-to-provider: oneof<nothing, bool> # Pass *True*, if user's phone number should be sent to provider
  start_parameter: string # Unique deep-linking parameter that can be used to generate this invoice when used as a start parameter
  title: string # Product name, 1-32 characters
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendInvoice")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "chat_id": $chat_id, "currency": $currency, "description": $description, "disable_notification": $disable_notification, "is_flexible": $is_flexible, "need_email": $need_email, "need_name": $need_name, "need_phone_number": $need_phone_number, "need_shipping_address": $need_shipping_address, "payload": $payload, "photo_height": $photo_height, "photo_size": $photo_size, "photo_url": $photo_url, "photo_width": $photo_width, "prices": $prices, "provider_data": $provider_data, "provider_token": $provider_token, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id, "send_email_to_provider": $send_email_to_provider, "send_phone_number_to_provider": $send_phone_number_to_provider, "start_parameter": $start_parameter, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to send point on the map. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendLocation
# Docs: https://core.telegram.org/bots/api/#sendlocation
export def "send-location create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --heading: int # For live locations, a direction in which the user is moving, in degrees. Must be between 1 and 360 if specified.
  --horizontal-accuracy: float # The radius of uncertainty for the location, measured in meters; 0-1500
  latitude: float # Latitude of the location
  --live-period: int # Period in seconds for which the location will be updated (see [Live Locations](https://telegram.org/blog/live-locations), should be between 60 and 86400.
  longitude: float # Longitude of the location
  --proximity-alert-radius: int # For live locations, a maximum distance for proximity alerts about approaching another chat member, in meters. Must be between 1 and 100000 if specified.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendLocation")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "chat_id": $chat_id, "disable_notification": $disable_notification, "heading": $heading, "horizontal_accuracy": $horizontal_accuracy, "latitude": $latitude, "live_period": $live_period, "longitude": $longitude, "proximity_alert_radius": $proximity_alert_radius, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to send a group of photos, videos, documents or audios as an album. Documents and audio files can be only grouped in an album with messages of the same type. On success, an array of [Messages](https://core.telegram.org/bots/api/#message) that were sent is returned.
#
# POST /sendMediaGroup
# Docs: https://core.telegram.org/bots/api/#sendmediagroup
export def "send-media-group create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends messages [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  media: list # A JSON-serialized array describing messages to be sent, must include 2-10 items
  --reply-to-message-id: int # If the messages are a reply, ID of the original message
]: any -> record<ok: bool, result: table<animation: record, audio: record, author_signature: string, caption: string, caption_entities: list, channel_chat_created: bool, chat: record, connected_website: string, contact: record, date: int, delete_chat_photo: bool, dice: record, document: record, edit_date: int, entities: list, forward_date: int, forward_from: record, forward_from_chat: record, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record, game: record, group_chat_created: bool, invoice: record, left_chat_member: record, location: record, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list, new_chat_photo: list, new_chat_title: string, passport_data: record, photo: list, pinned_message: any, poll: record, proximity_alert_triggered: record, reply_markup: record, reply_to_message: any, sender_chat: record, sticker: record, successful_payment: record, supergroup_chat_created: bool, text: string, venue: record, via_bot: record, video: record, video_note: record, voice: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendMediaGroup")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "chat_id": $chat_id, "disable_notification": $disable_notification, "media": $media, "reply_to_message_id": $reply_to_message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to send text messages. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendMessage
# Docs: https://core.telegram.org/bots/api/#sendmessage
# --entities item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
export def "send-message create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --disable-web-page-preview: oneof<nothing, bool> # Disables link previews for links in this message
  --entities: list # List of special entities that appear in message text, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  --parse-mode: string # Mode for parsing entities in the message text. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  text: string # Text of the message to be sent, 1-4096 characters after entities parsing
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendMessage")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "chat_id": $chat_id, "disable_notification": $disable_notification, "disable_web_page_preview": $disable_web_page_preview, "entities": $entities, "parse_mode": $parse_mode, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id, "text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to send photos. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendPhoto
# Docs: https://core.telegram.org/bots/api/#sendphoto
# --caption_entities item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
export def "send-photo create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  --caption: string # Photo caption (may also be used when resending photos by *file\_id*), 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --parse-mode: string # Mode for parsing entities in the photo caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  photo: any # Photo to send. Pass a file\_id as String to send a photo that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a photo from the Internet, or upload a new photo using multipart/form-data. The photo must be at most 10 MB in size. The photo's width and height must not exceed 10000 in total. Width and height ratio must be at most 20. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendPhoto")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "caption": $caption, "caption_entities": $caption_entities, "chat_id": $chat_id, "disable_notification": $disable_notification, "parse_mode": $parse_mode, "photo": $photo, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to send a native poll. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendPoll
# Docs: https://core.telegram.org/bots/api/#sendpoll
# --explanation_entities item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
export def "send-poll create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  --allows-multiple-answers: oneof<nothing, bool> # True, if the poll allows multiple answers, ignored for polls in quiz mode, defaults to *False*
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --close-date: int # Point in time (Unix timestamp) when the poll will be automatically closed. Must be at least 5 and no more than 600 seconds in the future. Can't be used together with *open\_period*.
  --correct-option-id: int # 0-based identifier of the correct answer option, required for polls in quiz mode
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --explanation: string # Text that is shown when a user chooses an incorrect answer or taps on the lamp icon in a quiz-style poll, 0-200 characters with at most 2 line feeds after entities parsing
  --explanation-entities: list # List of special entities that appear in the poll explanation, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  --explanation-parse-mode: string # Mode for parsing entities in the explanation. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --is-anonymous: oneof<nothing, bool> # True, if the poll needs to be anonymous, defaults to *True*
  --is-closed: oneof<nothing, bool> # Pass *True*, if the poll needs to be immediately closed. This can be useful for poll preview.
  --open-period: int # Amount of time in seconds the poll will be active after creation, 5-600. Can't be used together with *close\_date*.
  options: list<string> # A JSON-serialized list of answer options, 2-10 strings 1-100 characters each
  question: string # Poll question, 1-300 characters
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --type: string # Poll type, “quiz” or “regular”, defaults to “regular”
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendPoll")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "allows_multiple_answers": $allows_multiple_answers, "chat_id": $chat_id, "close_date": $close_date, "correct_option_id": $correct_option_id, "disable_notification": $disable_notification, "explanation": $explanation, "explanation_entities": $explanation_entities, "explanation_parse_mode": $explanation_parse_mode, "is_anonymous": $is_anonymous, "is_closed": $is_closed, "open_period": $open_period, "options": $options, "question": $question, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to send static .WEBP or [animated](https://telegram.org/blog/animated-stickers) .TGS stickers. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendSticker
# Docs: https://core.telegram.org/bots/api/#sendsticker
export def "send-sticker create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  sticker: any # Sticker to send. Pass a file\_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a .WEBP file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendSticker")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "chat_id": $chat_id, "disable_notification": $disable_notification, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id, "sticker": $sticker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to send information about a venue. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendVenue
# Docs: https://core.telegram.org/bots/api/#sendvenue
export def "send-venue create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # Address of the venue
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --foursquare-id: string # Foursquare identifier of the venue
  --foursquare-type: string # Foursquare type of the venue, if known. (For example, “arts\_entertainment/default”, “arts\_entertainment/aquarium” or “food/icecream”.)
  --google-place-id: string # Google Places identifier of the venue
  --google-place-type: string # Google Places type of the venue. (See [supported types](https://developers.google.com/places/web-service/supported_types).)
  latitude: float # Latitude of the venue
  longitude: float # Longitude of the venue
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  title: string # Name of the venue
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendVenue")
  let req_body = {"address": $address, "allow_sending_without_reply": $allow_sending_without_reply, "chat_id": $chat_id, "disable_notification": $disable_notification, "foursquare_id": $foursquare_id, "foursquare_type": $foursquare_type, "google_place_id": $google_place_id, "google_place_type": $google_place_type, "latitude": $latitude, "longitude": $longitude, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to send video files, Telegram clients support mp4 videos (other formats may be sent as [Document](https://core.telegram.org/bots/api/#document)). On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned. Bots can currently send video files of up to 50 MB in size, this limit may be changed in the future.
#
# POST /sendVideo
# Docs: https://core.telegram.org/bots/api/#sendvideo
# --caption_entities item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
export def "send-video create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  --caption: string # Video caption (may also be used when resending videos by *file\_id*), 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --duration: int # Duration of sent video in seconds
  --height: int # Video height
  --parse-mode: string # Mode for parsing entities in the video caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --supports-streaming: oneof<nothing, bool> # Pass *True*, if the uploaded video is suitable for streaming
  --thumb: any # Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file\_attach\_name>” if the thumbnail was uploaded using multipart/form-data under <file\_attach\_name>. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  video: any # Video to send. Pass a file\_id as String to send a video that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a video from the Internet, or upload a new video using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  --width: int # Video width
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendVideo")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "caption": $caption, "caption_entities": $caption_entities, "chat_id": $chat_id, "disable_notification": $disable_notification, "duration": $duration, "height": $height, "parse_mode": $parse_mode, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id, "supports_streaming": $supports_streaming, "thumb": $thumb, "video": $video, "width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# As of [v.4.0](https://telegram.org/blog/video-messages-and-telescope), Telegram clients support rounded square mp4 videos of up to 1 minute long. Use this method to send video messages. On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned.
#
# POST /sendVideoNote
# Docs: https://core.telegram.org/bots/api/#sendvideonote
export def "send-video-note create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --duration: int # Duration of sent video in seconds
  --length: int # Video width and height, i.e. diameter of the video message
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  --thumb: any # Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file\_attach\_name>” if the thumbnail was uploaded using multipart/form-data under <file\_attach\_name>. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
  video_note: any # Video note to send. Pass a file\_id as String to send a video note that exists on the Telegram servers (recommended) or upload a new video using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files). Sending video notes by a URL is currently unsupported
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendVideoNote")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "chat_id": $chat_id, "disable_notification": $disable_notification, "duration": $duration, "length": $length, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id, "thumb": $thumb, "video_note": $video_note} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to send audio files, if you want Telegram clients to display the file as a playable voice message. For this to work, your audio must be in an .OGG file encoded with OPUS (other formats may be sent as [Audio](https://core.telegram.org/bots/api/#audio) or [Document](https://core.telegram.org/bots/api/#document)). On success, the sent [Message](https://core.telegram.org/bots/api/#message) is returned. Bots can currently send voice messages of up to 50 MB in size, this limit may be changed in the future.
#
# POST /sendVoice
# Docs: https://core.telegram.org/bots/api/#sendvoice
# --caption_entities item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
export def "send-voice create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-sending-without-reply: oneof<nothing, bool> # Pass *True*, if the message should be sent even if the specified replied-to message is not found
  --caption: string # Voice message caption, 0-1024 characters after entities parsing
  --caption-entities: list # List of special entities that appear in the caption, which can be specified instead of *parse\_mode* — item shape: {language?: string, length: int, offset: int, type: "mention"|"hashtag"|"cashtag"|"bot_command"|"url"|"email"|"phone_number"|"bold"|"italic"|"underline"|"strikethrough"|"code"|"pre"|"text_link"|"text_mention", url?: string, user?: record}
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --disable-notification: oneof<nothing, bool> # Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
  --duration: int # Duration of the voice message in seconds
  --parse-mode: string # Mode for parsing entities in the voice message caption. See [formatting options](https://core.telegram.org/bots/api/#formatting-options) for more details.
  --reply-markup: any # Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating), [custom reply keyboard](https://core.telegram.org/bots#keyboards), instructions to remove reply keyboard or to force a reply from the user.
  --reply-to-message-id: int # If the message is a reply, ID of the original message
  voice: any # Audio file to send. Pass a file\_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files)
]: any -> record<ok: bool, result: record<animation: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, audio: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, performer: string, thumb: record, title: string>, author_signature: string, caption: string, caption_entities: list<record>, channel_chat_created: bool, chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, connected_website: string, contact: record<first_name: string, last_name: string, phone_number: string, user_id: int, vcard: string>, date: int, delete_chat_photo: bool, dice: record<emoji: string, value: int>, document: record<file_id: string, file_name: string, file_size: int, file_unique_id: string, mime_type: string, thumb: record>, edit_date: int, entities: list<record>, forward_date: int, forward_from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, forward_from_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, forward_from_message_id: int, forward_sender_name: string, forward_signature: string, from: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, game: record<animation: record, description: string, photo: list, text: string, text_entities: list, title: string>, group_chat_created: bool, invoice: record<currency: string, description: string, start_parameter: string, title: string, total_amount: int>, left_chat_member: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, location: record<heading: int, horizontal_accuracy: float, latitude: float, live_period: int, longitude: float, proximity_alert_radius: int>, media_group_id: string, message_id: int, migrate_from_chat_id: int, migrate_to_chat_id: int, new_chat_members: list<record>, new_chat_photo: list<record>, new_chat_title: string, passport_data: record<credentials: record, data: list>, photo: list<record>, pinned_message: any, poll: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list, question: string, total_voter_count: int, type: string>, proximity_alert_triggered: record<distance: int, traveler: record, watcher: record>, reply_markup: record<inline_keyboard: list>, reply_to_message: any, sender_chat: record<bio: string, can_set_sticker_set: bool, description: string, first_name: string, id: int, invite_link: string, last_name: string, linked_chat_id: int, location: record, permissions: record, photo: record, pinned_message: any, slow_mode_delay: int, sticker_set_name: string, title: string, type: string, username: string>, sticker: record<emoji: string, file_id: string, file_size: int, file_unique_id: string, height: int, is_animated: bool, mask_position: record, set_name: string, thumb: record, width: int>, successful_payment: record<currency: string, invoice_payload: string, order_info: record, provider_payment_charge_id: string, shipping_option_id: string, telegram_payment_charge_id: string, total_amount: int>, supergroup_chat_created: bool, text: string, venue: record<address: string, foursquare_id: string, foursquare_type: string, google_place_id: string, google_place_type: string, location: record, title: string>, via_bot: record<can_join_groups: bool, can_read_all_group_messages: bool, first_name: string, id: int, is_bot: bool, language_code: string, last_name: string, supports_inline_queries: bool, username: string>, video: record<duration: int, file_id: string, file_name: string, file_size: int, file_unique_id: string, height: int, mime_type: string, thumb: record, width: int>, video_note: record<duration: int, file_id: string, file_size: int, file_unique_id: string, length: int, thumb: record>, voice: record<duration: int, file_id: string, file_size: int, file_unique_id: string, mime_type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sendVoice")
  let req_body = {"allow_sending_without_reply": $allow_sending_without_reply, "caption": $caption, "caption_entities": $caption_entities, "chat_id": $chat_id, "disable_notification": $disable_notification, "duration": $duration, "parse_mode": $parse_mode, "reply_markup": $reply_markup, "reply_to_message_id": $reply_to_message_id, "voice": $voice} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to set a custom title for an administrator in a supergroup promoted by the bot. Returns *True* on success.
#
# POST /setChatAdministratorCustomTitle
# Docs: https://core.telegram.org/bots/api/#setchatadministratorcustomtitle
export def "set-chat-administrator-custom-title create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
  custom_title: string # New custom title for the administrator; 0-16 characters, emoji are not allowed
  user_id: int # Unique identifier of the target user
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setChatAdministratorCustomTitle")
  let req_body = {"chat_id": $chat_id, "custom_title": $custom_title, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to change the description of a group, a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns *True* on success.
#
# POST /setChatDescription
# Docs: https://core.telegram.org/bots/api/#setchatdescription
export def "set-chat-description create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --description: string # New chat description, 0-255 characters
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setChatDescription")
  let req_body = {"chat_id": $chat_id, "description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to set default chat permissions for all members. The bot must be an administrator in the group or a supergroup for this to work and must have the *can\_restrict\_members* admin rights. Returns *True* on success.
#
# POST /setChatPermissions
# Docs: https://core.telegram.org/bots/api/#setchatpermissions
# --permissions shape: {can_add_web_page_previews?: bool, can_change_info?: bool, can_invite_users?: bool, can_pin_messages?: bool, can_send_media_messages?: bool, can_send_messages?: bool, can_send_other_messages?: bool, can_send_polls?: bool}
export def "set-chat-permissions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
  permissions: record # Describes actions that a non-administrator user is allowed to take in a chat. — shape: {can_add_web_page_previews?: bool, can_change_info?: bool, can_invite_users?: bool, can_pin_messages?: bool, can_send_media_messages?: bool, can_send_messages?: bool, can_send_other_messages?: bool, can_send_polls?: bool}
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setChatPermissions")
  let req_body = {"chat_id": $chat_id, "permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to set a new profile photo for the chat. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns *True* on success.
#
# POST /setChatPhoto
# Docs: https://core.telegram.org/bots/api/#setchatphoto
export def "set-chat-photo create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  photo: any # This object represents the contents of a file to be uploaded. Must be posted using multipart/form-data in the usual way that files are uploaded via the browser.
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setChatPhoto")
  let req_body = {"chat_id": $chat_id, "photo": $photo} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to set a new group sticker set for a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Use the field *can\_set\_sticker\_set* optionally returned in [getChat](https://core.telegram.org/bots/api/#getchat) requests to check if the bot can use this method. Returns *True* on success.
#
# POST /setChatStickerSet
# Docs: https://core.telegram.org/bots/api/#setchatstickerset
export def "set-chat-sticker-set create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
  sticker_set_name: string # Name of the sticker set to be set as the group sticker set
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setChatStickerSet")
  let req_body = {"chat_id": $chat_id, "sticker_set_name": $sticker_set_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to change the title of a chat. Titles can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate admin rights. Returns *True* on success.
#
# POST /setChatTitle
# Docs: https://core.telegram.org/bots/api/#setchattitle
export def "set-chat-title create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  title: string # New chat title, 1-255 characters
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setChatTitle")
  let req_body = {"chat_id": $chat_id, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to set the score of the specified user in a game. On success, if the message was sent by the bot, returns the edited [Message](https://core.telegram.org/bots/api/#message), otherwise returns *True*. Returns an error, if the new score is not greater than the user's current score in the chat and *force* is *False*.
#
# POST /setGameScore
# Docs: https://core.telegram.org/bots/api/#setgamescore
export def "set-game-score create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: int # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat
  --disable-edit-message: oneof<nothing, bool> # Pass True, if the game message should not be automatically edited to include the current scoreboard
  --force: oneof<nothing, bool> # Pass True, if the high score is allowed to decrease. This can be useful when fixing mistakes or banning cheaters
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the sent message
  score: int # New score, must be non-negative
  user_id: int # User identifier
]: any -> record<ok: bool, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setGameScore")
  let req_body = {"chat_id": $chat_id, "disable_edit_message": $disable_edit_message, "force": $force, "inline_message_id": $inline_message_id, "message_id": $message_id, "score": $score, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to change the list of the bot's commands. Returns *True* on success.
#
# POST /setMyCommands
# Docs: https://core.telegram.org/bots/api/#setmycommands
# --commands item shape: {command: string, description: string}
export def "set-my-commands create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  commands: list # A JSON-serialized list of bot commands to be set as the list of the bot's commands. At most 100 commands can be specified. — item shape: {command: string, description: string}
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setMyCommands")
  let req_body = {"commands": $commands} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Informs a user that some of the Telegram Passport elements they provided contains errors. The user will not be able to re-submit their Passport to you until the errors are fixed (the contents of the field for which you returned the error must change). Returns *True* on success. Use this if the data submitted by the user doesn't satisfy the standards your service requires for any reason. For example, if a birthday date seems invalid, a submitted document is blurry, a scan shows evidence of tampering, etc. Supply some details in the error message to make sure the user knows how to correct the issues.
#
# POST /setPassportDataErrors
# Docs: https://core.telegram.org/bots/api/#setpassportdataerrors
export def "set-passport-data-errors create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  errors: list # A JSON-serialized array describing the errors
  user_id: int # User identifier
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setPassportDataErrors")
  let req_body = {"errors": $errors, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to move a sticker in a set created by the bot to a specific position. Returns *True* on success.
#
# POST /setStickerPositionInSet
# Docs: https://core.telegram.org/bots/api/#setstickerpositioninset
export def "set-sticker-position-in-set create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  position: int # New sticker position in the set, zero-based
  sticker: string # File identifier of the sticker
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setStickerPositionInSet")
  let req_body = {"position": $position, "sticker": $sticker} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to set the thumbnail of a sticker set. Animated thumbnails can be set for animated sticker sets only. Returns *True* on success.
#
# POST /setStickerSetThumb
# Docs: https://core.telegram.org/bots/api/#setstickersetthumb
export def "set-sticker-set-thumb create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Sticker set name
  --thumb: any # A **PNG** image with the thumbnail, must be up to 128 kilobytes in size and have width and height exactly 100px, or a **TGS** animation with the thumbnail up to 32 kilobytes in size; see [](https://core.telegram.org/animated_stickers#technical-requirements)[https://core.telegram.org/animated\_stickers#technical-requirements](https://core.telegram.org/animated_stickers#technical-requirements) for animated sticker technical requirements. Pass a *file\_id* as a String to send a file that already exists on the Telegram servers, pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. [More info on Sending Files »](https://core.telegram.org/bots/api/#sending-files). Animated sticker set thumbnail can't be uploaded via HTTP URL.
  user_id: int # User identifier of the sticker set owner
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setStickerSetThumb")
  let req_body = {"name": $name, "thumb": $thumb, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to specify a url and receive incoming updates via an outgoing webhook. Whenever there is an update for the bot, we will send an HTTPS POST request to the specified url, containing a JSON-serialized [Update](https://core.telegram.org/bots/api/#update). In case of an unsuccessful request, we will give up after a reasonable amount of attempts. Returns *True* on success. If you'd like to make sure that the Webhook request comes from Telegram, we recommend using a secret path in the URL, e.g. `https://www.example.com/`. Since nobody else knows your bot's token, you can be pretty sure it's us.
#
# POST /setWebhook
# Docs: https://core.telegram.org/bots/api/#setwebhook
export def "set-webhook create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowed-updates: list<string> # A JSON-serialized list of the update types you want your bot to receive. For example, specify [“message”, “edited\_channel\_post”, “callback\_query”] to only receive updates of these types. See [Update](https://core.telegram.org/bots/api/#update) for a complete list of available update types. Specify an empty list to receive all updates regardless of type (default). If not specified, the previous setting will be used. Please note that this parameter doesn't affect updates created before the call to the setWebhook, so unwanted updates may be received for a short period of time.
  --certificate: any # This object represents the contents of a file to be uploaded. Must be posted using multipart/form-data in the usual way that files are uploaded via the browser.
  --drop-pending-updates: oneof<nothing, bool> # Pass *True* to drop all pending updates
  --ip-address: string # The fixed IP address which will be used to send webhook requests instead of the IP address resolved through DNS
  --max-connections: int # Maximum allowed number of simultaneous HTTPS connections to the webhook for update delivery, 1-100. Defaults to *40*. Use lower values to limit the load on your bot's server, and higher values to increase your bot's throughput. (default: 40)
  url: string # HTTPS url to send updates to. Use an empty string to remove webhook integration
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setWebhook")
  let req_body = {"allowed_updates": $allowed_updates, "certificate": $certificate, "drop_pending_updates": $drop_pending_updates, "ip_address": $ip_address, "max_connections": $max_connections, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Use this method to stop updating a live location message before *live\_period* expires. On success, if the message was sent by the bot, the sent [Message](https://core.telegram.org/bots/api/#message) is returned, otherwise *True* is returned.
#
# POST /stopMessageLiveLocation
# Docs: https://core.telegram.org/bots/api/#stopmessagelivelocation
# --reply_markup shape: {inline_keyboard: list}
export def "stop-message-live-location create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --chat-id: any # Required if *inline\_message\_id* is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --inline-message-id: string # Required if *chat\_id* and *message\_id* are not specified. Identifier of the inline message
  --message-id: int # Required if *inline\_message\_id* is not specified. Identifier of the message with live location to stop
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
]: any -> record<ok: bool, result: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stopMessageLiveLocation")
  let req_body = {"chat_id": $chat_id, "inline_message_id": $inline_message_id, "message_id": $message_id, "reply_markup": $reply_markup} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to stop a poll which was sent by the bot. On success, the stopped [Poll](https://core.telegram.org/bots/api/#poll) with the final results is returned.
#
# POST /stopPoll
# Docs: https://core.telegram.org/bots/api/#stoppoll
# --reply_markup shape: {inline_keyboard: list}
export def "stop-poll create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  message_id: int # Identifier of the original message with the poll
  --reply-markup: record # This object represents an [inline keyboard](https://core.telegram.org/bots#inline-keyboards-and-on-the-fly-updating) that appears right next to the message it belongs to. — shape: {inline_keyboard: list}
]: any -> record<ok: bool, result: record<allows_multiple_answers: bool, close_date: int, correct_option_id: int, explanation: string, explanation_entities: list<record>, id: string, is_anonymous: bool, is_closed: bool, open_period: int, options: list<record>, question: string, total_voter_count: int, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stopPoll")
  let req_body = {"chat_id": $chat_id, "message_id": $message_id, "reply_markup": $reply_markup} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to unban a previously kicked user in a supergroup or channel. The user will **not** return to the group or channel automatically, but will be able to join via link, etc. The bot must be an administrator for this to work. By default, this method guarantees that after the call the user is not a member of the chat, but will be able to join it. So if the user is a member of the chat they will also be **removed** from the chat. If you don't want this, use the parameter *only\_if\_banned*. Returns *True* on success.
#
# POST /unbanChatMember
# Docs: https://core.telegram.org/bots/api/#unbanchatmember
export def "unban-chat-member create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target group or username of the target supergroup or channel (in the format `@username`)
  --only-if-banned: oneof<nothing, bool> # Do nothing if the user is not banned
  user_id: int # Unique identifier of the target user
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unbanChatMember")
  let req_body = {"chat_id": $chat_id, "only_if_banned": $only_if_banned, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to clear the list of pinned messages in a chat. If the chat is not a private chat, the bot must be an administrator in the chat for this to work and must have the 'can\_pin\_messages' admin right in a supergroup or 'can\_edit\_messages' admin right in a channel. Returns *True* on success.
#
# POST /unpinAllChatMessages
# Docs: https://core.telegram.org/bots/api/#unpinallchatmessages
export def "unpin-all-chat-messages create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unpinAllChatMessages")
  let req_body = {"chat_id": $chat_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to remove a message from the list of pinned messages in a chat. If the chat is not a private chat, the bot must be an administrator in the chat for this to work and must have the 'can\_pin\_messages' admin right in a supergroup or 'can\_edit\_messages' admin right in a channel. Returns *True* on success.
#
# POST /unpinChatMessage
# Docs: https://core.telegram.org/bots/api/#unpinchatmessage
export def "unpin-chat-message create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  chat_id: any # Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
  --message-id: int # Identifier of a message to unpin. If not specified, the most recent pinned message (by sending date) will be unpinned.
]: any -> record<ok: bool, result: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unpinChatMessage")
  let req_body = {"chat_id": $chat_id, "message_id": $message_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Use this method to upload a .PNG file with a sticker for later use in *createNewStickerSet* and *addStickerToSet* methods (can be used multiple times). Returns the uploaded [File](https://core.telegram.org/bots/api/#file) on success.
#
# POST /uploadStickerFile
# Docs: https://core.telegram.org/bots/api/#uploadstickerfile
export def "upload-sticker-file create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  png_sticker: any # This object represents the contents of a file to be uploaded. Must be posted using multipart/form-data in the usual way that files are uploaded via the browser.
  user_id: int # User identifier of sticker file owner
]: any -> record<ok: bool, result: record<file_id: string, file_path: string, file_size: int, file_unique_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploadStickerFile")
  let req_body = {"png_sticker": $png_sticker, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}
