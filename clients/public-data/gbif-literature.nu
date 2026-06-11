# Auto-generated client for Literature API vv1
# Source: https://techdocs.gbif.org/openapi/literature.json
# Auth: --token flag or $env.LITERATURE_API_TOKEN

const BASE_URL = "https://api.gbif.org/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LITERATURE_API_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.gbif.org/v1" "https://api.gbif-uat.org/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def language-completer [] { ["" "aar" "abk" "afr" "aka" "amh" "ara" "arg" "asm" "ava" "ave" "aym" "aze" "bak" "bam" "bel" "ben" "bih" "bis" "bod" "bos" "bre" "bul" "cat" "ces" "cha" "che" "chu" "chv" "cor" "cos" "cre" "cym" "dan" "deu" "div" "dzo" "ell" "eng" "epo" "est" "eus" "ewe" "fao" "fas" "fij" "fin" "fra" "fry" "ful" "gla" "gle" "glg" "glv" "grn" "guj" "hat" "hau" "heb" "her" "hin" "hmo" "hrv" "hun" "hye" "ibo" "ido" "iii" "iku" "ile" "ina" "ind" "ipk" "isl" "ita" "jav" "jpn" "kal" "kan" "kas" "kat" "kau" "kaz" "khm" "kik" "kin" "kir" "kom" "kon" "kor" "kua" "kur" "lao" "lat" "lav" "lim" "lin" "lit" "ltz" "lub" "lug" "mah" "mal" "mar" "mkd" "mlg" "mlt" "mol" "mon" "mri" "msa" "mya" "nau" "nav" "nbl" "nde" "ndo" "nep" "nld" "nno" "nob" "nor" "nya" "oci" "oji" "ori" "orm" "oss" "pan" "pli" "pol" "por" "pus" "que" "roh" "ron" "run" "rus" "sag" "san" "sin" "slk" "slv" "sme" "smo" "sna" "snd" "som" "sot" "spa" "sqi" "srd" "srp" "ssw" "sun" "swa" "swe" "tah" "tam" "tat" "tel" "tgk" "tgl" "tha" "tir" "ton" "tsn" "tso" "tuk" "tur" "twi" "uig" "ukr" "urd" "uzb" "ven" "vie" "vol" "wln" "wol" "xho" "yid" "yor" "zha" "zho" "zul"] }
def format-completer [] { ["CSV" "TSV"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "literature get" } } | get name | first)
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

