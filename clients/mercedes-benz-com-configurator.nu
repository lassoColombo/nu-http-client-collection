# Auto-generated client for Car Configurator v1.0
# Source: https://api.apis.guru/v2/specs/mercedes-benz.com/configurator/1.0/swagger.json
# Auth: --token flag or $env.CAR_CONFIGURATOR_TOKEN

const BASE_URL = "https://api.mercedes-benz.com/configurator_tryout/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CAR_CONFIGURATOR_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.mercedes-benz.com/configurator_tryout/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "markets marketsGET" } } | get name | first)
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

# Get all available markets.
#
# GET /markets
# operationId: marketsGET
export def "markets marketsGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # This is a ISO language string e.g. 'de' and is spoken in Austria 'AT', Germany 'DE' and Swiss 'CH'. (default: de)
  --country: string # This is a ISO country string e.g. Germany 'DE' or Swiss 'CH'.
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> table<_links: record<bodies: record, classes: record, models: record, productgroups: record, self: record>, country: string, language: string, marketId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/markets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the market with the given marketId.
#
# GET /markets/{marketId}
# operationId: marketGET
export def "markets marketGET" [
  marketId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<bodies: record<href: string>, classes: record<href: string>, models: record<href: string>, productgroups: record<href: string>, self: record<href: string>>, country: string, language: string, marketId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all available bodies for the given marketId.
#
# GET /markets/{marketId}/bodies
# operationId: bodiesGET
export def "markets-bodies bodiesGET" [
  marketId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --classId: string # This is a class id e.g. '176' for 'A-Class' in Germany. (default: 222)
  --bodyId: string # This is a body id e.g. '1' for 'Limousine' in Germany. (default: 2)
  --productGroups: list # Specifies to which product groups the vehicles belong which should be returned. The product groups are separated from each other by a comma and are case sensitive. Allowed values are:   * PKW   * VAN   * SMART
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> table<_links: record<models: record, self: record>, bodyId: string, bodyName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "classId" $classId "scalar") (serialize-qp "bodyId" $bodyId "scalar") (serialize-qp "productGroups" $productGroups "csv") (serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/bodies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the body for the given marketId and bodyId.
#
# GET /markets/{marketId}/bodies/{bodyId}
# operationId: bodyGET
export def "markets-bodies bodyGET" [
  marketId: string
  bodyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<models: record<href: string>, self: record<href: string>>, bodyId: string, bodyName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/bodies/($bodyId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all available classes for the given marketId.
#
# GET /markets/{marketId}/classes
# operationId: classesGET
export def "markets-classes classesGET" [
  marketId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --classId: string # This is a class id e.g. '176' for 'A-Class' in Germany. (default: 222)
  --bodyId: string # This is a body id e.g. '1' for 'Limousine' in Germany. (default: 2)
  --productGroups: list # Specifies to which product groups the vehicles belong which should be returned. The product groups are separated from each other by a comma and are case sensitive. Allowed values are:   * PKW   * VAN   * SMART
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> table<_links: record<models: record, self: record>, classId: string, className: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "classId" $classId "scalar") (serialize-qp "bodyId" $bodyId "scalar") (serialize-qp "productGroups" $productGroups "csv") (serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/classes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the class for the given marketId and classId.
#
# GET /markets/{marketId}/classes/{classId}
# operationId: classGET
export def "markets-classes classGET" [
  marketId: string
  classId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<models: record<href: string>, self: record<href: string>>, classId: string, className: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/classes/($classId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all available models for the given marketId.
#
# GET /markets/{marketId}/models
# operationId: modelsGET
export def "markets-models modelsGET" [
  marketId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --classId: string # This is a class id e.g. '176' for 'A-Class' in Germany. (default: 222)
  --bodyId: string # This is a body id e.g. '1' for 'Limousine' in Germany. (default: 2)
  --baumuster4prefix: string # The first four digits of a baumuster are called baumuster4prefix e.g. '1760' for 'Berline' in France.
  --baumuster: string # This is a baumuster e.g. '176042' for 'A 180 Limousine' in Germany.
  --nationalSalesType: string # This is the national sales type (NST) of a distinct baumuster. There is no predefined pattern for the NST, each market defines its NST. e.g. 'E07' in France, 0001 in Germany and ZA1 in South Africa Using the NST markets can define market specific conditions. e.g. different initial configuration, etc.
  --productGroups: list # Specifies to which product groups the vehicles belong which should be returned. The product groups are separated from each other by a comma and are case sensitive. Allowed values are:   * PKW   * VAN   * SMART
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> table<_links: record<configuration: record, self: record>, baumuster: string, modelId: string, name: string, nationalSalesType: string, priceInformation: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list>, productGroup: record<name: string>, shortName: string, vehicleBody: record<_links: record, bodyId: string, bodyName: string>, vehicleClass: record<_links: record, classId: string, className: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "classId" $classId "scalar") (serialize-qp "bodyId" $bodyId "scalar") (serialize-qp "baumuster4prefix" $baumuster4prefix "scalar") (serialize-qp "baumuster" $baumuster "scalar") (serialize-qp "nationalSalesType" $nationalSalesType "scalar") (serialize-qp "productGroups" $productGroups "csv") (serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the model for the given marketId and modelId.
#
# GET /markets/{marketId}/models/{modelId}
# operationId: modelGET
export def "markets-models modelGET" [
  marketId: string
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<configuration: record<href: string>, self: record<href: string>>, baumuster: string, modelId: string, name: string, nationalSalesType: string, priceInformation: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, productGroup: record<name: string>, shortName: string, vehicleBody: record<_links: record<models: record, self: record>, bodyId: string, bodyName: string>, vehicleClass: record<_links: record<models: record, self: record>, classId: string, className: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the initial configuration for the given marketId and modelId.
#
# GET /markets/{marketId}/models/{modelId}/configurations/initial
# operationId: modelConfigurationsGET
export def "markets-models-configurations-initial modelConfigurationsGET" [
  marketId: string
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<imageapi_vehicle: record<href: string>, selectables: record<href: string>, self: record<href: string>>, changeYear: string, configurationId: string, configurationPrice: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, initialPrice: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, marketId: string, modelId: string, modelYear: string, technicalInformation: record<acceleration: record<unit: string, value: float>, doors: float, energyEfficiencyClass: string, engine: record<alternativeFuelType: string, capacity: record, cylinder: string, driveConcept: string, emissionStandard: string, engineConcept: string, fuelEconomy: record, fuelType: string, powerHp: record, powerHybridExtensionHp: record, powerHybridExtensionKw: record, powerKw: record>, nedc: record<consumption: record, electricRange: record, emission: record, weight: record>, seats: float, topSpeed: record<unit: string, value: float>, transmission: record<code: string, codeType: string, name: string>, wltp: record<consumption: record, emission: record>>, vehicleComponents: table<_links: record, code: string, codeType: string, componentSortId: float, componentType: string, description: string, fixed: bool, hidden: bool, id: string, name: string, priceInformation: record, pseudoCode: bool, selected: bool, standard: bool>, wltpConfiguration: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/initial" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the configuration for the given marketId, modelId and configurationId.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}
# operationId: modelConfigurationGET
export def "markets-models-configurations modelConfigurationGET" [
  marketId: string
  modelId: string
  configurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<imageapi_vehicle: record<href: string>, selectables: record<href: string>, self: record<href: string>>, changeYear: string, configurationId: string, configurationPrice: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, initialPrice: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, marketId: string, modelId: string, modelYear: string, technicalInformation: record<acceleration: record<unit: string, value: float>, doors: float, energyEfficiencyClass: string, engine: record<alternativeFuelType: string, capacity: record, cylinder: string, driveConcept: string, emissionStandard: string, engineConcept: string, fuelEconomy: record, fuelType: string, powerHp: record, powerHybridExtensionHp: record, powerHybridExtensionKw: record, powerKw: record>, nedc: record<consumption: record, electricRange: record, emission: record, weight: record>, seats: float, topSpeed: record<unit: string, value: float>, transmission: record<code: string, codeType: string, name: string>, wltp: record<consumption: record, emission: record>>, vehicleComponents: table<_links: record, code: string, codeType: string, componentSortId: float, componentType: string, description: string, fixed: bool, hidden: bool, id: string, name: string, priceInformation: record, pseudoCode: bool, selected: bool, standard: bool>, wltpConfiguration: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/($configurationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the alternatives for the given marketId, modelId, configurationId and componentList.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/alternatives/{componentList}
# operationId: modelConfigurationAlternativesGET
export def "markets-models-configurations-alternatives modelConfigurationAlternativesGET" [
  marketId: string
  modelId: string
  configurationId: string
  componentList: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> table<_links: record<imageapi_vehicle: record, selectables: record, self: record>, addedComponents: list<record>, configurationId: string, marketId: string, modelId: string, priceInformation: record, removedComponents: list<record>, updatedComponents: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/($configurationId)/alternatives/($componentList)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns URLs pointing to images in JPG format in the highest available resolution (depending on the component) of the vehicle's:   * engine (1024x576 px),   * rim (710x710 px),   * trim (800x600 px),   * paints (800x600 px),   * upholstery (800x600 px) and   * equipments (740x416 px).
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components
# operationId: imageComponentsGET
export def "markets-models-configurations-images-components imageComponentsGET" [
  marketId: string
  modelId: string
  configurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<components: record<engine: record<url: string>, equipments: record, paint: record<paint1: record, paint2: record>, rim: record<code: string, url: string>, trim: record<code: string, url: string>, upholstery: record<code: string, url: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/($configurationId)/images/components")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a URL pointing to an image of the vehicles engine.  These images are available in the resolution 1024x576 px.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/engine
# operationId: imageComponentsEngineGET
export def "markets-models-configurations-images-components-engine imageComponentsEngineGET" [
  marketId: string
  modelId: string
  configurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<engine: record<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/($configurationId)/images/components/engine")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns URLs pointing to images of this vehicle's equipments. The images are available in the highest possible resolution (usually 740x416 px).
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/equipments
# operationId: imageComponentsEquipmentsGET
export def "markets-models-configurations-images-components-equipments imageComponentsEquipmentsGET" [
  marketId: string
  modelId: string
  configurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<equipments: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/($configurationId)/images/components/equipments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns URLs pointing to images of this vehicle's equipments. The images are available in the highest possible resolution (usually 740x416 px).
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/equipments/{componentCode}
# operationId: imageComponentsEquipmentsByCodeGET
export def "markets-models-configurations-images-components-equipments imageComponentsEquipmentsByCodeGET" [
  marketId: string
  modelId: string
  configurationId: string
  componentCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<equipment: record<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/($configurationId)/images/components/equipments/($componentCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns URLs pointing to images of this vehicles paint.  These images are available in resolution 800x600 px.  Note there might be two paints (e.g. Smart, 'paint' for body panel and 'paint2' for the tridion cell)
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/paint
# operationId: imageComponentsPaintGET
export def "markets-models-configurations-images-components-paint imageComponentsPaintGET" [
  marketId: string
  modelId: string
  configurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<paint: record<paint1: record<code: string, url: string>, paint2: record<code: string, url: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/($configurationId)/images/components/paint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a URL pointing to an image of the vehicles rim.  These images are available in the resolution 710x710 px.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/rim
# operationId: imageComponentsRimGET
export def "markets-models-configurations-images-components-rim imageComponentsRimGET" [
  marketId: string
  modelId: string
  configurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<rim: record<code: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/($configurationId)/images/components/rim")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a URL pointing to an image of this vehicles trim.  These images are available in resolution 800x600 px.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/trim
# operationId: imageComponentsTrimGET
export def "markets-models-configurations-images-components-trim imageComponentsTrimGET" [
  marketId: string
  modelId: string
  configurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<trim: record<code: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/($configurationId)/images/components/trim")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns URLs pointing to images of the vehicle's upholsteries. Tge images are available in the highest possible resolution (usually 800x600 px).
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/components/upholstery
# operationId: imageComponentsUpholsteryGET
export def "markets-models-configurations-images-components-upholstery imageComponentsUpholsteryGET" [
  marketId: string
  modelId: string
  configurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<upholstery: record<code: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/($configurationId)/images/components/upholstery")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns URLs pointing to PNG images of a vehicle with a white background.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/images/vehicle
# operationId: imageVehicleGET
export def "markets-models-configurations-images-vehicle imageVehicleGET" [
  marketId: string
  modelId: string
  configurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --perspectives: string # One or more perspectives as a comma separated String list e.g. 'EXT000,EXT010,INT1'.  The following perspectives are available:   * EXT000-EXT350: EXT000 defines the front view, EXT010 defines a rotation of 10 degress and so forth.   * INT1-INT4: These are the 4 available interior perspectives.  The default value is EXT020,INT1 if no value is provided. (default: EXT020,INT1)
  --roofOpen: oneof<nothing, bool> # Set 'true', if you are looking for images with the roof open. This option is only valid for cabrios. Default is 'false'. (default: false)
  --night: oneof<nothing, bool> # Set 'true', if you are looking for images with a darker background and the vehicle's headlights turned on. Default is 'false'. (default: false)
]: nothing -> record<vehicle: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "perspectives" $perspectives "scalar") (serialize-qp "roofOpen" $roofOpen "scalar") (serialize-qp "night" $night "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/($configurationId)/images/vehicle" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the selectable components for the given marketId, modelId and configurationId.
#
# GET /markets/{marketId}/models/{modelId}/configurations/{configurationId}/selectables
# operationId: modelConfigurationSelectablesGET
export def "markets-models-configurations-selectables modelConfigurationSelectablesGET" [
  marketId: string
  modelId: string
  configurationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --componentTypes: list # A list of component types separated by a comma case insensitive. If nothing is defined all component types are returned. Allowed values are:   - WHEELS   - PAINTS   - UPHOLSTERIES   - TRIMS   - PACKAGES   - LINES   - SPECIAL_EDITION   - SPECIAL_EQUIPMENT
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<self: record<href: string>>, componentCategories: table<cardinality: string, categoryId: string, categoryName: string, categorySortId: float, componentIds: list, subcategories: list>, vehicleComponents: record<componentId: record<_links: record, code: string, codeType: string, componentSortId: float, componentType: string, description: string, fixed: bool, hidden: bool, id: string, name: string, priceInformation: record, pseudoCode: bool, selected: bool, standard: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "componentTypes" $componentTypes "csv") (serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/models/($modelId)/configurations/($configurationId)/selectables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stores the configuration of the given configurationId and modelId
#
# POST /markets/{marketId}/onlinecode
# operationId: onlineCodePOST
export def "markets-onlinecode onlineCodePOST" [
  marketId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<onlineCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/markets/($marketId)/onlinecode")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the configuration of the given onlineCode and marketId.
#
# GET /markets/{marketId}/onlinecode/{onlineCode}
# operationId: onlineCodeGET
export def "markets-onlinecode onlineCodeGET" [
  onlineCode: string
  marketId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<imageapi_vehicle: record<href: string>, selectables: record<href: string>, self: record<href: string>>, changeYear: string, configurationId: string, configurationPrice: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, initialPrice: record<currency: string, instalmentPrice: float, netPrice: float, price: float, taxes: list<record>>, marketId: string, modelId: string, modelYear: string, technicalInformation: record<acceleration: record<unit: string, value: float>, doors: float, energyEfficiencyClass: string, engine: record<alternativeFuelType: string, capacity: record, cylinder: string, driveConcept: string, emissionStandard: string, engineConcept: string, fuelEconomy: record, fuelType: string, powerHp: record, powerHybridExtensionHp: record, powerHybridExtensionKw: record, powerKw: record>, nedc: record<consumption: record, electricRange: record, emission: record, weight: record>, seats: float, topSpeed: record<unit: string, value: float>, transmission: record<code: string, codeType: string, name: string>, wltp: record<consumption: record, emission: record>>, vehicleComponents: table<_links: record, code: string, codeType: string, componentSortId: float, componentType: string, description: string, fixed: bool, hidden: bool, id: string, name: string, priceInformation: record, pseudoCode: bool, selected: bool, standard: bool>, wltpConfiguration: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/onlinecode/($onlineCode)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all configured active product groups for the given marketId.
#
# GET /markets/{marketId}/productgroups
# operationId: productGroupsGET
export def "markets-productgroups productGroupsGET" [
  marketId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsFilter: list # Specifies which fields should be included in the result. If this filter is not used, per default all fields are returned.
]: nothing -> record<_links: record<models: record<href: string>, self: record<href: string>>, market: record<_links: record<bodies: record, classes: record, models: record, productgroups: record, self: record>, country: string, language: string, marketId: string>, productGroups: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldsFilter" $fieldsFilter "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/markets/($marketId)/productgroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
