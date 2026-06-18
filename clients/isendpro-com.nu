# Auto-generated client for API iSendPro v1.1.1
# Source: https://api.apis.guru/v2/specs/isendpro.com/1.1.1/openapi.json
# Auth: --token flag or $env.API_ISENDPRO_TOKEN

const BASE_URL = "https://apirest.isendpro.com/cgi-bin"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_ISENDPRO_TOKEN | default "" }
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

def base-url-completer [] { ["https://apirest.isendpro.com/cgi-bin" "http://apirest.isendpro.com/cgi-bin"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def rapport-campagne-completer [] { ["1"] }
def accept-completer [] { ["application/json" "file"] }
def comptage-completer [] { ["1"] }
def gmt-zone-completer [] { ["Africa/Abidjan" "Africa/Addis_Ababa" "Africa/Algiers" "Africa/Blantyre" "Africa/Cairo" "Africa/Windhoek" "America/Adak" "America/Anchorage" "America/Araguaina" "America/Argentina/Buenos_Aires" "America/Belize" "America/Bogota" "America/Campo_Grande" "America/Cancun" "America/Caracas" "America/Chicago" "America/Chihuahua" "America/Dawson_Creek" "America/Denver" "America/Ensenada" "America/Glace_Bay" "America/Godthab" "America/Goose_Bay" "America/Havana" "America/La_Paz" "America/Los_Angeles" "America/Miquelon" "America/Montevideo" "America/New_York" "America/Noronha" "America/Santiago" "America/Sao_Paulo" "America/St_Johns" "Asia/Anadyr" "Asia/Bangkok" "Asia/Beirut" "Asia/Damascus" "Asia/Dhaka" "Asia/Dubai" "Asia/Gaza" "Asia/Hong_Kong" "Asia/Irkutsk" "Asia/Jerusalem" "Asia/Kabul" "Asia/Katmandu" "Asia/Kolkata" "Asia/Krasnoyarsk" "Asia/Magadan" "Asia/Novosibirsk" "Asia/Rangoon" "Asia/Seoul" "Asia/Tashkent" "Asia/Tehran" "Asia/Tokyo" "Asia/Vladivostok" "Asia/Yakutsk" "Asia/Yekaterinburg" "Asia/Yerevan" "Atlantic/Azores" "Atlantic/Cape_Verde" "Atlantic/Stanley" "Australia/Adelaide" "Australia/Brisbane" "Australia/Darwin" "Australia/Eucla" "Australia/Hobart" "Australia/Lord_Howe" "Australia/Perth" "Chile/EasterIsland" "Etc/GMT+10" "Etc/GMT+8" "Etc/GMT-11" "Etc/GMT-12" "Europe/Amsterdam" "Europe/Belfast" "Europe/Belgrade" "Europe/Brussels" "Europe/Dublin" "Europe/Lisbon" "Europe/London" "Europe/Minsk" "Europe/Moscow" "Pacific/Auckland" "Pacific/Chatham" "Pacific/Gambier" "Pacific/Kiritimati" "Pacific/Marquesas" "Pacific/Midway" "Pacific/Norfolk" "Pacific/Tongatapu"] }
def num-azur-completer [] { ["1"] }
def smslong-completer [] { ["999"] }
def accept-completer-1 [] { ["application/json" "etat"] }
def credit-completer [] { ["1" "2"] }
def del-liste-noire-completer [] { ["1"] }
def get-liste-noire-completer [] { ["1"] }
def get-hlr-completer [] { ["1"] }
def repertoire-edit-completer [] { ["create"] }
def repertoire-edit-completer-1 [] { ["add" "del"] }
def setliste-noire-completer [] { ["1"] }
def accept-completer-2 [] { ["application/json" "exemple1"] }
def sub-account-edit-completer [] { ["addAccount"] }
def sub-account-edit-completer-1 [] { ["addCredit" "setPrice" "setRestriction"] }
def sub-account-restriction-stop-completer [] { ["0" "1"] }
def sub-account-restriction-time-completer [] { ["0" "1"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "campagne get" } } | get name | first)
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

# Retourne les SMS envoyés sur une période donnée
#
# GET /campagne
# operationId: getCampagne
export def "campagne get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --keyid: string # Clé API
  --rapport-campagne: string@rapport-campagne-completer # Doit valoir "1"
  --date-deb: string # date de debut au format YYYY-MM-DD hh:mm
  --date-fin: string # date de fin au format YYYY-MM-DD hh:mm
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyid" $keyid "scalar") (serialize-qp "rapportCampagne" $rapport_campagne "scalar") (serialize-qp "date_deb" $date_deb "scalar") (serialize-qp "date_fin" $date_fin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campagne" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compter le nombre de caractère
#
# POST /comptage
# operationId: comptage
export def "comptage create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  comptage: string@comptage-completer # default: 1
  --date-envoi: string # Date d'envoi au format YYYY-MM-DD hh:mm . Ce paramètre est optionnel, si il est omis l'envoi est réalisé immédiatement.
  --emetteur: string # - L'emetteur doit être une chaîne alphanumérique comprise entre 4 et 11 caractères. - Les caractères acceptés sont les chiffres entre 0 et 9, les lettres entre A et Z et l’espace. - Il ne peut pas comporter uniquement des chiffres. - Pour la modification de l'émetteur et dans le cadre de campagnes commerciales, les opérateurs imposent contractuellement d'ajouter en fin de message le texte "STOP XXXXX". De ce fait, le message envoyé ne pourra excéder une longueur de 148 caractères au lieu des 160 caractères, le « STOP » étant rajouté automatiquement.
  --gmt-zone: string@gmt-zone-completer # Fuseau horaire de la date d'envoi
  keyid: string # Clé API
  --nostop: string # Si le message n’est pas à but commercial, vous pouvez faire une demande pour retirer l’obligation du STOP. Une fois votre demande validée par nos services, vous pourrez supprimer la mention STOP SMS en ajoutant nostop = "1"
  num: string # Numero de téléphone au format national (exemple 0680010203) ou international (example 33680010203)
  --num-azur: string@num-azur-completer
  sms: string # Message à envoyer aux destinataires. Le message doit être encodé au format utf-8 et ne contenir que des caractères existant dans l'alphabet GSM. Il est également possible d'envoyer (à l'étranger uniquement) des SMS en UCS-2, cf paramètre ucs2 pour plus de détails.
  --smslong: string@smslong-completer # Le SMS long permet de dépasser la limite de 160 caractères en envoyant un message constitué de plusieurs SMS. Il est possible d’envoyer jusqu’à 6 SMS concaténés pour une longueur totale maximale de 918 caractères par message. Pour des raisons technique, la limite par SMS concaténé étant de 153 caractères. En cas de modification de l’émetteur, il faut considérer l’ajout automatique de 12 caractères du « STOP SMS ». Pour envoyer un smslong, il faut ajouter le paramètre smslong aux appels. La valeur de SMS doit être le nombre maximum de sms concaténé autorisé. Pour ne pas avoir ce message d’erreur et obtenir un calcul dynamique du nombre de SMS alors il faut renseigner smslong = "999" (default: 999)
  --tracker: string # Le tracker doit être une chaine alphanumérique de moins de 50 caractères. Ce tracker sera ensuite renvoyé en paramètre des urls pour les retours des accusés de réception.
  --ucs2: string # Il est également possible d’envoyer des SMS en alphabet non latin (russe, chinois, arabe, etc) sur les numéros hors France métropolitaine. Pour ce faire, la requête devrait être encodée au format UTF-8 et contenir l’argument ucs2 = "1" Du fait de contraintes techniques, 1 SMS unique ne pourra pas dépasser 70 caractères (au lieu des 160 usuels) et dans le cas de SMS long, chaque sms ne pourra dépasser 67 caractères.
]: any -> record<etat: record<etat: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comptage")
  let req_body = {"comptage": $comptage, "date_envoi": $date_envoi, "emetteur": $emetteur, "gmt_zone": $gmt_zone, "keyid": $keyid, "nostop": $nostop, "num": $num, "numAzur": $num_azur, "sms": $sms, "smslong": $smslong, "tracker": $tracker, "ucs2": $ucs2} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Interrogation credit