# Literature item by id
#
# GET /literature/{uuid}
# operationId: getLiteratureById
export def "literature get" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<discovered: string, authors: list<record>, countriesOfCoverage: list<string>, countriesOfResearcher: list<string>, publishingCountry: list<string>, added: string, published: string, day: int, gbifDownloadKey: list<string>, gbifOccurrenceKey: list<int>, gbifTaxonKey: list<int>, gbifHigherTaxonKey: list<int>, gbifNetworkKey: list<string>, gbifProjectIdentifier: list<string>, gbifProgramme: list<string>, citationType: string, gbifRegion: list<string>, id: string, identifiers: record, keywords: list<string>, language: string, literatureType: string, month: int, notes: string, openAccess: bool, peerReview: bool, publisher: string, relevance: list<string>, source: string, tags: list<string>, title: string, topics: list<string>, modified: string, websites: list<string>, year: int, abstract: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/literature/($uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search literature
#
# GET /literature/search
# operationId: search
export def "literature-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --citationType: list # The manner in which GBIF is cited in a paper.  Make a [facet query](https://api.gbif.org/v1/literature/search?limit=0&facet=citationType) for available values.  *This parameter may be repeated to search for multiple values.*
  --countriesOfCoverage: list # Country or area of focus of study. Country codes are listed in our [Country enum](https://api.gbif.org/v1/enumeration/country).  *This parameter may be repeated to search for multiple values.*
  --countriesOfResearcher: list # Country or area of institution with which author is affiliated. Country codes are listed in our [Country enum](https://api.gbif.org/v1/enumeration/country).  *This parameter may be repeated to search for multiple values.*
  --doi: list # Digital Object Identifier (DOI) of the literature item.  *This parameter may be repeated to search for multiple values.*
  --gbifDatasetKey: string # GBIF dataset referenced in publication.  *This parameter may be repeated to search for multiple values.* (format: uuid)
  --gbifDownloadKey: list # GBIF download referenced in publication.  *This parameter may be repeated to search for multiple values.*
  --gbifHigherTaxonKey: list # All parent keys of any taxon that is the focus of the paper (see `gbifTaxonKey`)  *This parameter may be repeated to search for multiple values.*
  --gbifNetworkKey: string # GBIF network referenced in publication.  *This parameter may be repeated to search for multiple values.* (format: uuid)
  --gbifOccurrenceKey: list # Any GBIF occurrence keys directly mentioned in a paper.  *This parameter may be repeated to search for multiple values.*
  --gbifProjectIdentifier: string # GBIF dataset referenced in publication.  *This parameter may be repeated to search for multiple values.* (format: uuid)
  --gbifProgrammeAcronym: string # GBIF dataset referenced in publication.  *This parameter may be repeated to search for multiple values.* (format: uuid)
  --gbifTaxonKey: list # Key(s) from the GBIF backbone of taxa that are the focus of a paper.  *This parameter may be repeated to search for multiple values.*
  --literatureType: list # Type of literature, e.g. journal article.  *This parameter may be repeated to search for multiple values.*
  --openAccess: string@bool-completer # Is the publication Open Access?
  --peerReview: string@bool-completer # Has the publication undergone peer review?
  --publisher: list # Publisher of journal.  *This parameter may be repeated to search for multiple values.*
  --publishingOrganizationKey: list # Publisher whose dataset is referenced in publication.  *This parameter may be repeated to search for multiple values.*
  --publishingCountry: list # Country of the publisher whose dataset is referenced in publication. Country codes are listed in our [Country enum](https://api.gbif.org/v1/enumeration/country).  *This parameter may be repeated to search for multiple values.*
  --relevance: list # Relevance to GBIF community, see [literature relevance](https://www.gbif.org/faq?question=literature-relevance).  *This parameter may be repeated to search for multiple values.*
  --qp-source: list # Journal of publication.  *This parameter may be repeated to search for multiple values.*
  --topics: list # Topic of publication.  *This parameter may be repeated to search for multiple values.*
  --websites: list # Website of publication  *This parameter may be repeated to search for multiple values.*
  --year: int # Year of publication.  This can be a single range such as `2019,2021`, or can be repeated to search multiple years. (format: int32)
  --language: string@language-completer # Language of publication. Language codes are listed in our [Language enum](https://api.gbif.org/v1/enumeration/language).  *This parameter may be repeated to search for multiple values.*
  --added: string # Date or date range when the publication was added. Format is ISO 8601, e.g., '2024-07-14' or '2024-07-14,2024-08-14'. (format: date-time)
  --published: string # Date or date range when the publication was published. Format is ISO 8601, e.g., '2024-02-22' or '2024-02-22,2024-03-22'. (format: date-time)
  --discovered: string # Date or date range when the publication was discovered. Format is ISO 8601, e.g., '2024-02-26' or '2024-02-26,2024-03-26'. (format: date-time)
  --modified: string # Date or date range when the publication was discovered. Format is ISO 8601, e.g., '2024-07-26' or '2024-07-26,2024-10-26'. (format: date-time)
  --hl: string@bool-completer # Set `hl=true` to highlight terms matching the query when in fulltext search fields. The highlight will be an emphasis tag of class `gbifHl`.
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
  --facet: list # A facet name used to retrieve the most frequent values for a field. This parameter may be repeated to request multiple facets.
  --facetMinCount: int # Used in combination with the facet parameter. Set `facetMinCount={#}` to exclude facets with a count less than `{#}`. (format: int32)
  --facetMultiselect: string@bool-completer # Used in combination with the facet parameter. Set `facetMultiselect=true` to still return counts for values that are not currently filtered.
  --facetLimit: int # Facet parameters allow paging requests using the parameters facetOffset and facetLimit (format: int32)
  --facetOffset: int # Facet parameters allow paging requests using the parameters facetOffset and facetLimit (format: int32)
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
]: nothing -> record<discovered: string, authors: list<record>, countriesOfCoverage: list<string>, countriesOfResearcher: list<string>, publishingCountry: list<string>, added: string, published: string, day: int, gbifDownloadKey: list<string>, gbifOccurrenceKey: list<int>, gbifTaxonKey: list<int>, gbifHigherTaxonKey: list<int>, gbifNetworkKey: list<string>, gbifProjectIdentifier: list<string>, gbifProgramme: list<string>, citationType: string, gbifRegion: list<string>, id: string, identifiers: record, keywords: list<string>, language: string, literatureType: string, month: int, notes: string, openAccess: bool, peerReview: bool, publisher: string, relevance: list<string>, source: string, tags: list<string>, title: string, topics: list<string>, modified: string, websites: list<string>, year: int, abstract: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "citationType" $citationType "multi") (serialize-qp "countriesOfCoverage" $countriesOfCoverage "multi") (serialize-qp "countriesOfResearcher" $countriesOfResearcher "multi") (serialize-qp "doi" $doi "multi") (serialize-qp "gbifDatasetKey" $gbifDatasetKey "scalar") (serialize-qp "gbifDownloadKey" $gbifDownloadKey "multi") (serialize-qp "gbifHigherTaxonKey" $gbifHigherTaxonKey "multi") (serialize-qp "gbifNetworkKey" $gbifNetworkKey "scalar") (serialize-qp "gbifOccurrenceKey" $gbifOccurrenceKey "multi") (serialize-qp "gbifProjectIdentifier" $gbifProjectIdentifier "scalar") (serialize-qp "gbifProgrammeAcronym" $gbifProgrammeAcronym "scalar") (serialize-qp "gbifTaxonKey" $gbifTaxonKey "multi") (serialize-qp "literatureType" $literatureType "multi") (serialize-qp "openAccess" $openAccess "scalar") (serialize-qp "peerReview" $peerReview "scalar") (serialize-qp "publisher" $publisher "multi") (serialize-qp "publishingOrganizationKey" $publishingOrganizationKey "multi") (serialize-qp "publishingCountry" $publishingCountry "multi") (serialize-qp "relevance" $relevance "multi") (serialize-qp "source" $qp_source "multi") (serialize-qp "topics" $topics "multi") (serialize-qp "websites" $websites "multi") (serialize-qp "year" $year "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "added" $added "scalar") (serialize-qp "published" $published "scalar") (serialize-qp "discovered" $discovered "scalar") (serialize-qp "modified" $modified "scalar") (serialize-qp "hl" $hl "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "facet" $facet "multi") (serialize-qp "facetMinCount" $facetMinCount "scalar") (serialize-qp "facetMultiselect" $facetMultiselect "scalar") (serialize-qp "facetLimit" $facetLimit "scalar") (serialize-qp "facetOffset" $facetOffset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/literature/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export literature search results
#
# GET /literature/export
# operationId: export
export def "literature-export export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # The format for the search results export. Defaults to `TSV`. (default: TSV)
  --citationType: list # The manner in which GBIF is cited in a paper.  Make a [facet query](https://api.gbif.org/v1/literature/search?limit=0&facet=citationType) for available values.  *This parameter may be repeated to search for multiple values.*
  --countriesOfCoverage: list # Country or area of focus of study. Country codes are listed in our [Country enum](https://api.gbif.org/v1/enumeration/country).  *This parameter may be repeated to search for multiple values.*
  --countriesOfResearcher: list # Country or area of institution with which author is affiliated. Country codes are listed in our [Country enum](https://api.gbif.org/v1/enumeration/country).  *This parameter may be repeated to search for multiple values.*
  --doi: list # Digital Object Identifier (DOI) of the literature item.  *This parameter may be repeated to search for multiple values.*
  --gbifDatasetKey: string # GBIF dataset referenced in publication.  *This parameter may be repeated to search for multiple values.* (format: uuid)
  --gbifDownloadKey: list # GBIF download referenced in publication.  *This parameter may be repeated to search for multiple values.*
  --gbifHigherTaxonKey: list # All parent keys of any taxon that is the focus of the paper (see `gbifTaxonKey`)  *This parameter may be repeated to search for multiple values.*
  --gbifNetworkKey: string # GBIF network referenced in publication.  *This parameter may be repeated to search for multiple values.* (format: uuid)
  --gbifOccurrenceKey: list # Any GBIF occurrence keys directly mentioned in a paper.  *This parameter may be repeated to search for multiple values.*
  --gbifProjectIdentifier: string # GBIF dataset referenced in publication.  *This parameter may be repeated to search for multiple values.* (format: uuid)
  --gbifProgrammeAcronym: string # GBIF dataset referenced in publication.  *This parameter may be repeated to search for multiple values.* (format: uuid)
  --gbifTaxonKey: list # Key(s) from the GBIF backbone of taxa that are the focus of a paper.  *This parameter may be repeated to search for multiple values.*
  --literatureType: list # Type of literature, e.g. journal article.  *This parameter may be repeated to search for multiple values.*
  --openAccess: string@bool-completer # Is the publication Open Access?
  --peerReview: string@bool-completer # Has the publication undergone peer review?
  --publisher: list # Publisher of journal.  *This parameter may be repeated to search for multiple values.*
  --publishingOrganizationKey: list # Publisher whose dataset is referenced in publication.  *This parameter may be repeated to search for multiple values.*
  --publishingCountry: list # Country of the publisher whose dataset is referenced in publication. Country codes are listed in our [Country enum](https://api.gbif.org/v1/enumeration/country).  *This parameter may be repeated to search for multiple values.*
  --relevance: list # Relevance to GBIF community, see [literature relevance](https://www.gbif.org/faq?question=literature-relevance).  *This parameter may be repeated to search for multiple values.*
  --qp-source: list # Journal of publication.  *This parameter may be repeated to search for multiple values.*
  --topics: list # Topic of publication.  *This parameter may be repeated to search for multiple values.*
  --websites: list # Website of publication  *This parameter may be repeated to search for multiple values.*
  --year: int # Year of publication.  This can be a single range such as `2019,2021`, or can be repeated to search multiple years. (format: int32)
  --language: string@language-completer # Language of publication. Language codes are listed in our [Language enum](https://api.gbif.org/v1/enumeration/language).  *This parameter may be repeated to search for multiple values.*
  --added: string # Date or date range when the publication was added. Format is ISO 8601, e.g., '2024-07-14' or '2024-07-14,2024-08-14'. (format: date-time)
  --published: string # Date or date range when the publication was published. Format is ISO 8601, e.g., '2024-02-22' or '2024-02-22,2024-03-22'. (format: date-time)
  --discovered: string # Date or date range when the publication was discovered. Format is ISO 8601, e.g., '2024-02-26' or '2024-02-26,2024-03-26'. (format: date-time)
  --modified: string # Date or date range when the publication was discovered. Format is ISO 8601, e.g., '2024-07-26' or '2024-07-26,2024-10-26'. (format: date-time)
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "citationType" $citationType "multi") (serialize-qp "countriesOfCoverage" $countriesOfCoverage "multi") (serialize-qp "countriesOfResearcher" $countriesOfResearcher "multi") (serialize-qp "doi" $doi "multi") (serialize-qp "gbifDatasetKey" $gbifDatasetKey "scalar") (serialize-qp "gbifDownloadKey" $gbifDownloadKey "multi") (serialize-qp "gbifHigherTaxonKey" $gbifHigherTaxonKey "multi") (serialize-qp "gbifNetworkKey" $gbifNetworkKey "scalar") (serialize-qp "gbifOccurrenceKey" $gbifOccurrenceKey "multi") (serialize-qp "gbifProjectIdentifier" $gbifProjectIdentifier "scalar") (serialize-qp "gbifProgrammeAcronym" $gbifProgrammeAcronym "scalar") (serialize-qp "gbifTaxonKey" $gbifTaxonKey "multi") (serialize-qp "literatureType" $literatureType "multi") (serialize-qp "openAccess" $openAccess "scalar") (serialize-qp "peerReview" $peerReview "scalar") (serialize-qp "publisher" $publisher "multi") (serialize-qp "publishingOrganizationKey" $publishingOrganizationKey "multi") (serialize-qp "publishingCountry" $publishingCountry "multi") (serialize-qp "relevance" $relevance "multi") (serialize-qp "source" $qp_source "multi") (serialize-qp "topics" $topics "multi") (serialize-qp "websites" $websites "multi") (serialize-qp "year" $year "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "added" $added "scalar") (serialize-qp "published" $published "scalar") (serialize-qp "discovered" $discovered "scalar") (serialize-qp "modified" $modified "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/literature/export" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
