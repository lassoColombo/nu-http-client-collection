# Auto-generated client for Occurrence API vv1
# Source: https://techdocs.gbif.org/openapi/occurrence.json
# Auth: --token flag or $env.OCCURRENCE_API_TOKEN

const BASE_URL = "https://api.gbif.org/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OCCURRENCE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.gbif.org/v1" "https://api.gbif-uat.org/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def occurrenceStatus-completer [] { ["ABSENT" "PRESENT"] }
def accept-completer [] { ["application/json" "application/x-javascript"] }
def format-completer [] { ["BIONOMIA" "DWCA" "MAP_OF_LIFE" "SIMPLE_AVRO" "SIMPLE_CSV" "SIMPLE_PARQUET" "SIMPLE_WITH_VERBATIM_AVRO" "SPECIES_LIST" "SQL_TSV_ZIP"] }
def accept-completer-1 [] { ["application/json" "text/plain"] }
def accept-completer-2 [] { ["application/json" "text/xml"] }
def term-completer [] { ["FOSSIL_SPECIMEN" "HUMAN_OBSERVATION" "LITERATURE" "LIVING_SPECIMEN" "MACHINE_OBSERVATION" "MATERIAL_CITATION" "MATERIAL_SAMPLE" "OBSERVATION" "OCCURRENCE" "PRESERVED_SPECIMEN" "UNKNOWN"] }
def sortBy-completer [] { ["COUNTRY_CODE" "RECORD_COUNT"] }
def sortOrder-completer [] { ["ASC" "DESC"] }
def sortBy-completer-1 [] { ["COUNTRY_CODE" "DATASET_TITLE" "RECORD_COUNT"] }
def sortBy-completer-2 [] { ["COUNTRY_CODE" "ORGANIZATION_TITLE" "RECORD_COUNT"] }
def format-completer-1 [] { ["CSV" "TSV"] }
def publishingCountry-completer [] { ["AA" "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "XK" "XZ" "YE" "YT" "ZA" "ZM" "ZW" "ZZ"] }
def userCountry-completer [] { ["AA" "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "XK" "XZ" "YE" "YT" "ZA" "ZM" "ZW" "ZZ"] }
def basisOfRecord-completer [] { ["FOSSIL_SPECIMEN" "HUMAN_OBSERVATION" "LITERATURE" "LIVING_SPECIMEN" "MACHINE_OBSERVATION" "MATERIAL_CITATION" "MATERIAL_SAMPLE" "OBSERVATION" "OCCURRENCE" "PRESERVED_SPECIMEN" "UNKNOWN"] }
def country-completer [] { ["AA" "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "XK" "XZ" "YE" "YT" "ZA" "ZM" "ZW" "ZZ"] }
def issue-completer [] { ["AGE_OR_STAGE_INFERRED_FROM_PARENT_RANK" "AGE_OR_STAGE_INVALID_RANGE" "AGE_OR_STAGE_RANK_MISMATCH" "AMBIGUOUS_COLLECTION" "AMBIGUOUS_INSTITUTION" "BASIS_OF_RECORD_INVALID" "COLLECTION_MATCH_FUZZY" "COLLECTION_MATCH_NONE" "CONTINENT_COORDINATE_MISMATCH" "CONTINENT_COUNTRY_MISMATCH" "CONTINENT_DERIVED_FROM_COORDINATES" "CONTINENT_DERIVED_FROM_COUNTRY" "CONTINENT_INVALID" "COORDINATE_ACCURACY_INVALID" "COORDINATE_INVALID" "COORDINATE_OUT_OF_RANGE" "COORDINATE_PRECISION_INVALID" "COORDINATE_PRECISION_UNCERTAINTY_MISMATCH" "COORDINATE_REPROJECTED" "COORDINATE_REPROJECTION_FAILED" "COORDINATE_REPROJECTION_SUSPICIOUS" "COORDINATE_ROUNDED" "COORDINATE_UNCERTAINTY_METERS_INVALID" "COUNTRY_COORDINATE_MISMATCH" "COUNTRY_DERIVED_FROM_COORDINATES" "COUNTRY_INVALID" "COUNTRY_MISMATCH" "DEPTH_MIN_MAX_SWAPPED" "DEPTH_NON_NUMERIC" "DEPTH_NOT_METRIC" "DEPTH_UNLIKELY" "DIFFERENT_OWNER_INSTITUTION" "ELEVATION_MIN_MAX_SWAPPED" "ELEVATION_NON_NUMERIC" "ELEVATION_NOT_METRIC" "ELEVATION_UNLIKELY" "EON_OR_EONOTHEM_AND_ERA_OR_ERATHEM_MISMATCH" "EON_OR_EONOTHEM_INVALID_RANGE" "EON_OR_EONOTHEM_RANK_MISMATCH" "EPOCH_OR_SERIES_AND_AGE_OR_STAGE_MISMATCH" "EPOCH_OR_SERIES_INFERRED_FROM_PARENT_RANK" "EPOCH_OR_SERIES_INVALID_RANGE" "EPOCH_OR_SERIES_RANK_MISMATCH" "ERA_OR_ERATHEM_AND_PERIOD_OR_SYSTEM_MISMATCH" "ERA_OR_ERATHEM_INFERRED_FROM_PARENT_RANK" "ERA_OR_ERATHEM_INVALID_RANGE" "ERA_OR_ERATHEM_RANK_MISMATCH" "FOOTPRINT_SRS_INVALID" "FOOTPRINT_WKT_INVALID" "FOOTPRINT_WKT_MISMATCH" "GEODETIC_DATUM_ASSUMED_WGS84" "GEODETIC_DATUM_INVALID" "GEOREFERENCED_DATE_INVALID" "GEOREFERENCED_DATE_UNLIKELY" "IDENTIFIED_DATE_INVALID" "IDENTIFIED_DATE_UNLIKELY" "INDIVIDUAL_COUNT_CONFLICTS_WITH_OCCURRENCE_STATUS" "INDIVIDUAL_COUNT_INVALID" "INSTITUTION_COLLECTION_MISMATCH" "INSTITUTION_MATCH_FUZZY" "INSTITUTION_MATCH_NONE" "INTERPRETATION_ERROR" "MODIFIED_DATE_INVALID" "MODIFIED_DATE_UNLIKELY" "MULTIMEDIA_DATE_INVALID" "MULTIMEDIA_URI_INVALID" "OCCURRENCE_STATUS_INFERRED_FROM_BASIS_OF_RECORD" "OCCURRENCE_STATUS_INFERRED_FROM_INDIVIDUAL_COUNT" "OCCURRENCE_STATUS_UNPARSABLE" "PERIOD_OR_SYSTEM_AND_EPOCH_OR_SERIES_MISMATCH" "PERIOD_OR_SYSTEM_INFERRED_FROM_PARENT_RANK" "PERIOD_OR_SYSTEM_INVALID_RANGE" "PERIOD_OR_SYSTEM_RANK_MISMATCH" "POSSIBLY_ON_LOAN" "PRESUMED_NEGATED_LATITUDE" "PRESUMED_NEGATED_LONGITUDE" "PRESUMED_SWAPPED_COORDINATE" "RECORDED_DATE_INVALID" "RECORDED_DATE_MISMATCH" "RECORDED_DATE_UNLIKELY" "REFERENCES_URI_INVALID" "SCIENTIFIC_NAME_AND_ID_INCONSISTENT" "SCIENTIFIC_NAME_ID_NOT_FOUND" "SUSPECTED_TYPE" "TAXON_CONCEPT_ID_NOT_FOUND" "TAXON_ID_NOT_FOUND" "TAXON_MATCH_AGGREGATE" "TAXON_MATCH_FUZZY" "TAXON_MATCH_HIGHERRANK" "TAXON_MATCH_NAME_AND_ID_AMBIGUOUS" "TAXON_MATCH_NONE" "TAXON_MATCH_SCIENTIFIC_NAME_ID_IGNORED" "TAXON_MATCH_TAXON_CONCEPT_ID_IGNORED" "TAXON_MATCH_TAXON_ID_IGNORED" "TYPE_STATUS_INVALID" "ZERO_COORDINATE"] }
def protocol-completer [] { ["ACEF" "BIOCASE" "BIOCASE_XML_ARCHIVE" "BIOM_1_0" "BIOM_2_1" "CAMTRAP_DP" "COLDP" "DIGIR" "DIGIR_MANIS" "DWC_ARCHIVE" "DWC_DP" "EML" "FEED" "OAI_PMH" "OTHER" "TAPIR" "TCS_RDF" "TCS_XML" "TEXT_TREE" "WFS" "WMS"] }
def typeStatus-completer [] { ["ALLOLECTOTYPE" "ALLONEOTYPE" "ALLOTYPE" "COTYPE" "EPITYPE" "EXEPITYPE" "EXHOLOTYPE" "EXISOTYPE" "EXLECTOTYPE" "EXNEOTYPE" "EXPARATYPE" "EXSYNTYPE" "EXTYPE" "HAPANTOTYPE" "HOLOTYPE" "HYPOTYPE" "ICONOTYPE" "ISOLECTOTYPE" "ISONEOTYPE" "ISOPARATYPE" "ISOSYNTYPE" "ISOTYPE" "LECTOTYPE" "NEOTYPE" "NOTATYPE" "ORIGINALMATERIAL" "PARALECTOTYPE" "PARANEOTYPE" "PARATYPE" "PLASTOHOLOTYPE" "PLASTOISOTYPE" "PLASTOLECTOTYPE" "PLASTONEOTYPE" "PLASTOPARATYPE" "PLASTOSYNTYPE" "PLASTOTYPE" "PLESIOTYPE" "SECONDARYTYPE" "SUPPLEMENTARYTYPE" "SYNTYPE" "TOPOTYPE" "TYPE" "TYPE_GENUS" "TYPE_SPECIES"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "occurrence-search searchOccurrence" } } | get name | first)
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

# Occurrence search
#
# GET /occurrence/search
# operationId: searchOccurrence
export def "occurrence-search searchOccurrence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --acceptedTaxonKey: list # A taxon key from the GBIF backbone or the specified checklist (see checklistKey parameter). Only synonym taxa are included in the search, so a search for Aves with acceptedTaxonKey=212 (i.e. [/occurrence/search?taxonKey=212](https://api.gbif.org/v1/occurrence/search?acceptedTaxonKey=212)) will match occurrences identified as birds, but not any known family, genus or species of bird.*Parameter may be repeated.* (e.g. 2476674)
  --associatedSequences: list # Identifier (publication, global unique identifier, URI) of genetic sequence information associated with the material entity.  *Parameter may be repeated.* (e.g. http://www.ncbi.nlm.nih.gov/nuccore/U34853.1)
  --basisOfRecord: list # Basis of record, as defined in our BasisOfRecord vocabulary.  *Parameter may be repeated.* (e.g. PRESERVED_SPECIMEN)
  --bed: list # The full name of the lithostratigraphic bed from which the material entity was collected.  *Parameter may be repeated.* (e.g. Harlem coal)
  --catalogNumber: list # An identifier of any form assigned by the source within a physical collection or digital dataset for the record which may not be unique, but should be fairly unique in combination with the institution and collection code.  *Parameter may be repeated.* (e.g. K001275042)
  --classKey: list # Class classification key.  *Parameter may be repeated.* (e.g. 212)
  --checklistKey: string # *Experimental.* The checklist key. This determines which taxonomy will be used for the search in conjunction with other taxon keys or scientificName. If this is not specified, the GBIF backbone taxonomy will be used. (e.g. 2d59e5db-57ad-41ff-97d6-11f5fb264527)
  --collectionCode: list # An identifier of any form assigned by the source to identify the physical collection or digital dataset uniquely within the context of an institution.  *Parameter may be repeated.* (e.g. F)
  --collectionKey: list # A key (UUID) for a collection registered in the [Global Registry of Scientific Collections](https://www.gbif.org/grscicoll).  *Parameter may be repeated.* (e.g. dceb8d52-094c-4c2c-8960-75e0097c6861)
  --continent: list # Continent, as defined in our Continent vocabulary.  *Parameter may be repeated.* (e.g. EUROPE)
  --coordinateUncertaintyInMeters: string # The horizontal distance (in metres) from the given decimalLatitude and decimalLongitude describing the smallest circle containing the whole of the Location.  *Supports range queries.* (e.g. 0,500)
  --country: list # The 2-letter country code (as per ISO-3166-1) of the country in which the occurrence was recorded.  *Parameter may be repeated.* (e.g. AF)
  --crawlId: list # Crawl attempt that harvested this record.  *Parameter may be repeated.* (e.g. 1)
  --datasetId: list # The ID of the dataset.  *Parameter may be repeated.* (e.g. https://doi.org/10.1594/PANGAEA.315492)
  --datasetKey: list # The occurrence dataset key (a UUID).  *Parameter may be repeated.* (e.g. 13b70480-bd69-11dd-b15f-b8a03c50a862)
  --datasetName: list # The exact name of the dataset.  *Parameter may be repeated.*
  --day: list # The day of the month, a number between 1 and 31.  *Parameter may be repeated or a range.* (e.g. 15)
  --decimalLatitude: string # Latitude in decimal degrees between -90° and 90° based on WGS 84.  *Supports range queries.* (e.g. 40.5,45)
  --degreeOfEstablishment: list # The degree to which an organism survives, reproduces and expands its range at the given place and time, as defined in the [GBIF DegreeOfEstablishment vocabulary](https://registry.gbif.org/vocabulary/DegreeOfEstablishment/concepts).  *Parameter may be repeated.* (e.g. Invasive)
  --decimalLongitude: string # Longitude in decimals between -180 and 180 based on WGS 84.  *Supports range queries.* (e.g. -120,-95.5)
  --depth: string # Depth in metres relative to altitude. For example 10 metres below a lake surface with given altitude.  *Parameter may be repeated or a range.* (e.g. 10,20)
  --distanceFromCentroidInMeters: string # The horizontal distance (in metres) of the occurrence from the nearest centroid known to be used in automated georeferencing procedures, if that distance is 5000m or less.  Occurrences (especially specimens) near a country centroid may have a poor-quality georeference, especially if coordinateUncertaintyInMeters is blank or large.  *Supports range queries.* (e.g. 0,500)
  --dwcaExtension: list # A known Darwin Core Archive extension RowType.  Limits the search to occurrences which have this extension, although they will not necessarily have any useful data recorded using the extension.  *Parameter may be repeated.* (e.g. http://rs.tdwg.org/ac/terms/Multimedia)
  --earliestEonOrLowestEonothem: list # The full name of the earliest possible geochronologic era or lowest chronostratigraphic erathem attributable to the stratigraphic horizon from which the material entity was collected*Parameter may be repeated.* (e.g. Mesozoic)
  --earliestEraOrLowestErathem: list # The full name of the latest possible geochronologic eon or highest chrono-stratigraphic eonothem or the informal name ("Precambrian") attributable to the stratigraphic horizon from which the material entity was collected*Parameter may be repeated.* (e.g. Proterozoic)
  --earliestPeriodOrLowestSystem: list # The full name of the earliest possible geochronologic period or lowest chronostratigraphic system attributable to the stratigraphic horizon from which the material entity was collected*Parameter may be repeated.* (e.g. Neogene)
  --earliestEpochOrLowestSeries: list # The full name of the earliest possible geochronologic epoch or lowest chronostratigraphic series attributable to the stratigraphic horizon from which the material entity was collected*Parameter may be repeated.* (e.g. Holocene)
  --earliestAgeOrLowestStage: list # The full name of the earliest possible geochronologic age or lowest chronostratigraphic stage attributable to the stratigraphic horizon from which the material entity was collected*Parameter may be repeated.* (e.g. Skullrockian)
  --elevation: string # Elevation (altitude) in metres above sea level.  *Parameter may be repeated or a range.* (e.g. 1000,1250)
  --endDayOfYear: list # The latest integer day of the year on which the event occurred.  *Parameter may be repeated.* (e.g. 6)
  --establishmentMeans: list # Whether an organism or organisms have been introduced to a given place and time through the direct or indirect activity of modern humans, as defined in the [GBIF EstablishmentMeans vocabulary](https://registry.gbif.org/vocabulary/EstablishmentMeans/concepts).  *Parameter may be repeated.* (e.g. Native)
  --eventDate: list # Occurrence date in ISO 8601 format: yyyy, yyyy-MM or yyyy-MM-dd.  *Parameter may be repeated or a range.* (e.g. 2000,2001-06-30)
  --eventId: list # An identifier for the information associated with a sampling event.  *Parameter may be repeated.* (e.g. A 123)
  --familyKey: list # Family classification key. (e.g. 2405)
  --fieldNumber: list # An identifier given to the event in the field. Often serves as a link between field notes and the event.  *Parameter may be repeated.* (e.g. RV Sol 87-03-08)
  --formation: list # The full name of the lithostratigraphic formation from which the material entity was collected.  *Parameter may be repeated.* (e.g. Notch Peak Formation)
  --gadmGid: list # A GADM geographic identifier at any level, for example AGO, AGO.1_1, AGO.1.1_1 or AGO.1.1.1_1  *Parameter may be repeated.* (e.g. AGO.1_1)
  --gadmLevel0Gid: list # A GADM geographic identifier at the zero level, for example AGO.  *Parameter may be repeated.* (e.g. AGO)
  --gadmLevel1Gid: list # A GADM geographic identifier at the first level, for example AGO.1_1.  *Parameter may be repeated.* (e.g. AGO.1_1)
  --gadmLevel2Gid: list # A GADM geographic identifier at the second level, for example AFG.1.1_1.  *Parameter may be repeated.* (e.g. AFG.1.1_1)
  --gadmLevel3Gid: list # A GADM geographic identifier at the third level, for example AFG.1.1.1_1.  *Parameter may be repeated.* (e.g. AFG.1.1.1_1)
  --gbifId: int # The unique GBIF key for a single occurrence. (format: int64, e.g. 2005380410)
  --gbifRegion: list # Gbif region based on country code.  *Parameter may be repeated.* (e.g. AFRICA)
  --genusKey: list # Genus classification key. (e.g. 2877951)
  --geoDistance: string # Filters to match occurrence records with coordinate values within a specified distance of a coordinate.  Distance may be specified in kilometres (km) or metres (m). (e.g. 90,100,5km)
  --georeferencedBy: list # Name of a person, group, or organization who determined the georeference (spatial representation) for the location.  *Parameter may be repeated.* (e.g. Brad Millen)
  --geometry: list # Searches for occurrences inside a polygon described in Well Known Text (WKT) format. Only `POLYGON` and `MULTIPOLYGON` are accepted WKT types.  For example, a shape written as `POLYGON ((30.1 10.1, 40 40, 20 40, 10 20, 30.1 10.1))` would be queried as is.  _Polygons must have *anticlockwise* ordering of points._ (A clockwise polygon represents the opposite area: the Earth's surface with a 'hole' in it. Such queries are not supported.)  *Parameter may be repeated.* (e.g. POLYGON ((30.1 10.1, 40 40, 20 40, 10 20, 30.1 10.1)))
  --group: list # The full name of the lithostratigraphic group from which the material entity was collected.  *Parameter may be repeated.* (e.g. Bathurst)
  --hasCoordinate: oneof<nothing, bool> # Limits searches to occurrence records which contain a value in both latitude and longitude (i.e. `hasCoordinate=true` limits to occurrence records with coordinate values and `hasCoordinate=false` limits to occurrence records without coordinate values). (e.g. true)
  --higherGeography: list # Geographic name less specific than the information captured in the locality term.  *Parameter may be repeated.* (e.g. Argentina)
  --highestBiostratigraphicZone: list # The full name of the highest possible geological biostratigraphic zone of the stratigraphic horizon from which the material entity was collected.  *Parameter may be repeated.* (e.g. Blancan)
  --hasGeospatialIssue: oneof<nothing, bool> # Includes/excludes occurrence records which contain spatial issues (as determined in our record interpretation), i.e. hasGeospatialIssue=true returns only those records with spatial issues while hasGeospatialIssue=false includes only records without spatial issues.  The absence of this parameter returns any record with or without spatial issues. (e.g. true)
  --hostingOrganizationKey: list # The key (UUID) of the publishing organization whose installation (server) hosts the original dataset.  (This is of little interest to most data users.)  *Parameter may be repeated.* (e.g. fbca90e3-8aed-48b1-84e3-369afbd000ce)
  --identifiedBy: list # The person who provided the taxonomic identification of the occurrence.  *Parameter may be repeated.* (e.g. Allison)
  --identifiedByID: list # Identifier (e.g. ORCID) for the person who provided the taxonomic identification of the occurrence.  *Parameter may be repeated.* (e.g. https://orcid.org/0000-0001-6492-4016)
  --installationKey: list # The occurrence installation key (a UUID).  (This is of little interest to most data users.  It is the identifier for the server that provided the data to GBIF.)  *Parameter may be repeated.* (e.g. 17a83780-3060-4851-9d6f-029d5fcb81c9)
  --institutionCode: list # An identifier of any form assigned by the source to identify the institution the record belongs to. Not guaranteed to be unique.  *Parameter may be repeated.* (e.g. K)
  --institutionKey: list # A key (UUID) for an institution registered in the [Global Registry of Scientific Collections](https://www.gbif.org/grscicoll).  *Parameter may be repeated.* (e.g. fa252605-26f6-426c-9892-94d071c2c77f)
  --issue: list # A specific interpretation issue as defined in our OccurrenceIssue enumeration.  *Parameter may be repeated.* (e.g. COUNTRY_COORDINATE_MISMATCH)
  --isInCluster: oneof<nothing, bool> # *Experimental.* Searches for records which are part of a cluster.  See the documentation on [clustering](/en/data-processing/clustering-occurrences). (e.g. true)
  --island: list # The name of the island on or near which the location occurs.  *Parameter may be repeated.* (e.g. Zanzibar)
  --islandGroup: list # The name of the island group in which the location occurs.  *Parameter may be repeated.* (e.g. Seychelles)
  --isSequenced: oneof<nothing, bool> # Flag occurrence when associated sequences exists (e.g. true)
  --iucnRedListCategory: list # A threat status category from the IUCN Red List.  The two-letter code for the status should be used.  *Parameter may be repeated.* (e.g. EX)
  --kingdomKey: list # Kingdom classification key.  *Parameter may be repeated.* (e.g. 5)
  --lastInterpreted: list # This date the record was last modified in GBIF, in ISO 8601 format: yyyy, yyyy-MM, yyyy-MM-dd, or MM-dd.  Note that this is the date the record was last changed in GBIF, not necessarily the date the record was first/last changed by the publisher. Data is re-interpreted when we change the taxonomic backbone, geographic data sources, or interpretation processes.  *Parameter may be repeated or a range.* (e.g. 2023-02)
  --latestEonOrHighestEonothem: list # The full name of the latest possible geochronologic eon or highest chrono-stratigraphic eonothem or the informal name ("Precambrian") attributable to the stratigraphic horizon from which the material entity was collected*Parameter may be repeated.* (e.g. Proterozoic)
  --latestEraOrHighestErathem: list # The full name of the latest possible geochronologic era or highest chronostratigraphic erathem attributable to the stratigraphic horizon from which the material entity was collected*Parameter may be repeated.* (e.g. Cenozoic)
  --latestPeriodOrHighestSystem: list # The full name of the latest possible geochronologic period or highest chronostratigraphic system attributable to the stratigraphic horizon from which the material entity was collected*Parameter may be repeated.* (e.g. Neogene)
  --latestEpochOrHighestSeries: list # The full name of the latest possible geochronologic epoch or highest chronostratigraphic series attributable to the stratigraphic horizon from which the material entity was collected*Parameter may be repeated.* (e.g. Pleistocene)
  --latestAgeOrHighestStage: list # The full name of the latest possible geochronologic age or highest chronostratigraphic stage attributable to the stratigraphic horizon from which the material entity was collected.*Parameter may be repeated.* (e.g. Boreal)
  --license: list # The licence applied to the dataset or record by the publisher.  *Parameter may be repeated or a range.* (e.g. CC0_1_0)
  --lifeStage: list # The age class or life stage of an organism at the time the occurrence was recorded, as defined in the GBIF LifeStage vocabulary](https://registry.gbif.org/vocabulary/LifeStage/concepts).  *Parameter may be repeated.* (e.g. Juvenile)
  --locality: list # The specific description of the place.  *Parameter may be repeated.*
  --lowestBiostratigraphicZone: list # The full name of the lowest possible geological biostratigraphic zone of the stratigraphic horizon from which the material entity was collected.  *Parameter may be repeated.* (e.g. Maastrichtian)
  --measurementType: list # The measurement type of the record as it comes in the measurement or fact extension.  *Parameter may be repeated.*
  --measurementTypeID: list # The measurement type ID of the record as it comes in the extended measurement or fact extension.  *Parameter may be repeated.*
  --mediaType: list # The kind of multimedia associated with an occurrence as defined in our MediaType enumeration.  *Parameter may be repeated.*
  --member: list # The full name of the lithostratigraphic member from which the material entity was collected.  *Parameter may be repeated.* (e.g. Lava Dam Member)
  --modified: list # The most recent date-time on which the occurrnce was changed, according to the publisher.  *Parameter may be repeated or a range.* (e.g. 2023-02-20)
  --month: list # The month of the year, starting with 1 for January.  *Parameter may be repeated or a range.* (e.g. 5)
  --networkKey: list # The network's GBIF key (a UUID).  *Parameter may be repeated.* (e.g. 2b7c7b4f-4d4f-40d3-94de-c28b6fa054a6)
  --nucleotideSequencenucleotideSequenceID: list # MD5 hash of the final cleaned sequence.*Parameter may be repeated.*
  --nucleotideSequencetargetGene: list # Normalized gene name using the target_gene vocabulary.*Parameter may be repeated.*
  --nucleotideSequencesequence: list # Final cleaned sequence. null if flagged invalid.*Parameter may be repeated.*
  --nucleotideSequencesequenceLength: list # Length of cleaned sequence in base pairs.*Parameter may be repeated.*
  --nucleotideSequencegcContent: list # GC content (0-1, based on A/C/G/T only).*Parameter may be repeated.*
  --nucleotideSequencenonIupacFraction: list # Fraction of non-IUPAC characters (0-1).*Parameter may be repeated.*
  --nucleotideSequencenonACGTNFraction: list # Fraction of ambiguous IUPAC codes, not A/C/G/T/N (0-1).*Parameter may be repeated.*
  --nucleotideSequencenFraction: list # Fraction of N characters (0-1).*Parameter may be repeated.*
  --nucleotideSequencenRunsCapped: list # Number of N-runs that were capped.*Parameter may be repeated.*
  --nucleotideSequencenaturalLanguageDetected: oneof<nothing, bool> # Whether UNMERGED marker was found.*Parameter may be repeated.*
  --nucleotideSequenceendsTrimmed: oneof<nothing, bool> # Whether ends were trimmed.*Parameter may be repeated.*
  --nucleotideSequencegapsOrWhitespaceRemoved: oneof<nothing, bool> # Whether gaps and/or whitespace were removed.*Parameter may be repeated.*
  --nucleotideSequenceinvalid: oneof<nothing, bool> # nonIupacFraction > 0 and/or naturalLanguageDetected is true.*Parameter may be repeated.*
  --occurrenceId: list # A globally unique identifier for the occurrence record as provided by the publisher.  *Parameter may be repeated.* (e.g. URN:catalog:UWBM:Bird:126493)
  --occurrenceStatus: string@occurrenceStatus-completer # Either `ABSENT` or `PRESENT`; the presence or absence of the occurrence. (e.g. PRESENT)
  --orderKey: list # Order classification key.  *Parameter may be repeated.* (e.g. 1448)
  --organismId: list # An identifier for the organism instance (as opposed to a particular digital record of the organism). May be a globally unique identifier or an identifier specific to the data set.  *Parameter may be repeated.*
  --organismQuantity: list # A number or enumeration value for the quantity of organisms.  *Parameter may be repeated.* (e.g. 1)
  --organismQuantityType: list # The type of quantification system used for the quantity of organisms.  *Note this term is not aligned to a vocabulary.*  *Parameter may be repeated.* (e.g. individuals)
  --otherCatalogNumbers: list # Previous or alternate fully qualified catalog numbers.  *Parameter may be repeated.*
  --parentEventId: list # An identifier for the information associated with a sampling event.  *Parameter may be repeated.* (e.g. A 123)
  --pathway: list # The process by which an organism came to be in a given place at a given time, as defined in the [GBIF Pathway vocabulary](https://registry.gbif.org/vocabulary/Pathway/concepts).  *Parameter may be repeated.* (e.g. Agriculture)
  --phylumKey: list # Phylum classification key.  *Parameter may be repeated.* (e.g. 44)
  --preparations: list # Preparation or preservation method for a specimen.  *Parameter may be repeated.* (e.g. pinned)
  --previousIdentifications: list # Previous assignment of name to the organism.  *Parameter may be repeated.* (e.g. Chalepidae)
  --programme: list # A group of activities, often associated with a specific funding stream, such as the GBIF BID programme.  *Parameter may be repeated.* (e.g. BID)
  --projectId: list # The identifier for a project, which is often assigned by a funded programme.  *Parameter may be repeated.* (e.g. bid-af2020-039-reg)
  --protocol: list # Protocol or mechanism used to provide the occurrence record.  *Parameter may be repeated.* (e.g. DWC_ARCHIVE)
  --publishingCountry: list # The 2-letter country code (as per ISO-3166-1) of the owning organization's country.  *Parameter may be repeated.* (e.g. AD)
  --publishedByGbifRegion: list # GBIF region based on the owning organization's country.  *Parameter may be repeated.* (e.g. AFRICA)
  --publishingOrg: list # The publishing organization's GBIF key (a UUID).  *Parameter may be repeated.* (e.g. e2e717bf-551a-4917-bdc9-4fa0f342c530)
  --recordedBy: list # The person who recorded the occurrence.  *Parameter may be repeated.* (e.g. MiljoStyrelsen)
  --recordedByID: list # Identifier (e.g. ORCID) for the person who recorded the occurrence.  *Parameter may be repeated.* (e.g. https://orcid.org/0000-0003-0623-6682)
  --recordNumber: list # An identifier given to the record at the time it was recorded in the field.  *Parameter may be repeated.* (e.g. 1)
  --relativeOrganismQuantity: list # The relative measurement of the quantity of the organism (i.e. without absolute units).  *Parameter may be repeated.*
  --repatriated: oneof<nothing, bool> # Searches for records whose publishing country is different to the country in which the record was recorded. (e.g. true)
  --sampleSizeUnit: list # The unit of measurement of the size (time duration, length, area, or volume) of a sample in a sampling event.  *Parameter may be repeated.* (e.g. hectares)
  --sampleSizeValue: list # A numeric value for a measurement of the size (time duration, length, area, or volume) of a sample in a sampling event.  *Parameter may be repeated.* (e.g. 50.5)
  --samplingProtocol: list # The name of, reference to, or description of the method or protocol used during a sampling event.  *Parameter may be repeated.* (e.g. malaise trap)
  --sex: list # The sex of the biological individual(s) represented in the occurrence.  *Parameter may be repeated.* (e.g. MALE)
  --scientificName: list # A scientific name from the [GBIF backbone](https://www.gbif.org/dataset/d7dddbf4-2cf0-4f39-9b2a-bb099caae36c) or the specified checklist (see checklistKey parameter). All included and synonym taxa are included in the search.  Under the hood a call to the [species match service](https://www.gbif.org/developer/species#searching) is done first to retrieve a taxonKey. Only unique scientific names will return results, homonyms (many monomials) return nothing! Consider to use the taxonKey parameter instead and the species match service directly.  *Parameter may be repeated.* (e.g. Quercus robur)
  --speciesKey: list # Species classification key.*Parameter may be repeated.* (e.g. 2476674)
  --startDayOfYear: list # The earliest integer day of the year on which the event occurred.  *Parameter may be repeated.* (e.g. 5)
  --stateProvince: list # The name of the next smaller administrative region than country (state, province, canton, department, region, etc.) in which the Location occurs.  This term does not have any data quality checks; see also the GADM parameters.  *Parameter may be repeated.* (e.g. Leicestershire)
  --taxonConceptId: list # An identifier for the taxonomic concept to which the record refers - not for the nomenclatural details of a taxon.  *Parameter may be repeated.* (e.g. 8fa58e08-08de-4ac1-b69c-1235340b7001)
  --taxonKey: list # A taxon key from the GBIF backbone or the specified checklist (see checklistKey parameter). All included (child) and synonym taxa are included in the search, so a search for Aves with taxonKey=212 (i.e. [/occurrence/search?taxonKey=212](https://api.gbif.org/v1/occurrence/search?taxonKey=212)) will match all birds, no matter which species.*Parameter may be repeated.* (e.g. 2476674)
  --taxonId: list # The taxon identifier provided to GBIF by the data publisher.  *Parameter may be repeated.* (e.g. urn:lsid:dyntaxa.se:Taxon:103026)
  --taxonomicIssue: list # *Experimental.* A specific taxonomic interpretation issue as defined in our OccurrenceIssue enumeration.  *Parameter may be repeated.* (e.g. TAXON_CONCEPT_ID_NOT_FOUND)
  --taxonomicStatus: list # A taxonomic status from our TaxonomicStatus enumeration.  *Parameter may be repeated.* (e.g. SYNONYM)
  --typeStatus: list # Nomenclatural type (type status, typified scientific name, publication) applied to the subject.  *Parameter may be repeated.* (e.g. HOLOTYPE)
  --verbatimScientificName: list # The scientific name provided to GBIF by the data publisher, before interpretation and processing by GBIF.  *Parameter may be repeated.* (e.g. Quercus robur L.)
  --waterBody: list # The name of the water body in which the Locations occurs.  *Parameter may be repeated.* (e.g. Lake Michigan)
  --year: list # The 4 digit year. A year of 98 will be interpreted as AD 98.  *Parameter may be repeated or a range.* (e.g. 1998)
  --geologicalTime: string # The geological time of an occurrence that is present in the chronostratigraphy terms. *Parameter may be repeated or a range.* (e.g. Mesozoic)
  --lithostratigraphy: string # The lithostratigraphy of an occurrence that is present in the group, formation, member and bed terms (e.g. Wayne Fm)
  --biostratigraphy: string # The biostratigraphy of an occurrence that is present in the lowest and highest biostratigraphy terms (e.g. Rhynchonella cuvieri Zone)
  --matchCase: oneof<nothing, bool> # *Experimental.* Indicates if the search has to be case sensitive (e.g. true)
  --shuffle: string # *Experimental.* Seed to sort the results randomly. (e.g. abcdefgh)
  --hl: oneof<nothing, bool> # Set `hl=true` to highlight terms matching the query when in full-text search fields. The highlight will be an emphasis tag of class `gbifH1` e.g. [`/search?q=plant&hl=true`](https://api.gbif.org/v1/literature/search?q=plant&hl=true).  Full-text search fields include: title, keyword, country, publishing country, publishing organization title, hosting organization title, and description. One additional full text field is searched which includes information from metadata documents, but the text of this field is not returned in the response. (e.g. true)
  --q: string # Simple full-text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the maximum threshold, which is 300 for this service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. This service has a maximum offset of 100,000. (format: int32)
  --facet: string # A facet name used to retrieve the most frequent values for a field. Facets are allowed for all search parameters except geometry and geoDistance. This parameter may by repeated to request multiple facets, as in [this example](https://api.gbif.org/v1/occurrence/search?facet=datasetKey&facet=basisOfRecord&limit=0).  Note terms not available for searching are not available for faceting.
  --facetMincount: int # Used in combination with the facet parameter. Set facetMincount={#} to exclude facets with a count less than {#}, e.g. [/search?facet=basisOfRecord&limit=0&facetMincount=10000](https://api.gbif.org/v1/occurrence/search?facet=basisOfRecord&limit=0&facetMincount=1000000]. (format: int32)
  --facetMultiselect: oneof<nothing, bool> # Used in combination with the facet parameter. Set facetMultiselect=true to still return counts for values that are not currently filtered, e.g. [/search?facet=basisOfRecord&limit=0&basisOfRecord=HUMAN_OBSERVATION&facetMultiselect=true](https://api.gbif.org/v1/occurrence/search?facet=basisOfRecord&limit=0&basisOfRecord=HUMAN_OBSERVATION&facetMultiselect=true) still shows Basis of Record values 'PRESERVED_SPECIMEN' and so on, even though Basis of Record is being filtered.
  --facetLimit: int # Facet parameters allow paging requests using the parameters facetOffset and facetLimit (format: int32)
  --facetOffset: int # Facet parameters allow paging requests using the parameters facetOffset and facetLimit (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, datasetKey: string, publishingOrgKey: string, networkKeys: list, installationKey: string, hostingOrganizationKey: string, publishingCountry: string, protocol: string, lastCrawled: string, lastParsed: string, crawlId: int, projectId: string, programmeAcronym: string, extensions: record, basisOfRecord: string, individualCount: int, occurrenceStatus: string, sex: string, lifeStage: string, establishmentMeans: string, degreeOfEstablishment: string, pathway: string, classifications: record, taxonKey: int, kingdomKey: int, phylumKey: int, classKey: int, orderKey: int, familyKey: int, genusKey: int, subgenusKey: int, speciesKey: int, acceptedTaxonKey: int, scientificName: string, scientificNameAuthorship: string, acceptedScientificName: string, kingdom: string, phylum: string, order: string, family: string, genus: string, subgenus: string, species: string, genericName: string, specificEpithet: string, infraspecificEpithet: string, taxonRank: string, taxonomicStatus: string, iucnRedListCategory: string, dateIdentified: string, decimalLatitude: float, decimalLongitude: float, coordinatePrecision: float, coordinateUncertaintyInMeters: float, coordinateAccuracy: float, elevation: float, elevationAccuracy: float, depth: float, depthAccuracy: float, continent: string, stateProvince: string, gadm: record, waterBody: string, distanceFromCentroidInMeters: float, higherGeography: string, georeferencedBy: string, year: int, month: int, day: int, eventDate: record, startDayOfYear: int, endDayOfYear: int, typeStatus: string, typifiedName: string, issues: list, modified: string, lastInterpreted: string, references: string, license: string, organismQuantity: float, organismQuantityType: string, sampleSizeUnit: string, sampleSizeValue: float, relativeOrganismQuantity: float, isSequenced: bool, associatedSequences: string, identifiers: list, media: list, facts: list, relations: list, institutionKey: string, collectionKey: string, isInCluster: bool, datasetID: string, datasetName: string, otherCatalogNumbers: string, earliestEonOrLowestEonothem: string, latestEonOrHighestEonothem: string, earliestEraOrLowestErathem: string, latestEraOrHighestErathem: string, earliestPeriodOrLowestSystem: string, latestPeriodOrHighestSystem: string, earliestEpochOrLowestSeries: string, latestEpochOrHighestSeries: string, earliestAgeOrLowestStage: string, latestAgeOrHighestStage: string, lowestBiostratigraphicZone: string, highestBiostratigraphicZone: string, group: string, formation: string, member: string, bed: string, recordedBy: string, identifiedBy: string, preparations: string, samplingProtocol: string, dnaSequenceID: list, nucleotideSequence: list, verbatimScientificName: string, geodeticDatum: string, class: string, countryCode: string, recordedByIDs: list, identifiedByIDs: list, gbifRegion: string, country: string, publishedByGbifRegion: string>, facets: table<field: string, counts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "acceptedTaxonKey" $acceptedTaxonKey "multi") (serialize-qp "associatedSequences" $associatedSequences "multi") (serialize-qp "basisOfRecord" $basisOfRecord "multi") (serialize-qp "bed" $bed "multi") (serialize-qp "catalogNumber" $catalogNumber "multi") (serialize-qp "classKey" $classKey "multi") (serialize-qp "checklistKey" $checklistKey "scalar") (serialize-qp "collectionCode" $collectionCode "multi") (serialize-qp "collectionKey" $collectionKey "multi") (serialize-qp "continent" $continent "multi") (serialize-qp "coordinateUncertaintyInMeters" $coordinateUncertaintyInMeters "scalar") (serialize-qp "country" $country "multi") (serialize-qp "crawlId" $crawlId "multi") (serialize-qp "datasetId" $datasetId "multi") (serialize-qp "datasetKey" $datasetKey "multi") (serialize-qp "datasetName" $datasetName "multi") (serialize-qp "day" $day "multi") (serialize-qp "decimalLatitude" $decimalLatitude "scalar") (serialize-qp "degreeOfEstablishment" $degreeOfEstablishment "multi") (serialize-qp "decimalLongitude" $decimalLongitude "scalar") (serialize-qp "depth" $depth "scalar") (serialize-qp "distanceFromCentroidInMeters" $distanceFromCentroidInMeters "scalar") (serialize-qp "dwcaExtension" $dwcaExtension "multi") (serialize-qp "earliestEonOrLowestEonothem" $earliestEonOrLowestEonothem "multi") (serialize-qp "earliestEraOrLowestErathem" $earliestEraOrLowestErathem "multi") (serialize-qp "earliestPeriodOrLowestSystem" $earliestPeriodOrLowestSystem "multi") (serialize-qp "earliestEpochOrLowestSeries" $earliestEpochOrLowestSeries "multi") (serialize-qp "earliestAgeOrLowestStage" $earliestAgeOrLowestStage "multi") (serialize-qp "elevation" $elevation "scalar") (serialize-qp "endDayOfYear" $endDayOfYear "multi") (serialize-qp "establishmentMeans" $establishmentMeans "multi") (serialize-qp "eventDate" $eventDate "multi") (serialize-qp "eventId" $eventId "multi") (serialize-qp "familyKey" $familyKey "multi") (serialize-qp "fieldNumber" $fieldNumber "multi") (serialize-qp "formation" $formation "multi") (serialize-qp "gadmGid" $gadmGid "multi") (serialize-qp "gadmLevel0Gid" $gadmLevel0Gid "multi") (serialize-qp "gadmLevel1Gid" $gadmLevel1Gid "multi") (serialize-qp "gadmLevel2Gid" $gadmLevel2Gid "multi") (serialize-qp "gadmLevel3Gid" $gadmLevel3Gid "multi") (serialize-qp "gbifId" $gbifId "scalar") (serialize-qp "gbifRegion" $gbifRegion "multi") (serialize-qp "genusKey" $genusKey "multi") (serialize-qp "geoDistance" $geoDistance "scalar") (serialize-qp "georeferencedBy" $georeferencedBy "multi") (serialize-qp "geometry" $geometry "multi") (serialize-qp "group" $group "multi") (serialize-qp "hasCoordinate" $hasCoordinate "scalar") (serialize-qp "higherGeography" $higherGeography "multi") (serialize-qp "highestBiostratigraphicZone" $highestBiostratigraphicZone "multi") (serialize-qp "hasGeospatialIssue" $hasGeospatialIssue "scalar") (serialize-qp "hostingOrganizationKey" $hostingOrganizationKey "multi") (serialize-qp "identifiedBy" $identifiedBy "multi") (serialize-qp "identifiedByID" $identifiedByID "multi") (serialize-qp "installationKey" $installationKey "multi") (serialize-qp "institutionCode" $institutionCode "multi") (serialize-qp "institutionKey" $institutionKey "multi") (serialize-qp "issue" $issue "multi") (serialize-qp "isInCluster" $isInCluster "scalar") (serialize-qp "island" $island "multi") (serialize-qp "islandGroup" $islandGroup "multi") (serialize-qp "isSequenced" $isSequenced "scalar") (serialize-qp "iucnRedListCategory" $iucnRedListCategory "multi") (serialize-qp "kingdomKey" $kingdomKey "multi") (serialize-qp "lastInterpreted" $lastInterpreted "multi") (serialize-qp "latestEonOrHighestEonothem" $latestEonOrHighestEonothem "multi") (serialize-qp "latestEraOrHighestErathem" $latestEraOrHighestErathem "multi") (serialize-qp "latestPeriodOrHighestSystem" $latestPeriodOrHighestSystem "multi") (serialize-qp "latestEpochOrHighestSeries" $latestEpochOrHighestSeries "multi") (serialize-qp "latestAgeOrHighestStage" $latestAgeOrHighestStage "multi") (serialize-qp "license" $license "multi") (serialize-qp "lifeStage" $lifeStage "multi") (serialize-qp "locality" $locality "multi") (serialize-qp "lowestBiostratigraphicZone" $lowestBiostratigraphicZone "multi") (serialize-qp "measurementType" $measurementType "multi") (serialize-qp "measurementTypeID" $measurementTypeID "multi") (serialize-qp "mediaType" $mediaType "multi") (serialize-qp "member" $member "multi") (serialize-qp "modified" $modified "multi") (serialize-qp "month" $month "multi") (serialize-qp "networkKey" $networkKey "multi") (serialize-qp "nucleotideSequence.nucleotideSequenceID" $nucleotideSequencenucleotideSequenceID "multi") (serialize-qp "nucleotideSequence.targetGene" $nucleotideSequencetargetGene "multi") (serialize-qp "nucleotideSequence.sequence" $nucleotideSequencesequence "multi") (serialize-qp "nucleotideSequence.sequenceLength" $nucleotideSequencesequenceLength "multi") (serialize-qp "nucleotideSequence.gcContent" $nucleotideSequencegcContent "multi") (serialize-qp "nucleotideSequence.nonIupacFraction" $nucleotideSequencenonIupacFraction "multi") (serialize-qp "nucleotideSequence.nonACGTNFraction" $nucleotideSequencenonACGTNFraction "multi") (serialize-qp "nucleotideSequence.nFraction" $nucleotideSequencenFraction "multi") (serialize-qp "nucleotideSequence.nRunsCapped" $nucleotideSequencenRunsCapped "multi") (serialize-qp "nucleotideSequence.naturalLanguageDetected" $nucleotideSequencenaturalLanguageDetected "scalar") (serialize-qp "nucleotideSequence.endsTrimmed" $nucleotideSequenceendsTrimmed "scalar") (serialize-qp "nucleotideSequence.gapsOrWhitespaceRemoved" $nucleotideSequencegapsOrWhitespaceRemoved "scalar") (serialize-qp "nucleotideSequence.invalid" $nucleotideSequenceinvalid "scalar") (serialize-qp "occurrenceId" $occurrenceId "multi") (serialize-qp "occurrenceStatus" $occurrenceStatus "scalar") (serialize-qp "orderKey" $orderKey "multi") (serialize-qp "organismId" $organismId "multi") (serialize-qp "organismQuantity" $organismQuantity "multi") (serialize-qp "organismQuantityType" $organismQuantityType "multi") (serialize-qp "otherCatalogNumbers" $otherCatalogNumbers "multi") (serialize-qp "parentEventId" $parentEventId "multi") (serialize-qp "pathway" $pathway "multi") (serialize-qp "phylumKey" $phylumKey "multi") (serialize-qp "preparations" $preparations "multi") (serialize-qp "previousIdentifications" $previousIdentifications "multi") (serialize-qp "programme" $programme "multi") (serialize-qp "projectId" $projectId "multi") (serialize-qp "protocol" $protocol "multi") (serialize-qp "publishingCountry" $publishingCountry "multi") (serialize-qp "publishedByGbifRegion" $publishedByGbifRegion "multi") (serialize-qp "publishingOrg" $publishingOrg "multi") (serialize-qp "recordedBy" $recordedBy "multi") (serialize-qp "recordedByID" $recordedByID "multi") (serialize-qp "recordNumber" $recordNumber "multi") (serialize-qp "relativeOrganismQuantity" $relativeOrganismQuantity "multi") (serialize-qp "repatriated" $repatriated "scalar") (serialize-qp "sampleSizeUnit" $sampleSizeUnit "multi") (serialize-qp "sampleSizeValue" $sampleSizeValue "multi") (serialize-qp "samplingProtocol" $samplingProtocol "multi") (serialize-qp "sex" $sex "multi") (serialize-qp "scientificName" $scientificName "multi") (serialize-qp "speciesKey" $speciesKey "multi") (serialize-qp "startDayOfYear" $startDayOfYear "multi") (serialize-qp "stateProvince" $stateProvince "multi") (serialize-qp "taxonConceptId" $taxonConceptId "multi") (serialize-qp "taxonKey" $taxonKey "multi") (serialize-qp "taxonId" $taxonId "multi") (serialize-qp "taxonomicIssue" $taxonomicIssue "multi") (serialize-qp "taxonomicStatus" $taxonomicStatus "multi") (serialize-qp "typeStatus" $typeStatus "multi") (serialize-qp "verbatimScientificName" $verbatimScientificName "multi") (serialize-qp "waterBody" $waterBody "multi") (serialize-qp "year" $year "multi") (serialize-qp "geologicalTime" $geologicalTime "scalar") (serialize-qp "lithostratigraphy" $lithostratigraphy "scalar") (serialize-qp "biostratigraphy" $biostratigraphy "scalar") (serialize-qp "matchCase" $matchCase "scalar") (serialize-qp "shuffle" $shuffle "scalar") (serialize-qp "hl" $hl "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "facet" $facet "scalar") (serialize-qp "facetMincount" $facetMincount "scalar") (serialize-qp "facetMultiselect" $facetMultiselect "scalar") (serialize-qp "facetLimit" $facetLimit "scalar") (serialize-qp "facetOffset" $facetOffset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Requests the creation of a download file.
#
# POST /occurrence/download/request
# operationId: requestDownload
export def "occurrence-download-request requestDownload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --predicate: any # A predicate defining the filters to apply to the download.
  --creator: string # The GBIF username of the initiator of the download request.
  --notificationAddresses: list
  --sendNotification: oneof<nothing, bool> # Whether to send a notification email when the download finishes.
  --format: string@format-completer # The data format of the download.
  --description: string # A user-specified description of the download, such as the intended purpose or a tag for later reference.
  --machineDescription: any
  --verbatimExtensions: list
  --interpretedExtensions: list
  --checklistKey: string
  --sql: string # An SQL query defining the filter and output for the download.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/download/request")
  let body = {predicate: $predicate, creator: $creator, notificationAddresses: $notificationAddresses, sendNotification: $sendNotification, format: $format, description: $description, machineDescription: $machineDescription, verbatimExtensions: $verbatimExtensions, interpretedExtensions: $interpretedExtensions, checklistKey: $checklistKey, sql: $sql} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "text/plain")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the resulting download file
#
# GET /occurrence/download/request/{key}
# operationId: retrieveDownload
export def "occurrence-download-request retrieveDownload" [
  key: string
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
  let full_url = (build-url $base $"/occurrence/download/request/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a running download
#
# DELETE /occurrence/download/request/{key}
# operationId: cancelDownload
export def "occurrence-download-request cancelDownload" [
  key: string
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
  let full_url = (build-url $base $"/occurrence/download/request/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Experimental** Validates the SQL contained in an SQL download request.
#
# POST /occurrence/download/request/validate
# operationId: validateDownloadRequest
export def "occurrence-download-request-validate validateDownloadRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sql: string # An SQL query defining the filter and output for the download.
  --creator: string # The GBIF username of the initiator of the download request.
  --notificationAddresses: list
  --sendNotification: oneof<nothing, bool> # Whether to send a notification email when the download finishes.
  --format: string@format-completer # The data format of the download.
  --description: string # A user-specified description of the download, such as the intended purpose or a tag for later reference.
  --machineDescription: any
  --checklistKey: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/download/request/validate")
  let body = {sql: $sql, creator: $creator, notificationAddresses: $notificationAddresses, sendNotification: $sendNotification, format: $format, description: $description, machineDescription: $machineDescription, checklistKey: $checklistKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Converts a plain search query into a download predicate.
#
# GET /occurrence/download/request/predicate
# operationId: searchToPredicate
export def "occurrence-download-request-predicate searchToPredicate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --notification-address: string # Email notification address.
  --format: string # Download format.
  --verbatimExtensions: string # Verbatim extensions to include in a Darwin Core Archive download.
  --interpretedExtensions: string
  --description: string
  --machineDescription: string
  --checklistKey: string # *Experimental.* The checklist to use that will supply interpreted taxonomic fields. The default is to use the GBIF Backbone.download.
]: nothing -> record<creator: string, notificationAddresses: list<string>, sendNotification: bool, format: string, description: string, machineDescription: any, checklistKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notification_address" $notification_address "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "verbatimExtensions" $verbatimExtensions "scalar") (serialize-qp "interpretedExtensions" $interpretedExtensions "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "machineDescription" $machineDescription "scalar") (serialize-qp "checklistKey" $checklistKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/download/request/predicate" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Converts a plain search query into an SQL download predicate.
#
# GET /occurrence/download/request/sql
# operationId: searchToSql
export def "occurrence-download-request-sql searchToSql" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --notification-address: string
  --description: string
  --machineDescription: string
  --checklistKey: string
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notification_address" $notification_address "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "machineDescription" $machineDescription "scalar") (serialize-qp "checklistKey" $checklistKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/download/request/sql" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Converts a predicate download request into an SQL download request.
#
# POST /occurrence/download/request/sql
# operationId: searchToSql_1
export def "occurrence-download-request-sql searchToSql-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --predicate: any # A predicate defining the filters to apply to the download.
  --creator: string # The GBIF username of the initiator of the download request.
  --notificationAddresses: list
  --sendNotification: oneof<nothing, bool> # Whether to send a notification email when the download finishes.
  --format: string@format-completer # The data format of the download.
  --description: string # A user-specified description of the download, such as the intended purpose or a tag for later reference.
  --machineDescription: any
  --verbatimExtensions: list
  --interpretedExtensions: list
  --checklistKey: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/download/request/sql")
  let body = {predicate: $predicate, creator: $creator, notificationAddresses: $notificationAddresses, sendNotification: $sendNotification, format: $format, description: $description, machineDescription: $machineDescription, verbatimExtensions: $verbatimExtensions, interpretedExtensions: $interpretedExtensions, checklistKey: $checklistKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Occurrence by id
#
# GET /occurrence/{gbifId}
# operationId: getOccurrenceById
export def "occurrence list" [
  gbifId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<key: int, datasetKey: string, publishingOrgKey: string, networkKeys: list<string>, installationKey: string, hostingOrganizationKey: string, publishingCountry: string, protocol: string, lastCrawled: string, lastParsed: string, crawlId: int, projectId: string, programmeAcronym: string, extensions: record, basisOfRecord: string, individualCount: int, occurrenceStatus: string, sex: string, lifeStage: string, establishmentMeans: string, degreeOfEstablishment: string, pathway: string, classifications: record, taxonKey: int, kingdomKey: int, phylumKey: int, classKey: int, orderKey: int, familyKey: int, genusKey: int, subgenusKey: int, speciesKey: int, acceptedTaxonKey: int, scientificName: string, scientificNameAuthorship: string, acceptedScientificName: string, kingdom: string, phylum: string, order: string, family: string, genus: string, subgenus: string, species: string, genericName: string, specificEpithet: string, infraspecificEpithet: string, taxonRank: string, taxonomicStatus: string, iucnRedListCategory: string, dateIdentified: string, decimalLatitude: float, decimalLongitude: float, coordinatePrecision: float, coordinateUncertaintyInMeters: float, coordinateAccuracy: float, elevation: float, elevationAccuracy: float, depth: float, depthAccuracy: float, continent: string, stateProvince: string, gadm: record<level0: record<gid: string, name: string>, level1: record<gid: string, name: string>, level2: record<gid: string, name: string>, level3: record<gid: string, name: string>>, waterBody: string, distanceFromCentroidInMeters: float, higherGeography: string, georeferencedBy: string, year: int, month: int, day: int, eventDate: record<from: any, to: any>, startDayOfYear: int, endDayOfYear: int, typeStatus: string, typifiedName: string, issues: list<string>, modified: string, lastInterpreted: string, references: string, license: string, organismQuantity: float, organismQuantityType: string, sampleSizeUnit: string, sampleSizeValue: float, relativeOrganismQuantity: float, isSequenced: bool, associatedSequences: string, identifiers: table<identifier: string, title: string, type: string, identifierLink: string>, media: table<type: string, format: string, references: string, title: string, description: string, source: string, audience: string, created: string, creator: string, contributor: string, publisher: string, license: string, rightsHolder: string, identifier: string>, facts: table<id: string, type: string, value: string, unit: string, accuracy: string, method: string, determinedBy: string, determinedDate: string, remarks: string>, relations: table<id: string, occurrenceId: int, relatedOccurrenceId: int, type: string, accordingTo: string, establishedDate: string, remarks: string>, institutionKey: string, collectionKey: string, isInCluster: bool, datasetID: string, datasetName: string, otherCatalogNumbers: string, earliestEonOrLowestEonothem: string, latestEonOrHighestEonothem: string, earliestEraOrLowestErathem: string, latestEraOrHighestErathem: string, earliestPeriodOrLowestSystem: string, latestPeriodOrHighestSystem: string, earliestEpochOrLowestSeries: string, latestEpochOrHighestSeries: string, earliestAgeOrLowestStage: string, latestAgeOrHighestStage: string, lowestBiostratigraphicZone: string, highestBiostratigraphicZone: string, group: string, formation: string, member: string, bed: string, recordedBy: string, identifiedBy: string, preparations: string, samplingProtocol: string, dnaSequenceID: list<string>, nucleotideSequence: table<nucleotideSequenceID: string, targetGene: string, sequence: string, sequenceLength: int, gcContent: float, nonIupacFraction: float, nonACGTNFraction: float, getnFraction: float, getnRunsCapped: int, naturalLanguageDetected: bool, endsTrimmed: bool, gapsOrWhitespaceRemoved: bool, invalid: bool>, verbatimScientificName: string, geodeticDatum: string, class: string, countryCode: string, recordedByIDs: table<type: string, value: string>, identifiedByIDs: table<type: string, value: string>, gbifRegion: string, country: string, publishedByGbifRegion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/occurrence/($gbifId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Occurrence search using predicates
#
# POST /occurrence/search/predicate
# operationId: predicateSearchOccurrence
export def "occurrence-search-predicate predicateSearchOccurrence" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --predicate: any
]: any -> record<endOfRecords: bool, count: int, results: table<key: int, datasetKey: string, publishingOrgKey: string, networkKeys: list, installationKey: string, hostingOrganizationKey: string, publishingCountry: string, protocol: string, lastCrawled: string, lastParsed: string, crawlId: int, projectId: string, programmeAcronym: string, extensions: record, basisOfRecord: string, individualCount: int, occurrenceStatus: string, sex: string, lifeStage: string, establishmentMeans: string, degreeOfEstablishment: string, pathway: string, classifications: record, taxonKey: int, kingdomKey: int, phylumKey: int, classKey: int, orderKey: int, familyKey: int, genusKey: int, subgenusKey: int, speciesKey: int, acceptedTaxonKey: int, scientificName: string, scientificNameAuthorship: string, acceptedScientificName: string, kingdom: string, phylum: string, order: string, family: string, genus: string, subgenus: string, species: string, genericName: string, specificEpithet: string, infraspecificEpithet: string, taxonRank: string, taxonomicStatus: string, iucnRedListCategory: string, dateIdentified: string, decimalLatitude: float, decimalLongitude: float, coordinatePrecision: float, coordinateUncertaintyInMeters: float, coordinateAccuracy: float, elevation: float, elevationAccuracy: float, depth: float, depthAccuracy: float, continent: string, stateProvince: string, gadm: record, waterBody: string, distanceFromCentroidInMeters: float, higherGeography: string, georeferencedBy: string, year: int, month: int, day: int, eventDate: record, startDayOfYear: int, endDayOfYear: int, typeStatus: string, typifiedName: string, issues: list, modified: string, lastInterpreted: string, references: string, license: string, organismQuantity: float, organismQuantityType: string, sampleSizeUnit: string, sampleSizeValue: float, relativeOrganismQuantity: float, isSequenced: bool, associatedSequences: string, identifiers: list, media: list, facts: list, relations: list, institutionKey: string, collectionKey: string, isInCluster: bool, datasetID: string, datasetName: string, otherCatalogNumbers: string, earliestEonOrLowestEonothem: string, latestEonOrHighestEonothem: string, earliestEraOrLowestErathem: string, latestEraOrHighestErathem: string, earliestPeriodOrLowestSystem: string, latestPeriodOrHighestSystem: string, earliestEpochOrLowestSeries: string, latestEpochOrHighestSeries: string, earliestAgeOrLowestStage: string, latestAgeOrHighestStage: string, lowestBiostratigraphicZone: string, highestBiostratigraphicZone: string, group: string, formation: string, member: string, bed: string, recordedBy: string, identifiedBy: string, preparations: string, samplingProtocol: string, dnaSequenceID: list, nucleotideSequence: list, verbatimScientificName: string, geodeticDatum: string, class: string, countryCode: string, recordedByIDs: list, identifiedByIDs: list, gbifRegion: string, country: string, publishedByGbifRegion: string>, facets: table<field: string, counts: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/search/predicate")
  let body = {predicate: $predicate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Occurrence by dataset key and occurrence id
#
# GET /occurrence/{datasetKey}/{occurrenceId}
# operationId: getOccurrenceByDatasetKeyAndOccurrenceId
export def "occurrence get" [
  datasetKey: string
  occurrenceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<key: int, datasetKey: string, publishingOrgKey: string, networkKeys: list<string>, installationKey: string, hostingOrganizationKey: string, publishingCountry: string, protocol: string, lastCrawled: string, lastParsed: string, crawlId: int, projectId: string, programmeAcronym: string, extensions: record, basisOfRecord: string, individualCount: int, occurrenceStatus: string, sex: string, lifeStage: string, establishmentMeans: string, degreeOfEstablishment: string, pathway: string, classifications: record, taxonKey: int, kingdomKey: int, phylumKey: int, classKey: int, orderKey: int, familyKey: int, genusKey: int, subgenusKey: int, speciesKey: int, acceptedTaxonKey: int, scientificName: string, scientificNameAuthorship: string, acceptedScientificName: string, kingdom: string, phylum: string, order: string, family: string, genus: string, subgenus: string, species: string, genericName: string, specificEpithet: string, infraspecificEpithet: string, taxonRank: string, taxonomicStatus: string, iucnRedListCategory: string, dateIdentified: string, decimalLatitude: float, decimalLongitude: float, coordinatePrecision: float, coordinateUncertaintyInMeters: float, coordinateAccuracy: float, elevation: float, elevationAccuracy: float, depth: float, depthAccuracy: float, continent: string, stateProvince: string, gadm: record<level0: record<gid: string, name: string>, level1: record<gid: string, name: string>, level2: record<gid: string, name: string>, level3: record<gid: string, name: string>>, waterBody: string, distanceFromCentroidInMeters: float, higherGeography: string, georeferencedBy: string, year: int, month: int, day: int, eventDate: record<from: any, to: any>, startDayOfYear: int, endDayOfYear: int, typeStatus: string, typifiedName: string, issues: list<string>, modified: string, lastInterpreted: string, references: string, license: string, organismQuantity: float, organismQuantityType: string, sampleSizeUnit: string, sampleSizeValue: float, relativeOrganismQuantity: float, isSequenced: bool, associatedSequences: string, identifiers: table<identifier: string, title: string, type: string, identifierLink: string>, media: table<type: string, format: string, references: string, title: string, description: string, source: string, audience: string, created: string, creator: string, contributor: string, publisher: string, license: string, rightsHolder: string, identifier: string>, facts: table<id: string, type: string, value: string, unit: string, accuracy: string, method: string, determinedBy: string, determinedDate: string, remarks: string>, relations: table<id: string, occurrenceId: int, relatedOccurrenceId: int, type: string, accordingTo: string, establishedDate: string, remarks: string>, institutionKey: string, collectionKey: string, isInCluster: bool, datasetID: string, datasetName: string, otherCatalogNumbers: string, earliestEonOrLowestEonothem: string, latestEonOrHighestEonothem: string, earliestEraOrLowestErathem: string, latestEraOrHighestErathem: string, earliestPeriodOrLowestSystem: string, latestPeriodOrHighestSystem: string, earliestEpochOrLowestSeries: string, latestEpochOrHighestSeries: string, earliestAgeOrLowestStage: string, latestAgeOrHighestStage: string, lowestBiostratigraphicZone: string, highestBiostratigraphicZone: string, group: string, formation: string, member: string, bed: string, recordedBy: string, identifiedBy: string, preparations: string, samplingProtocol: string, dnaSequenceID: list<string>, nucleotideSequence: table<nucleotideSequenceID: string, targetGene: string, sequence: string, sequenceLength: int, gcContent: float, nonIupacFraction: float, nonACGTNFraction: float, getnFraction: float, getnRunsCapped: int, naturalLanguageDetected: bool, endsTrimmed: bool, gapsOrWhitespaceRemoved: bool, invalid: bool>, verbatimScientificName: string, geodeticDatum: string, class: string, countryCode: string, recordedByIDs: table<type: string, value: string>, identifiedByIDs: table<type: string, value: string>, gbifRegion: string, country: string, publishedByGbifRegion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/occurrence/($datasetKey)/($occurrenceId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Occurrence fragment by id
#
# GET /occurrence/{gbifId}/fragment
# operationId: getOccurrenceFragmentById
export def "occurrence-fragment list" [
  gbifId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/occurrence/($gbifId)/fragment")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Occurrence fragment by dataset key and occurrence id
#
# GET /occurrence/{datasetKey}/{occurrenceId}/fragment
# operationId: getOccurrenceFragmentByDatasetKeyAndOccurrenceId
export def "occurrence-fragment get" [
  datasetKey: string
  occurrenceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-2 # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/occurrence/($datasetKey)/($occurrenceId)/fragment")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verbatim occurrence by id
#
# GET /occurrence/{gbifId}/verbatim
# operationId: getVerbatimOccurrenceById
export def "occurrence-verbatim list" [
  gbifId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<key: int, datasetKey: string, publishingOrgKey: string, networkKeys: list<string>, installationKey: string, hostingOrganizationKey: string, publishingCountry: string, protocol: string, lastCrawled: string, lastParsed: string, crawlId: int, projectId: string, programmeAcronym: string, extensions: record, publishedByGbifRegion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/occurrence/($gbifId)/verbatim")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verbatim occurrence by dataset key and occurrence id
#
# GET /occurrence/{datasetKey}/{occurrenceId}/verbatim
# operationId: getVerbatimOccurrenceByDatasetKeyAndOccurrenceId
export def "occurrence-verbatim get" [
  datasetKey: string
  occurrenceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<key: int, datasetKey: string, publishingOrgKey: string, networkKeys: list<string>, installationKey: string, hostingOrganizationKey: string, publishingCountry: string, protocol: string, lastCrawled: string, lastParsed: string, crawlId: int, projectId: string, programmeAcronym: string, extensions: record, publishedByGbifRegion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/occurrence/($datasetKey)/($occurrenceId)/verbatim")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Related occurrences by gbifId
#
# GET /occurrence/{gbifId}/experimental/related
# operationId: experimentalGetRelatedOccurrences
export def "occurrence-experimental-related experimentalGetRelatedOccurrences" [
  gbifId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/occurrence/($gbifId)/experimental/related")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest catalogue numbers
#
# GET /occurrence/search/catalogNumber
# operationId: suggestCatalogNumbers
export def "occurrence-search-catalog-number suggestCatalogNumbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/catalogNumber" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest collection codes
#
# GET /occurrence/search/collectionCode
# operationId: suggestCollectionCodes
export def "occurrence-search-collection-code suggestCollectionCodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/collectionCode" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest dataset names
#
# GET /occurrence/search/datasetName
# operationId: suggestDatasetNames
export def "occurrence-search-dataset-name suggestDatasetNames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/datasetName" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest event ids
#
# GET /occurrence/search/eventId
# operationId: suggestEventIds
export def "occurrence-search-event-id suggestEventIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/eventId" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest identified by values
#
# GET /occurrence/search/identifiedBy
# operationId: suggestIdentifiedBy
export def "occurrence-search-identified-by suggestIdentifiedBy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/identifiedBy" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest institution codes
#
# GET /occurrence/search/institutionCode
# operationId: suggestInstitutionCodes
export def "occurrence-search-institution-code suggestInstitutionCodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # format: int32
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/institutionCode" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest locality strings
#
# GET /occurrence/search/locality
# operationId: suggestLocalities
export def "occurrence-search-locality suggestLocalities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/locality" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest occurrence ids
#
# GET /occurrence/search/occurrenceId
# operationId: suggestOccurrenceIds
export def "occurrence-search-occurrence-id suggestOccurrenceIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/occurrenceId" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest organism ids
#
# GET /occurrence/search/organismId
# operationId: suggestOrganismIds
export def "occurrence-search-organism-id suggestOrganismIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/organismId" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest other catalogue numbers
#
# GET /occurrence/search/otherCatalogNumbers
# operationId: suggestOtherCatalogNumbers
export def "occurrence-search-other-catalog-numbers suggestOtherCatalogNumbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/otherCatalogNumbers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest parent event ids
#
# GET /occurrence/search/parentEventId
# operationId: suggestParentEventIds
export def "occurrence-search-parent-event-id suggestParentEventIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/parentEventId" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest record numbers
#
# GET /occurrence/search/recordNumber
# operationId: suggestRecordNumbers
export def "occurrence-search-record-number suggestRecordNumbers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/recordNumber" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest recorded by values
#
# GET /occurrence/search/recordedBy
# operationId: suggestRecordedBy
export def "occurrence-search-recorded-by suggestRecordedBy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/recordedBy" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest sampling protocols
#
# GET /occurrence/search/samplingProtocol
# operationId: suggestSamplingProtocols
export def "occurrence-search-sampling-protocol suggestSamplingProtocols" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/samplingProtocol" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest states/provinces
#
# GET /occurrence/search/stateProvince
# operationId: suggestStateProvinces
export def "occurrence-search-state-province suggestStateProvinces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/stateProvince" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest water bodies
#
# GET /occurrence/search/waterBody
# operationId: suggestWaterBodies
export def "occurrence-search-water-body suggestWaterBodies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --q: string # Simple search suggestion parameter. Wildcards are not supported. (e.g. A)
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/search/waterBody" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest values for supported terms
#
# GET /occurrence/search/experimental/term/{term}
# operationId: suggestTerm
export def "occurrence-search-experimental-term suggestTerm" [
  term: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --term: string@term-completer # A supported term (e.g. Continent)
  --q: string
  --limit: int # Controls the number of suggestions. (format: int32, e.g. 5)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occurrence/search/experimental/term/($term)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Experimental.** Describes the fields present in a Darwin Core Archive format download
#
# GET /occurrence/download/describe/dwca
# operationId: describeDwcaDownload
export def "occurrence-download-describe-dwca describeDwcaDownload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<verbatim: record<fields: list<record>>, multimedia: record<fields: list<record>>, interpreted: record<fields: list<record>>, verbatimExtensions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/download/describe/dwca")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Experimental.** Describes the fields present in a Simple Avro format download
#
# GET /occurrence/download/describe/simpleAvro
# operationId: describeSimpleAvroDownload
export def "occurrence-download-describe-simple-avro describeSimpleAvroDownload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: table<name: string, type: string, typeFormat: string, delimiter: string, term: record, nullable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/download/describe/simpleAvro")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Experimental.** Describes the fields present in a Simple CSV format download
#
# GET /occurrence/download/describe/simpleCsv
# operationId: describeSimpleCsvDownload
export def "occurrence-download-describe-simple-csv describeSimpleCsvDownload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: table<name: string, type: string, typeFormat: string, delimiter: string, term: record, nullable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/download/describe/simpleCsv")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Experimental.** Describes the fields present in a Simple Parquet format download
#
# GET /occurrence/download/describe/simpleParquet
# operationId: describeSimpleParquetDownload
export def "occurrence-download-describe-simple-parquet describeSimpleParquetDownload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: table<name: string, type: string, typeFormat: string, delimiter: string, term: record, nullable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/download/describe/simpleParquet")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Experimental.** Describes the fields present in a Species List format download
#
# GET /occurrence/download/describe/speciesList
# operationId: describeSpeciesListDownload
export def "occurrence-download-describe-species-list describeSpeciesListDownload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: table<name: string, type: string, typeFormat: string, delimiter: string, term: record, nullable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/download/describe/speciesList")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Very experimental.** Describes the fields available for searching or download when using an SQL query.
#
# GET /occurrence/download/describe/sql
# operationId: describeSqlDownload
export def "occurrence-download-describe-sql describeSqlDownload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fields: table<name: string, type: string, typeFormat: string, delimiter: string, term: record, nullable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/download/describe/sql")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /
#
# operationId: index
export def "home-resource index" [
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
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /occurrence/experimental/multimedia/species/{taxonKey}
#
# operationId: listMultimediaBySpecies
export def "occurrence-experimental-multimedia-species listMultimediaBySpecies" [
  taxonKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --mediaType: string
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> record<taxonKey: string, mediaType: string, count: int, endOfRecords: bool, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mediaType" $mediaType "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occurrence/experimental/multimedia/species/($taxonKey)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /occurrence/experimental/multimedia/species/{checklistKey}/{taxonKey}
#
# operationId: listMultimediaBySpecies_1
export def "occurrence-experimental-multimedia-species listMultimediaBySpecies-by-checklistKey-taxonKey" [
  checklistKey: string
  taxonKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --mediaType: string
  --limit: int # format: int32
  --offset: int # format: int32
]: nothing -> record<taxonKey: string, mediaType: string, count: int, endOfRecords: bool, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mediaType" $mediaType "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occurrence/experimental/multimedia/species/($checklistKey)/($taxonKey)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Occurrence terms
#
# GET /occurrence/term
# operationId: occurrenceTerms
export def "occurrence-term occurrenceTerms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<simpleName: string, qualifiedName: string, group: string, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/term")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Information about an occurrence download
#
# GET /occurrence/download/{key}
# operationId: getOccurrenceDownloadByKey
export def "occurrence-download list" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statistics: oneof<nothing, bool> # If true it also shows number of organizations and countries.
]: nothing -> record<key: string, doi: string, license: string, request: record<creator: string, notificationAddresses: list<string>, sendNotification: bool, format: string, description: string, machineDescription: any, checklistKey: string>, created: string, modified: string, eraseAfter: string, erasureNotification: string, status: string, downloadLink: string, size: int, totalRecords: int, numberDatasets: int, numberOrganizations: int, numberPublishingCountries: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statistics" $statistics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occurrence/download/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Information about an occurrence download
#
# GET /occurrence/download/{prefix}/{suffix}
# operationId: getOccurrenceDownloadByDOI
export def "occurrence-download get" [
  prefix: string
  suffix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, doi: string, license: string, request: record<creator: string, notificationAddresses: list<string>, sendNotification: bool, format: string, description: string, machineDescription: any, checklistKey: string>, created: string, modified: string, eraseAfter: string, erasureNotification: string, status: string, downloadLink: string, size: int, totalRecords: int, numberDatasets: int, numberOrganizations: int, numberPublishingCountries: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/occurrence/download/($prefix)/($suffix)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all occurrence downloads from a user
#
# GET /occurrence/download/user/{user}
# operationId: listOccurrenceDownloadsByUser
export def "occurrence-download-user listOccurrenceDownloadsByUser" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: record
  --status: list
  --qp-from: string # format: date-time
  --statistics: oneof<nothing, bool> # default: true
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, doi: string, license: string, request: record, created: string, modified: string, eraseAfter: string, erasureNotification: string, status: string, downloadLink: string, size: int, totalRecords: int, numberDatasets: int, numberOrganizations: int, numberPublishingCountries: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "multi") (serialize-qp "status" $status "multi") (serialize-qp "from" $qp_from "scalar") (serialize-qp "statistics" $statistics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occurrence/download/user/($user)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Counts all downloads from a user
#
# GET /occurrence/download/user/{user}/count
# operationId: countOccurrenceDownloadsByUser
export def "occurrence-download-user-count countOccurrenceDownloadsByUser" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: list
  --qp-from: string # format: date-time
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "multi") (serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occurrence/download/user/($user)/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists datasets present in an occurrence download
#
# GET /occurrence/download/{prefix}/{suffix}/datasets
# operationId: listDatasetUsagesByOccurrenceDownloadDOI
export def "occurrence-download-datasets listDatasetUsagesByOccurrenceDownloadDOI" [
  prefix: string
  suffix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<downloadKey: string, datasetKey: string, datasetTitle: string, datasetDOI: string, datasetCitation: string, numberRecords: int, download: record, publishingCountryCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occurrence/download/($prefix)/($suffix)/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists countries present in an occurrence download
#
# GET /occurrence/download/{key}/countries
# operationId: listCountryUsagesByOccurrenceDownloadKey
export def "occurrence-download-countries listCountryUsagesByOccurrenceDownloadKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sortBy: string@sortBy-completer
  --sortOrder: string@sortOrder-completer
  --page: record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "page" $page "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/occurrence/download/($key)/countries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists datasets present in an occurrence download
#
# GET /occurrence/download/{key}/datasets
# operationId: listDatasetUsagesByOccurrenceDownloadKey
export def "occurrence-download-datasets listDatasetUsagesByOccurrenceDownloadKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --datasetTitle: string
  --sortBy: string@sortBy-completer-1
  --sortOrder: string@sortOrder-completer
  --page: record
]: nothing -> record<endOfRecords: bool, count: int, results: table<downloadKey: string, datasetKey: string, datasetTitle: string, datasetDOI: string, datasetCitation: string, numberRecords: int, download: record, publishingCountryCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasetTitle" $datasetTitle "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "page" $page "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/occurrence/download/($key)/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists organizations present in an occurrence download
#
# GET /occurrence/download/{key}/organizations
# operationId: listOrganizationUsagesByOccurrenceDownloadKey
export def "occurrence-download-organizations listOrganizationUsagesByOccurrenceDownloadKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationTitle: string
  --sortBy: string@sortBy-completer-2
  --sortOrder: string@sortOrder-completer
  --page: record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organizationTitle" $organizationTitle "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "page" $page "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/occurrence/download/($key)/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exports datasets present in an occurrence download in TSV or CSV format
#
# GET /occurrence/download/{key}/datasets/export
# operationId: exportDatasetUsagesByOccurrenceDownloadKey
export def "occurrence-download-datasets-export exportDatasetUsagesByOccurrenceDownloadKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer-1 # The export format.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occurrence/download/($key)/datasets/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shows the citation for an occurrence download
#
# GET /occurrence/download/{key}/citation
# operationId: getOccurrenceDownloadCitationByKey
export def "occurrence-download-citation list" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/occurrence/download/($key)/citation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shows the citation for an occurrence download
#
# GET /occurrence/download/{prefix}/{suffix}/citation
# operationId: getOccurrenceDownloadCitationByDOI
export def "occurrence-download-citation get" [
  prefix: string
  suffix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/occurrence/download/($prefix)/($suffix)/citation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Provides summarized download statistics
#
# GET /occurrence/download/statistics
# operationId: getOccurrenceDownloadedStatistics
export def "occurrence-download-statistics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromDate: string # format: date-time
  --toDate: string # format: date-time
  --publishingCountry: string@publishingCountry-completer
  --datasetKey: string # format: uuid
  --publishingOrgKey: string # format: uuid
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<datasetKey: string, totalRecords: int, numberDownloads: int, year: int, month: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "publishingCountry" $publishingCountry "scalar") (serialize-qp "datasetKey" $datasetKey "scalar") (serialize-qp "publishingOrgKey" $publishingOrgKey "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/download/statistics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export summary of occurrence downloads
#
# GET /occurrence/download/statistics/export
# operationId: exportOccurrenceDownloadedStatistics
export def "occurrence-download-statistics-export exportOccurrenceDownloadedStatistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer-1 # default: TSV
  --fromDate: string # format: date-time
  --toDate: string # format: date-time
  --publishingCountry: string@publishingCountry-completer
  --datasetKey: string # format: uuid
  --publishingOrgKey: string # format: uuid
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "publishingCountry" $publishingCountry "scalar") (serialize-qp "datasetKey" $datasetKey "scalar") (serialize-qp "publishingOrgKey" $publishingOrgKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/download/statistics/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Summarizes downloads by month, grouped by the user's country, territory or island
#
# GET /occurrence/download/statistics/downloadsByUserCountry
# operationId: getOccurrenceDownloadsByUserCountry
export def "occurrence-download-statistics-downloads-by-user-country get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromDate: string # The year and month (YYYY-MM) to start from. (format: date-time)
  --toDate: string # The year and month (YYYY-MM) to end at. (format: date-time)
  --userCountry: string@userCountry-completer # The ISO 3166-2 code for the user's country, territory or island.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "userCountry" $userCountry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/download/statistics/downloadsByUserCountry" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Summarize downloaded records by dataset
#
# GET /occurrence/download/statistics/downloadedRecordsByDataset
# operationId: getOccurrenceDownloadedRecordsByDataset
export def "occurrence-download-statistics-downloaded-records-by-dataset get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromDate: string # format: date-time
  --toDate: string # format: date-time
  --publishingCountry: string@publishingCountry-completer
  --datasetKey: string # format: uuid
  --publishingOrgKey: string # format: uuid
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "publishingCountry" $publishingCountry "scalar") (serialize-qp "datasetKey" $datasetKey "scalar") (serialize-qp "publishingOrgKey" $publishingOrgKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/download/statistics/downloadedRecordsByDataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Summarize downloads by dataset
#
# GET /occurrence/download/statistics/downloadsByDataset
# operationId: getOccurrenceDownloadedRecordsByDataset_1
export def "occurrence-download-statistics-downloads-by-dataset get-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromDate: string # format: date-time
  --toDate: string # format: date-time
  --publishingCountry: string@publishingCountry-completer
  --datasetKey: string # format: uuid
  --publishingOrgKey: string # format: uuid
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "publishingCountry" $publishingCountry "scalar") (serialize-qp "datasetKey" $datasetKey "scalar") (serialize-qp "publishingOrgKey" $publishingOrgKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/download/statistics/downloadsByDataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Summarize downloaded record totals by source
#
# GET /occurrence/download/statistics/downloadsBySource
# operationId: getOccurrenceDownloadedRecordsBySource
export def "occurrence-download-statistics-downloads-by-source get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromDate: string # The year and month (YYYY-MM) to start from. (format: date-time)
  --toDate: string # The year and month (YYYY-MM) to end at. (format: date-time)
  --qp-source: string # Restrict to a particular source
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/download/statistics/downloadsBySource" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the downloads activity of a dataset.
#
# GET /occurrence/download/dataset/{datasetKey}
# operationId: getDatasetDownloadActivity
export def "occurrence-download-dataset get" [
  datasetKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --showDownloadDetails: oneof<nothing, bool> # Flag to indicate if we want the download details in the response. It defaults to true to keep backwards compatibility. (default: true)
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<downloadKey: string, datasetKey: string, datasetTitle: string, datasetDOI: string, datasetCitation: string, numberRecords: int, download: record, publishingCountryCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "showDownloadDetails" $showDownloadDetails "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/occurrence/download/dataset/($datasetKey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Subdivisions of a GADM region
#
# GET /geocode/gadm/{gid}/subdivisions
# operationId: getGadmSubdivisions
export def "geocode-gadm-subdivisions get" [
  gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query for (sub)divisions matching a wildcard.
]: nothing -> table<id: string, name: string, gadmLevel: int, variantName: list<string>, nonLatinName: list<string>, type: list<string>, englishType: list<string>, higherRegions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geocode/gadm/($gid)/subdivisions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Details for a GADM region
#
# GET /geocode/gadm/{gid}
# operationId: getGadmRegion
export def "geocode-gadm get" [
  gid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, gadmLevel: int, variantName: list<string>, nonLatinName: list<string>, type: list<string>, englishType: list<string>, higherRegions: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/geocode/gadm/($gid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for GADM regions.
#
# GET /geocode/gadm/search
# operationId: gadmRegionSearch
export def "geocode-gadm-search gadmRegionSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query for (sub)divisions matching a wildcard.
  --gadmLevel: string # Limit to subdivisions at this level. (e.g. 2)
  --gadmGid: string # Limit to subdivisions of this GADM region. (e.g. SLV.4_1)
  --page: record
]: nothing -> record<offset: int, limit: int, endOfRecords: bool, count: int, results: table<id: string, name: string, gadmLevel: int, variantName: list, nonLatinName: list, type: list, englishType: list, higherRegions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "gadmLevel" $gadmLevel "scalar") (serialize-qp "gadmGid" $gadmGid "scalar") (serialize-qp "page" $page "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/geocode/gadm/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Third-level subdivisions of a GADM region
#
# GET /geocode/gadm/browse/{level0}/{level1}/{level2}
# operationId: gadmRegionBrowseLevel3
export def "geocode-gadm-browse gadmRegionBrowseLevel3" [
  level0: string
  level1: string
  level2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query for (sub)divisions matching a wildcard.
]: nothing -> table<id: string, name: string, gadmLevel: int, variantName: list<string>, nonLatinName: list<string>, type: list<string>, englishType: list<string>, higherRegions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geocode/gadm/browse/($level0)/($level1)/($level2)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Second-level subdivisions of a GADM region
#
# GET /geocode/gadm/browse/{level0}/{level1}
# operationId: gadmRegionBrowseLevel2
export def "geocode-gadm-browse gadmRegionBrowseLevel2" [
  level0: string
  level1: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query for (sub)divisions matching a wildcard.
]: nothing -> table<id: string, name: string, gadmLevel: int, variantName: list<string>, nonLatinName: list<string>, type: list<string>, englishType: list<string>, higherRegions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geocode/gadm/browse/($level0)/($level1)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# First-level subdivisions of a GADM region
#
# GET /geocode/gadm/browse/{level0}
# operationId: gadmRegionBrowseLevel1
export def "geocode-gadm-browse gadmRegionBrowseLevel1" [
  level0: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query for (sub)divisions matching a wildcard.
]: nothing -> table<id: string, name: string, gadmLevel: int, variantName: list<string>, nonLatinName: list<string>, type: list<string>, englishType: list<string>, higherRegions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/geocode/gadm/browse/($level0)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all top-level GADM regions
#
# GET /geocode/gadm/browse
# operationId: gadmRegionBrowseLevel0
export def "geocode-gadm-browse gadmRegionBrowseLevel0" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Query for (sub)divisions matching a wildcard.
]: nothing -> table<id: string, name: string, gadmLevel: int, variantName: list<string>, nonLatinName: list<string>, type: list<string>, englishType: list<string>, higherRegions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocode/gadm/browse" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Occurrence counts
#
# GET /occurrence/count
# operationId: getOccurrenceCount
export def "occurrence-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --arg0: string
  --basisOfRecord: string@basisOfRecord-completer # Count records with a particular basisOfRecord.
  --country: string@country-completer # Count records in the given country.
  --datasetKey: string # Count records in a dataset. (format: uuid)
  --isGeoreferenced: oneof<nothing, bool> # Count only georeferenced (or not) records.
  --issue: string@issue-completer # Count only records with this issue.
  --protocol: string@protocol-completer # Count records retrieved using the chosen protocol.
  --publishingCountry: string@publishingCountry-completer # Count records published by the given country.
  --taxonKey: string # Count records of a particular taxon.
  --typeStatus: string@typeStatus-completer # Count records with this type status.
  --year: int # Count records from this year to current year or given range (format: int32)
  --checklistKey: string # *Experimental.* The checklist key. This determines which taxonomy will be used for the search in conjunction with other taxon keys. If this is not specified, the GBIF backbone taxonomy will be used.
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "arg0" $arg0 "scalar") (serialize-qp "basisOfRecord" $basisOfRecord "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "datasetKey" $datasetKey "scalar") (serialize-qp "isGeoreferenced" $isGeoreferenced "scalar") (serialize-qp "issue" $issue "scalar") (serialize-qp "protocol" $protocol "scalar") (serialize-qp "publishingCountry" $publishingCountry "scalar") (serialize-qp "taxonKey" $taxonKey "scalar") (serialize-qp "typeStatus" $typeStatus "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "checklistKey" $checklistKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Supported occurrence count metrics
#
# GET /occurrence/count/schema
# operationId: getOccurrenceCountSchema
export def "occurrence-count-schema get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<dimensions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/count/schema")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Occurrence inventory by basis of record
#
# GET /occurrence/counts/basisOfRecord
# operationId: getOccurrenceInventoryBasisOfRecord
export def "occurrence-counts-basis-of-record get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/occurrence/counts/basisOfRecord")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Occurrence inventory by year
#
# GET /occurrence/counts/year
# operationId: getOccurrenceInventoryYear
export def "occurrence-counts-year get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --year: string # Limit to occurrences from a particular year or range of years. (e.g. 1981,1991)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/counts/year" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Occurrence inventory by dataset
#
# GET /occurrence/counts/datasets
# operationId: getOccurrenceInventoryDataset
export def "occurrence-counts-datasets get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string # Limit to occurrences in an ISO 3166 country or area.
  --nubKey: int # format: int32
  --taxonKey: string # Limit to occurrences of a particular taxon.
  --checklistKey: string # *Experimental.* The checklist key. This determines which taxonomy will be used for the search in conjunction with other taxon keys. If this is not specified, the GBIF backbone taxonomy will be used.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "nubKey" $nubKey "scalar") (serialize-qp "taxonKey" $taxonKey "scalar") (serialize-qp "checklistKey" $checklistKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/counts/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Occurrence inventory by country
#
# GET /occurrence/counts/countries
# operationId: getOccurrenceInventoryCountry
export def "occurrence-counts-countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --publishingCountry: string # Limit to data published by a particular country.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "publishingCountry" $publishingCountry "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/counts/countries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Occurrence inventory by publishing country
#
# GET /occurrence/counts/publishingCountries
# operationId: getOccurrenceInventoryPublishingCountry
export def "occurrence-counts-publishing-countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string # Count only occurrences from a country or area.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/occurrence/counts/publishingCountries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