#
# GET /credit
# operationId: getCredit
export def "credit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyid: string # Clé API (format: string)
  --credit: string@credit-completer # Type de reponse demandée, 1 pour euro, 2 pour euro + estimation quantité
]: nothing -> record<etat: record<credit: float, quantite: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyid" $keyid "scalar") (serialize-qp "credit" $credit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/credit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ajoute un numero en liste noire
#
# POST /dellistenoire
# operationId: delListeNoire
export def "dellistenoire delete-liste-noire" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyid: string # Clé API (format: string)
  --del-liste-noire: string@del-liste-noire-completer # Doit valoir "1"
  --num: string # numéro de mobile à supprimer (format: string)
]: nothing -> record<etat: record<etat: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyid" $keyid "scalar") (serialize-qp "delListeNoire" $del_liste_noire "scalar") (serialize-qp "num" $num "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dellistenoire" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retourne le liste noire
#
# POST /getlistenoire
# operationId: getListeNoire
export def "getlistenoire get-liste-noire" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyid: string # Clé API (format: string)
  --get-liste-noire: string@get-liste-noire-completer # Doit valoir "1"
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyid" $keyid "scalar") (serialize-qp "getListeNoire" $get_liste_noire "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/getlistenoire" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Vérifier la validité d'un numéro
#
# POST /hlr
# operationId: getHlr
export def "hlr get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  get_hlr: string@get-hlr-completer # Doit valoir "1" (default: 1)
  keyid: string # Clé API
  num: list<string> # liste de numéros de téléphone
]: any -> record<etat: record<etat: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hlr")
  let req_body = {"getHLR": $get_hlr, "keyid": $keyid, "num": $num} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gestion repertoire (creation)
