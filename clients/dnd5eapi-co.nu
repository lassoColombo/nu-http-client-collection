# Auto-generated client for D&D 5e API v0.1
# Source: https://api.apis.guru/v2/specs/dnd5eapi.co/0.1/openapi.json
# Auth: --token flag or $env.D_D_5E_API_TOKEN

const BASE_URL = "https://www.dnd5eapi.co"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o D_D_5E_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://www.dnd5eapi.co" "http://localhost:3000"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def index-completer [] { ["cha" "con" "dex" "int" "str" "wis"] }
def index-completer-1 [] { ["chaotic-evil" "chaotic-good" "chaotic-neutral" "lawful-evil" "lawful-good" "lawful-neutral" "neutral" "neutral-evil" "neutral-good"] }
def index-completer-2 [] { ["acolyte"] }
def index-completer-3 [] { ["barbarian" "bard" "cleric" "druid" "fighter" "monk" "paladin" "ranger" "rogue" "sorcerer" "warlock" "wizard"] }
def index-completer-4 [] { ["blinded" "charmed" "deafened" "exhaustion" "frightened" "grappled" "incapacitated" "invisible" "paralyzed" "petrified" "poisoned" "prone" "restrained" "stunned" "unconscious"] }
def index-completer-5 [] { ["acid" "bludgeoning" "cold" "fire" "force" "lightning" "necrotic" "piercing" "poison" "psychic" "radiant" "slashing" "thunder"] }
def index-completer-6 [] { ["grappler"] }
def index-completer-7 [] { ["abyssal" "celestial" "common" "deep-speech" "draconic" "dwarvish" "elvish" "giant" "gnomish" "goblin" "halfling" "infernal" "orc" "primordial" "sylvan" "undercommon"] }
def index-completer-8 [] { ["abjuration" "conjuration" "divination" "enchantment" "evocation" "illusion" "necromancy" "transmutation"] }
def index-completer-9 [] { ["dragonborn" "dwarf" "elf" "gnome" "half-elf" "half-orc" "halfling" "human" "tiefling"] }
def index-completer-10 [] { ["ability-checks" "ability-scores-and-modifiers" "actions-in-combat" "advantage-and-disadvantage" "between-adventures" "casting-a-spell" "cover" "damage-and-healing" "diseases" "fantasy-historical-pantheons" "madness" "making-an-attack" "mounted-combat" "movement" "movement-and-position" "objects" "poisons" "proficiency-bonus" "resting" "saving-throws" "sentient-magic-items" "standard-exchange-rates" "the-environment" "the-order-of-combat" "the-planes-of-existence" "time" "traps" "underwater-combat" "using-each-ability" "what-is-a-spell"] }
def index-completer-11 [] { ["adventuring" "appendix" "combat" "equipment" "spellcasting" "using-ability-scores"] }
def index-completer-12 [] { ["acrobatics" "animal-handling" "arcana" "athletics" "deception" "history" "insight" "intimidation" "investigation" "medicine" "nature" "perception" "performance" "persuasion" "religion" "sleight-of-hand" "stealth" "survival"] }
def index-completer-13 [] { ["berserker" "champion" "devotion" "draconic" "evocation" "fiend" "hunter" "land" "life" "lore" "open-hand" "thief"] }
def index-completer-14 [] { ["high-elf" "hill-dwarf" "lightfoot-halfling" "rock-gnome"] }
def index-completer-15 [] { ["artificers-lore" "brave" "breath-weapon" "damage-resistance" "darkvision" "draconic-ancestry" "draconic-ancestry-black" "draconic-ancestry-blue" "draconic-ancestry-brass" "draconic-ancestry-bronze" "draconic-ancestry-copper" "draconic-ancestry-gold" "draconic-ancestry-green" "draconic-ancestry-red" "draconic-ancestry-silver" "draconic-ancestry-white" "dwarven-combat-training" "dwarven-resilience" "dwarven-toughness" "elf-weapon-training" "extra-language" "fey-ancestry" "gnome-cunning" "halfling-nimbleness" "hellish-resistance" "high-elf-cantrip" "infernal-legacy" "keen-senses" "lucky" "menacing" "naturally-stealthy" "relentless-endurance" "savage-attacks" "skill-versatility" "stonecunning" "tinker" "tool-proficiency" "trance"] }
def index-completer-16 [] { ["ammunition" "finesse" "heavy" "light" "loading" "monk" "reach" "special" "thrown" "two-handed" "versatile"] }
def endpoint-completer [] { ["ability-scores" "alignments" "backgrounds" "classes" "conditions" "damage-types" "equipment" "equipment-categories" "feats" "features" "languages" "magic-items" "magic-schools" "monsters" "proficiencies" "races" "rule-sections" "rules" "skills" "spells" "subclasses" "subraces" "traits" "weapon-properties"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-api" "get-api-ability-scores-index" "get-api-alignments-index" "get-api-backgrounds-index" "get-api-classes-index" "get-api-classes-index-features" "get-api-classes-index-levels" "get-api-classes-index-levels-class-level" "get-api-classes-index-levels-class-level-features" "get-api-classes-index-levels-spell-level-spells" "get-api-classes-index-multi-classing" "get-api-classes-index-proficiencies" "get-api-classes-index-spellcasting" "get-api-classes-index-spells" "get-api-classes-index-subclasses" "get-api-conditions-index" "get-api-damage-types-index" "get-api-equipment-categories-index" "get-api-equipment-index" "get-api-feats-index" "get-api-features-index" "get-api-languages-index" "get-api-magic-items-index" "get-api-magic-schools-index" "get-api-monsters" "get-api-monsters-index" "get-api-proficiencies-index" "get-api-races-index" "get-api-races-index-proficiencies" "get-api-races-index-subraces" "get-api-races-index-traits" "get-api-rule-sections-index" "get-api-rules-index" "get-api-skills-index" "get-api-spells" "get-api-spells-index" "get-api-subclasses-index" "get-api-subclasses-index-features" "get-api-subclasses-index-levels" "get-api-subclasses-index-levels-subclass-level" "get-api-subclasses-index-levels-subclass-level-features" "get-api-subraces-index" "get-api-subraces-index-proficiencies" "get-api-subraces-index-traits" "get-api-traits-index" "get-api-weapon-properties-index" "get-api-endpoint" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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

# Get all resource URLs.
#
# GET /api
export def "get-api" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get an ability score by index.
#
# GET /api/ability-scores/{index}
export def "get-api-ability-scores-index" [
  index: string@index-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: list<string>, full_name: string, skills: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/ability-scores/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get an alignment by index.
#
# GET /api/alignments/{index}
export def "get-api-alignments-index" [
  index: string@index-completer-1
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, abbreviation: string, desc: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/alignments/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a background by index.
#
# GET /api/backgrounds/{index}
export def "get-api-backgrounds-index" [
  index: string@index-completer-2
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, bonds: record<choose: float, desc: string, from: any, type: string>, feature: record<desc: list<string>, name: string>, flaws: record<choose: float, desc: string, from: any, type: string>, ideals: record<choose: float, desc: string, from: any, type: string>, language_options: record<choose: float, desc: string, from: any, type: string>, personality_traits: record, starting_equipment: table<index: string, name: string, url: string>, starting_equipment_options: record<choose: float, desc: string, from: any, type: string>, starting_proficiencies: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/backgrounds/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a class by index.
#
# GET /api/classes/{index}
export def "get-api-classes-index" [
  index: string@index-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, class_levels: string, hit_die: float, multi_classing: record<prerequisite_options: list<record>, prerequisites: list<record>, proficiencies: list<record>, proficiency_choices: list<record>>, proficiencies: table<index: string, name: string, url: string>, proficiency_choices: table<choose: float, desc: string, from: any, type: string>, saving_throws: table<index: string, name: string, url: string>, spellcasting: record<info: list<record>, level: float, spellcasting_ability: record<index: string, name: string, url: string>>, spells: string, starting_equipment: table<equipment: record, quantity: float>, starting_equipment_options: table<choose: float, desc: string, from: any, type: string>, subclasses: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/classes/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get features available for a class.
#
# GET /api/classes/{index}/features
export def "get-api-classes-index-features" [
  index: string@index-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/classes/{index}/features") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all level resources for a class.
#
# GET /api/classes/{index}/levels
export def "get-api-classes-index-levels" [
  index: string@index-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subclass: string # Adds subclasses for class to the response
]: nothing -> oneof<table<ability_score_bonuses: float, class_specific: any, features: list<record>, index: string, level: float, prof_bonus: float, spellcasting: record<cantrips_known: float, spell_slots_level_1: float, spell_slots_level_2: float, spell_slots_level_3: float, spell_slots_level_4: float, spell_slots_level_5: float, spell_slots_level_6: float, spell_slots_level_7: float, spell_slots_level_8: float, spell_slots_level_9: float, spells_known: float>, url: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let qp = [(serialize-qp "subclass" $subclass "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/classes/{index}/levels") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"subclass": $subclass} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get level resource for a class and level.
#
# GET /api/classes/{index}/levels/{class_level}
export def "get-api-classes-index-levels-class-level" [
  index: string@index-completer-3
  class_level: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<ability_score_bonuses: float, class_specific: any, features: table<index: string, name: string, url: string>, index: string, level: float, prof_bonus: float, spellcasting: record<cantrips_known: float, spell_slots_level_1: float, spell_slots_level_2: float, spell_slots_level_3: float, spell_slots_level_4: float, spell_slots_level_5: float, spell_slots_level_6: float, spell_slots_level_7: float, spell_slots_level_8: float, spell_slots_level_9: float, spells_known: float>, url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($class_level | is-empty) { error make --unspanned { msg: "path parameter 'class_level' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index), class_level: (encode-path-segment $class_level)} | format pattern "/api/classes/{index}/levels/{class_level}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get features available to a class at the requested level.
#
# GET /api/classes/{index}/levels/{class_level}/features
export def "get-api-classes-index-levels-class-level-features" [
  index: string@index-completer-3
  class_level: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($class_level | is-empty) { error make --unspanned { msg: "path parameter 'class_level' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index), class_level: (encode-path-segment $class_level)} | format pattern "/api/classes/{index}/levels/{class_level}/features") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get spells of the requested level available to the class.
#
# GET /api/classes/{index}/levels/{spell_level}/spells
export def "get-api-classes-index-levels-spell-level-spells" [
  index: string@index-completer-3
  spell_level: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($spell_level | is-empty) { error make --unspanned { msg: "path parameter 'spell_level' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index), spell_level: (encode-path-segment $spell_level)} | format pattern "/api/classes/{index}/levels/{spell_level}/spells") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get multiclassing resource for a class.
#
# GET /api/classes/{index}/multi-classing
export def "get-api-classes-index-multi-classing" [
  index: string@index-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<prerequisite_options: table<choose: float, desc: string, from: any, type: string>, prerequisites: table<ability_score: record, minimum_score: float>, proficiencies: table<index: string, name: string, url: string>, proficiency_choices: table<choose: float, desc: string, from: any, type: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/classes/{index}/multi-classing") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get proficiencies available for a class.
#
# GET /api/classes/{index}/proficiencies
export def "get-api-classes-index-proficiencies" [
  index: string@index-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/classes/{index}/proficiencies") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get spellcasting info for a class.
#
# GET /api/classes/{index}/spellcasting
export def "get-api-classes-index-spellcasting" [
  index: string@index-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<info: table<desc: list, name: string>, level: float, spellcasting_ability: record<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/classes/{index}/spellcasting") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get spells available for a class.
#
# GET /api/classes/{index}/spells
export def "get-api-classes-index-spells" [
  index: string@index-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/classes/{index}/spells") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get subclasses available for a class.
#
# GET /api/classes/{index}/subclasses
export def "get-api-classes-index-subclasses" [
  index: string@index-completer-3
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/classes/{index}/subclasses") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a condition by index.
#
# GET /api/conditions/{index}
export def "get-api-conditions-index" [
  index: string@index-completer-4
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/conditions/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a damage type by index.
#
# GET /api/damage-types/{index}
export def "get-api-damage-types-index" [
  index: string@index-completer-5
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/damage-types/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get an equipment category by index.
#
# GET /api/equipment-categories/{index}
export def "get-api-equipment-categories-index" [
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, equipment: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/equipment-categories/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get an equipment item by index.
#
# GET /api/equipment/{index}
export def "get-api-equipment-index" [
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/equipment/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a feat by index.
#
# GET /api/feats/{index}
export def "get-api-feats-index" [
  index: string@index-completer-6
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: list<string>, prerequisites: table<ability_score: record, minimum_score: float>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/feats/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a feature by index.
#
# GET /api/features/{index}
export def "get-api-features-index" [
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: list<string>, class: record<index: string, name: string, url: string>, feature_specific: any, level: float, parent: record<index: string, name: string, url: string>, prerequisites: list<any>, subclass: record<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/features/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a language by index.
#
# GET /api/languages/{index}
export def "get-api-languages-index" [
  index: string@index-completer-7
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: string, script: string, type: string, typical_speakers: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/languages/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a magic item by index.
#
# GET /api/magic-items/{index}
export def "get-api-magic-items-index" [
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: list<string>, equipment_category: record<index: string, name: string, url: string>, rarity: record<name: string>, variant: bool, variants: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/magic-items/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a magic school by index.
#
# GET /api/magic-schools/{index}
export def "get-api-magic-schools-index" [
  index: string@index-completer-8
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/magic-schools/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get list of monsters with optional filtering
#
# GET /api/monsters
export def "get-api-monsters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --challenge-rating: list<float> # The challenge rating or ratings to filter on.
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "challenge_rating" $challenge_rating "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/monsters" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"challenge_rating": $challenge_rating} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get monster by index.
#
# GET /api/monsters/{index}
export def "get-api-monsters-index" [
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: list<string>, charisma: float, constitution: float, dexterity: float, intelligence: float, strength: float, wisdom: float, actions: table<action_options: record, actions: list, attack_bonus: float, attacks: list, damage: list, dc: record, desc: string, multiattack_type: string, name: string, options: record>, alignments: string, armor_class: list<record>, challenge_rating: float, condition_immunities: table<index: string, name: string, url: string>, damage_immunities: list<string>, damage_resistances: list<string>, damage_vulnerabilities: list<string>, forms: table<index: string, name: string, url: string>, hit_dice: string, hit_points: float, hit_points_roll: string, image: string, languages: string, legendary_actions: table<action_options: record, actions: list, attack_bonus: float, attacks: list, damage: list, dc: record, desc: string, multiattack_type: string, name: string, options: record>, proficiencies: table<proficiency: record, value: float>, reactions: table<action_options: record, actions: list, attack_bonus: float, attacks: list, damage: list, dc: record, desc: string, multiattack_type: string, name: string, options: record>, senses: record<blindsight: string, darkvision: string, passive_perception: float, tremorsense: string, truesight: string>, size: string, special_abilities: table<attack_bonus: float, damage: list, dc: record, desc: string, name: string, spellcasting: record, usage: record>, speed: record<burrow: string, climb: string, fly: string, swim: string, walk: string>, subtype: string, type: string, xp: float>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/monsters/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a proficiency by index.
#
# GET /api/proficiencies/{index}
export def "get-api-proficiencies-index" [
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, classes: table<index: string, name: string, url: string>, races: table<index: string, name: string, url: string>, reference: record<index: string, name: string, url: string>, type: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/proficiencies/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a race by index.
#
# GET /api/races/{index}
export def "get-api-races-index" [
  index: string@index-completer-9
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, ability_bonuses: table<ability_score: record, bonus: float>, age: string, alignment: string, language_desc: string, languages: table<index: string, name: string, url: string>, size: string, size_description: string, speed: float, starting_proficiencies: table<index: string, name: string, url: string>, starting_proficiency_options: record<choose: float, desc: string, from: any, type: string>, subraces: table<index: string, name: string, url: string>, traits: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/races/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get proficiencies available for a race.
#
# GET /api/races/{index}/proficiencies
export def "get-api-races-index-proficiencies" [
  index: string@index-completer-9
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/races/{index}/proficiencies") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get subraces available for a race.
#
# GET /api/races/{index}/subraces
export def "get-api-races-index-subraces" [
  index: string@index-completer-9
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/races/{index}/subraces") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get traits available for a race.
#
# GET /api/races/{index}/traits
export def "get-api-races-index-traits" [
  index: string@index-completer-9
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/races/{index}/traits") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a rule section by index.
#
# GET /api/rule-sections/{index}
export def "get-api-rule-sections-index" [
  index: string@index-completer-10
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/rule-sections/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a rule by index.
#
# GET /api/rules/{index}
export def "get-api-rules-index" [
  index: string@index-completer-11
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: string, subsections: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/rules/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a skill by index.
#
# GET /api/skills/{index}
export def "get-api-skills-index" [
  index: string@index-completer-12
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: list<string>, ability_score: record<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/skills/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get list of spells with optional filtering.
#
# GET /api/spells
export def "get-api-spells" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: list<int> # The level or levels to filter on.
  --school: list<string> # The magic school or schools to filter on.
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "level" $level "multi") (serialize-qp "school" $school "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/spells" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"level": $level, "school": $school} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a spell by index.
#
# GET /api/spells/{index}
export def "get-api-spells-index" [
  index: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: list<string>, area_of_effect: record<size: float, type: string>, attack_type: string, casting_time: string, classes: table<index: string, name: string, url: string>, components: list<string>, concentration: bool, damage: any, duration: string, higher_level: list<string>, level: float, material: string, range: string, ritual: bool, school: record<index: string, name: string, url: string>, subclasses: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/spells/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a subclass by index.
#
# GET /api/subclasses/{index}
export def "get-api-subclasses-index" [
  index: string@index-completer-13
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: list<string>, class: record<index: string, name: string, url: string>, spells: table<prerequisites: list, spell: record>, subclass_flavor: string, subclass_levels: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/subclasses/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get features available for a subclass.
#
# GET /api/subclasses/{index}/features
export def "get-api-subclasses-index-features" [
  index: string@index-completer-13
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/subclasses/{index}/features") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all level resources for a subclass.
#
# GET /api/subclasses/{index}/levels
export def "get-api-subclasses-index-levels" [
  index: string@index-completer-13
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<table<class: record<index: string, name: string, url: string>, features: list<record>, index: string, level: float, subclass: record<index: string, name: string, url: string>, url: string>, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/subclasses/{index}/levels") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get level resources for a subclass and level.
#
# GET /api/subclasses/{index}/levels/{subclass_level}
export def "get-api-subclasses-index-levels-subclass-level" [
  index: string@index-completer-13
  subclass_level: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<ability_score_bonuses: float, classspecific: any, features: table<index: string, name: string, url: string>, index: string, level: float, prof_bonus: float, spellcasting: record<cantrips_known: float, spell_slots_level_1: float, spell_slots_level_2: float, spell_slots_level_3: float, spell_slots_level_4: float, spell_slots_level_5: float, spell_slots_level_6: float, spell_slots_level_7: float, spell_slots_level_8: float, spell_slots_level_9: float, spells_known: float>, url: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($subclass_level | is-empty) { error make --unspanned { msg: "path parameter 'subclass_level' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index), subclass_level: (encode-path-segment $subclass_level)} | format pattern "/api/subclasses/{index}/levels/{subclass_level}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get features of the requested spell level available to the class.
#
# GET /api/subclasses/{index}/levels/{subclass_level}/features
export def "get-api-subclasses-index-levels-subclass-level-features" [
  index: string@index-completer-13
  subclass_level: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  if ($subclass_level | is-empty) { error make --unspanned { msg: "path parameter 'subclass_level' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index), subclass_level: (encode-path-segment $subclass_level)} | format pattern "/api/subclasses/{index}/levels/{subclass_level}/features") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a subrace by index.
#
# GET /api/subraces/{index}
export def "get-api-subraces-index" [
  index: string@index-completer-14
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, ability_bonuses: table<ability_score: record, bonus: float>, desc: string, language_options: record<choose: float, desc: string, from: any, type: string>, languages: table<index: string, name: string, url: string>, race: record<index: string, name: string, url: string>, racial_traits: table<index: string, name: string, url: string>, starting_proficiencies: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/subraces/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get proficiences available for a subrace.
#
# GET /api/subraces/{index}/proficiencies
export def "get-api-subraces-index-proficiencies" [
  index: string@index-completer-14
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/subraces/{index}/proficiencies") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get traits available for a subrace.
#
# GET /api/subraces/{index}/traits
export def "get-api-subraces-index-traits" [
  index: string@index-completer-14
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/subraces/{index}/traits") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a trait by index.
#
# GET /api/traits/{index}
export def "get-api-traits-index" [
  index: string@index-completer-15
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: list<string>, language_options: record<choose: float, desc: string, from: any, type: string>, proficiencies: table<index: string, name: string, url: string>, proficiency_choices: record<choose: float, desc: string, from: any, type: string>, races: table<index: string, name: string, url: string>, subraces: table<index: string, name: string, url: string>, trait_specific: any>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/traits/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a weapon property by index.
#
# GET /api/weapon-properties/{index}
export def "get-api-weapon-properties-index" [
  index: string@index-completer-16
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<index: string, name: string, url: string, desc: list<string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($index | is-empty) { error make --unspanned { msg: "path parameter 'index' must be non-empty" } }
  let full_url = (build-url $base ({index: (encode-path-segment $index)} | format pattern "/api/weapon-properties/{index}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get list of all available resources for an endpoint.
#
# GET /api/{endpoint}
export def "get-api-endpoint" [
  endpoint: string@endpoint-completer
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<count: float, results: table<index: string, name: string, url: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($endpoint | is-empty) { error make --unspanned { msg: "path parameter 'endpoint' must be non-empty" } }
  let full_url = (build-url $base ({endpoint: (encode-path-segment $endpoint)} | format pattern "/api/{endpoint}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