#
# POST /repertoire
# operationId: repertoireCrea
export def "repertoire create-crea" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  keyid: string # Clé API
  repertoire_edit: string@repertoire-edit-completer # Action à réaliser doit valoir "create" ici. (default: create)
  repertoire_nom: string # Nom du répertoire (libellé) à créer
]: any -> record<etat: record<etat: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/repertoire")
  let req_body = {"keyid": $keyid, "repertoireEdit": $repertoire_edit, "repertoireNom": $repertoire_nom} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gestion repertoire (modification)
#
# PUT /repertoire
# operationId: repertoire
export def "repertoire update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --champ1: list<string> # Noms des contact
  --champ10: list<string> # Champs I des contacts
  --champ11: list<string> # Champs J des contacts
  --champ12: list<string> # Champs K des contacts
  --champ13: list<string> # Champs L des contacts
  --champ14: list<string> # Champs M des contacts
  --champ15: list<string> # Champs N des contacts
  --champ16: list<string> # Champs O des contacts
  --champ17: list<string> # Champs P des contacts
  --champ18: list<string> # Champs Q des contacts
  --champ19: list<string> # Champs R des contacts
  --champ2: list<string> # Champs A des contacts
  --champ20: list<string> # Champs S des contacts
  --champ21: list<string> # Champs T des contacts
  --champ22: list<string> # Champs U des contacts
  --champ23: list<string> # Champs V des contacts
  --champ24: list<string> # Champs W des contacts
  --champ25: list<string> # Champs X des contacts
  --champ26: list<string> # Champs Y des contacts
  --champ27: list<string> # Champs Z des contacts
  --champ3: list<string> # Champs B des contacts
  --champ4: list<string> # Champs C des contacts
  --champ5: list<string> # Champs D des contacts
  --champ6: list<string> # Champs E des contacts
  --champ7: list<string> # Champs F des contacts
  --champ8: list<string> # Champs G des contacts
  --champ9: list<string> # Champs H des contacts
  keyid: string # Clé API
  num: list<string> # liste des numéros des téléphone à ajouter ou supprimer
  repertoire_edit: string@repertoire-edit-completer-1 # action à réaliser, "add" pour l'ajout de numéros, "del" pour la suppression de numéros
  repertoire_id: string # repertoireId du répertoire cible
]: any -> record<etat: record<etat: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/repertoire")
  let req_body = {"champ1": $champ1, "champ10": $champ10, "champ11": $champ11, "champ12": $champ12, "champ13": $champ13, "champ14": $champ14, "champ15": $champ15, "champ16": $champ16, "champ17": $champ17, "champ18": $champ18, "champ19": $champ19, "champ2": $champ2, "champ20": $champ20, "champ21": $champ21, "champ22": $champ22, "champ23": $champ23, "champ24": $champ24, "champ25": $champ25, "champ26": $champ26, "champ27": $champ27, "champ3": $champ3, "champ4": $champ4, "champ5": $champ5, "champ6": $champ6, "champ7": $champ7, "champ8": $champ8, "champ9": $champ9, "keyid": $keyid, "num": $num, "repertoireEdit": $repertoire_edit, "repertoireId": $repertoire_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Ajoute un numero en liste noire
#
# POST /setlistenoire
# operationId: setListeNoire
export def "setlistenoire update-liste-noire" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyid: string # Clé API (format: string)
  --setliste-noire: string@setliste-noire-completer # Doit valoir "1"
  --num: string # numéro de mobile à insérer en liste noire (format: string)
]: nothing -> record<etat: record<etat: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyid" $keyid "scalar") (serialize-qp "setlisteNoire" $setliste_noire "scalar") (serialize-qp "num" $num "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setlistenoire" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# add a shortlink
#
# POST /shortlink
# operationId: addShortlink
export def "shortlink create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  keyid: string
  shortlink: string
]: any -> record<etat: record<etat: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shortlink")
  let req_body = {"keyid": $keyid, "shortlink": $shortlink} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Envoyer un sms
#
# POST /sms
# operationId: sendSms
export def "sms send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --date-envoi: string # Date d'envoi au format YYYY-MM-DD hh:mm . Ce paramètre est optionnel, si il est omis l'envoi est réalisé immédiatement.
  --emetteur: string # - L'emetteur doit être une chaîne alphanumérique comprise entre 4 et 11 caractères. - Les caractères acceptés sont les chiffres entre 0 et 9, les lettres entre A et Z et l’espace. - Il ne peut pas comporter uniquement des chiffres. - Pour la modification de l'émetteur et dans le cadre de campagnes commerciales, les opérateurs imposent contractuellement d'ajouter en fin de message le texte "STOP XXXXX". De ce fait, le message envoyé ne pourra excéder une longueur de 148 caractères au lieu des 160 caractères, le « STOP » étant rajouté automatiquement.
  --gmt-zone: string@gmt-zone-completer # Fuseau horaire de la date d'envoi
  keyid: string # Clé API
  --nostop: string # Si le message n’est pas à but commercial, vous pouvez faire une demande pour retirer l’obligation du STOP. Une fois votre demande validée par nos services, vous pourrez supprimer la mention STOP SMS en ajoutant nostop = "1"
  num: string # Numero de téléphone au format national (exemple 0680010203) ou international (example 33680010203)
  --num-azur: string@num-azur-completer
  sms: string # Message à envoyer aux destinataires. Le message doit être encodé au format utf-8 et ne contenir que des caractères existant dans l'alphabet GSM. Il est également possible d'envoyer (à l'étranger uniquement) des SMS en UCS-2, cf paramètre ucs2 pour plus de détails.
  --smslong: string # Le SMS long permet de dépasser la limite de 160 caractères en envoyant un message constitué de plusieurs SMS. Il est possible d’envoyer jusqu’à 6 SMS concaténés pour une longueur totale maximale de 918 caractères par message. Pour des raisons technique, la limite par SMS concaténé étant de 153 caractères. En cas de modification de l’émetteur, il faut considérer l’ajout automatique de 12 caractères du « STOP SMS ». Pour envoyer un smslong, il faut ajouter le paramètre smslong aux appels. La valeur de SMS doit être le nombre maximum de sms concaténé autorisé. Pour ne pas avoir ce message d’erreur et obtenir un calcul dynamique du nombre de SMS alors il faut renseigner smslong = "999"
  --tracker: string # Le tracker doit être une chaine alphanumérique de moins de 50 caractères. Ce tracker sera ensuite renvoyé en paramètre des urls pour les retours des accusés de réception.
  --ucs2: string # Il est également possible d’envoyer des SMS en alphabet non latin (russe, chinois, arabe, etc) sur les numéros hors France métropolitaine. Pour ce faire, la requête devrait être encodée au format UTF-8 et contenir l’argument ucs2 = "1" Du fait de contraintes techniques, 1 SMS unique ne pourra pas dépasser 70 caractères (au lieu des 160 usuels) et dans le cas de SMS long, chaque sms ne pourra dépasser 67 caractères.
]: any -> record<etat: record<etat: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sms")
  let req_body = {"date_envoi": $date_envoi, "emetteur": $emetteur, "gmt_zone": $gmt_zone, "keyid": $keyid, "nostop": $nostop, "num": $num, "numAzur": $num_azur, "sms": $sms, "smslong": $smslong, "tracker": $tracker, "ucs2": $ucs2} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Envoyer des SMS
#
# POST /smsmulti
# operationId: sendSmsMulti
export def "smsmulti send-sms-multi" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --date-envoi: string # Paramètre optionnel, date d'envoi au format YYYY-MM-DD hh:mm
  --emetteur: string # L'emetteur doit être une chaîne alphanumérique comprise entre 4 et 11 caractères. Les caractères acceptés sont les chiffres entre 0 et 9, les lettres entre A et Z et l’espace. Il ne peut pas comporter uniquement des chiffres. Pour la modification de l’émetteur et dans le cadre de campagnes commerciales, les opérateurs imposent contractuellement d’ajouter en fin de message le texte suivant : STOP XXXXX De ce fait, le message envoyé ne pourra excéder une longueur de 148 caractères au lieu des 160 caractères, le « STOP » étant rajouté automatiquement.
  --gmt-zone: string@gmt-zone-completer # Fuseau horaire de la date d'envoi
  keyid: string # Clé API
  --nostop: string # Si le message n’est pas à but commercial, vous pouvez faire une demande pour retirer l’obligation du STOP. Une fois votre demande validée par nos services, vous pourrez supprimer la mention STOP SMS en ajoutant nostop = "1"
  num: list<string>
  --num-azur: string@num-azur-completer
  --repertoire-id: string # Id du repertoire
  sms: list<string>
  --smslong: string # Le SMS long permet de dépasser la limite de 160 caractères en envoyant un message constitué de plusieurs SMS. Il est possible d’envoyer jusqu’à 6 SMS concaténés pour une longueur totale maximale de 918 caractères par message. Pour des raisons technique, la limite par SMS concaténé étant de 153 caractères. En cas de modification de l’émetteur, il faut considérer l’ajout automatique de 12 caractères du « STOP SMS ». Pour envoyer un smslong, il faut ajouter le paramètre smslong aux appels. La valeur de SMS doit être le nombre maximum de sms concaténé autorisé. Pour ne pas avoir ce message d’erreur et obtenir un calcul dynamique du nombre de SMS alors il faut renseigner smslong = "999"
  --tracker: list<string>
  --ucs2: string # Il est également possible d’envoyer des SMS en alphabet non latin (russe, chinois, arabe, etc) sur les numéros hors France métropolitaine. Pour ce faire, la requête devrait être encodée au format UTF-8 et contenir l’argument ucs2 = "1" Du fait de contraintes techniques, 1 SMS unique ne pourra pas dépasser 70 caractères (au lieu des 160 usuels) et dans le cas de SMS long, chaque sms ne pourra dépasser 67 caractères.
]: any -> record<etat: record<etat: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/smsmulti")
  let req_body = {"date_envoi": $date_envoi, "emetteur": $emetteur, "gmt_zone": $gmt_zone, "keyid": $keyid, "nostop": $nostop, "num": $num, "numAzur": $num_azur, "repertoireId": $repertoire_id, "sms": $sms, "smslong": $smslong, "tracker": $tracker, "ucs2": $ucs2} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Ajoute un sous compte
#
# POST /subaccount
# operationId: subaccountAdd
export def "subaccount create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  keyid: string
  sub_account_edit: string@sub-account-edit-completer
  sub_account_login: string
  sub_account_password: string
]: any -> record<etat: record<etat: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subaccount")
  let req_body = {"keyid": $keyid, "subAccountEdit": $sub_account_edit, "subAccountLogin": $sub_account_login, "subAccountPassword": $sub_account_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Edit a subaccount
#
# PUT /subaccount
# operationId: subaccountEdit
export def "subaccount update-edit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  keyid: string # Clé API
  --sub-account-add-credit: string # montant du crédit à ajouter
  --sub-account-country-code: string
  sub_account_edit: string@sub-account-edit-completer-1 # action à réaliser soit setPrice pour définir un prix ou addCredit pour ajouter du credit ou setRestriction modifier la restriction stop /
  --sub-account-key-id: string # keyid du sous-compte
  --sub-account-price: string
  --sub-account-restriction-stop: string@sub-account-restriction-stop-completer
  --sub-account-restriction-time: string@sub-account-restriction-time-completer
]: any -> record<etat: record<etat: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/subaccount")
  let req_body = {"keyid": $keyid, "subAccountAddCredit": $sub_account_add_credit, "subAccountCountryCode": $sub_account_country_code, "subAccountEdit": $sub_account_edit, "subAccountKeyId": $sub_account_key_id, "subAccountPrice": $sub_account_price, "subAccountRestrictionStop": $sub_account_restriction_stop, "subAccountRestrictionTime": $sub_account_restriction_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
