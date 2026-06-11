# Auto-generated client for Registry API vv1
# Source: https://techdocs.gbif.org/openapi/registry.json
# Auth: --token flag or $env.REGISTRY_API_TOKEN

const BASE_URL = "https://api.gbif.org/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o REGISTRY_API_TOKEN | default "" }
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
def source-completer [] { ["DATASET" "IH_IRN" "ORGANIZATION"] }
def identifierType-completer [] { ["CITES" "CLB_DATASET_KEY" "DOI" "FTP" "GBIF_NODE" "GBIF_PARTICIPANT" "GBIF_PORTAL" "GRID" "GRSCICOLL_ID" "GRSCICOLL_URI" "HANDLER" "IH_IRN" "ISIL" "LSID" "NCBI_BIOCOLLECTION" "RNC_COLOMBIA" "ROR" "SYMBIOTA_UUID" "UNKNOWN" "URI" "URL" "UUID" "WIKIDATA"] }
def country-completer [] { ["AA" "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "XK" "XZ" "YE" "YT" "ZA" "ZM" "ZW" "ZZ"] }
def gbifRegion-completer [] { ["AFRICA" "ANTARCTICA" "ASIA" "EUROPE" "LATIN_AMERICA" "NORTH_AMERICA" "OCEANIA"] }
def masterSourceType-completer [] { ["GBIF_REGISTRY" "GRSCICOLL" "IH"] }
def sortBy-completer [] { ["NUMBER_SPECIMENS"] }
def sortOrder-completer [] { ["ASC" "DESC"] }
def masterSource-completer [] { ["GBIF_REGISTRY" "GRSCICOLL" "IH"] }
def featuredImageLicense-completer [] { ["CC0_1_0" "CC_BY_4_0" "CC_BY_NC_4_0" "UNSPECIFIED" "UNSUPPORTED"] }
def type-completer [] { ["CHECKLIST" "METADATA" "OCCURRENCE" "SAMPLING_EVENT"] }
def subtype-completer [] { ["DERIVED_FROM_OCCURRENCE" "GLOBAL_SPECIES_DATASET" "INVENTORY_REGIONAL" "INVENTORY_THEMATIC" "NOMENCLATOR_AUTHORITY" "OBSERVATION" "SPECIMEN" "TAXONOMIC_AUTHORITY"] }
def language-completer [] { ["" "aar" "abk" "afr" "aka" "amh" "ara" "arg" "asm" "ava" "ave" "aym" "aze" "bak" "bam" "bel" "ben" "bih" "bis" "bod" "bos" "bre" "bul" "cat" "ces" "cha" "che" "chu" "chv" "cor" "cos" "cre" "cym" "dan" "deu" "div" "dzo" "ell" "eng" "epo" "est" "eus" "ewe" "fao" "fas" "fij" "fin" "fra" "fry" "ful" "gla" "gle" "glg" "glv" "grn" "guj" "hat" "hau" "heb" "her" "hin" "hmo" "hrv" "hun" "hye" "ibo" "ido" "iii" "iku" "ile" "ina" "ind" "ipk" "isl" "ita" "jav" "jpn" "kal" "kan" "kas" "kat" "kau" "kaz" "khm" "kik" "kin" "kir" "kom" "kon" "kor" "kua" "kur" "lao" "lat" "lav" "lim" "lin" "lit" "ltz" "lub" "lug" "mah" "mal" "mar" "mkd" "mlg" "mlt" "mol" "mon" "mri" "msa" "mya" "nau" "nav" "nbl" "nde" "ndo" "nep" "nld" "nno" "nob" "nor" "nya" "oci" "oji" "ori" "orm" "oss" "pan" "pli" "pol" "por" "pus" "que" "roh" "ron" "run" "rus" "sag" "san" "sin" "slk" "slv" "sme" "smo" "sna" "snd" "som" "sot" "spa" "sqi" "srd" "srp" "ssw" "sun" "swa" "swe" "tah" "tam" "tat" "tel" "tgk" "tgl" "tha" "tir" "ton" "tsn" "tso" "tuk" "tur" "twi" "uig" "ukr" "urd" "uzb" "ven" "vie" "vol" "wln" "wol" "xho" "yid" "yor" "zha" "zho" "zul"] }
def type-completer-1 [] { ["BIOCASE_INSTALLATION" "DIGIR_INSTALLATION" "EARTHCAPE_INSTALLATION" "HTTP_INSTALLATION" "IPT_INSTALLATION" "MDT_INSTALLATION" "SYMBIOTA_INSTALLATION" "TAPIR_INSTALLATION"] }
def endorsementStatus-completer [] { ["ENDORSED" "ON_HOLD" "REJECTED" "WAITING_FOR_ENDORSEMENT"] }
def publishingCountry-completer [] { ["AA" "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "XK" "XZ" "YE" "YT" "ZA" "ZM" "ZW" "ZZ"] }
def hostingCountry-completer [] { ["AA" "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "XK" "XZ" "YE" "YT" "ZA" "ZM" "ZW" "ZZ"] }
def continent-completer [] { ["AFRICA" "ANTARCTICA" "ASIA" "EUROPE" "NORTH_AMERICA" "OCEANIA" "SOUTH_AMERICA"] }
def license-completer [] { ["CC0_1_0" "CC_BY_4_0" "CC_BY_NC_4_0" "UNSPECIFIED" "UNSUPPORTED"] }
def endpointType-completer [] { ["ACEF" "BIOCASE" "BIOCASE_XML_ARCHIVE" "BIOM_1_0" "BIOM_2_1" "CAMTRAP_DP" "COLDP" "DIGIR" "DIGIR_MANIS" "DWC_ARCHIVE" "DWC_DP" "EML" "FEED" "OAI_PMH" "OTHER" "TAPIR" "TCS_RDF" "TCS_XML" "TEXT_TREE" "WFS" "WMS"] }
def format-completer [] { ["CSV" "TSV"] }
def usageRank-completer [] { ["ABERRATION" "BIOVAR" "CHEMOFORM" "CHEMOVAR" "CLASS" "COHORT" "CONVARIETY" "CULTIVAR" "CULTIVAR_GROUP" "DOMAIN" "FAMILY" "FORM" "FORMA_SPECIALIS" "GENUS" "GRANDORDER" "GREX" "INFRACLASS" "INFRACOHORT" "INFRAFAMILY" "INFRAGENERIC_NAME" "INFRAGENUS" "INFRAKINGDOM" "INFRALEGION" "INFRAORDER" "INFRAPHYLUM" "INFRASPECIFIC_NAME" "INFRASUBSPECIFIC_NAME" "INFRATRIBE" "KINGDOM" "LEGION" "MAGNORDER" "MORPH" "MORPHOVAR" "NATIO" "ORDER" "OTHER" "PARVCLASS" "PARVORDER" "PATHOVAR" "PHAGOVAR" "PHYLUM" "PROLES" "RACE" "SECTION" "SERIES" "SEROVAR" "SPECIES" "SPECIES_AGGREGATE" "STRAIN" "SUBCLASS" "SUBCOHORT" "SUBFAMILY" "SUBFORM" "SUBGENUS" "SUBKINGDOM" "SUBLEGION" "SUBORDER" "SUBPHYLUM" "SUBSECTION" "SUBSERIES" "SUBSPECIES" "SUBTRIBE" "SUBVARIETY" "SUPERCLASS" "SUPERCOHORT" "SUPERFAMILY" "SUPERKINGDOM" "SUPERLEGION" "SUPERORDER" "SUPERPHYLUM" "SUPERTRIBE" "SUPRAGENERIC_NAME" "TRIBE" "UNRANKED" "VARIETY"] }
def type-completer-2 [] { ["DC" "EML"] }
def type-completer-3 [] { ["CONVERSION_TO_COLLECTION" "CREATE" "DELETE" "MERGE" "UPDATE"] }
def status-completer [] { ["APPLIED" "DISCARDED" "PENDING"] }
def type-completer-4 [] { ["ADDITIONAL_DELEGATE" "ADMINISTRATIVE_POINT_OF_CONTACT" "AUTHOR" "CONTENT_PROVIDER" "CURATOR" "CUSTODIAN_STEWARD" "DATA_ADMINISTRATOR" "DISTRIBUTOR" "EDITOR" "HEAD_OF_DELEGATION" "METADATA_AUTHOR" "NODE_MANAGER" "NODE_STAFF" "ORIGINATOR" "OWNER" "POINT_OF_CONTACT" "PRINCIPAL_INVESTIGATOR" "PROCESSOR" "PROGRAMMER" "PUBLISHER" "REGIONAL_NODE_REPRESENTATIVE" "REVIEWER" "SYSTEM_ADMINISTRATOR" "TECHNICAL_POINT_OF_CONTACT" "TEMPORARY_DELEGATE" "TEMPORARY_HEAD_OF_DELEGATION" "USER"] }
def type-completer-5 [] { ["ACEF" "BIOCASE" "BIOCASE_XML_ARCHIVE" "BIOM_1_0" "BIOM_2_1" "CAMTRAP_DP" "COLDP" "DIGIR" "DIGIR_MANIS" "DWC_ARCHIVE" "DWC_DP" "EML" "FEED" "OAI_PMH" "OTHER" "TAPIR" "TCS_RDF" "TCS_XML" "TEXT_TREE" "WFS" "WMS"] }
def type-completer-6 [] { ["CITES" "CLB_DATASET_KEY" "DOI" "FTP" "GBIF_NODE" "GBIF_PARTICIPANT" "GBIF_PORTAL" "GRID" "GRSCICOLL_ID" "GRSCICOLL_URI" "HANDLER" "IH_IRN" "ISIL" "LSID" "NCBI_BIOCOLLECTION" "RNC_COLOMBIA" "ROR" "SYMBIOTA_UUID" "UNKNOWN" "URI" "URL" "UUID" "WIKIDATA"] }
def entityCountry-completer [] { ["AA" "AD" "AE" "AF" "AG" "AI" "AL" "AM" "AO" "AQ" "AR" "AS" "AT" "AU" "AW" "AX" "AZ" "BA" "BB" "BD" "BE" "BF" "BG" "BH" "BI" "BJ" "BL" "BM" "BN" "BO" "BQ" "BR" "BS" "BT" "BV" "BW" "BY" "BZ" "CA" "CC" "CD" "CF" "CG" "CH" "CI" "CK" "CL" "CM" "CN" "CO" "CR" "CU" "CV" "CW" "CX" "CY" "CZ" "DE" "DJ" "DK" "DM" "DO" "DZ" "EC" "EE" "EG" "EH" "ER" "ES" "ET" "FI" "FJ" "FK" "FM" "FO" "FR" "GA" "GB" "GD" "GE" "GF" "GG" "GH" "GI" "GL" "GM" "GN" "GP" "GQ" "GR" "GS" "GT" "GU" "GW" "GY" "HK" "HM" "HN" "HR" "HT" "HU" "ID" "IE" "IL" "IM" "IN" "IO" "IQ" "IR" "IS" "IT" "JE" "JM" "JO" "JP" "KE" "KG" "KH" "KI" "KM" "KN" "KP" "KR" "KW" "KY" "KZ" "LA" "LB" "LC" "LI" "LK" "LR" "LS" "LT" "LU" "LV" "LY" "MA" "MC" "MD" "ME" "MF" "MG" "MH" "MK" "ML" "MM" "MN" "MO" "MP" "MQ" "MR" "MS" "MT" "MU" "MV" "MW" "MX" "MY" "MZ" "NA" "NC" "NE" "NF" "NG" "NI" "NL" "NO" "NP" "NR" "NU" "NZ" "OM" "PA" "PE" "PF" "PG" "PH" "PK" "PL" "PM" "PN" "PR" "PS" "PT" "PW" "PY" "QA" "RE" "RO" "RS" "RU" "RW" "SA" "SB" "SC" "SD" "SE" "SG" "SH" "SI" "SJ" "SK" "SL" "SM" "SN" "SO" "SR" "SS" "ST" "SV" "SX" "SY" "SZ" "TC" "TD" "TF" "TG" "TH" "TJ" "TK" "TL" "TM" "TN" "TO" "TR" "TT" "TV" "TW" "TZ" "UA" "UG" "UM" "US" "UY" "UZ" "VA" "VC" "VE" "VG" "VI" "VN" "VU" "WF" "WS" "XK" "XZ" "YE" "YT" "ZA" "ZM" "ZW" "ZZ"] }
def collectionEntityType-completer [] { ["COLLECTION" "INSTITUTION" "PERSON"] }
def accept-completer [] { ["application/json" "application/x-javascript"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "derived-dataset createDerivedDataset" } } | get name | first)
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

# Create a new derived dataset
#
# POST /derivedDataset
# operationId: createDerivedDataset
export def "derived-dataset createDerivedDataset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --originalDownloadDOI: string # The DOI of the source (large) download which has been filtered
  title: string # The human title of the derived dataset.
  --description: string # Description of the derived dataset, such as how it was filtered.
  sourceUrl: string # The URL where your derived dataset is deposited. (format: uri)
  --registrationDate: string # A future date should you wish to delay the registration of the DOI, for example for embargoed materials. (format: date-time)
  --relatedDatasets: record # A map with keys of GBIF Dataset DOIs or UUIDs, and values (>0) of the number of records present in the derived dataset.
]: any -> record<doi: string, originalDownloadDOI: string, description: string, citation: string, title: string, sourceUrl: string, createdBy: string, modifiedBy: string, registrationDate: string, created: string, modified: string, category: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/derivedDataset")
  let body = {originalDownloadDOI: $originalDownloadDOI, title: $title, description: $description, sourceUrl: $sourceUrl, registrationDate: $registrationDate, relatedDatasets: $relatedDatasets} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# An inventory of all enumerations
#
# GET /enumeration/basic
# operationId: enumerationsBasic
export def "enumeration-basic enumerationsBasic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enumeration/basic")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all collections
#
# GET /grscicoll/collection
# operationId: listCollections
@deprecated --flag institution
export def "grscicoll-collection listCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --institution: string # A key for the institution. Deprecated: use institutionKey instead. (DEPRECATED, format: uuid)
  --contentType: string # Content type of a GrSciColl collection. Accepts multiple values, for example `contentType=Paleontological&contentType=EarthPlanetary`.
  --preservationType: string # Preservation type of a GrSciColl collection. Accepts multiple values, for example `preservationType=SampleCryopreserved&preservationType=SampleFluidPreserved`.
  --accessionStatus: string # Accession status of a GrSciColl collection. Accepts multiple values, for example `accessionStatus=Institutional&accessionStatus=Project
  --personalCollection: string@bool-completer # Flag for personal GRSciColl collections
  --sourceId: string # sourceId of MasterSourceMetadata
  --qp-source: string@source-completer # Source attribute of MasterSourceMetadata
  --code: string # Code of a GrSciColl institution or collection
  --name: string # Name of a GrSciColl institution or collection
  --alternativeCode: string # Alternative code of a GrSciColl institution or collection
  --contact: string # Filters collections and institutions whose contacts contain the person key specified (format: uuid)
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --country: string@country-completer # Filters by country given as a ISO 639-1 (2 letter) country code.
  --gbifRegion: string@gbifRegion-completer # Filters by a gbif region
  --city: string # Filters by the city of the address. It searches in both the physical and the mailing address.
  --fuzzyName: string # It searches by name fuzzily so the parameter doesn't have to be the exact name
  --active: string@bool-completer # Active status of a GrSciColl institution or collection
  --masterSourceType: string@masterSourceType-completer # The master source type of a GRSciColl institution or collection
  --numberSpecimens: string # Number of specimens. It supports ranges and a `*` can be used as a wildcard
  --displayOnNHCPortal: string@bool-completer # Flag to show this record in the NHC portal
  --replacedBy: string # Key of the entity that replaced another entity (format: uuid)
  --occurrenceCount: string # Count of occurrences linked. It supports ranges and a `*` can be used as a wildcard
  --typeSpecimenCount: string # Count of type specimens linked. It supports ranges and a `*` can be used as a wildcard
  --institutionKey: string # Keys of institutions to filter by (format: uuid)
  --sortBy: string@sortBy-completer # Field to sort the results by. It only supports the fields contained in the enum.
  --sortOrder: string@sortOrder-completer # Sort order to use with the sortBy parameter
  --contactUserId: string # Filter by contact user ID
  --contactEmail: string # Filter by contact email
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, code: string, name: string, description: string, contentTypes: list, active: bool, personalCollection: bool, doi: string, email: list, phone: list, homepage: string, catalogUrls: list, apiUrls: list, preservationTypes: list, accessionStatus: string, institutionKey: string, mailingAddress: record, address: record, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, tags: list, identifiers: list, contactPersons: list, numberSpecimens: int, machineTags: list, taxonomicCoverage: string, geographicCoverage: string, notes: string, incorporatedCollections: list, alternativeCodes: list, comments: list, occurrenceMappings: list, replacedBy: string, masterSource: string, masterSourceMetadata: record, department: string, division: string, displayOnNHCPortal: bool, occurrenceCount: int, typeSpecimenCount: int, featuredImageUrl: string, featuredImageLicense: string, temporalCoverage: string, featuredImageAttribution: string, institutionName: string, institutionCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "institution" $institution "scalar") (serialize-qp "contentType" $contentType "scalar") (serialize-qp "preservationType" $preservationType "scalar") (serialize-qp "accessionStatus" $accessionStatus "scalar") (serialize-qp "personalCollection" $personalCollection "scalar") (serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "alternativeCode" $alternativeCode "scalar") (serialize-qp "contact" $contact "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "gbifRegion" $gbifRegion "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuzzyName" $fuzzyName "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "masterSourceType" $masterSourceType "scalar") (serialize-qp "numberSpecimens" $numberSpecimens "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "scalar") (serialize-qp "replacedBy" $replacedBy "scalar") (serialize-qp "occurrenceCount" $occurrenceCount "scalar") (serialize-qp "typeSpecimenCount" $typeSpecimenCount "scalar") (serialize-qp "institutionKey" $institutionKey "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/collection" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new collection
#
# POST /grscicoll/collection
# operationId: createCollection
# --mailingAddress shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
# --address shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
# --tags item shape: {value: string}
# --identifiers item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --contactPersons item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
# --machineTags item shape: {namespace: string, name: string, value: string}
# --alternativeCodes item shape: {code?: string, description?: string}
# --comments item shape: {content: string}
# --occurrenceMappings item shape: {key?: int, code?: string, parentCode?: string, identifier?: string, datasetKey: string, createdBy?: string, created?: string}
# --masterSourceMetadata shape: {source: "DATASET"|"ORGANIZATION"|"IH_IRN", sourceId: string}
export def "grscicoll-collection createCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # Code of the collection — identifies a collection at the owner's location.  *(NB Not required for updates.)*
  name: string # Descriptive name of the collection.  *(NB Not required for updates.)*
  --description: string # Description or summary of the contents of the collection.
  --contentTypes: list # Content type of the elements found in the collection.
  --active: string@bool-completer # Whether the collection is active/maintained.
  --personalCollection: string@bool-completer # Whether this collection belongs to an individual.
  --doi: string # A Digital Object Identifier for the collection.
  --email: list # Email addresses associated with the collection.
  --phone: list # Telephone numbers associated with the collection.
  --homepage: string # The collection's WWW homepage. (format: uri)
  --catalogUrls: list # URLs for interactive catalogues of the collection.
  --apiUrls: list # URLs for machine-readable APIs for the collection catalogue.
  --preservationTypes: list # The preservation mechanisms used for this collection.
  --accessionStatus: string # How the collection was added or joined.
  --institutionKey: string # The key of the institution owning or hosting the collection. (format: uuid)
  --mailingAddress: record # shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
  --address: record # shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
  --numberSpecimens: int # The number of specimens contained in this collection. (format: int32)
  --taxonomicCoverage: string # The taxonomic coverage of this collection.
  --geographicCoverage: string # The geographic coverage of this collection.
  --notes: string # Notes on the collection.
  --incorporatedCollections: list # Other collections incorporated into this collection.
  --alternativeCodes: list # Alternative codes for this collection. — item shape: {code?: string, description?: string}
  --replacedBy: string # A collection record that replaces this collection. (format: uuid)
  --masterSource: string@masterSource-completer # The primary source of this collection record.
  --masterSourceMetadata: record # shape: {source: "DATASET"|"ORGANIZATION"|"IH_IRN", sourceId: string}
  --department: string # An organizational department managing the collection.
  --division: string # An organizational division managing the collection.
  --displayOnNHCPortal: string@bool-completer # Whether the collection is shown on the NHC portal.
  --occurrenceCount: int # An estimate of the number of occurrences linked to the institution. (format: int32)
  --typeSpecimenCount: int # An estimate of the number of type specimens linked to the institution. (format: int32)
  --featuredImageUrl: string # URI to the image to be featured on the collection page, this image should be associated with a license. (format: uri)
  --featuredImageLicense: string@featuredImageLicense-completer # The license associated with the image to be featured on the collection page.
  --temporalCoverage: string # Temporal scope or focus of the collection. This free text field can be used to describe both the collection date ranges as well as the geological time group(s) of the collection objects in the context of paleontological collections.
  --featuredImageAttribution: string #  Information about ownership, attribution, etc. of the featured image. This value with be used to generate a suggested citation of the image.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grscicoll/collection")
  let body = {code: $code, name: $name, description: $description, contentTypes: $contentTypes, active: $active, personalCollection: $personalCollection, doi: $doi, email: $email, phone: $phone, homepage: $homepage, catalogUrls: $catalogUrls, apiUrls: $apiUrls, preservationTypes: $preservationTypes, accessionStatus: $accessionStatus, institutionKey: $institutionKey, mailingAddress: $mailingAddress, address: $address, numberSpecimens: $numberSpecimens, taxonomicCoverage: $taxonomicCoverage, geographicCoverage: $geographicCoverage, notes: $notes, incorporatedCollections: $incorporatedCollections, alternativeCodes: $alternativeCodes, replacedBy: $replacedBy, masterSource: $masterSource, masterSourceMetadata: $masterSourceMetadata, department: $department, division: $division, displayOnNHCPortal: $displayOnNHCPortal, occurrenceCount: $occurrenceCount, typeSpecimenCount: $typeSpecimenCount, featuredImageUrl: $featuredImageUrl, featuredImageLicense: $featuredImageLicense, temporalCoverage: $temporalCoverage, featuredImageAttribution: $featuredImageAttribution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all collections in Latimer Core format
#
# GET /grscicoll/collection/latimerCore
# operationId: listCollectionsAsLatimerCore
@deprecated --flag institution
export def "grscicoll-collection-latimer-core listCollectionsAsLatimerCore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --institution: string # A key for the institution. Deprecated: use institutionKey instead. (DEPRECATED, format: uuid)
  --contentType: string # Content type of a GrSciColl collection. Accepts multiple values, for example `contentType=Paleontological&contentType=EarthPlanetary`.
  --preservationType: string # Preservation type of a GrSciColl collection. Accepts multiple values, for example `preservationType=SampleCryopreserved&preservationType=SampleFluidPreserved`.
  --accessionStatus: string # Accession status of a GrSciColl collection. Accepts multiple values, for example `accessionStatus=Institutional&accessionStatus=Project
  --personalCollection: string@bool-completer # Flag for personal GRSciColl collections
  --sourceId: string # sourceId of MasterSourceMetadata
  --qp-source: string@source-completer # Source attribute of MasterSourceMetadata
  --code: string # Code of a GrSciColl institution or collection
  --name: string # Name of a GrSciColl institution or collection
  --alternativeCode: string # Alternative code of a GrSciColl institution or collection
  --contact: string # Filters collections and institutions whose contacts contain the person key specified (format: uuid)
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --country: string@country-completer # Filters by country given as a ISO 639-1 (2 letter) country code.
  --gbifRegion: string@gbifRegion-completer # Filters by a gbif region
  --city: string # Filters by the city of the address. It searches in both the physical and the mailing address.
  --fuzzyName: string # It searches by name fuzzily so the parameter doesn't have to be the exact name
  --active: string@bool-completer # Active status of a GrSciColl institution or collection
  --masterSourceType: string@masterSourceType-completer # The master source type of a GRSciColl institution or collection
  --numberSpecimens: string # Number of specimens. It supports ranges and a `*` can be used as a wildcard
  --displayOnNHCPortal: string@bool-completer # Flag to show this record in the NHC portal
  --replacedBy: string # Key of the entity that replaced another entity (format: uuid)
  --occurrenceCount: string # Count of occurrences linked. It supports ranges and a `*` can be used as a wildcard
  --typeSpecimenCount: string # Count of type specimens linked. It supports ranges and a `*` can be used as a wildcard
  --institutionKey: string # Keys of institutions to filter by (format: uuid)
  --sortBy: string@sortBy-completer # Field to sort the results by. It only supports the fields contained in the enum.
  --sortOrder: string@sortOrder-completer # Sort order to use with the sortBy parameter
  --contactUserId: string # Filter by contact user ID
  --contactEmail: string # Filter by contact email
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<collectionName: string, description: string, discipline: list, typeOfObjectGroup: list, hasOrganisationalUnit: list, isCurrentCollection: bool, preservationMethod: list, address: list, collectionStatusHistory: list, contactDetail: list, geographicContext: list, identifier: list, measurementOrFact: list, personRole: list, reference: list, resourceRelationship: list, objectClassification: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "institution" $institution "scalar") (serialize-qp "contentType" $contentType "scalar") (serialize-qp "preservationType" $preservationType "scalar") (serialize-qp "accessionStatus" $accessionStatus "scalar") (serialize-qp "personalCollection" $personalCollection "scalar") (serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "alternativeCode" $alternativeCode "scalar") (serialize-qp "contact" $contact "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "gbifRegion" $gbifRegion "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuzzyName" $fuzzyName "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "masterSourceType" $masterSourceType "scalar") (serialize-qp "numberSpecimens" $numberSpecimens "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "scalar") (serialize-qp "replacedBy" $replacedBy "scalar") (serialize-qp "occurrenceCount" $occurrenceCount "scalar") (serialize-qp "typeSpecimenCount" $typeSpecimenCount "scalar") (serialize-qp "institutionKey" $institutionKey "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/collection/latimerCore" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new collection posted in Latimer Core format.
#
# POST /grscicoll/collection/latimerCore
# operationId: createCollectionFromLatimerCore
# --hasOrganisationalUnit item shape: {organisationalUnitName?: string, organisationalUnitType?: string, address?: list, contactDetail?: list, identifier?: list, measurementOrFact?: list, reference?: list}
# --address item shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
# --collectionStatusHistory item shape: {status?: string, statusType?: string}
# --contactDetail item shape: {contactDetailValue?: string, contactDetailCategory?: string}
# --geographicContext item shape: {hasMeasurementOrFact?: list}
# --identifier item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --measurementOrFact item shape: {measurementFactText?: string, measurementValue?: string, measurementType?: string}
# --personRole item shape: {person?: list, role?: list, measurementOrFact?: list}
# --reference item shape: {resourceIRI?: string, referenceType?: string, referenceName?: string}
# --resourceRelationship item shape: {relatedResourceName?: string, relationshipOfResource?: string}
# --objectClassification item shape: {objectClassificationName?: string, objectClassificationLevel?: string}
export def "grscicoll-collection-latimer-core createCollectionFromLatimerCore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --collectionName: string
  --description: string
  --discipline: list
  --typeOfObjectGroup: list
  --hasOrganisationalUnit: list # item shape: {organisationalUnitName?: string, organisationalUnitType?: string, address?: list, contactDetail?: list, identifier?: list, measurementOrFact?: list, reference?: list}
  --isCurrentCollection: string@bool-completer
  --preservationMethod: list
  --address: list # item shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
  --collectionStatusHistory: list # item shape: {status?: string, statusType?: string}
  --contactDetail: list # item shape: {contactDetailValue?: string, contactDetailCategory?: string}
  --geographicContext: list # item shape: {hasMeasurementOrFact?: list}
  --identifier: list # item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
  --measurementOrFact: list # item shape: {measurementFactText?: string, measurementValue?: string, measurementType?: string}
  --personRole: list # item shape: {person?: list, role?: list, measurementOrFact?: list}
  --reference: list # item shape: {resourceIRI?: string, referenceType?: string, referenceName?: string}
  --resourceRelationship: list # item shape: {relatedResourceName?: string, relationshipOfResource?: string}
  --objectClassification: list # item shape: {objectClassificationName?: string, objectClassificationLevel?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grscicoll/collection/latimerCore")
  let body = {collectionName: $collectionName, description: $description, discipline: $discipline, typeOfObjectGroup: $typeOfObjectGroup, hasOrganisationalUnit: $hasOrganisationalUnit, isCurrentCollection: $isCurrentCollection, preservationMethod: $preservationMethod, address: $address, collectionStatusHistory: $collectionStatusHistory, contactDetail: $contactDetail, geographicContext: $geographicContext, identifier: $identifier, measurementOrFact: $measurementOrFact, personRole: $personRole, reference: $reference, resourceRelationship: $resourceRelationship, objectClassification: $objectClassification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all datasets
#
# GET /dataset
# operationId: listDatasets
export def "dataset listDatasets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string@country-completer # The 2-letter country code (as per ISO-3166-1) of the country publishing the dataset.
  --type: string@type-completer # The primary type of the dataset.
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --modified: string # The modified date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `modified=2023-04-01,*`
  --created: string # The created date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `created=2023-04-01,*`
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, parentDatasetKey: string, duplicateOfDatasetKey: string, installationKey: string, publishingOrganizationKey: string, publishingOrganizationName: string, networkKeys: list, doi: string, version: string, external: bool, numConstituents: int, type: string, subtype: string, shortName: string, title: string, alias: string, abbreviation: string, description: string, language: string, homepage: string, logoUrl: string, citation: record, contactsCitation: list, rights: string, lockedForAutoUpdate: bool, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list, bibliographicCitations: list, curatorialUnits: list, taxonomicCoverages: list, geographicCoverageDescription: string, geographicCoverages: list, temporalCoverages: list, keywordCollections: list, project: record, samplingDescription: record, countryCoverage: list, collections: list, dataDescriptions: list, dataLanguage: string, purpose: string, introduction: string, gettingStarted: string, acknowledgements: string, additionalInfo: string, pubDate: string, maintenanceUpdateFrequency: string, maintenanceDescription: string, license: string, dwca: record, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "modified" $modified "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new dataset
#
# POST /dataset
# operationId: createDataset
# --citation shape: {text?: string, identifier?: string, citationProvidedBySource?: bool}
# --contactsCitation item shape: {key?: int, abbreviatedName?: string, firstName?: string, lastName?: string, roles?: list, userId?: list}
# --contacts item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
# --endpoints item shape: {type: "EML"|"FEED"|"WFS"|"WMS"|"TCS_RDF"|"TCS_XML"|"DWC_ARCHIVE"|"DIGIR"|"DIGIR_MANIS"|"TAPIR"|"BIOCASE"|"BIOCASE_XML_ARCHIVE"|"OAI_PMH"|"COLDP"|"CAMTRAP_DP"|"DWC_DP"|"BIOM_1_0"|"BIOM_2_1"|"ACEF"|"TEXT_TREE"|"OTHER", url?: string, description?: string, machineTags: list}
# --machineTags item shape: {namespace: string, name: string, value: string}
# --tags item shape: {value: string}
# --identifiers item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --comments item shape: {content: string}
# --bibliographicCitations item shape: {text?: string, identifier?: string, citationProvidedBySource?: bool}
# --curatorialUnits item shape: {type?: "SPECIMENS"|"DRAWERS", typeVerbatim?: string, count?: int, deviation?: int, lower?: int, upper?: int}
# --taxonomicCoverages item shape: {description?: string, coverages?: list}
# --geographicCoverages item shape: {description?: string, boundingBox?: record}
# --keywordCollections item shape: {thesaurus?: string, keywords?: list}
# --project shape: {title?: string, identifier?: string, description?: string, contacts?: list, funding?: string, awards?: list, studyAreaDescription?: string, designDescription?: string, relatedProjects?: list, abstract?: string}
# --samplingDescription shape: {studyExtent?: string, sampling?: string, qualityControl?: string, methodSteps?: list}
# --collections item shape: {code?: string, name: string, description?: string, contentTypes?: list, active?: bool, personalCollection?: bool, doi?: string, email?: list, phone?: list, homepage?: string, catalogUrls?: list, apiUrls?: list, preservationTypes?: list, accessionStatus?: string, institutionKey?: string, mailingAddress?: record, address?: record, numberSpecimens?: int, taxonomicCoverage?: string, geographicCoverage?: string, notes?: string, incorporatedCollections?: list, alternativeCodes?: list, replacedBy?: string, masterSource?: "GRSCICOLL"|"GBIF_REGISTRY"|"IH", masterSourceMetadata?: record, department?: string, division?: string, displayOnNHCPortal?: bool, occurrenceCount?: int, typeSpecimenCount?: int, featuredImageUrl?: string, featuredImageLicense?: "CC0_1_0"|"CC_BY_4_0"|"CC_BY_NC_4_0"|"UNSPECIFIED"|"UNSUPPORTED", temporalCoverage?: string, featuredImageAttribution?: string}
# --dataDescriptions item shape: {name?: string, charset?: string, url?: string, format?: string, formatVersion?: string}
# --dwca shape: {coreType?: string, extensions?: list}
export def "dataset createDataset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentDatasetKey: string # If set, this dataset is a sub-dataset of the parent. (format: uuid)
  --duplicateOfDatasetKey: string # A dataset of which this dataset is a duplicate. Typically, this means this dataset is an old version of the duplicated dataset, which has replaced this dataset. Therefore **this link is usually found on deleted datasets**. (format: uuid)
  installationKey: string # The installation providing access to the source dataset.  *(NB Not required for updates.)* (format: uuid)
  publishingOrganizationKey: string # The publishing organization publishing this dataset.  *(NB Not required for updates.)* (format: uuid)
  --publishingOrganizationName: string # The publishing organization name.  *(NB Not required for updates.)*
  --networkKeys: list # A list of GBIF Networks to which this dataset belongs.
  --doi: string # The primary Digital Object Identifier (DOI) for this dataset.
  --version: string # The version of the published dataset.
  --external: string@bool-completer # Not currently used.
  --numConstituents: int # If set, the number of sub-datasets of this parent dataset. (format: int32)
  type: string@type-completer # The primary type of the dataset.  *(NB Not required for updates.)*
  --subtype: string@subtype-completer # The sub-type of the dataset.
  --shortName: string # Concise name of the dataset.
  title: string # The title of the dataset.  *(NB Not required for updates.)*
  --alias: string # An alias for this dataset. Rarely used.
  --abbreviation: string # An abbreviation for this dataset. Rarely used.
  --description: string # A description of the dataset.
  language: string@language-completer # The language of the dataset metadata.  *(NB Not required for updates.)*
  --homepage: string # A homepage with further details on the dataset. (format: uri)
  --logoUrl: string # A logo for the dataset, accessible over HTTP. (format: uri)
  --citation: record # shape: {text?: string, identifier?: string, citationProvidedBySource?: bool}
  --contactsCitation: list # Contacts use to generate a citation. — item shape: {key?: int, abbreviatedName?: string, firstName?: string, lastName?: string, roles?: list, userId?: list}
  --rights: string # Intellectual property rights applied to this dataset.  *Rarely used, see `license` instead.*
  --project: record # shape: {title?: string, identifier?: string, description?: string, contacts?: list, funding?: string, awards?: list, studyAreaDescription?: string, designDescription?: string, relatedProjects?: list, abstract?: string}
  --samplingDescription: record # shape: {studyExtent?: string, sampling?: string, qualityControl?: string, methodSteps?: list}
  --dwca: record # shape: {coreType?: string, extensions?: list}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/dataset")
  let body = {parentDatasetKey: $parentDatasetKey, duplicateOfDatasetKey: $duplicateOfDatasetKey, installationKey: $installationKey, publishingOrganizationKey: $publishingOrganizationKey, publishingOrganizationName: $publishingOrganizationName, networkKeys: $networkKeys, doi: $doi, version: $version, external: $external, numConstituents: $numConstituents, type: $type, subtype: $subtype, shortName: $shortName, title: $title, alias: $alias, abbreviation: $abbreviation, description: $description, language: $language, homepage: $homepage, logoUrl: $logoUrl, citation: $citation, contactsCitation: $contactsCitation, rights: $rights, project: $project, samplingDescription: $samplingDescription, dwca: $dwca} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all installations
#
# GET /installation
# operationId: listInstallations
export def "installation listInstallations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-1 # Filter by the type of installation.
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --modified: string # The modified date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `modified=2023-04-01,*`
  --created: string # The created date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `created=2023-04-01,*`
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, organizationKey: string, type: string, title: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, disabled: bool, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "modified" $modified "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/installation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new installation
#
# POST /installation
# operationId: createInstallation
# --contacts item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
# --endpoints item shape: {type: "EML"|"FEED"|"WFS"|"WMS"|"TCS_RDF"|"TCS_XML"|"DWC_ARCHIVE"|"DIGIR"|"DIGIR_MANIS"|"TAPIR"|"BIOCASE"|"BIOCASE_XML_ARCHIVE"|"OAI_PMH"|"COLDP"|"CAMTRAP_DP"|"DWC_DP"|"BIOM_1_0"|"BIOM_2_1"|"ACEF"|"TEXT_TREE"|"OTHER", url?: string, description?: string, machineTags: list}
# --machineTags item shape: {namespace: string, name: string, value: string}
# --tags item shape: {value: string}
# --identifiers item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --comments item shape: {content: string}
export def "installation createInstallation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationKey: string # The publishing organization managing this installation.  *(NB Not required for updates.)* (format: uuid)
  type: string@type-completer-1 # The type of the installation. Defines what protocols are usedfor communication.  *(NB Not required for updates.)*
  title: string # A name for the installation.  *(NB Not required for updates.)*
  --description: string # A description for the installation.
  --disabled: string@bool-completer # Whether the installation is disabled. A disabled installation is not checked for new or deleted datasets, or metadata changes to existingdatasets. However, data updates from existing datasets are not affected.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/installation")
  let body = {organizationKey: $organizationKey, type: $type, title: $title, description: $description, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all institutions
#
# GET /grscicoll/institution
# operationId: listInstitutions
export def "grscicoll-institution listInstitutions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Type of a GrSciColl institution. Accepts multiple values, for example `type=Museum&type=BotanicalGarden
  --institutionalGovernance: string # Institutional governance of a GrSciColl institution. Accepts multiple values, for example `InstitutionalGovernance=NonProfit&InstitutionalGovernance=Local`
  --discipline: string # Discipline of a GrSciColl institution. Accepts multiple values, for example `discipline=Zoology&discipline=Biological`
  --sourceId: string # sourceId of MasterSourceMetadata
  --qp-source: string@source-completer # Source attribute of MasterSourceMetadata
  --code: string # Code of a GrSciColl institution or collection
  --name: string # Name of a GrSciColl institution or collection
  --alternativeCode: string # Alternative code of a GrSciColl institution or collection
  --contact: string # Filters collections and institutions whose contacts contain the person key specified (format: uuid)
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --country: string@country-completer # Filters by country given as a ISO 639-1 (2 letter) country code.
  --gbifRegion: string@gbifRegion-completer # Filters by a gbif region
  --city: string # Filters by the city of the address. It searches in both the physical and the mailing address.
  --fuzzyName: string # It searches by name fuzzily so the parameter doesn't have to be the exact name
  --active: string@bool-completer # Active status of a GrSciColl institution or collection
  --masterSourceType: string@masterSourceType-completer # The master source type of a GRSciColl institution or collection
  --numberSpecimens: string # Number of specimens. It supports ranges and a `*` can be used as a wildcard
  --displayOnNHCPortal: string@bool-completer # Flag to show this record in the NHC portal
  --replacedBy: string # Key of the entity that replaced another entity (format: uuid)
  --occurrenceCount: string # Count of occurrences linked. It supports ranges and a `*` can be used as a wildcard
  --typeSpecimenCount: string # Count of type specimens linked. It supports ranges and a `*` can be used as a wildcard
  --institutionKey: string # Keys of institutions to filter by (format: uuid)
  --sortBy: string@sortBy-completer # Field to sort the results by. It only supports the fields contained in the enum.
  --sortOrder: string@sortOrder-completer # Sort order to use with the sortBy parameter
  --contactUserId: string # Filter by contact user ID
  --contactEmail: string # Filter by contact email
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, code: string, name: string, description: string, types: list, active: bool, email: list, phone: list, homepage: string, catalogUrls: list, apiUrls: list, institutionalGovernances: list, disciplines: list, latitude: float, longitude: float, mailingAddress: record, address: record, additionalNames: list, foundingDate: int, numberSpecimens: int, logoUrl: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, tags: list, identifiers: list, contactPersons: list, machineTags: list, alternativeCodes: list, comments: list, occurrenceMappings: list, replacedBy: string, convertedToCollection: string, masterSource: string, masterSourceMetadata: record, displayOnNHCPortal: bool, occurrenceCount: int, typeSpecimenCount: int, featuredImageUrl: string, featuredImageLicense: string, featuredImageAttribution: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "institutionalGovernance" $institutionalGovernance "scalar") (serialize-qp "discipline" $discipline "scalar") (serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "alternativeCode" $alternativeCode "scalar") (serialize-qp "contact" $contact "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "gbifRegion" $gbifRegion "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuzzyName" $fuzzyName "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "masterSourceType" $masterSourceType "scalar") (serialize-qp "numberSpecimens" $numberSpecimens "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "scalar") (serialize-qp "replacedBy" $replacedBy "scalar") (serialize-qp "occurrenceCount" $occurrenceCount "scalar") (serialize-qp "typeSpecimenCount" $typeSpecimenCount "scalar") (serialize-qp "institutionKey" $institutionKey "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/institution" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new institution
#
# POST /grscicoll/institution
# operationId: createInstitution
# --mailingAddress shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
# --address shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
# --tags item shape: {value: string}
# --identifiers item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --contactPersons item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
# --machineTags item shape: {namespace: string, name: string, value: string}
# --alternativeCodes item shape: {code?: string, description?: string}
# --comments item shape: {content: string}
# --occurrenceMappings item shape: {key?: int, code?: string, parentCode?: string, identifier?: string, datasetKey: string, createdBy?: string, created?: string}
# --masterSourceMetadata shape: {source: "DATASET"|"ORGANIZATION"|"IH_IRN", sourceId: string}
export def "grscicoll-institution createInstitution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # Code used to identify the institution.  *(NB Not required for updates.)*
  name: string # Name or title of the institution.  *(NB Not required for updates.)*
  --description: string # Description of the institution.
  --types: list # Types of the institution, describing its main activities.
  --active: string@bool-completer # Whether the institution is active or operational.
  --email: list # Email addresses associated with the institution.
  --phone: list # Telephone numbers associated with the instutiton.
  --homepage: string # The institution's WWW homepage. (format: uri)
  --catalogUrls: list # URLs for the main interactive catalogues of the institution.
  --apiUrls: list # URLs for machine-readable APIs for the institution catalogues.
  --institutionalGovernances: list # The mechanisms, processes and relations by which an institution is controlled and directed.
  --disciplines: list # The academic or research disciplines to which an institution is dedicated.
  --latitude: float # The latitude of the institution.
  --longitude: float # The longitude of the institution.
  --mailingAddress: record # shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
  --address: record # shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
  --additionalNames: list # Additional names by which the institution is known.
  --foundingDate: int # The date the institution was founded or established. (format: int32)
  --numberSpecimens: int # An estimate of the number of specimens hosted by the institution. (format: int32)
  --logoUrl: string # A URL to a logo for the institution. (format: uri)
  --contactPersons: list # A list of contact people for this institution. — item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
  --alternativeCodes: list # Alternative codes for this institution. — item shape: {code?: string, description?: string}
  --replacedBy: string # A collection record that replaces this collection. (format: uuid)
  --convertedToCollection: string # Indicates if the institution was converted to a collection and specifies the UUID key of that collection (format: uuid)
  --masterSource: string@masterSource-completer # The primary source of this institution record.
  --masterSourceMetadata: record # shape: {source: "DATASET"|"ORGANIZATION"|"IH_IRN", sourceId: string}
  --displayOnNHCPortal: string@bool-completer # Whether the institution is shown on the NHC portal.
  --occurrenceCount: int # An estimate of the number of occurrences linked to the institution. (format: int32)
  --typeSpecimenCount: int # An estimate of the number of type specimens linked to the institution. (format: int32)
  --featuredImageUrl: string # URI to the image to be featured on the institution page, this image should be associated with a license. (format: uri)
  --featuredImageLicense: string@featuredImageLicense-completer # The license associated with the image to be featured on the institution page.
  --featuredImageAttribution: string #  Information about ownership, attribution, etc. of the featured image. This value with be used to generate a suggested citation of the image.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grscicoll/institution")
  let body = {code: $code, name: $name, description: $description, types: $types, active: $active, email: $email, phone: $phone, homepage: $homepage, catalogUrls: $catalogUrls, apiUrls: $apiUrls, institutionalGovernances: $institutionalGovernances, disciplines: $disciplines, latitude: $latitude, longitude: $longitude, mailingAddress: $mailingAddress, address: $address, additionalNames: $additionalNames, foundingDate: $foundingDate, numberSpecimens: $numberSpecimens, logoUrl: $logoUrl, contactPersons: $contactPersons, alternativeCodes: $alternativeCodes, replacedBy: $replacedBy, convertedToCollection: $convertedToCollection, masterSource: $masterSource, masterSourceMetadata: $masterSourceMetadata, displayOnNHCPortal: $displayOnNHCPortal, occurrenceCount: $occurrenceCount, typeSpecimenCount: $typeSpecimenCount, featuredImageUrl: $featuredImageUrl, featuredImageLicense: $featuredImageLicense, featuredImageAttribution: $featuredImageAttribution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List institutions in Latimer Core format
#
# GET /grscicoll/institution/latimerCore
# operationId: listInstitutionsAsLatimerCore
export def "grscicoll-institution-latimer-core listInstitutionsAsLatimerCore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Type of a GrSciColl institution. Accepts multiple values, for example `type=Museum&type=BotanicalGarden
  --institutionalGovernance: string # Institutional governance of a GrSciColl institution. Accepts multiple values, for example `InstitutionalGovernance=NonProfit&InstitutionalGovernance=Local`
  --discipline: string # Discipline of a GrSciColl institution. Accepts multiple values, for example `discipline=Zoology&discipline=Biological`
  --sourceId: string # sourceId of MasterSourceMetadata
  --qp-source: string@source-completer # Source attribute of MasterSourceMetadata
  --code: string # Code of a GrSciColl institution or collection
  --name: string # Name of a GrSciColl institution or collection
  --alternativeCode: string # Alternative code of a GrSciColl institution or collection
  --contact: string # Filters collections and institutions whose contacts contain the person key specified (format: uuid)
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --country: string@country-completer # Filters by country given as a ISO 639-1 (2 letter) country code.
  --gbifRegion: string@gbifRegion-completer # Filters by a gbif region
  --city: string # Filters by the city of the address. It searches in both the physical and the mailing address.
  --fuzzyName: string # It searches by name fuzzily so the parameter doesn't have to be the exact name
  --active: string@bool-completer # Active status of a GrSciColl institution or collection
  --masterSourceType: string@masterSourceType-completer # The master source type of a GRSciColl institution or collection
  --numberSpecimens: string # Number of specimens. It supports ranges and a `*` can be used as a wildcard
  --displayOnNHCPortal: string@bool-completer # Flag to show this record in the NHC portal
  --replacedBy: string # Key of the entity that replaced another entity (format: uuid)
  --occurrenceCount: string # Count of occurrences linked. It supports ranges and a `*` can be used as a wildcard
  --typeSpecimenCount: string # Count of type specimens linked. It supports ranges and a `*` can be used as a wildcard
  --institutionKey: string # Keys of institutions to filter by (format: uuid)
  --sortBy: string@sortBy-completer # Field to sort the results by. It only supports the fields contained in the enum.
  --sortOrder: string@sortOrder-completer # Sort order to use with the sortBy parameter
  --contactUserId: string # Filter by contact user ID
  --contactEmail: string # Filter by contact email
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<organisationalUnitName: string, organisationalUnitType: string, address: list, contactDetail: list, identifier: list, measurementOrFact: list, reference: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "institutionalGovernance" $institutionalGovernance "scalar") (serialize-qp "discipline" $discipline "scalar") (serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "alternativeCode" $alternativeCode "scalar") (serialize-qp "contact" $contact "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "gbifRegion" $gbifRegion "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuzzyName" $fuzzyName "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "masterSourceType" $masterSourceType "scalar") (serialize-qp "numberSpecimens" $numberSpecimens "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "scalar") (serialize-qp "replacedBy" $replacedBy "scalar") (serialize-qp "occurrenceCount" $occurrenceCount "scalar") (serialize-qp "typeSpecimenCount" $typeSpecimenCount "scalar") (serialize-qp "institutionKey" $institutionKey "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/institution/latimerCore" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new institution posted in Latimer Core format
#
# POST /grscicoll/institution/latimerCore
# operationId: createInstitutionFromLatimerCore
# --address item shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
# --contactDetail item shape: {contactDetailValue?: string, contactDetailCategory?: string}
# --identifier item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --measurementOrFact item shape: {measurementFactText?: string, measurementValue?: string, measurementType?: string}
# --reference item shape: {resourceIRI?: string, referenceType?: string, referenceName?: string}
export def "grscicoll-institution-latimer-core createInstitutionFromLatimerCore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organisationalUnitName: string
  --organisationalUnitType: string
  --address: list # item shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
  --contactDetail: list # item shape: {contactDetailValue?: string, contactDetailCategory?: string}
  --identifier: list # item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
  --measurementOrFact: list # item shape: {measurementFactText?: string, measurementValue?: string, measurementType?: string}
  --reference: list # item shape: {resourceIRI?: string, referenceType?: string, referenceName?: string}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grscicoll/institution/latimerCore")
  let body = {organisationalUnitName: $organisationalUnitName, organisationalUnitType: $organisationalUnitType, address: $address, contactDetail: $contactDetail, identifier: $identifier, measurementOrFact: $measurementOrFact, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all networks
#
# GET /network
# operationId: listNetworks
export def "network listNetworks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --modified: string # The modified date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `modified=2023-04-01,*`
  --created: string # The created date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `created=2023-04-01,*`
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, title: string, description: string, language: string, numConstituents: int, email: list, phone: list, homepage: list, logoUrl: string, address: list, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "modified" $modified "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/network" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new network
#
# POST /network
# operationId: createNetwork
# --contacts item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
# --endpoints item shape: {type: "EML"|"FEED"|"WFS"|"WMS"|"TCS_RDF"|"TCS_XML"|"DWC_ARCHIVE"|"DIGIR"|"DIGIR_MANIS"|"TAPIR"|"BIOCASE"|"BIOCASE_XML_ARCHIVE"|"OAI_PMH"|"COLDP"|"CAMTRAP_DP"|"DWC_DP"|"BIOM_1_0"|"BIOM_2_1"|"ACEF"|"TEXT_TREE"|"OTHER", url?: string, description?: string, machineTags: list}
# --machineTags item shape: {namespace: string, name: string, value: string}
# --tags item shape: {value: string}
# --identifiers item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --comments item shape: {content: string}
export def "network createNetwork" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # A name for the network.  *(NB Not required for updates.)*
  --description: string # A description for the network.
  language: string@language-completer # The language of the network metadata.  *(NB Not required for updates.)*
  --numConstituents: int # The number of datasets collected in this network. (format: int32)
  --email: list # Email addresses associated with this network.
  --phone: list # Telephone numbers associated with this network.
  --homepage: list # Homepages with further details on the network.
  --logoUrl: string # A logo for the network, accessible over HTTP. (format: uri)
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the network's address.
  --province: string # The province or similar line of the network's address.
  --country: string@country-completer # The country or other region of the network's address.
  --postalCode: string # The postal code or similar line of the network's address.
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/network")
  let body = {title: $title, description: $description, language: $language, numConstituents: $numConstituents, email: $email, phone: $phone, homepage: $homepage, logoUrl: $logoUrl, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all nodes
#
# GET /node
# operationId: listNodes
export def "node listNodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --modified: string # The modified date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `modified=2023-04-01,*`
  --created: string # The created date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `created=2023-04-01,*`
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, type: string, participationStatus: string, participantSince: int, dateSignedMOU: string, gbifRegion: string, title: string, participantTitle: string, abbreviation: string, description: string, email: list, phone: list, homepage: list, logoUrl: string, address: list, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "modified" $modified "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/node" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all publishing organizations
#
# GET /organization
# operationId: listOrganizations
export def "organization listOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isEndorsed: string@bool-completer # Whether the organization is endorsed by a node.
  --networkKey: string # Filter for organizations publishing datasets belonging to a network. (format: uuid)
  --numPublishedDatasets: string # Filter by number of published datasets. Examples: '5' (exactly 5), '1,*' (at least 1), '*,10' (at most 10), '5,15' (between 5 and 15).
  --canModify: string # Filter for organizations the specified user has permission to modify.
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --modified: string # The modified date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `modified=2023-04-01,*`
  --created: string # The created date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `created=2023-04-01,*`
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, endorsingNodeKey: string, endorsementApproved: bool, endorsementStatus: string, title: string, abbreviation: string, description: string, language: string, email: list, phone: list, homepage: list, logoUrl: string, address: list, city: string, province: string, country: string, postalCode: string, latitude: float, longitude: float, numPublishedDatasets: int, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, endorsed: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isEndorsed" $isEndorsed "scalar") (serialize-qp "networkKey" $networkKey "scalar") (serialize-qp "numPublishedDatasets" $numPublishedDatasets "scalar") (serialize-qp "canModify" $canModify "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "modified" $modified "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new publishing organization
#
# POST /organization
# operationId: createOrganization
# --contacts item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
# --endpoints item shape: {type: "EML"|"FEED"|"WFS"|"WMS"|"TCS_RDF"|"TCS_XML"|"DWC_ARCHIVE"|"DIGIR"|"DIGIR_MANIS"|"TAPIR"|"BIOCASE"|"BIOCASE_XML_ARCHIVE"|"OAI_PMH"|"COLDP"|"CAMTRAP_DP"|"DWC_DP"|"BIOM_1_0"|"BIOM_2_1"|"ACEF"|"TEXT_TREE"|"OTHER", url?: string, description?: string, machineTags: list}
# --machineTags item shape: {namespace: string, name: string, value: string}
# --tags item shape: {value: string}
# --identifiers item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --comments item shape: {content: string}
export def "organization createOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  endorsingNodeKey: string # The participant node which has endorsed or would endorse this publishing organization.  *(NB Not required for updates.)* (format: uuid)
  --endorsementApproved: string@bool-completer # Whether the participant node in `endorsingNodeKey` has endorsed this publishing organization — whether `endorsementStatus == ENDORSED`.
  --endorsementStatus: string@endorsementStatus-completer # The endorsement decision regarding this publishing organization made by the participant node in `endorsingNodeKey`.
  title: string # The title of the publishing organization.  *(NB Not required for updates.)*
  --abbreviation: string # The abbreviation for the publishing organization.
  --description: string # The description of the publishing organization.
  language: string@language-completer # The primary language of the description of the publishing organization.  *(NB Not required for updates.)*
  --email: list # Email addresses associated with this publishing organization.
  --phone: list # Telephone numbers associated with this publishing organization.
  --homepage: list # Homepages with further details on the publishing organization.
  --logoUrl: string # A logo for the publishing organization, accessible over HTTP. (format: uri)
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the publishing organization's address.
  --province: string # The province or similar line of the publishing organization's address.
  country: string@country-completer # The country or other region of the publishing organization's address.
  --postalCode: string # The postal code or similar line of the publishing organization's address.
  --latitude: float # The latitude of the publishing organization.
  --longitude: float # The longitude of the publishing organization.
  --endorsed: string # The time when this publishing organization was endorsed by the linked participant node. (format: date-time)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organization")
  let body = {endorsingNodeKey: $endorsingNodeKey, endorsementApproved: $endorsementApproved, endorsementStatus: $endorsementStatus, title: $title, abbreviation: $abbreviation, description: $description, language: $language, email: $email, phone: $phone, homepage: $homepage, logoUrl: $logoUrl, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode, latitude: $latitude, longitude: $longitude, endorsed: $endorsed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all institutions in GeoJson format
#
# GET /grscicoll/institution/geojson
# operationId: listInstitutionsGeoJson
export def "grscicoll-institution-geojson listInstitutionsGeoJson" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Type of a GrSciColl institution. Accepts multiple values, for example `type=Museum&type=BotanicalGarden
  --institutionalGovernance: string # Institutional governance of a GrSciColl institution. Accepts multiple values, for example `InstitutionalGovernance=NonProfit&InstitutionalGovernance=Local`
  --discipline: string # Discipline of a GrSciColl institution. Accepts multiple values, for example `discipline=Zoology&discipline=Biological`
  --sourceId: string # sourceId of MasterSourceMetadata
  --qp-source: string@source-completer # Source attribute of MasterSourceMetadata
  --code: string # Code of a GrSciColl institution or collection
  --name: string # Name of a GrSciColl institution or collection
  --alternativeCode: string # Alternative code of a GrSciColl institution or collection
  --contact: string # Filters collections and institutions whose contacts contain the person key specified (format: uuid)
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --country: string@country-completer # Filters by country given as a ISO 639-1 (2 letter) country code.
  --gbifRegion: string@gbifRegion-completer # Filters by a gbif region
  --city: string # Filters by the city of the address. It searches in both the physical and the mailing address.
  --fuzzyName: string # It searches by name fuzzily so the parameter doesn't have to be the exact name
  --active: string@bool-completer # Active status of a GrSciColl institution or collection
  --masterSourceType: string@masterSourceType-completer # The master source type of a GRSciColl institution or collection
  --numberSpecimens: string # Number of specimens. It supports ranges and a `*` can be used as a wildcard
  --displayOnNHCPortal: string@bool-completer # Flag to show this record in the NHC portal
  --replacedBy: string # Key of the entity that replaced another entity (format: uuid)
  --occurrenceCount: string # Count of occurrences linked. It supports ranges and a `*` can be used as a wildcard
  --typeSpecimenCount: string # Count of type specimens linked. It supports ranges and a `*` can be used as a wildcard
  --institutionKey: string # Keys of institutions to filter by (format: uuid)
  --sortBy: string@sortBy-completer # Field to sort the results by. It only supports the fields contained in the enum.
  --sortOrder: string@sortOrder-completer # Sort order to use with the sortBy parameter
  --contactUserId: string # Filter by contact user ID
  --contactEmail: string # Filter by contact email
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<crs: record<type: string, properties: record>, bbox: list<float>, features: table<crs: record, bbox: list, properties: record, geometry: any, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "institutionalGovernance" $institutionalGovernance "scalar") (serialize-qp "discipline" $discipline "scalar") (serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "alternativeCode" $alternativeCode "scalar") (serialize-qp "contact" $contact "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "gbifRegion" $gbifRegion "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuzzyName" $fuzzyName "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "masterSourceType" $masterSourceType "scalar") (serialize-qp "numberSpecimens" $numberSpecimens "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "scalar") (serialize-qp "replacedBy" $replacedBy "scalar") (serialize-qp "occurrenceCount" $occurrenceCount "scalar") (serialize-qp "typeSpecimenCount" $typeSpecimenCount "scalar") (serialize-qp "institutionKey" $institutionKey "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/institution/geojson" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search collections and institutions
#
# GET /grscicoll/search
# operationId: searchCollectionsInstitutions
export def "grscicoll-search searchCollectionsInstitutions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --hl: string@bool-completer # Set `hl=true` to highlight terms matching the query when in fulltext search fields. The highlight will be an emphasis tag of class `gbifHl`.
  --entityType: string # Code of a GrSciColl institution or collection
  --displayOnNHCPortal: list
  --country: string@country-completer # The 2-letter country code (as per ISO-3166-1) of the country.
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> table<key: string, code: string, name: string, alternativeCodes: list<record>, description: string, active: bool, displayOnNHCPortal: bool, country: string, mailingCountry: string, city: string, mailingCity: string, temporalCoverage: string, featuredImageLicense: string, featuredImageUrl: string, featuredImageAttribution: string, masterSource: string, highlights: list<record>, type: string, institutionKey: string, institutionCode: string, institutionName: string, descriptorMatches: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "hl" $hl "scalar") (serialize-qp "entityType" $entityType "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "multi") (serialize-qp "country" $country "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search across all datasets.
#
# GET /dataset/search
# operationId: searchDatasets
@deprecated --flag continent
export def "dataset-search searchDatasets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # The primary type of the dataset.
  --subtype: string@subtype-completer # The sub-type of the dataset.
  --publishingOrg: string # Filters datasets by their publishing organization UUID key (format: uuid)
  --hostingOrg: string # Filters datasets by their hosting organization UUID key (format: uuid)
  --keyword: string # Filters datasets by a case insensitive plain text keyword. The search is done on the merged collection of tags, the dataset keywordCollections and temporalCoverages.
  --decade: int # Filters datasets by their temporal coverage broken down to decades. Decades are given as a full year, e.g. 1880, 1960, 2000, etc, and will return datasets wholly contained in the decade as well as those that cover the entire decade or more. Facet by decade to get the break down, i.e. `facet=DECADE&limit=0` (format: int32)
  --publishingCountry: string@publishingCountry-completer # Filters datasets by their owning organization's country given as a ISO 639-1 (2 letter) country code
  --hostingCountry: string@hostingCountry-completer # Filters datasets by their hosting organization's country given as a ISO 639-1 (2 letter) country code
  --continent: string@continent-completer # Not implemented. (DEPRECATED)
  --license: string@license-completer # The dataset's licence.
  --projectId: string # Filter or facet based on the project ID of a given dataset. A dataset can have a project id if it is the result of a project. multiple datasets can have the same project id. (e.g. AA003-AA003311F)
  --taxonKey: int # A taxon key from the GBIF backbone. (format: int32)
  --recordCount: string # Number of records of the dataset. Accepts ranges and a `*` can be used as a wildcard. (e.g. 100,*)
  --modifiedDate: string # Date when the dataset was modified the last time. Accepts ranges and a `*` can be used as a wildcard. (e.g. 2022-05-01,*)
  --createdDate: string # Date when the dataset was created. Accepts ranges and a `*` can be used as a wildcard. (e.g. 2022-05-01,*)
  --doi: string # A DOI identifier.
  --networkKey: string # Network associated to a dataset (format: uuid)
  --endorsingNodeKey: string # Node key that endorsed this dataset's publisher (format: uuid)
  --installationKey: string # Key of the installation that hosts the dataset. (format: uuid)
  --endpointType: string@endpointType-completer # Type of the endpoint of the dataset.
  --category: string # Category of the dataset.
  --contactUserId: string # Filter datasets by contact user ID (e.g., ORCID).
  --contactEmail: string # Filter datasets by contact email address.
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --hl: string@bool-completer # Set `hl=true` to highlight terms matching the query when in fulltext search fields. The highlight will be an emphasis tag of class `gbifHl`.
  --facet: list # A facet name used to retrieve the most frequent values for a field. This parameter may be repeated to request multiple facets.
  --facetMinCount: int # Used in combination with the facet parameter. Set `facetMinCount={#}` to exclude facets with a count less than `{#}`. (format: int32)
  --facetMultiselect: string@bool-completer # Used in combination with the facet parameter. Set `facetMultiselect=true` to still return counts for values that are not currently filtered.
  --facetLimit: int # Facet parameters allow paging requests using the parameters facetOffset and facetLimit (format: int32)
  --facetOffset: int # Facet parameters allow paging requests using the parameters facetOffset and facetLimit (format: int32)
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, title: string, doi: string, description: string, type: string, subtype: string, fullText: string, hostingOrganizationKey: string, hostingOrganizationTitle: string, hostingCountry: string, publisherTitle: string, countryCoverage: list, continent: list, publishingCountry: string, publishingOrganizationKey: string, publishingOrganizationTitle: string, endorsingNodeKey: string, networkKeys: list, license: string, decades: list, keywords: list, projectIdentifier: string, recordCount: int, nameUsagesCount: int, category: list>, facets: table<field: string, counts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "subtype" $subtype "scalar") (serialize-qp "publishingOrg" $publishingOrg "scalar") (serialize-qp "hostingOrg" $hostingOrg "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "decade" $decade "scalar") (serialize-qp "publishingCountry" $publishingCountry "scalar") (serialize-qp "hostingCountry" $hostingCountry "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "license" $license "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "taxonKey" $taxonKey "scalar") (serialize-qp "recordCount" $recordCount "scalar") (serialize-qp "modifiedDate" $modifiedDate "scalar") (serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "doi" $doi "scalar") (serialize-qp "networkKey" $networkKey "scalar") (serialize-qp "endorsingNodeKey" $endorsingNodeKey "scalar") (serialize-qp "installationKey" $installationKey "scalar") (serialize-qp "endpointType" $endpointType "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "hl" $hl "scalar") (serialize-qp "facet" $facet "multi") (serialize-qp "facetMinCount" $facetMinCount "scalar") (serialize-qp "facetMultiselect" $facetMultiselect "scalar") (serialize-qp "facetLimit" $facetLimit "scalar") (serialize-qp "facetOffset" $facetOffset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataset/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export search across all collections.
#
# GET /grscicoll/collection/export
# operationId: listCollectionsExport
@deprecated --flag institution
export def "grscicoll-collection-export listCollectionsExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # default: TSV
  --institution: string # A key for the institution. Deprecated: use institutionKey instead. (DEPRECATED, format: uuid)
  --contentType: string # Content type of a GrSciColl collection. Accepts multiple values, for example `contentType=Paleontological&contentType=EarthPlanetary`.
  --preservationType: string # Preservation type of a GrSciColl collection. Accepts multiple values, for example `preservationType=SampleCryopreserved&preservationType=SampleFluidPreserved`.
  --accessionStatus: string # Accession status of a GrSciColl collection. Accepts multiple values, for example `accessionStatus=Institutional&accessionStatus=Project
  --personalCollection: string@bool-completer # Flag for personal GRSciColl collections
  --sourceId: string # sourceId of MasterSourceMetadata
  --qp-source: string@source-completer # Source attribute of MasterSourceMetadata
  --code: string # Code of a GrSciColl institution or collection
  --name: string # Name of a GrSciColl institution or collection
  --alternativeCode: string # Alternative code of a GrSciColl institution or collection
  --contact: string # Filters collections and institutions whose contacts contain the person key specified (format: uuid)
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --country: string@country-completer # Filters by country given as a ISO 639-1 (2 letter) country code.
  --gbifRegion: string@gbifRegion-completer # Filters by a gbif region
  --city: string # Filters by the city of the address. It searches in both the physical and the mailing address.
  --fuzzyName: string # It searches by name fuzzily so the parameter doesn't have to be the exact name
  --active: string@bool-completer # Active status of a GrSciColl institution or collection
  --masterSourceType: string@masterSourceType-completer # The master source type of a GRSciColl institution or collection
  --numberSpecimens: string # Number of specimens. It supports ranges and a `*` can be used as a wildcard
  --displayOnNHCPortal: string@bool-completer # Flag to show this record in the NHC portal
  --replacedBy: string # Key of the entity that replaced another entity (format: uuid)
  --occurrenceCount: string # Count of occurrences linked. It supports ranges and a `*` can be used as a wildcard
  --typeSpecimenCount: string # Count of type specimens linked. It supports ranges and a `*` can be used as a wildcard
  --institutionKey: string # Keys of institutions to filter by (format: uuid)
  --sortBy: string@sortBy-completer # Field to sort the results by. It only supports the fields contained in the enum.
  --sortOrder: string@sortOrder-completer # Sort order to use with the sortBy parameter
  --contactUserId: string # Filter by contact user ID
  --contactEmail: string # Filter by contact email
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "institution" $institution "scalar") (serialize-qp "contentType" $contentType "scalar") (serialize-qp "preservationType" $preservationType "scalar") (serialize-qp "accessionStatus" $accessionStatus "scalar") (serialize-qp "personalCollection" $personalCollection "scalar") (serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "alternativeCode" $alternativeCode "scalar") (serialize-qp "contact" $contact "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "gbifRegion" $gbifRegion "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuzzyName" $fuzzyName "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "masterSourceType" $masterSourceType "scalar") (serialize-qp "numberSpecimens" $numberSpecimens "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "scalar") (serialize-qp "replacedBy" $replacedBy "scalar") (serialize-qp "occurrenceCount" $occurrenceCount "scalar") (serialize-qp "typeSpecimenCount" $typeSpecimenCount "scalar") (serialize-qp "institutionKey" $institutionKey "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/collection/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export search across all institutions.
#
# GET /grscicoll/institution/export
# operationId: listInstitutionsExport
@deprecated --flag institution
export def "grscicoll-institution-export listInstitutionsExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # default: TSV
  --institution: string # A key for the institution. Deprecated: use institutionKey instead. (DEPRECATED, format: uuid)
  --contentType: string # Content type of a GrSciColl collection. Accepts multiple values, for example `contentType=Paleontological&contentType=EarthPlanetary`.
  --preservationType: string # Preservation type of a GrSciColl collection. Accepts multiple values, for example `preservationType=SampleCryopreserved&preservationType=SampleFluidPreserved`.
  --accessionStatus: string # Accession status of a GrSciColl collection. Accepts multiple values, for example `accessionStatus=Institutional&accessionStatus=Project
  --personalCollection: string@bool-completer # Flag for personal GRSciColl collections
  --sourceId: string # sourceId of MasterSourceMetadata
  --qp-source: string@source-completer # Source attribute of MasterSourceMetadata
  --code: string # Code of a GrSciColl institution or collection
  --name: string # Name of a GrSciColl institution or collection
  --alternativeCode: string # Alternative code of a GrSciColl institution or collection
  --contact: string # Filters collections and institutions whose contacts contain the person key specified (format: uuid)
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --country: string@country-completer # Filters by country given as a ISO 639-1 (2 letter) country code.
  --gbifRegion: string@gbifRegion-completer # Filters by a gbif region
  --city: string # Filters by the city of the address. It searches in both the physical and the mailing address.
  --fuzzyName: string # It searches by name fuzzily so the parameter doesn't have to be the exact name
  --active: string@bool-completer # Active status of a GrSciColl institution or collection
  --masterSourceType: string@masterSourceType-completer # The master source type of a GRSciColl institution or collection
  --numberSpecimens: string # Number of specimens. It supports ranges and a `*` can be used as a wildcard
  --displayOnNHCPortal: string@bool-completer # Flag to show this record in the NHC portal
  --replacedBy: string # Key of the entity that replaced another entity (format: uuid)
  --occurrenceCount: string # Count of occurrences linked. It supports ranges and a `*` can be used as a wildcard
  --typeSpecimenCount: string # Count of type specimens linked. It supports ranges and a `*` can be used as a wildcard
  --institutionKey: string # Keys of institutions to filter by (format: uuid)
  --sortBy: string@sortBy-completer # Field to sort the results by. It only supports the fields contained in the enum.
  --sortOrder: string@sortOrder-completer # Sort order to use with the sortBy parameter
  --contactUserId: string # Filter by contact user ID
  --contactEmail: string # Filter by contact email
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "institution" $institution "scalar") (serialize-qp "contentType" $contentType "scalar") (serialize-qp "preservationType" $preservationType "scalar") (serialize-qp "accessionStatus" $accessionStatus "scalar") (serialize-qp "personalCollection" $personalCollection "scalar") (serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "alternativeCode" $alternativeCode "scalar") (serialize-qp "contact" $contact "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "gbifRegion" $gbifRegion "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuzzyName" $fuzzyName "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "masterSourceType" $masterSourceType "scalar") (serialize-qp "numberSpecimens" $numberSpecimens "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "scalar") (serialize-qp "replacedBy" $replacedBy "scalar") (serialize-qp "occurrenceCount" $occurrenceCount "scalar") (serialize-qp "typeSpecimenCount" $typeSpecimenCount "scalar") (serialize-qp "institutionKey" $institutionKey "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/institution/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export search across all datasets.
#
# GET /dataset/search/export
# operationId: searchDatasetsExport
@deprecated --flag continent
export def "dataset-search-export searchDatasetsExport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # default: TSV
  --type: string@type-completer # The primary type of the dataset.
  --subtype: string@subtype-completer # The sub-type of the dataset.
  --publishingOrg: string # Filters datasets by their publishing organization UUID key (format: uuid)
  --hostingOrg: string # Filters datasets by their hosting organization UUID key (format: uuid)
  --keyword: string # Filters datasets by a case insensitive plain text keyword. The search is done on the merged collection of tags, the dataset keywordCollections and temporalCoverages.
  --decade: int # Filters datasets by their temporal coverage broken down to decades. Decades are given as a full year, e.g. 1880, 1960, 2000, etc, and will return datasets wholly contained in the decade as well as those that cover the entire decade or more. Facet by decade to get the break down, i.e. `facet=DECADE&limit=0` (format: int32)
  --publishingCountry: string@publishingCountry-completer # Filters datasets by their owning organization's country given as a ISO 639-1 (2 letter) country code
  --hostingCountry: string@hostingCountry-completer # Filters datasets by their hosting organization's country given as a ISO 639-1 (2 letter) country code
  --continent: string@continent-completer # Not implemented. (DEPRECATED)
  --license: string@license-completer # The dataset's licence.
  --projectId: string # Filter or facet based on the project ID of a given dataset. A dataset can have a project id if it is the result of a project. multiple datasets can have the same project id. (e.g. AA003-AA003311F)
  --taxonKey: int # A taxon key from the GBIF backbone. (format: int32)
  --recordCount: string # Number of records of the dataset. Accepts ranges and a `*` can be used as a wildcard. (e.g. 100,*)
  --modifiedDate: string # Date when the dataset was modified the last time. Accepts ranges and a `*` can be used as a wildcard. (e.g. 2022-05-01,*)
  --createdDate: string # Date when the dataset was created. Accepts ranges and a `*` can be used as a wildcard. (e.g. 2022-05-01,*)
  --doi: string # A DOI identifier.
  --networkKey: string # Network associated to a dataset (format: uuid)
  --endorsingNodeKey: string # Node key that endorsed this dataset's publisher (format: uuid)
  --installationKey: string # Key of the installation that hosts the dataset. (format: uuid)
  --endpointType: string@endpointType-completer # Type of the endpoint of the dataset.
  --category: string # Category of the dataset.
  --contactUserId: string # Filter datasets by contact user ID (e.g., ORCID).
  --contactEmail: string # Filter datasets by contact email address.
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "subtype" $subtype "scalar") (serialize-qp "publishingOrg" $publishingOrg "scalar") (serialize-qp "hostingOrg" $hostingOrg "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "decade" $decade "scalar") (serialize-qp "publishingCountry" $publishingCountry "scalar") (serialize-qp "hostingCountry" $hostingCountry "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "license" $license "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "taxonKey" $taxonKey "scalar") (serialize-qp "recordCount" $recordCount "scalar") (serialize-qp "modifiedDate" $modifiedDate "scalar") (serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "doi" $doi "scalar") (serialize-qp "networkKey" $networkKey "scalar") (serialize-qp "endorsingNodeKey" $endorsingNodeKey "scalar") (serialize-qp "installationKey" $installationKey "scalar") (serialize-qp "endpointType" $endpointType "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataset/search/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export collections for institutions matching search criteria
#
# GET /grscicoll/collection/exportForInstitution
# operationId: exportCollectionsForInstitutions
export def "grscicoll-collection-export-for-institution exportCollectionsForInstitutions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # default: TSV
  --searchRequest: record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "searchRequest" $searchRequest "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/collection/exportForInstitution" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest collections.
#
# GET /grscicoll/collection/suggest
# operationId: suggestCollections
export def "grscicoll-collection-suggest suggestCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
]: nothing -> table<key: string, code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/collection/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest datasets.
#
# GET /dataset/suggest
# operationId: suggestDatasets
@deprecated --flag continent
export def "dataset-suggest suggestDatasets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # The primary type of the dataset.
  --subtype: string@subtype-completer # The sub-type of the dataset.
  --publishingOrg: string # Filters datasets by their publishing organization UUID key (format: uuid)
  --hostingOrg: string # Filters datasets by their hosting organization UUID key (format: uuid)
  --keyword: string # Filters datasets by a case insensitive plain text keyword. The search is done on the merged collection of tags, the dataset keywordCollections and temporalCoverages.
  --decade: int # Filters datasets by their temporal coverage broken down to decades. Decades are given as a full year, e.g. 1880, 1960, 2000, etc, and will return datasets wholly contained in the decade as well as those that cover the entire decade or more. Facet by decade to get the break down, i.e. `facet=DECADE&limit=0` (format: int32)
  --publishingCountry: string@publishingCountry-completer # Filters datasets by their owning organization's country given as a ISO 639-1 (2 letter) country code
  --hostingCountry: string@hostingCountry-completer # Filters datasets by their hosting organization's country given as a ISO 639-1 (2 letter) country code
  --continent: string@continent-completer # Not implemented. (DEPRECATED)
  --license: string@license-completer # The dataset's licence.
  --projectId: string # Filter or facet based on the project ID of a given dataset. A dataset can have a project id if it is the result of a project. multiple datasets can have the same project id. (e.g. AA003-AA003311F)
  --taxonKey: int # A taxon key from the GBIF backbone. (format: int32)
  --recordCount: string # Number of records of the dataset. Accepts ranges and a `*` can be used as a wildcard. (e.g. 100,*)
  --modifiedDate: string # Date when the dataset was modified the last time. Accepts ranges and a `*` can be used as a wildcard. (e.g. 2022-05-01,*)
  --createdDate: string # Date when the dataset was created. Accepts ranges and a `*` can be used as a wildcard. (e.g. 2022-05-01,*)
  --doi: string # A DOI identifier.
  --networkKey: string # Network associated to a dataset (format: uuid)
  --endorsingNodeKey: string # Node key that endorsed this dataset's publisher (format: uuid)
  --installationKey: string # Key of the installation that hosts the dataset. (format: uuid)
  --endpointType: string@endpointType-completer # Type of the endpoint of the dataset.
  --category: string # Category of the dataset.
  --contactUserId: string # Filter datasets by contact user ID (e.g., ORCID).
  --contactEmail: string # Filter datasets by contact email address.
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
]: nothing -> table<key: string, title: string, description: string, type: string, subtype: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "subtype" $subtype "scalar") (serialize-qp "publishingOrg" $publishingOrg "scalar") (serialize-qp "hostingOrg" $hostingOrg "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "decade" $decade "scalar") (serialize-qp "publishingCountry" $publishingCountry "scalar") (serialize-qp "hostingCountry" $hostingCountry "scalar") (serialize-qp "continent" $continent "scalar") (serialize-qp "license" $license "scalar") (serialize-qp "projectId" $projectId "scalar") (serialize-qp "taxonKey" $taxonKey "scalar") (serialize-qp "recordCount" $recordCount "scalar") (serialize-qp "modifiedDate" $modifiedDate "scalar") (serialize-qp "createdDate" $createdDate "scalar") (serialize-qp "doi" $doi "scalar") (serialize-qp "networkKey" $networkKey "scalar") (serialize-qp "endorsingNodeKey" $endorsingNodeKey "scalar") (serialize-qp "installationKey" $installationKey "scalar") (serialize-qp "endpointType" $endpointType "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataset/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest installations.
#
# GET /installation/suggest
# operationId: suggestInstallations
export def "installation-suggest suggestInstallations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> table<key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/installation/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest institutions.
#
# GET /grscicoll/institution/suggest
# operationId: suggestInstitutions
export def "grscicoll-institution-suggest suggestInstitutions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
]: nothing -> table<key: string, code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/institution/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest networks.
#
# GET /network/suggest
# operationId: suggestNetworks
export def "network-suggest suggestNetworks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
]: nothing -> table<key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/network/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest nodes.
#
# GET /node/suggest
# operationId: suggestNodes
export def "node-suggest suggestNodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
]: nothing -> table<key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/node/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Suggest organizations.
#
# GET /organization/suggest
# operationId: suggestOrganizations
export def "organization-suggest suggestOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
]: nothing -> table<key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List collections for institutions matching search criteria
#
# GET /grscicoll/collection/listForInstitution
# operationId: listCollectionsForInstitutions
export def "grscicoll-collection-list-for-institution listCollectionsForInstitutions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchRequest: record
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, code: string, name: string, description: string, contentTypes: list, active: bool, personalCollection: bool, doi: string, email: list, phone: list, homepage: string, catalogUrls: list, apiUrls: list, preservationTypes: list, accessionStatus: string, institutionKey: string, mailingAddress: record, address: record, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, tags: list, identifiers: list, contactPersons: list, numberSpecimens: int, machineTags: list, taxonomicCoverage: string, geographicCoverage: string, notes: string, incorporatedCollections: list, alternativeCodes: list, comments: list, occurrenceMappings: list, replacedBy: string, masterSource: string, masterSourceMetadata: record, department: string, division: string, displayOnNHCPortal: bool, occurrenceCount: int, typeSpecimenCount: int, featuredImageUrl: string, featuredImageLicense: string, temporalCoverage: string, featuredImageAttribution: string, institutionName: string, institutionCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchRequest" $searchRequest "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/collection/listForInstitution" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show a summary of an enumeration
#
# GET /enumeration/basic/{name}
# operationId: enumerationBasic
export def "enumeration-basic enumerationBasic" [
  name: string
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
  let full_url = (build-url $base $"/enumeration/basic/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a derived dataset record
#
# GET /derivedDataset/{doiPrefix}/{doiSuffix}
# operationId: getDerivedDatasetByDoi
export def "derived-dataset get" [
  doiPrefix: string
  doiSuffix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<doi: string, originalDownloadDOI: string, description: string, citation: string, title: string, sourceUrl: string, createdBy: string, modifiedBy: string, registrationDate: string, created: string, modified: string, category: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/derivedDataset/($doiPrefix)/($doiSuffix)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a derived dataset
#
# PUT /derivedDataset/{doiPrefix}/{doiSuffix}
# operationId: updateDerivedDataset
export def "derived-dataset updateDerivedDataset" [
  doiPrefix: string
  doiSuffix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceUrl: string # format: uri
  --title: string
  --description: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/derivedDataset/($doiPrefix)/($doiSuffix)")
  let body = {sourceUrl: $sourceUrl, title: $title, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a dataset by DOI
#
# GET /dataset/doi/{prefix}/{suffix}
# operationId: datasetByDoi
export def "dataset-doi datasetByDoi" [
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
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, parentDatasetKey: string, duplicateOfDatasetKey: string, installationKey: string, publishingOrganizationKey: string, publishingOrganizationName: string, networkKeys: list, doi: string, version: string, external: bool, numConstituents: int, type: string, subtype: string, shortName: string, title: string, alias: string, abbreviation: string, description: string, language: string, homepage: string, logoUrl: string, citation: record, contactsCitation: list, rights: string, lockedForAutoUpdate: bool, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list, bibliographicCitations: list, curatorialUnits: list, taxonomicCoverages: list, geographicCoverageDescription: string, geographicCoverages: list, temporalCoverages: list, keywordCollections: list, project: record, samplingDescription: record, countryCoverage: list, collections: list, dataDescriptions: list, dataLanguage: string, purpose: string, introduction: string, gettingStarted: string, acknowledgements: string, additionalInfo: string, pubDate: string, maintenanceUpdateFrequency: string, maintenanceDescription: string, license: string, dwca: record, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dataset/doi/($prefix)/($suffix)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show the Country enumeration
#
# GET /enumeration/country
# operationId: enumerationCountry
export def "enumeration-country enumerationCountry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enumeration/country")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a single dataset
#
# GET /dataset/{key}
# operationId: getDataset
export def "dataset get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, parentDatasetKey: string, duplicateOfDatasetKey: string, installationKey: string, publishingOrganizationKey: string, publishingOrganizationName: string, networkKeys: list<string>, doi: string, version: string, external: bool, numConstituents: int, type: string, subtype: string, shortName: string, title: string, alias: string, abbreviation: string, description: string, language: string, homepage: string, logoUrl: string, citation: record<text: string, identifier: string, citationProvidedBySource: bool>, contactsCitation: table<key: int, abbreviatedName: string, firstName: string, lastName: string, roles: list, userId: list>, rights: string, lockedForAutoUpdate: bool, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: table<key: int, type: string, primary: bool, userId: list, salutation: string, firstName: string, lastName: string, position: list, description: string, email: list, phone: list, homepage: list, organization: string, address: list, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string>, endpoints: table<key: int, type: string, url: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, machineTags: list>, machineTags: table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string>, tags: table<key: int, value: string, createdBy: string, created: string>, identifiers: table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool>, comments: table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string>, bibliographicCitations: table<text: string, identifier: string, citationProvidedBySource: bool>, curatorialUnits: table<type: string, typeVerbatim: string, count: int, deviation: int, lower: int, upper: int>, taxonomicCoverages: table<description: string, coverages: list>, geographicCoverageDescription: string, geographicCoverages: table<description: string, boundingBox: record>, temporalCoverages: list<any>, keywordCollections: table<thesaurus: string, keywords: list>, project: record<title: string, identifier: string, description: string, contacts: list<record>, funding: string, awards: list<record>, studyAreaDescription: string, designDescription: string, relatedProjects: list<record>, abstract: string>, samplingDescription: record<studyExtent: string, sampling: string, qualityControl: string, methodSteps: list<string>>, countryCoverage: list<string>, collections: table<key: string, code: string, name: string, description: string, contentTypes: list, active: bool, personalCollection: bool, doi: string, email: list, phone: list, homepage: string, catalogUrls: list, apiUrls: list, preservationTypes: list, accessionStatus: string, institutionKey: string, mailingAddress: record, address: record, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, tags: list, identifiers: list, contactPersons: list, numberSpecimens: int, machineTags: list, taxonomicCoverage: string, geographicCoverage: string, notes: string, incorporatedCollections: list, alternativeCodes: list, comments: list, occurrenceMappings: list, replacedBy: string, masterSource: string, masterSourceMetadata: record, department: string, division: string, displayOnNHCPortal: bool, occurrenceCount: int, typeSpecimenCount: int, featuredImageUrl: string, featuredImageLicense: string, temporalCoverage: string, featuredImageAttribution: string>, dataDescriptions: table<name: string, charset: string, url: string, format: string, formatVersion: string>, dataLanguage: string, purpose: string, introduction: string, gettingStarted: string, acknowledgements: string, additionalInfo: string, pubDate: string, maintenanceUpdateFrequency: string, maintenanceDescription: string, license: string, dwca: record<coreType: string, extensions: list<string>, modified: string>, category: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing dataset
#
# PUT /dataset/{key}
# operationId: updateDataset
# --citation shape: {text?: string, identifier?: string, citationProvidedBySource?: bool}
# --contactsCitation item shape: {key?: int, abbreviatedName?: string, firstName?: string, lastName?: string, roles?: list, userId?: list}
# --contacts item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
# --endpoints item shape: {type: "EML"|"FEED"|"WFS"|"WMS"|"TCS_RDF"|"TCS_XML"|"DWC_ARCHIVE"|"DIGIR"|"DIGIR_MANIS"|"TAPIR"|"BIOCASE"|"BIOCASE_XML_ARCHIVE"|"OAI_PMH"|"COLDP"|"CAMTRAP_DP"|"DWC_DP"|"BIOM_1_0"|"BIOM_2_1"|"ACEF"|"TEXT_TREE"|"OTHER", url?: string, description?: string, machineTags: list}
# --machineTags item shape: {namespace: string, name: string, value: string}
# --tags item shape: {value: string}
# --identifiers item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --comments item shape: {content: string}
# --bibliographicCitations item shape: {text?: string, identifier?: string, citationProvidedBySource?: bool}
# --curatorialUnits item shape: {type?: "SPECIMENS"|"DRAWERS", typeVerbatim?: string, count?: int, deviation?: int, lower?: int, upper?: int}
# --taxonomicCoverages item shape: {description?: string, coverages?: list}
# --geographicCoverages item shape: {description?: string, boundingBox?: record}
# --keywordCollections item shape: {thesaurus?: string, keywords?: list}
# --project shape: {title?: string, identifier?: string, description?: string, contacts?: list, funding?: string, awards?: list, studyAreaDescription?: string, designDescription?: string, relatedProjects?: list, abstract?: string}
# --samplingDescription shape: {studyExtent?: string, sampling?: string, qualityControl?: string, methodSteps?: list}
# --collections item shape: {code?: string, name: string, description?: string, contentTypes?: list, active?: bool, personalCollection?: bool, doi?: string, email?: list, phone?: list, homepage?: string, catalogUrls?: list, apiUrls?: list, preservationTypes?: list, accessionStatus?: string, institutionKey?: string, mailingAddress?: record, address?: record, numberSpecimens?: int, taxonomicCoverage?: string, geographicCoverage?: string, notes?: string, incorporatedCollections?: list, alternativeCodes?: list, replacedBy?: string, masterSource?: "GRSCICOLL"|"GBIF_REGISTRY"|"IH", masterSourceMetadata?: record, department?: string, division?: string, displayOnNHCPortal?: bool, occurrenceCount?: int, typeSpecimenCount?: int, featuredImageUrl?: string, featuredImageLicense?: "CC0_1_0"|"CC_BY_4_0"|"CC_BY_NC_4_0"|"UNSPECIFIED"|"UNSUPPORTED", temporalCoverage?: string, featuredImageAttribution?: string}
# --dataDescriptions item shape: {name?: string, charset?: string, url?: string, format?: string, formatVersion?: string}
# --dwca shape: {coreType?: string, extensions?: list}
export def "dataset updateDataset" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentDatasetKey: string # If set, this dataset is a sub-dataset of the parent. (format: uuid)
  --duplicateOfDatasetKey: string # A dataset of which this dataset is a duplicate. Typically, this means this dataset is an old version of the duplicated dataset, which has replaced this dataset. Therefore **this link is usually found on deleted datasets**. (format: uuid)
  installationKey: string # The installation providing access to the source dataset.  *(NB Not required for updates.)* (format: uuid)
  publishingOrganizationKey: string # The publishing organization publishing this dataset.  *(NB Not required for updates.)* (format: uuid)
  --publishingOrganizationName: string # The publishing organization name.  *(NB Not required for updates.)*
  --networkKeys: list # A list of GBIF Networks to which this dataset belongs.
  --doi: string # The primary Digital Object Identifier (DOI) for this dataset.
  --version: string # The version of the published dataset.
  --external: string@bool-completer # Not currently used.
  --numConstituents: int # If set, the number of sub-datasets of this parent dataset. (format: int32)
  type: string@type-completer # The primary type of the dataset.  *(NB Not required for updates.)*
  --subtype: string@subtype-completer # The sub-type of the dataset.
  --shortName: string # Concise name of the dataset.
  title: string # The title of the dataset.  *(NB Not required for updates.)*
  --alias: string # An alias for this dataset. Rarely used.
  --abbreviation: string # An abbreviation for this dataset. Rarely used.
  --description: string # A description of the dataset.
  language: string@language-completer # The language of the dataset metadata.  *(NB Not required for updates.)*
  --homepage: string # A homepage with further details on the dataset. (format: uri)
  --logoUrl: string # A logo for the dataset, accessible over HTTP. (format: uri)
  --citation: record # shape: {text?: string, identifier?: string, citationProvidedBySource?: bool}
  --contactsCitation: list # Contacts use to generate a citation. — item shape: {key?: int, abbreviatedName?: string, firstName?: string, lastName?: string, roles?: list, userId?: list}
  --rights: string # Intellectual property rights applied to this dataset.  *Rarely used, see `license` instead.*
  --project: record # shape: {title?: string, identifier?: string, description?: string, contacts?: list, funding?: string, awards?: list, studyAreaDescription?: string, designDescription?: string, relatedProjects?: list, abstract?: string}
  --samplingDescription: record # shape: {studyExtent?: string, sampling?: string, qualityControl?: string, methodSteps?: list}
  --dwca: record # shape: {coreType?: string, extensions?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)")
  let body = {parentDatasetKey: $parentDatasetKey, duplicateOfDatasetKey: $duplicateOfDatasetKey, installationKey: $installationKey, publishingOrganizationKey: $publishingOrganizationKey, publishingOrganizationName: $publishingOrganizationName, networkKeys: $networkKeys, doi: $doi, version: $version, external: $external, numConstituents: $numConstituents, type: $type, subtype: $subtype, shortName: $shortName, title: $title, alias: $alias, abbreviation: $abbreviation, description: $description, language: $language, homepage: $homepage, logoUrl: $logoUrl, citation: $citation, contactsCitation: $contactsCitation, rights: $rights, project: $project, samplingDescription: $samplingDescription, dwca: $dwca} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing dataset
#
# DELETE /dataset/{key}
# operationId: deleteDataset
export def "dataset delete" [
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
  let full_url = (build-url $base $"/dataset/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve derived datasets of a dataset by key
#
# GET /derivedDataset/dataset/{key}
# operationId: getDerivedDatasetByDatasetKey
export def "derived-dataset-dataset list" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<doi: string, originalDownloadDOI: string, description: string, citation: string, title: string, sourceUrl: string, createdBy: string, modifiedBy: string, registrationDate: string, created: string, modified: string, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/derivedDataset/dataset/($key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search across institutions
#
# GET /grscicoll/institution/search
# operationId: searchInstitutions
export def "grscicoll-institution-search searchInstitutions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hl: string@bool-completer # Set `hl=true` to highlight terms matching the query when in fulltext search fields. The highlight will be an emphasis tag of class `gbifHl`.
  --type: string # Type of a GrSciColl institution. Accepts multiple values, for example `type=Museum&type=BotanicalGarden
  --institutionalGovernance: string # Institutional governance of a GrSciColl institution. Accepts multiple values, for example `InstitutionalGovernance=NonProfit&InstitutionalGovernance=Local`
  --discipline: string # Discipline of a GrSciColl institution. Accepts multiple values, for example `discipline=Zoology&discipline=Biological`
  --sourceId: string # sourceId of MasterSourceMetadata
  --qp-source: string@source-completer # Source attribute of MasterSourceMetadata
  --code: string # Code of a GrSciColl institution or collection
  --name: string # Name of a GrSciColl institution or collection
  --alternativeCode: string # Alternative code of a GrSciColl institution or collection
  --contact: string # Filters collections and institutions whose contacts contain the person key specified (format: uuid)
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --country: string@country-completer # Filters by country given as a ISO 639-1 (2 letter) country code.
  --gbifRegion: string@gbifRegion-completer # Filters by a gbif region
  --city: string # Filters by the city of the address. It searches in both the physical and the mailing address.
  --fuzzyName: string # It searches by name fuzzily so the parameter doesn't have to be the exact name
  --active: string@bool-completer # Active status of a GrSciColl institution or collection
  --masterSourceType: string@masterSourceType-completer # The master source type of a GRSciColl institution or collection
  --numberSpecimens: string # Number of specimens. It supports ranges and a `*` can be used as a wildcard
  --displayOnNHCPortal: string@bool-completer # Flag to show this record in the NHC portal
  --replacedBy: string # Key of the entity that replaced another entity (format: uuid)
  --occurrenceCount: string # Count of occurrences linked. It supports ranges and a `*` can be used as a wildcard
  --typeSpecimenCount: string # Count of type specimens linked. It supports ranges and a `*` can be used as a wildcard
  --institutionKey: string # Keys of institutions to filter by (format: uuid)
  --sortBy: string@sortBy-completer # Field to sort the results by. It only supports the fields contained in the enum.
  --sortOrder: string@sortOrder-completer # Sort order to use with the sortBy parameter
  --contactUserId: string # Filter by contact user ID
  --contactEmail: string # Filter by contact email
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, code: string, name: string, alternativeCodes: list, description: string, active: bool, displayOnNHCPortal: bool, country: string, mailingCountry: string, city: string, mailingCity: string, temporalCoverage: string, featuredImageLicense: string, featuredImageUrl: string, featuredImageAttribution: string, masterSource: string, highlights: list, types: list, institutionalGovernances: list, disciplines: list, latitude: float, longitude: float, foundingDate: int, numberSpecimens: int, occurrenceCount: int, typeSpecimenCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hl" $hl "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "institutionalGovernance" $institutionalGovernance "scalar") (serialize-qp "discipline" $discipline "scalar") (serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "alternativeCode" $alternativeCode "scalar") (serialize-qp "contact" $contact "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "gbifRegion" $gbifRegion "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuzzyName" $fuzzyName "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "masterSourceType" $masterSourceType "scalar") (serialize-qp "numberSpecimens" $numberSpecimens "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "scalar") (serialize-qp "replacedBy" $replacedBy "scalar") (serialize-qp "occurrenceCount" $occurrenceCount "scalar") (serialize-qp "typeSpecimenCount" $typeSpecimenCount "scalar") (serialize-qp "institutionKey" $institutionKey "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/institution/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show the Extension enumeration
#
# GET /enumeration/extension
# operationId: enumerationExtension
export def "enumeration-extension enumerationExtension" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enumeration/extension")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve derived datasets of a dataset by DOI
#
# GET /derivedDataset/dataset/{doiPrefix}/{doiSuffix}
# operationId: getDerivedDatasetByDatasetDoi
export def "derived-dataset-dataset get" [
  doiPrefix: string
  doiSuffix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<doi: string, originalDownloadDOI: string, description: string, citation: string, title: string, sourceUrl: string, createdBy: string, modifiedBy: string, registrationDate: string, created: string, modified: string, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/derivedDataset/dataset/($doiPrefix)/($doiSuffix)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search across collections
#
# GET /grscicoll/collection/search
# operationId: searchCollections
@deprecated --flag institution
export def "grscicoll-collection-search searchCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --institution: string # A key for the institution. Deprecated: use institutionKey instead. (DEPRECATED, format: uuid)
  --contentType: string # Content type of a GrSciColl collection. Accepts multiple values, for example `contentType=Paleontological&contentType=EarthPlanetary`.
  --preservationType: string # Preservation type of a GrSciColl collection. Accepts multiple values, for example `preservationType=SampleCryopreserved&preservationType=SampleFluidPreserved`.
  --accessionStatus: string # Accession status of a GrSciColl collection. Accepts multiple values, for example `accessionStatus=Institutional&accessionStatus=Project
  --personalCollection: string@bool-completer # Flag for personal GRSciColl collections
  --sourceId: string # sourceId of MasterSourceMetadata
  --qp-source: string@source-completer # Source attribute of MasterSourceMetadata
  --descriptorGroupKey: int # Key of the descriptor group (format: int64)
  --usageKey: int # Taxon usage key of the descriptor (format: int32)
  --usageName: string # Taxon usage name of the descriptor
  --usageRank: string@usageRank-completer # Taxon usage rank of the descriptor
  --taxonKey: int # Taxon key of the descriptor (format: int32)
  --country: string@country-completer # Filters by country given as a ISO 639-1 (2 letter) country code.
  --individualCount: string # Individual count of the descriptor. It supports ranges and a `*` can be used as a wildcard
  --identifiedBy: string # Identified by field of the descriptor
  --dateIdentified: string # Date identified field of the descriptor. It supports ranges and a `*` can be used as a wildcard (format: date-time)
  --typeStatus: string # Type status of the descriptor
  --recordedBy: string # RecordedBy of the descriptor
  --discipline: string # Discipline of the descriptor
  --objectClassification: string # Object classification of the descriptor
  --biome: string # Biome of the descriptor
  --biomeType: string # Biome type of the descriptor
  --issues: string # Issues of the descriptor
  --taxonIssues: string # Taxon Issues of the descriptor
  --checklistKey: string # Checklist key to use with the taxonomy filters.
  --hl: string@bool-completer # Set `hl=true` to highlight terms matching the query when in fulltext search fields. The highlight will be an emphasis tag of class `gbifHl`.
  --code: string # Code of a GrSciColl institution or collection
  --name: string # Name of a GrSciColl institution or collection
  --alternativeCode: string # Alternative code of a GrSciColl institution or collection
  --contact: string # Filters collections and institutions whose contacts contain the person key specified (format: uuid)
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --gbifRegion: string@gbifRegion-completer # Filters by a gbif region
  --city: string # Filters by the city of the address. It searches in both the physical and the mailing address.
  --fuzzyName: string # It searches by name fuzzily so the parameter doesn't have to be the exact name
  --active: string@bool-completer # Active status of a GrSciColl institution or collection
  --masterSourceType: string@masterSourceType-completer # The master source type of a GRSciColl institution or collection
  --numberSpecimens: string # Number of specimens. It supports ranges and a `*` can be used as a wildcard
  --displayOnNHCPortal: string@bool-completer # Flag to show this record in the NHC portal
  --replacedBy: string # Key of the entity that replaced another entity (format: uuid)
  --occurrenceCount: string # Count of occurrences linked. It supports ranges and a `*` can be used as a wildcard
  --typeSpecimenCount: string # Count of type specimens linked. It supports ranges and a `*` can be used as a wildcard
  --institutionKey: string # Keys of institutions to filter by (format: uuid)
  --sortBy: string@sortBy-completer # Field to sort the results by. It only supports the fields contained in the enum.
  --sortOrder: string@sortOrder-completer # Sort order to use with the sortBy parameter
  --contactUserId: string # Filter by contact user ID
  --contactEmail: string # Filter by contact email
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, code: string, name: string, alternativeCodes: list, description: string, active: bool, displayOnNHCPortal: bool, country: string, mailingCountry: string, city: string, mailingCity: string, temporalCoverage: string, featuredImageLicense: string, featuredImageUrl: string, featuredImageAttribution: string, masterSource: string, highlights: list, contentTypes: list, personalCollection: bool, preservationTypes: list, accessionStatus: string, institutionKey: string, institutionCode: string, institutionName: string, numberSpecimens: int, taxonomicCoverage: string, geographicCoverage: string, department: string, division: string, occurrenceCount: int, typeSpecimenCount: int, descriptorMatches: list>, facets: table<field: string, cardinality: int, counts: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "institution" $institution "scalar") (serialize-qp "contentType" $contentType "scalar") (serialize-qp "preservationType" $preservationType "scalar") (serialize-qp "accessionStatus" $accessionStatus "scalar") (serialize-qp "personalCollection" $personalCollection "scalar") (serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "descriptorGroupKey" $descriptorGroupKey "scalar") (serialize-qp "usageKey" $usageKey "scalar") (serialize-qp "usageName" $usageName "scalar") (serialize-qp "usageRank" $usageRank "scalar") (serialize-qp "taxonKey" $taxonKey "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "individualCount" $individualCount "scalar") (serialize-qp "identifiedBy" $identifiedBy "scalar") (serialize-qp "dateIdentified" $dateIdentified "scalar") (serialize-qp "typeStatus" $typeStatus "scalar") (serialize-qp "recordedBy" $recordedBy "scalar") (serialize-qp "discipline" $discipline "scalar") (serialize-qp "objectClassification" $objectClassification "scalar") (serialize-qp "biome" $biome "scalar") (serialize-qp "biomeType" $biomeType "scalar") (serialize-qp "issues" $issues "scalar") (serialize-qp "taxonIssues" $taxonIssues "scalar") (serialize-qp "checklistKey" $checklistKey "scalar") (serialize-qp "hl" $hl "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "alternativeCode" $alternativeCode "scalar") (serialize-qp "contact" $contact "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "gbifRegion" $gbifRegion "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuzzyName" $fuzzyName "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "masterSourceType" $masterSourceType "scalar") (serialize-qp "numberSpecimens" $numberSpecimens "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "scalar") (serialize-qp "replacedBy" $replacedBy "scalar") (serialize-qp "occurrenceCount" $occurrenceCount "scalar") (serialize-qp "typeSpecimenCount" $typeSpecimenCount "scalar") (serialize-qp "institutionKey" $institutionKey "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/collection/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show the Interpretation Remark enumeration
#
# GET /enumeration/interpretationRemark
# operationId: enumerationInterpretationRemark
export def "enumeration-interpretation-remark enumerationInterpretationRemark" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enumeration/interpretationRemark")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve derived datasets of a dataset by User
#
# GET /derivedDataset/user/{user}
# operationId: getDerivedDatasetByUser
export def "derived-dataset-user get" [
  user: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<doi: string, originalDownloadDOI: string, description: string, citation: string, title: string, sourceUrl: string, createdBy: string, modifiedBy: string, registrationDate: string, created: string, modified: string, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/derivedDataset/user/($user)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show the Language enumeration
#
# GET /enumeration/language
# operationId: enumerationLanguage
export def "enumeration-language enumerationLanguage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enumeration/language")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Show the License enumeration
#
# GET /enumeration/license
# operationId: enumerationLicense
export def "enumeration-license enumerationLicense" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/enumeration/license")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a single collection
#
# GET /grscicoll/collection/{key}
# operationId: getCollection
export def "grscicoll-collection get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, code: string, name: string, description: string, contentTypes: list<string>, active: bool, personalCollection: bool, doi: string, email: list<string>, phone: list<string>, homepage: string, catalogUrls: list<string>, apiUrls: list<string>, preservationTypes: list<string>, accessionStatus: string, institutionKey: string, mailingAddress: record<key: int, address: string, city: string, province: string, postalCode: string, country: string>, address: record<key: int, address: string, city: string, province: string, postalCode: string, country: string>, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, tags: table<key: int, value: string, createdBy: string, created: string>, identifiers: table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool>, contactPersons: table<key: int, type: string, primary: bool, userId: list, salutation: string, firstName: string, lastName: string, position: list, description: string, email: list, phone: list, homepage: list, organization: string, address: list, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string>, numberSpecimens: int, machineTags: table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string>, taxonomicCoverage: string, geographicCoverage: string, notes: string, incorporatedCollections: list<string>, alternativeCodes: table<code: string, description: string>, comments: table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string>, occurrenceMappings: table<key: int, code: string, parentCode: string, identifier: string, datasetKey: string, createdBy: string, created: string>, replacedBy: string, masterSource: string, masterSourceMetadata: record<key: int, source: string, sourceId: string, createdBy: string, created: string>, department: string, division: string, displayOnNHCPortal: bool, occurrenceCount: int, typeSpecimenCount: int, featuredImageUrl: string, featuredImageLicense: string, temporalCoverage: string, featuredImageAttribution: string, institutionName: string, institutionCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing collection
#
# PUT /grscicoll/collection/{key}
# operationId: updateCollection
# --mailingAddress shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
# --address shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
# --tags item shape: {value: string}
# --identifiers item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --contactPersons item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
# --machineTags item shape: {namespace: string, name: string, value: string}
# --alternativeCodes item shape: {code?: string, description?: string}
# --comments item shape: {content: string}
# --occurrenceMappings item shape: {key?: int, code?: string, parentCode?: string, identifier?: string, datasetKey: string, createdBy?: string, created?: string}
# --masterSourceMetadata shape: {source: "DATASET"|"ORGANIZATION"|"IH_IRN", sourceId: string}
export def "grscicoll-collection updateCollection" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # Code of the collection — identifies a collection at the owner's location.  *(NB Not required for updates.)*
  name: string # Descriptive name of the collection.  *(NB Not required for updates.)*
  --description: string # Description or summary of the contents of the collection.
  --contentTypes: list # Content type of the elements found in the collection.
  --active: string@bool-completer # Whether the collection is active/maintained.
  --personalCollection: string@bool-completer # Whether this collection belongs to an individual.
  --doi: string # A Digital Object Identifier for the collection.
  --email: list # Email addresses associated with the collection.
  --phone: list # Telephone numbers associated with the collection.
  --homepage: string # The collection's WWW homepage. (format: uri)
  --catalogUrls: list # URLs for interactive catalogues of the collection.
  --apiUrls: list # URLs for machine-readable APIs for the collection catalogue.
  --preservationTypes: list # The preservation mechanisms used for this collection.
  --accessionStatus: string # How the collection was added or joined.
  --institutionKey: string # The key of the institution owning or hosting the collection. (format: uuid)
  --mailingAddress: record # shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
  --address: record # shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
  --numberSpecimens: int # The number of specimens contained in this collection. (format: int32)
  --taxonomicCoverage: string # The taxonomic coverage of this collection.
  --geographicCoverage: string # The geographic coverage of this collection.
  --notes: string # Notes on the collection.
  --incorporatedCollections: list # Other collections incorporated into this collection.
  --alternativeCodes: list # Alternative codes for this collection. — item shape: {code?: string, description?: string}
  --replacedBy: string # A collection record that replaces this collection. (format: uuid)
  --masterSource: string@masterSource-completer # The primary source of this collection record.
  --masterSourceMetadata: record # shape: {source: "DATASET"|"ORGANIZATION"|"IH_IRN", sourceId: string}
  --department: string # An organizational department managing the collection.
  --division: string # An organizational division managing the collection.
  --displayOnNHCPortal: string@bool-completer # Whether the collection is shown on the NHC portal.
  --occurrenceCount: int # An estimate of the number of occurrences linked to the institution. (format: int32)
  --typeSpecimenCount: int # An estimate of the number of type specimens linked to the institution. (format: int32)
  --featuredImageUrl: string # URI to the image to be featured on the collection page, this image should be associated with a license. (format: uri)
  --featuredImageLicense: string@featuredImageLicense-completer # The license associated with the image to be featured on the collection page.
  --temporalCoverage: string # Temporal scope or focus of the collection. This free text field can be used to describe both the collection date ranges as well as the geological time group(s) of the collection objects in the context of paleontological collections.
  --featuredImageAttribution: string #  Information about ownership, attribution, etc. of the featured image. This value with be used to generate a suggested citation of the image.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)")
  let body = {code: $code, name: $name, description: $description, contentTypes: $contentTypes, active: $active, personalCollection: $personalCollection, doi: $doi, email: $email, phone: $phone, homepage: $homepage, catalogUrls: $catalogUrls, apiUrls: $apiUrls, preservationTypes: $preservationTypes, accessionStatus: $accessionStatus, institutionKey: $institutionKey, mailingAddress: $mailingAddress, address: $address, numberSpecimens: $numberSpecimens, taxonomicCoverage: $taxonomicCoverage, geographicCoverage: $geographicCoverage, notes: $notes, incorporatedCollections: $incorporatedCollections, alternativeCodes: $alternativeCodes, replacedBy: $replacedBy, masterSource: $masterSource, masterSourceMetadata: $masterSourceMetadata, department: $department, division: $division, displayOnNHCPortal: $displayOnNHCPortal, occurrenceCount: $occurrenceCount, typeSpecimenCount: $typeSpecimenCount, featuredImageUrl: $featuredImageUrl, featuredImageLicense: $featuredImageLicense, temporalCoverage: $temporalCoverage, featuredImageAttribution: $featuredImageAttribution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing collection
#
# DELETE /grscicoll/collection/{key}
# operationId: deleteCollection
export def "grscicoll-collection delete" [
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
  let full_url = (build-url $base $"/grscicoll/collection/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a single collection in Latimer Core format
#
# GET /grscicoll/collection/latimerCore/{key}
# operationId: getCollectionAsLatimerCore
export def "grscicoll-collection-latimer-core get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<collectionName: string, description: string, discipline: list<string>, typeOfObjectGroup: list<string>, hasOrganisationalUnit: table<organisationalUnitName: string, organisationalUnitType: string, address: list, contactDetail: list, identifier: list, measurementOrFact: list, reference: list>, isCurrentCollection: bool, preservationMethod: list<string>, address: table<key: int, address: string, city: string, province: string, postalCode: string, country: string>, collectionStatusHistory: table<status: string, statusType: string>, contactDetail: table<contactDetailValue: string, contactDetailCategory: string>, geographicContext: table<hasMeasurementOrFact: list>, identifier: table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool>, measurementOrFact: table<measurementFactText: string, measurementValue: string, measurementType: string>, personRole: table<person: list, role: list, measurementOrFact: list>, reference: table<resourceIRI: string, referenceType: string, referenceName: string>, resourceRelationship: table<relatedResourceName: string, relationshipOfResource: string>, objectClassification: table<objectClassificationName: string, objectClassificationLevel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/latimerCore/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing collection sent in Latimer Core format
#
# PUT /grscicoll/collection/latimerCore/{key}
# operationId: updateCollectionFromLatimerCore
# --hasOrganisationalUnit item shape: {organisationalUnitName?: string, organisationalUnitType?: string, address?: list, contactDetail?: list, identifier?: list, measurementOrFact?: list, reference?: list}
# --address item shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
# --collectionStatusHistory item shape: {status?: string, statusType?: string}
# --contactDetail item shape: {contactDetailValue?: string, contactDetailCategory?: string}
# --geographicContext item shape: {hasMeasurementOrFact?: list}
# --identifier item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --measurementOrFact item shape: {measurementFactText?: string, measurementValue?: string, measurementType?: string}
# --personRole item shape: {person?: list, role?: list, measurementOrFact?: list}
# --reference item shape: {resourceIRI?: string, referenceType?: string, referenceName?: string}
# --resourceRelationship item shape: {relatedResourceName?: string, relationshipOfResource?: string}
# --objectClassification item shape: {objectClassificationName?: string, objectClassificationLevel?: string}
export def "grscicoll-collection-latimer-core updateCollectionFromLatimerCore" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --collectionName: string
  --description: string
  --discipline: list
  --typeOfObjectGroup: list
  --hasOrganisationalUnit: list # item shape: {organisationalUnitName?: string, organisationalUnitType?: string, address?: list, contactDetail?: list, identifier?: list, measurementOrFact?: list, reference?: list}
  --isCurrentCollection: string@bool-completer
  --preservationMethod: list
  --address: list # item shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
  --collectionStatusHistory: list # item shape: {status?: string, statusType?: string}
  --contactDetail: list # item shape: {contactDetailValue?: string, contactDetailCategory?: string}
  --geographicContext: list # item shape: {hasMeasurementOrFact?: list}
  --identifier: list # item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
  --measurementOrFact: list # item shape: {measurementFactText?: string, measurementValue?: string, measurementType?: string}
  --personRole: list # item shape: {person?: list, role?: list, measurementOrFact?: list}
  --reference: list # item shape: {resourceIRI?: string, referenceType?: string, referenceName?: string}
  --resourceRelationship: list # item shape: {relatedResourceName?: string, relationshipOfResource?: string}
  --objectClassification: list # item shape: {objectClassificationName?: string, objectClassificationLevel?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/latimerCore/($key)")
  let body = {collectionName: $collectionName, description: $description, discipline: $discipline, typeOfObjectGroup: $typeOfObjectGroup, hasOrganisationalUnit: $hasOrganisationalUnit, isCurrentCollection: $isCurrentCollection, preservationMethod: $preservationMethod, address: $address, collectionStatusHistory: $collectionStatusHistory, contactDetail: $contactDetail, geographicContext: $geographicContext, identifier: $identifier, measurementOrFact: $measurementOrFact, personRole: $personRole, reference: $reference, resourceRelationship: $resourceRelationship, objectClassification: $objectClassification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve derived dataset citation
#
# GET /derivedDataset/{doiPrefix}/{doiSuffix}/citation
# operationId: getDerivedDatasetCitation
export def "derived-dataset-citation get" [
  doiPrefix: string
  doiSuffix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/derivedDataset/($doiPrefix)/($doiSuffix)/citation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a single installation
#
# GET /installation/{key}
# operationId: getInstallation
export def "installation get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, organizationKey: string, type: string, title: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, disabled: bool, contacts: table<key: int, type: string, primary: bool, userId: list, salutation: string, firstName: string, lastName: string, position: list, description: string, email: list, phone: list, homepage: list, organization: string, address: list, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string>, endpoints: table<key: int, type: string, url: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, machineTags: list>, machineTags: table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string>, tags: table<key: int, value: string, createdBy: string, created: string>, identifiers: table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool>, comments: table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing installation
#
# PUT /installation/{key}
# operationId: updateInstallation
# --contacts item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
# --endpoints item shape: {type: "EML"|"FEED"|"WFS"|"WMS"|"TCS_RDF"|"TCS_XML"|"DWC_ARCHIVE"|"DIGIR"|"DIGIR_MANIS"|"TAPIR"|"BIOCASE"|"BIOCASE_XML_ARCHIVE"|"OAI_PMH"|"COLDP"|"CAMTRAP_DP"|"DWC_DP"|"BIOM_1_0"|"BIOM_2_1"|"ACEF"|"TEXT_TREE"|"OTHER", url?: string, description?: string, machineTags: list}
# --machineTags item shape: {namespace: string, name: string, value: string}
# --tags item shape: {value: string}
# --identifiers item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --comments item shape: {content: string}
export def "installation updateInstallation" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organizationKey: string # The publishing organization managing this installation.  *(NB Not required for updates.)* (format: uuid)
  type: string@type-completer-1 # The type of the installation. Defines what protocols are usedfor communication.  *(NB Not required for updates.)*
  title: string # A name for the installation.  *(NB Not required for updates.)*
  --description: string # A description for the installation.
  --disabled: string@bool-completer # Whether the installation is disabled. A disabled installation is not checked for new or deleted datasets, or metadata changes to existingdatasets. However, data updates from existing datasets are not affected.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)")
  let body = {organizationKey: $organizationKey, type: $type, title: $title, description: $description, disabled: $disabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an installation
#
# DELETE /installation/{key}
# operationId: deleteInstallation
export def "installation delete" [
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
  let full_url = (build-url $base $"/installation/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a single institution
#
# GET /grscicoll/institution/{key}
# operationId: getInstitution
export def "grscicoll-institution get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, code: string, name: string, description: string, types: list<string>, active: bool, email: list<string>, phone: list<string>, homepage: string, catalogUrls: list<string>, apiUrls: list<string>, institutionalGovernances: list<string>, disciplines: list<string>, latitude: float, longitude: float, mailingAddress: record<key: int, address: string, city: string, province: string, postalCode: string, country: string>, address: record<key: int, address: string, city: string, province: string, postalCode: string, country: string>, additionalNames: list<string>, foundingDate: int, numberSpecimens: int, logoUrl: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, tags: table<key: int, value: string, createdBy: string, created: string>, identifiers: table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool>, contactPersons: table<key: int, type: string, primary: bool, userId: list, salutation: string, firstName: string, lastName: string, position: list, description: string, email: list, phone: list, homepage: list, organization: string, address: list, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string>, machineTags: table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string>, alternativeCodes: table<code: string, description: string>, comments: table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string>, occurrenceMappings: table<key: int, code: string, parentCode: string, identifier: string, datasetKey: string, createdBy: string, created: string>, replacedBy: string, convertedToCollection: string, masterSource: string, masterSourceMetadata: record<key: int, source: string, sourceId: string, createdBy: string, created: string>, displayOnNHCPortal: bool, occurrenceCount: int, typeSpecimenCount: int, featuredImageUrl: string, featuredImageLicense: string, featuredImageAttribution: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing institution
#
# PUT /grscicoll/institution/{key}
# operationId: updateInstitution
# --mailingAddress shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
# --address shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
# --tags item shape: {value: string}
# --identifiers item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --contactPersons item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
# --machineTags item shape: {namespace: string, name: string, value: string}
# --alternativeCodes item shape: {code?: string, description?: string}
# --comments item shape: {content: string}
# --occurrenceMappings item shape: {key?: int, code?: string, parentCode?: string, identifier?: string, datasetKey: string, createdBy?: string, created?: string}
# --masterSourceMetadata shape: {source: "DATASET"|"ORGANIZATION"|"IH_IRN", sourceId: string}
export def "grscicoll-institution updateInstitution" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # Code used to identify the institution.  *(NB Not required for updates.)*
  name: string # Name or title of the institution.  *(NB Not required for updates.)*
  --description: string # Description of the institution.
  --types: list # Types of the institution, describing its main activities.
  --active: string@bool-completer # Whether the institution is active or operational.
  --email: list # Email addresses associated with the institution.
  --phone: list # Telephone numbers associated with the instutiton.
  --homepage: string # The institution's WWW homepage. (format: uri)
  --catalogUrls: list # URLs for the main interactive catalogues of the institution.
  --apiUrls: list # URLs for machine-readable APIs for the institution catalogues.
  --institutionalGovernances: list # The mechanisms, processes and relations by which an institution is controlled and directed.
  --disciplines: list # The academic or research disciplines to which an institution is dedicated.
  --latitude: float # The latitude of the institution.
  --longitude: float # The longitude of the institution.
  --mailingAddress: record # shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
  --address: record # shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
  --additionalNames: list # Additional names by which the institution is known.
  --foundingDate: int # The date the institution was founded or established. (format: int32)
  --numberSpecimens: int # An estimate of the number of specimens hosted by the institution. (format: int32)
  --logoUrl: string # A URL to a logo for the institution. (format: uri)
  --contactPersons: list # A list of contact people for this institution. — item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
  --alternativeCodes: list # Alternative codes for this institution. — item shape: {code?: string, description?: string}
  --replacedBy: string # A collection record that replaces this collection. (format: uuid)
  --convertedToCollection: string # Indicates if the institution was converted to a collection and specifies the UUID key of that collection (format: uuid)
  --masterSource: string@masterSource-completer # The primary source of this institution record.
  --masterSourceMetadata: record # shape: {source: "DATASET"|"ORGANIZATION"|"IH_IRN", sourceId: string}
  --displayOnNHCPortal: string@bool-completer # Whether the institution is shown on the NHC portal.
  --occurrenceCount: int # An estimate of the number of occurrences linked to the institution. (format: int32)
  --typeSpecimenCount: int # An estimate of the number of type specimens linked to the institution. (format: int32)
  --featuredImageUrl: string # URI to the image to be featured on the institution page, this image should be associated with a license. (format: uri)
  --featuredImageLicense: string@featuredImageLicense-completer # The license associated with the image to be featured on the institution page.
  --featuredImageAttribution: string #  Information about ownership, attribution, etc. of the featured image. This value with be used to generate a suggested citation of the image.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)")
  let body = {code: $code, name: $name, description: $description, types: $types, active: $active, email: $email, phone: $phone, homepage: $homepage, catalogUrls: $catalogUrls, apiUrls: $apiUrls, institutionalGovernances: $institutionalGovernances, disciplines: $disciplines, latitude: $latitude, longitude: $longitude, mailingAddress: $mailingAddress, address: $address, additionalNames: $additionalNames, foundingDate: $foundingDate, numberSpecimens: $numberSpecimens, logoUrl: $logoUrl, contactPersons: $contactPersons, alternativeCodes: $alternativeCodes, replacedBy: $replacedBy, convertedToCollection: $convertedToCollection, masterSource: $masterSource, masterSourceMetadata: $masterSourceMetadata, displayOnNHCPortal: $displayOnNHCPortal, occurrenceCount: $occurrenceCount, typeSpecimenCount: $typeSpecimenCount, featuredImageUrl: $featuredImageUrl, featuredImageLicense: $featuredImageLicense, featuredImageAttribution: $featuredImageAttribution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an existing institution
#
# DELETE /grscicoll/institution/{key}
# operationId: deleteInstitution
export def "grscicoll-institution delete" [
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
  let full_url = (build-url $base $"/grscicoll/institution/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a single institution in Latimer Core format
#
# GET /grscicoll/institution/latimerCore/{key}
# operationId: getInstitutionAsLatimerCore
export def "grscicoll-institution-latimer-core get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organisationalUnitName: string, organisationalUnitType: string, address: table<key: int, address: string, city: string, province: string, postalCode: string, country: string>, contactDetail: table<contactDetailValue: string, contactDetailCategory: string>, identifier: table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool>, measurementOrFact: table<measurementFactText: string, measurementValue: string, measurementType: string>, reference: table<resourceIRI: string, referenceType: string, referenceName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/latimerCore/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing institution sent in Latimer Core format
#
# PUT /grscicoll/institution/latimerCore/{key}
# operationId: updateInstitutionFromLatimerCore
# --address item shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
# --contactDetail item shape: {contactDetailValue?: string, contactDetailCategory?: string}
# --identifier item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --measurementOrFact item shape: {measurementFactText?: string, measurementValue?: string, measurementType?: string}
# --reference item shape: {resourceIRI?: string, referenceType?: string, referenceName?: string}
export def "grscicoll-institution-latimer-core updateInstitutionFromLatimerCore" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organisationalUnitName: string
  --organisationalUnitType: string
  --address: list # item shape: {key?: int, address?: string, city?: string, province?: string, postalCode?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ"}
  --contactDetail: list # item shape: {contactDetailValue?: string, contactDetailCategory?: string}
  --identifier: list # item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
  --measurementOrFact: list # item shape: {measurementFactText?: string, measurementValue?: string, measurementType?: string}
  --reference: list # item shape: {resourceIRI?: string, referenceType?: string, referenceName?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/latimerCore/($key)")
  let body = {organisationalUnitName: $organisationalUnitName, organisationalUnitType: $organisationalUnitType, address: $address, contactDetail: $contactDetail, identifier: $identifier, measurementOrFact: $measurementOrFact, reference: $reference} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get details of a single network
#
# GET /network/{key}
# operationId: getNetwork
export def "network get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, title: string, description: string, language: string, numConstituents: int, email: list<string>, phone: list<string>, homepage: list<string>, logoUrl: string, address: list<string>, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: table<key: int, type: string, primary: bool, userId: list, salutation: string, firstName: string, lastName: string, position: list, description: string, email: list, phone: list, homepage: list, organization: string, address: list, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string>, endpoints: table<key: int, type: string, url: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, machineTags: list>, machineTags: table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string>, tags: table<key: int, value: string, createdBy: string, created: string>, identifiers: table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool>, comments: table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing network
#
# PUT /network/{key}
# operationId: updateNetwork
# --contacts item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
# --endpoints item shape: {type: "EML"|"FEED"|"WFS"|"WMS"|"TCS_RDF"|"TCS_XML"|"DWC_ARCHIVE"|"DIGIR"|"DIGIR_MANIS"|"TAPIR"|"BIOCASE"|"BIOCASE_XML_ARCHIVE"|"OAI_PMH"|"COLDP"|"CAMTRAP_DP"|"DWC_DP"|"BIOM_1_0"|"BIOM_2_1"|"ACEF"|"TEXT_TREE"|"OTHER", url?: string, description?: string, machineTags: list}
# --machineTags item shape: {namespace: string, name: string, value: string}
# --tags item shape: {value: string}
# --identifiers item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --comments item shape: {content: string}
export def "network updateNetwork" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # A name for the network.  *(NB Not required for updates.)*
  --description: string # A description for the network.
  language: string@language-completer # The language of the network metadata.  *(NB Not required for updates.)*
  --numConstituents: int # The number of datasets collected in this network. (format: int32)
  --email: list # Email addresses associated with this network.
  --phone: list # Telephone numbers associated with this network.
  --homepage: list # Homepages with further details on the network.
  --logoUrl: string # A logo for the network, accessible over HTTP. (format: uri)
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the network's address.
  --province: string # The province or similar line of the network's address.
  --country: string@country-completer # The country or other region of the network's address.
  --postalCode: string # The postal code or similar line of the network's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)")
  let body = {title: $title, description: $description, language: $language, numConstituents: $numConstituents, email: $email, phone: $phone, homepage: $homepage, logoUrl: $logoUrl, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a network
#
# DELETE /network/{key}
# operationId: deleteNetwork
export def "network delete" [
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
  let full_url = (build-url $base $"/network/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a single node
#
# GET /node/{key}
# operationId: getNode
export def "node get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, type: string, participationStatus: string, participantSince: int, dateSignedMOU: string, gbifRegion: string, title: string, participantTitle: string, abbreviation: string, description: string, email: list<string>, phone: list<string>, homepage: list<string>, logoUrl: string, address: list<string>, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: table<key: int, type: string, primary: bool, userId: list, salutation: string, firstName: string, lastName: string, position: list, description: string, email: list, phone: list, homepage: list, organization: string, address: list, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string>, endpoints: table<key: int, type: string, url: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, machineTags: list>, machineTags: table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string>, tags: table<key: int, value: string, createdBy: string, created: string>, identifiers: table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool>, comments: table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a single publishing organization
#
# GET /organization/{key}
# operationId: getOrganization
export def "organization get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, endorsingNodeKey: string, endorsementApproved: bool, endorsementStatus: string, title: string, abbreviation: string, description: string, language: string, email: list<string>, phone: list<string>, homepage: list<string>, logoUrl: string, address: list<string>, city: string, province: string, country: string, postalCode: string, latitude: float, longitude: float, numPublishedDatasets: int, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, endorsed: string, contacts: table<key: int, type: string, primary: bool, userId: list, salutation: string, firstName: string, lastName: string, position: list, description: string, email: list, phone: list, homepage: list, organization: string, address: list, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string>, endpoints: table<key: int, type: string, url: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, machineTags: list>, machineTags: table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string>, tags: table<key: int, value: string, createdBy: string, created: string>, identifiers: table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool>, comments: table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing organization
#
# PUT /organization/{key}
# operationId: updateOrganization
# --contacts item shape: {type?: "TECHNICAL_POINT_OF_CONTACT"|"ADMINISTRATIVE_POINT_OF_CONTACT"|"POINT_OF_CONTACT"|"ORIGINATOR"|"METADATA_AUTHOR"|"PRINCIPAL_INVESTIGATOR"|"AUTHOR"|"CONTENT_PROVIDER"|"CUSTODIAN_STEWARD"|"DISTRIBUTOR"|"EDITOR"|"OWNER"|"PROCESSOR"|"PUBLISHER"|"USER"|"PROGRAMMER"|"CURATOR"|"DATA_ADMINISTRATOR"|"SYSTEM_ADMINISTRATOR"|"HEAD_OF_DELEGATION"|"TEMPORARY_HEAD_OF_DELEGATION"|"ADDITIONAL_DELEGATE"|"TEMPORARY_DELEGATE"|"REGIONAL_NODE_REPRESENTATIVE"|"NODE_MANAGER"|"NODE_STAFF"|"REVIEWER", primary?: bool, userId?: list, salutation?: string, firstName?: string, lastName?: string, position?: list, description?: string, email?: list, phone?: list, homepage?: list, organization?: string, address?: list, city?: string, province?: string, country?: "AF"|"AX"|"AL"|"DZ"|"AS"|"AD"|"AO"|"AI"|"AQ"|"AG"|"AR"|"AM"|"AW"|"AU"|"AT"|"AZ"|"BS"|"BH"|"BD"|"BB"|"BY"|"BE"|"BZ"|"BJ"|"BM"|"BT"|"BO"|"BQ"|"BA"|"BW"|"BV"|"BR"|"IO"|"BN"|"BG"|"BF"|"BI"|"KH"|"CM"|"CA"|"CV"|"KY"|"CF"|"TD"|"CL"|"CN"|"CX"|"CC"|"CO"|"KM"|"CD"|"CG"|"CK"|"CR"|"CI"|"HR"|"CU"|"CW"|"CY"|"CZ"|"DK"|"DJ"|"DM"|"DO"|"EC"|"EG"|"SV"|"GQ"|"ER"|"EE"|"ET"|"FK"|"FO"|"FJ"|"FI"|"FR"|"GF"|"PF"|"TF"|"GA"|"GM"|"GE"|"DE"|"GH"|"GI"|"GR"|"GL"|"GD"|"GP"|"GU"|"GT"|"GG"|"GN"|"GW"|"GY"|"HT"|"HM"|"VA"|"HN"|"HK"|"HU"|"IS"|"IN"|"ID"|"IR"|"IQ"|"IE"|"IM"|"IL"|"IT"|"JM"|"JP"|"JE"|"JO"|"KZ"|"KE"|"KI"|"KP"|"KR"|"KW"|"KG"|"LA"|"LV"|"LB"|"LS"|"LR"|"LY"|"LI"|"LT"|"LU"|"MO"|"MK"|"MG"|"MW"|"MY"|"MV"|"ML"|"MT"|"MH"|"MQ"|"MR"|"MU"|"YT"|"MX"|"FM"|"MD"|"MC"|"MN"|"ME"|"MS"|"MA"|"MZ"|"MM"|"NA"|"NR"|"NP"|"NL"|"NC"|"NZ"|"NI"|"NE"|"NG"|"NU"|"NF"|"MP"|"NO"|"OM"|"PK"|"PW"|"PS"|"PA"|"PG"|"PY"|"PE"|"PH"|"PN"|"PL"|"PT"|"PR"|"QA"|"RE"|"RO"|"RU"|"RW"|"BL"|"SH"|"KN"|"LC"|"MF"|"PM"|"VC"|"WS"|"SM"|"ST"|"SA"|"SN"|"RS"|"SC"|"SL"|"SG"|"SX"|"SK"|"SI"|"SB"|"SO"|"ZA"|"GS"|"SS"|"ES"|"LK"|"SD"|"SR"|"SJ"|"SZ"|"SE"|"CH"|"SY"|"TW"|"TJ"|"TZ"|"TH"|"TL"|"TG"|"TK"|"TO"|"TT"|"TN"|"TR"|"TM"|"TC"|"TV"|"UG"|"UA"|"AE"|"GB"|"US"|"UM"|"UY"|"UZ"|"VU"|"VE"|"VN"|"VG"|"VI"|"WF"|"EH"|"YE"|"ZM"|"ZW"|"AA"|"XK"|"XZ"|"ZZ", postalCode?: string}
# --endpoints item shape: {type: "EML"|"FEED"|"WFS"|"WMS"|"TCS_RDF"|"TCS_XML"|"DWC_ARCHIVE"|"DIGIR"|"DIGIR_MANIS"|"TAPIR"|"BIOCASE"|"BIOCASE_XML_ARCHIVE"|"OAI_PMH"|"COLDP"|"CAMTRAP_DP"|"DWC_DP"|"BIOM_1_0"|"BIOM_2_1"|"ACEF"|"TEXT_TREE"|"OTHER", url?: string, description?: string, machineTags: list}
# --machineTags item shape: {namespace: string, name: string, value: string}
# --tags item shape: {value: string}
# --identifiers item shape: {type: "URL"|"LSID"|"HANDLER"|"DOI"|"UUID"|"FTP"|"URI"|"UNKNOWN"|"GBIF_PORTAL"|"GBIF_NODE"|"GBIF_PARTICIPANT"|"GRSCICOLL_ID"|"GRSCICOLL_URI"|"IH_IRN"|"ROR"|"GRID"|"CITES"|"SYMBIOTA_UUID"|"WIKIDATA"|"NCBI_BIOCOLLECTION"|"ISIL"|"CLB_DATASET_KEY"|"RNC_COLOMBIA", identifier: string, primary: bool}
# --comments item shape: {content: string}
export def "organization updateOrganization" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  endorsingNodeKey: string # The participant node which has endorsed or would endorse this publishing organization.  *(NB Not required for updates.)* (format: uuid)
  --endorsementApproved: string@bool-completer # Whether the participant node in `endorsingNodeKey` has endorsed this publishing organization — whether `endorsementStatus == ENDORSED`.
  --endorsementStatus: string@endorsementStatus-completer # The endorsement decision regarding this publishing organization made by the participant node in `endorsingNodeKey`.
  title: string # The title of the publishing organization.  *(NB Not required for updates.)*
  --abbreviation: string # The abbreviation for the publishing organization.
  --description: string # The description of the publishing organization.
  language: string@language-completer # The primary language of the description of the publishing organization.  *(NB Not required for updates.)*
  --email: list # Email addresses associated with this publishing organization.
  --phone: list # Telephone numbers associated with this publishing organization.
  --homepage: list # Homepages with further details on the publishing organization.
  --logoUrl: string # A logo for the publishing organization, accessible over HTTP. (format: uri)
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the publishing organization's address.
  --province: string # The province or similar line of the publishing organization's address.
  country: string@country-completer # The country or other region of the publishing organization's address.
  --postalCode: string # The postal code or similar line of the publishing organization's address.
  --latitude: float # The latitude of the publishing organization.
  --longitude: float # The longitude of the publishing organization.
  --endorsed: string # The time when this publishing organization was endorsed by the linked participant node. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)")
  let body = {endorsingNodeKey: $endorsingNodeKey, endorsementApproved: $endorsementApproved, endorsementStatus: $endorsementStatus, title: $title, abbreviation: $abbreviation, description: $description, language: $language, email: $email, phone: $phone, homepage: $homepage, logoUrl: $logoUrl, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode, latitude: $latitude, longitude: $longitude, endorsed: $endorsed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a publishing organization
#
# DELETE /organization/{key}
# operationId: deleteOrganization
export def "organization delete" [
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
  let full_url = (build-url $base $"/organization/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Schedule a new ingestion of the dataset
#
# POST /dataset/{key}/crawl
# operationId: crawlDataset
export def "dataset-crawl crawlDataset" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --platform: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dataset/($key)/crawl" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve derived dataset related datasets
#
# GET /derivedDataset/{doiPrefix}/{doiSuffix}/datasets
# operationId: getDerivedDatasetRelatedDatasets
export def "derived-dataset-datasets get" [
  doiPrefix: string
  doiSuffix: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<datasetKey: string, datasetDOI: string, datasetTitle: string, derivedDatasetDOI: string, numberRecords: int, citation: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/derivedDataset/($doiPrefix)/($doiSuffix)/datasets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of all crawl attempts for a dataset
#
# GET /dataset/{key}/process
# operationId: listDatasetCrawlAttempt
export def "dataset-process listDatasetCrawlAttempt" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<datasetKey: string, crawlJob: record, startedCrawling: string, finishedCrawling: string, crawlContext: string, finishReason: string, processStateOccurrence: string, processStateChecklist: string, processStateSample: string, declaredCount: int, pagesCrawled: int, pagesFragmentedSuccessful: int, pagesFragmentedError: int, fragmentsEmitted: int, fragmentsReceived: int, rawOccurrencesPersistedNew: int, rawOccurrencesPersistedUpdated: int, rawOccurrencesPersistedUnchanged: int, rawOccurrencesPersistedError: int, fragmentsProcessed: int, verbatimOccurrencesPersistedSuccessful: int, verbatimOccurrencesPersistedError: int, interpretedOccurrencesPersistedSuccessful: int, interpretedOccurrencesPersistedError: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dataset/($key)/process" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a particular crawl attempt for the dataset
#
# GET /dataset/{key}/process/{attempt}
# operationId: datasetCrawlAttempt
export def "dataset-process datasetCrawlAttempt" [
  key: string
  attempt: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<datasetKey: string, crawlJob: record<datasetKey: string, endpointType: string, targetUrl: string, attempt: int, properties: record>, startedCrawling: string, finishedCrawling: string, crawlContext: string, finishReason: string, processStateOccurrence: string, processStateChecklist: string, processStateSample: string, declaredCount: int, pagesCrawled: int, pagesFragmentedSuccessful: int, pagesFragmentedError: int, fragmentsEmitted: int, fragmentsReceived: int, rawOccurrencesPersistedNew: int, rawOccurrencesPersistedUpdated: int, rawOccurrencesPersistedUnchanged: int, rawOccurrencesPersistedError: int, fragmentsProcessed: int, verbatimOccurrencesPersistedSuccessful: int, verbatimOccurrencesPersistedError: int, interpretedOccurrencesPersistedSuccessful: int, interpretedOccurrencesPersistedError: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dataset/($key)/process/($attempt)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the networks the dataset belongs to
#
# GET /dataset/{key}/networks
# operationId: getNetworks
export def "dataset-networks get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: string, title: string, description: string, language: string, numConstituents: int, email: list<string>, phone: list<string>, homepage: list<string>, logoUrl: string, address: list<string>, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list<record>, endpoints: list<record>, machineTags: list<record>, tags: list<record>, identifiers: list<record>, comments: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/networks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all constituents of the dataset
#
# GET /dataset/{key}/constituents
# operationId: getConstituents
export def "dataset-constituents get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, parentDatasetKey: string, duplicateOfDatasetKey: string, installationKey: string, publishingOrganizationKey: string, publishingOrganizationName: string, networkKeys: list, doi: string, version: string, external: bool, numConstituents: int, type: string, subtype: string, shortName: string, title: string, alias: string, abbreviation: string, description: string, language: string, homepage: string, logoUrl: string, citation: record, contactsCitation: list, rights: string, lockedForAutoUpdate: bool, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list, bibliographicCitations: list, curatorialUnits: list, taxonomicCoverages: list, geographicCoverageDescription: string, geographicCoverages: list, temporalCoverages: list, keywordCollections: list, project: record, samplingDescription: record, countryCoverage: list, collections: list, dataDescriptions: list, dataLanguage: string, purpose: string, introduction: string, gettingStarted: string, acknowledgements: string, additionalInfo: string, pubDate: string, maintenanceUpdateFrequency: string, maintenanceDescription: string, license: string, dwca: record, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dataset/($key)/constituents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all constituents (datasets) of a network
#
# GET /network/{key}/constituents
# operationId: listNetworkConstituents
export def "network-constituents listNetworkConstituents" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, parentDatasetKey: string, duplicateOfDatasetKey: string, installationKey: string, publishingOrganizationKey: string, publishingOrganizationName: string, networkKeys: list, doi: string, version: string, external: bool, numConstituents: int, type: string, subtype: string, shortName: string, title: string, alias: string, abbreviation: string, description: string, language: string, homepage: string, logoUrl: string, citation: record, contactsCitation: list, rights: string, lockedForAutoUpdate: bool, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list, bibliographicCitations: list, curatorialUnits: list, taxonomicCoverages: list, geographicCoverageDescription: string, geographicCoverages: list, temporalCoverages: list, keywordCollections: list, project: record, samplingDescription: record, countryCoverage: list, collections: list, dataDescriptions: list, dataLanguage: string, purpose: string, introduction: string, gettingStarted: string, acknowledgements: string, additionalInfo: string, pubDate: string, maintenanceUpdateFrequency: string, maintenanceDescription: string, license: string, dwca: record, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/network/($key)/constituents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List published datasets
#
# GET /organization/{key}/publishedDataset
# operationId: getPublishedDatasets
export def "organization-published-dataset get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, parentDatasetKey: string, duplicateOfDatasetKey: string, installationKey: string, publishingOrganizationKey: string, publishingOrganizationName: string, networkKeys: list, doi: string, version: string, external: bool, numConstituents: int, type: string, subtype: string, shortName: string, title: string, alias: string, abbreviation: string, description: string, language: string, homepage: string, logoUrl: string, citation: record, contactsCitation: list, rights: string, lockedForAutoUpdate: bool, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list, bibliographicCitations: list, curatorialUnits: list, taxonomicCoverages: list, geographicCoverageDescription: string, geographicCoverages: list, temporalCoverages: list, keywordCollections: list, project: record, samplingDescription: record, countryCoverage: list, collections: list, dataDescriptions: list, dataLanguage: string, purpose: string, introduction: string, gettingStarted: string, acknowledgements: string, additionalInfo: string, pubDate: string, maintenanceUpdateFrequency: string, maintenanceDescription: string, license: string, dwca: record, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/($key)/publishedDataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List hosted datasets
#
# GET /organization/{key}/hostedDataset
# operationId: getHostedDatasets
export def "organization-hosted-dataset get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, parentDatasetKey: string, duplicateOfDatasetKey: string, installationKey: string, publishingOrganizationKey: string, publishingOrganizationName: string, networkKeys: list, doi: string, version: string, external: bool, numConstituents: int, type: string, subtype: string, shortName: string, title: string, alias: string, abbreviation: string, description: string, language: string, homepage: string, logoUrl: string, citation: record, contactsCitation: list, rights: string, lockedForAutoUpdate: bool, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list, bibliographicCitations: list, curatorialUnits: list, taxonomicCoverages: list, geographicCoverageDescription: string, geographicCoverages: list, temporalCoverages: list, keywordCollections: list, project: record, samplingDescription: record, countryCoverage: list, collections: list, dataDescriptions: list, dataLanguage: string, purpose: string, introduction: string, gettingStarted: string, acknowledgements: string, additionalInfo: string, pubDate: string, maintenanceUpdateFrequency: string, maintenanceDescription: string, license: string, dwca: record, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/($key)/hostedDataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List installation's datasets
#
# GET /installation/{key}/dataset
# operationId: getInstallationDatasets
export def "installation-dataset get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, parentDatasetKey: string, duplicateOfDatasetKey: string, installationKey: string, publishingOrganizationKey: string, publishingOrganizationName: string, networkKeys: list, doi: string, version: string, external: bool, numConstituents: int, type: string, subtype: string, shortName: string, title: string, alias: string, abbreviation: string, description: string, language: string, homepage: string, logoUrl: string, citation: record, contactsCitation: list, rights: string, lockedForAutoUpdate: bool, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list, bibliographicCitations: list, curatorialUnits: list, taxonomicCoverages: list, geographicCoverageDescription: string, geographicCoverages: list, temporalCoverages: list, keywordCollections: list, project: record, samplingDescription: record, countryCoverage: list, collections: list, dataDescriptions: list, dataLanguage: string, purpose: string, introduction: string, gettingStarted: string, acknowledgements: string, additionalInfo: string, pubDate: string, maintenanceUpdateFrequency: string, maintenanceDescription: string, license: string, dwca: record, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/installation/($key)/dataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List organization's installations
#
# GET /organization/{key}/installation
# operationId: getOrganizationInstallations
export def "organization-installation get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, organizationKey: string, type: string, title: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, disabled: bool, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/($key)/installation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List node's organizations
#
# GET /node/{key}/organization
# operationId: getNodeOrganizations
export def "node-organization get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, endorsingNodeKey: string, endorsementApproved: bool, endorsementStatus: string, title: string, abbreviation: string, description: string, language: string, email: list, phone: list, homepage: list, logoUrl: string, address: list, city: string, province: string, country: string, postalCode: string, latitude: float, longitude: float, numPublishedDatasets: int, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, endorsed: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/node/($key)/organization" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the node for a country
#
# GET /node/country/{countryCode}
# operationId: getNodeByCountry
export def "node-country get" [
  countryCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, type: string, participationStatus: string, participantSince: int, dateSignedMOU: string, gbifRegion: string, title: string, participantTitle: string, abbreviation: string, description: string, email: list<string>, phone: list<string>, homepage: list<string>, logoUrl: string, address: list<string>, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: table<key: int, type: string, primary: bool, userId: list, salutation: string, firstName: string, lastName: string, position: list, description: string, email: list, phone: list, homepage: list, organization: string, address: list, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string>, endpoints: table<key: int, type: string, url: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, machineTags: list>, machineTags: table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string>, tags: table<key: int, value: string, createdBy: string, created: string>, identifiers: table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool>, comments: table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/country/($countryCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all GBIF member countries
#
# GET /node/country
# operationId: getMemberCountries
export def "node-country list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/node/country")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all GBIF member countries than are either voting or associate participants
#
# GET /node/activeCountries
# operationId: getActiveCountries
export def "node-active-countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/node/activeCountries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all datasets from a node
#
# GET /node/{key}/dataset
# operationId: getNodeDatasets
export def "node-dataset get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, parentDatasetKey: string, duplicateOfDatasetKey: string, installationKey: string, publishingOrganizationKey: string, publishingOrganizationName: string, networkKeys: list, doi: string, version: string, external: bool, numConstituents: int, type: string, subtype: string, shortName: string, title: string, alias: string, abbreviation: string, description: string, language: string, homepage: string, logoUrl: string, citation: record, contactsCitation: list, rights: string, lockedForAutoUpdate: bool, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list, bibliographicCitations: list, curatorialUnits: list, taxonomicCoverages: list, geographicCoverageDescription: string, geographicCoverages: list, temporalCoverages: list, keywordCollections: list, project: record, samplingDescription: record, countryCoverage: list, collections: list, dataDescriptions: list, dataLanguage: string, purpose: string, introduction: string, gettingStarted: string, acknowledgements: string, additionalInfo: string, pubDate: string, maintenanceUpdateFrequency: string, maintenanceDescription: string, license: string, dwca: record, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/node/($key)/dataset" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List node's installations
#
# GET /node/{key}/installation
# operationId: getNodeInstallations
export def "node-installation get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, organizationKey: string, type: string, title: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, disabled: bool, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/node/($key)/installation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve GBIF metadata document of the dataset
#
# GET /dataset/{key}/document
# operationId: getDocuments
export def "dataset-document get" [
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
  let full_url = (build-url $base $"/dataset/($key)/document")
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a metadata document to the record
#
# POST /dataset/{key}/document
# operationId: addDocument
export def "dataset-document addDocument" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<key: int, datasetKey: string, type: string, content: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/document")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/xml" $body
}

# Export a descriptor suggestion file
#
# GET /grscicoll/collection/{collectionKey}/descriptorGroup/suggestion/{key}/file
# operationId: exportDescriptorSuggestionFile
export def "grscicoll-collection-descriptor-group-suggestion-file exportDescriptorSuggestionFile" [
  collectionKey: string
  key: int
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
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/suggestion/($key)/file")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all dataset source metadata
#
# GET /dataset/{key}/metadata
# operationId: getAllMetadata
export def "dataset-metadata get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-2
]: nothing -> table<key: int, datasetKey: string, type: string, content: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dataset/($key)/metadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a descriptor change suggestion
#
# GET /grscicoll/collection/{collectionKey}/descriptorGroup/suggestion/{key}
# operationId: getDescriptorSuggestion
export def "grscicoll-collection-descriptor-group-suggestion get" [
  collectionKey: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: int, collectionKey: string, descriptorGroupKey: int, format: string, type: string, title: string, description: string, tags: list<string>, status: string, proposed: string, proposedBy: string, proposerEmail: string, applied: string, appliedBy: string, discarded: string, discardedBy: string, suggestedFile: string, comments: list<string>, country: string, modified: string, modifiedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/suggestion/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a descriptor change suggestion
#
# PUT /grscicoll/collection/{collectionKey}/descriptorGroup/suggestion/{key}
# operationId: updateDescriptorSuggestion
export def "grscicoll-collection-descriptor-group-suggestion updateDescriptorSuggestion" [
  collectionKey: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-3
  --title: string
  --description: string
  --format: string@format-completer
  --comments: list
  --tags: list
  --proposerEmail: string
  --file: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "comments" $comments "multi") (serialize-qp "tags" $tags "multi") (serialize-qp "proposerEmail" $proposerEmail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/suggestion/($key)" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Apply a descriptor change suggestion
#
# PUT /grscicoll/collection/{collectionKey}/descriptorGroup/suggestion/{key}/apply
# operationId: applyDescriptorSuggestion
export def "grscicoll-collection-descriptor-group-suggestion-apply applyDescriptorSuggestion" [
  collectionKey: string
  key: int
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
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/suggestion/($key)/apply")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve metadata about a source metadata document of a dataset
#
# GET /dataset/metadata/{metadataKey}
# operationId: getMetadata
export def "dataset-metadata get-by-metadataKey" [
  metadataKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: int, datasetKey: string, type: string, content: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/metadata/($metadataKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a source metadata document from the record
#
# DELETE /dataset/metadata/{metadataKey}
# operationId: deleteMetadata
export def "dataset-metadata delete" [
  metadataKey: int
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
  let full_url = (build-url $base $"/dataset/metadata/($metadataKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Discard a descriptor change suggestion
#
# PUT /grscicoll/collection/{collectionKey}/descriptorGroup/suggestion/{key}/discard
# operationId: discardDescriptorSuggestion
export def "grscicoll-collection-descriptor-group-suggestion-discard discardDescriptorSuggestion" [
  collectionKey: string
  key: int
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
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/suggestion/($key)/discard")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a source metadata document of the dataset
#
# GET /dataset/metadata/{metadataKey}/document
# operationId: getMetadataDocument
export def "dataset-metadata-document get" [
  metadataKey: int
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
  let full_url = (build-url $base $"/dataset/metadata/($metadataKey)/document")
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List descriptor change suggestions
#
# GET /grscicoll/collection/{collectionKey}/descriptorGroup/suggestion
# operationId: listDescriptorSuggestions
export def "grscicoll-collection-descriptor-group-suggestion listDescriptorSuggestions" [
  collectionKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer
  --type: string@type-completer-3
  --proposerEmail: string
  --country: string@country-completer
  --page: record
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, collectionKey: string, descriptorGroupKey: int, format: string, type: string, title: string, description: string, tags: list, status: string, proposed: string, proposedBy: string, proposerEmail: string, applied: string, appliedBy: string, discarded: string, discardedBy: string, suggestedFile: string, comments: list, country: string, modified: string, modifiedBy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "proposerEmail" $proposerEmail "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "page" $page "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/suggestion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new descriptor change suggestion
#
# POST /grscicoll/collection/{collectionKey}/descriptorGroup/suggestion
# operationId: createDescriptorSuggestion
export def "grscicoll-collection-descriptor-group-suggestion createDescriptorSuggestion" [
  collectionKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-3
  --descriptorGroupKey: int # format: int64
  --title: string
  --description: string
  --format: string@format-completer
  --comments: list
  --proposerEmail: string
  --tags: list
  --file: string # format: binary
]: any -> record<key: int, collectionKey: string, descriptorGroupKey: int, format: string, type: string, title: string, description: string, tags: list<string>, status: string, proposed: string, proposedBy: string, proposerEmail: string, applied: string, appliedBy: string, discarded: string, discardedBy: string, suggestedFile: string, comments: list<string>, country: string, modified: string, modifiedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "descriptorGroupKey" $descriptorGroupKey "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "comments" $comments "multi") (serialize-qp "proposerEmail" $proposerEmail "scalar") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/suggestion" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List all descriptor change suggestions
#
# GET /grscicoll/collection/descriptorGroup/suggestion
# operationId: listAllDescriptorSuggestions
export def "grscicoll-collection-descriptor-group-suggestion listAllDescriptorSuggestions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer
  --type: string@type-completer-3
  --proposerEmail: string
  --country: string@country-completer
  --page: record
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, collectionKey: string, descriptorGroupKey: int, format: string, type: string, title: string, description: string, tags: list, status: string, proposed: string, proposedBy: string, proposerEmail: string, applied: string, appliedBy: string, discarded: string, discardedBy: string, suggestedFile: string, comments: list, country: string, modified: string, modifiedBy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "proposerEmail" $proposerEmail "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "page" $page "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/collection/descriptorGroup/suggestion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all comments of the record
#
# GET /organization/{key}/comment
# operationId: getComment
export def "organization-comment get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/comment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a comment to the record
#
# POST /organization/{key}/comment
# operationId: addComment
export def "organization-comment addComment" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The text of the comment
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/comment")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all comments of the record
#
# GET /node/{key}/comment
# operationId: getComment_1
export def "node-comment get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/($key)/comment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a comment to the record
#
# POST /node/{key}/comment
# operationId: addComment_1
export def "node-comment addComment-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The text of the comment
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/($key)/comment")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all comments of the record
#
# GET /network/{key}/comment
# operationId: getComment_2
export def "network-comment get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/comment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a comment to the record
#
# POST /network/{key}/comment
# operationId: addComment_2
export def "network-comment addComment-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The text of the comment
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/comment")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all comments of the record
#
# GET /installation/{key}/comment
# operationId: getComment_3
export def "installation-comment get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/comment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a comment to the record
#
# POST /installation/{key}/comment
# operationId: addComment_3
export def "installation-comment addComment-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The text of the comment
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/comment")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all comments of the record
#
# GET /grscicoll/institution/{key}/comment
# operationId: getComment_4
export def "grscicoll-institution-comment get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/comment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a comment to the record
#
# POST /grscicoll/institution/{key}/comment
# operationId: addComment_4
export def "grscicoll-institution-comment addComment-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The text of the comment
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/comment")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all comments of the record
#
# GET /grscicoll/collection/{key}/comment
# operationId: getComment_5
export def "grscicoll-collection-comment get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/comment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a comment to the record
#
# POST /grscicoll/collection/{key}/comment
# operationId: addComment_5
export def "grscicoll-collection-comment addComment-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The text of the comment
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/comment")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all comments of the record
#
# GET /dataset/{key}/comment
# operationId: getComment_6
export def "dataset-comment get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, content: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/comment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a comment to the record
#
# POST /dataset/{key}/comment
# operationId: addComment_6
export def "dataset-comment addComment-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The text of the comment
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/comment")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a comment from the record
#
# DELETE /organization/{key}/comment/{commentKey}
# operationId: deleteComment
export def "organization-comment delete" [
  key: string
  commentKey: int
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
  let full_url = (build-url $base $"/organization/($key)/comment/($commentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a comment from the record
#
# DELETE /node/{key}/comment/{commentKey}
# operationId: deleteComment_1
export def "node-comment delete-by-key-commentKey" [
  key: string
  commentKey: int
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
  let full_url = (build-url $base $"/node/($key)/comment/($commentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a comment from the record
#
# DELETE /network/{key}/comment/{commentKey}
# operationId: deleteComment_2
export def "network-comment delete-by-key-commentKey" [
  key: string
  commentKey: int
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
  let full_url = (build-url $base $"/network/($key)/comment/($commentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a comment from the record
#
# DELETE /installation/{key}/comment/{commentKey}
# operationId: deleteComment_3
export def "installation-comment delete-by-key-commentKey" [
  key: string
  commentKey: int
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
  let full_url = (build-url $base $"/installation/($key)/comment/($commentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a comment from the record
#
# DELETE /dataset/{key}/comment/{commentKey}
# operationId: deleteComment_4
export def "dataset-comment delete-by-key-commentKey" [
  key: string
  commentKey: int
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
  let full_url = (build-url $base $"/dataset/($key)/comment/($commentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a comment from the record
#
# DELETE /grscicoll/institution/{key}/comment/{commentKey}
# operationId: deleteComment_5
export def "grscicoll-institution-comment delete-by-key-commentKey" [
  key: string
  commentKey: int
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
  let full_url = (build-url $base $"/grscicoll/institution/($key)/comment/($commentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a comment from the record
#
# DELETE /grscicoll/collection/{key}/comment/{commentKey}
# operationId: deleteComment_6
export def "grscicoll-collection-comment delete-by-key-commentKey" [
  key: string
  commentKey: int
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
  let full_url = (build-url $base $"/grscicoll/collection/($key)/comment/($commentKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a constituent dataset to a network
#
# POST /network/{key}/constituents/{datasetKey}
# operationId: networkConstituentAdd
export def "network-constituents networkConstituentAdd" [
  key: string
  datasetKey: string
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
  let full_url = (build-url $base $"/network/($key)/constituents/($datasetKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a constituent dataset from a network
#
# DELETE /network/{key}/constituents/{datasetKey}
# operationId: networkConstituentDelete
export def "network-constituents networkConstituentDelete" [
  key: string
  datasetKey: string
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
  let full_url = (build-url $base $"/network/($key)/constituents/($datasetKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all contacts of the record
#
# GET /organization/{key}/contact
# operationId: getContact
export def "organization-contact get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, primary: bool, userId: list<string>, salutation: string, firstName: string, lastName: string, position: list<string>, description: string, email: list<string>, phone: list<string>, homepage: list<string>, organization: string, address: list<string>, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/contact")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing contact on the record
#
# PUT /organization/{key}/contact
# operationId: updateContact
export def "organization-contact updateContact" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/contact")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a contact to the record
#
# POST /organization/{key}/contact
# operationId: addContact
export def "organization-contact addContact" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/contact")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all contacts of the record
#
# GET /network/{key}/contact
# operationId: getContact_1
export def "network-contact get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, primary: bool, userId: list<string>, salutation: string, firstName: string, lastName: string, position: list<string>, description: string, email: list<string>, phone: list<string>, homepage: list<string>, organization: string, address: list<string>, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/contact")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing contact on the record
#
# PUT /network/{key}/contact
# operationId: updateContact_1
export def "network-contact updateContact-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/contact")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a contact to the record
#
# POST /network/{key}/contact
# operationId: addContact_1
export def "network-contact addContact-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/contact")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all contacts of the record
#
# GET /installation/{key}/contact
# operationId: getContact_2
export def "installation-contact get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, primary: bool, userId: list<string>, salutation: string, firstName: string, lastName: string, position: list<string>, description: string, email: list<string>, phone: list<string>, homepage: list<string>, organization: string, address: list<string>, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/contact")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing contact on the record
#
# PUT /installation/{key}/contact
# operationId: updateContact_2
export def "installation-contact updateContact-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/contact")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a contact to the record
#
# POST /installation/{key}/contact
# operationId: addContact_2
export def "installation-contact addContact-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/contact")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all contacts of the record
#
# GET /dataset/{key}/contact
# operationId: getContact_3
export def "dataset-contact get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, primary: bool, userId: list<string>, salutation: string, firstName: string, lastName: string, position: list<string>, description: string, email: list<string>, phone: list<string>, homepage: list<string>, organization: string, address: list<string>, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/contact")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing contact on the record
#
# PUT /dataset/{key}/contact
# operationId: updateContact_3
export def "dataset-contact updateContact-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/contact")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a contact to the record
#
# POST /dataset/{key}/contact
# operationId: addContact_3
export def "dataset-contact addContact-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/contact")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an existing contact person on the record
#
# PUT /grscicoll/institution/{key}/contactPerson/{contactKey}
# operationId: updateContactPerson
export def "grscicoll-institution-contact-person updateContactPerson" [
  key: string
  contactKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/contactPerson/($contactKey)")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a contact person from the record
#
# DELETE /grscicoll/institution/{key}/contactPerson/{contactKey}
# operationId: deleteContactPerson
export def "grscicoll-institution-contact-person delete" [
  key: string
  contactKey: int
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
  let full_url = (build-url $base $"/grscicoll/institution/($key)/contactPerson/($contactKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing contact person on the record
#
# PUT /grscicoll/collection/{key}/contactPerson/{contactKey}
# operationId: updateContactPerson_1
export def "grscicoll-collection-contact-person updateContactPerson-by-key-contactKey" [
  key: string
  contactKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/contactPerson/($contactKey)")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a contact person from the record
#
# DELETE /grscicoll/collection/{key}/contactPerson/{contactKey}
# operationId: deleteContactPerson_1
export def "grscicoll-collection-contact-person delete-by-key-contactKey" [
  key: string
  contactKey: int
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
  let full_url = (build-url $base $"/grscicoll/collection/($key)/contactPerson/($contactKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing contact on the record
#
# PUT /organization/{key}/contact/{contactKey}
# operationId: updateContact_4
export def "organization-contact updateContact-by-key-contactKey" [
  key: string
  contactKey: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/contact/($contactKey)")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a contact from the record
#
# DELETE /organization/{key}/contact/{contactKey}
# operationId: deleteContact
export def "organization-contact delete" [
  key: string
  contactKey: int
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
  let full_url = (build-url $base $"/organization/($key)/contact/($contactKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing contact on the record
#
# PUT /node/{key}/contact
# operationId: updateContact_5
export def "node-contact updateContact-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/($key)/contact")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an existing contact on the record
#
# PUT /node/{key}/contact/{contactKey}
# operationId: updateContact_6
export def "node-contact updateContact-by-key-contactKey" [
  key: string
  contactKey: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/($key)/contact/($contactKey)")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an existing contact on the record
#
# PUT /network/{key}/contact/{contactKey}
# operationId: updateContact_7
export def "network-contact updateContact-by-key-contactKey" [
  key: string
  contactKey: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/contact/($contactKey)")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a contact from the record
#
# DELETE /network/{key}/contact/{contactKey}
# operationId: deleteContact_1
export def "network-contact delete-by-key-contactKey" [
  key: string
  contactKey: int
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
  let full_url = (build-url $base $"/network/($key)/contact/($contactKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing contact on the record
#
# PUT /installation/{key}/contact/{contactKey}
# operationId: updateContact_8
export def "installation-contact updateContact-by-key-contactKey" [
  key: string
  contactKey: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/contact/($contactKey)")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a contact from the record
#
# DELETE /installation/{key}/contact/{contactKey}
# operationId: deleteContact_2
export def "installation-contact delete-by-key-contactKey" [
  key: string
  contactKey: int
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
  let full_url = (build-url $base $"/installation/($key)/contact/($contactKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing contact on the record
#
# PUT /dataset/{key}/contact/{contactKey}
# operationId: updateContact_9
export def "dataset-contact updateContact-by-key-contactKey" [
  key: string
  contactKey: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/contact/($contactKey)")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a contact from the record
#
# DELETE /dataset/{key}/contact/{contactKey}
# operationId: deleteContact_3
export def "dataset-contact delete-by-key-contactKey" [
  key: string
  contactKey: int
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
  let full_url = (build-url $base $"/dataset/($key)/contact/($contactKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all endpoints of the record
#
# GET /organization/{key}/endpoint
# operationId: getEndpoint
export def "organization-endpoint get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, url: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, machineTags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/endpoint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an endpoint to the record
#
# POST /organization/{key}/endpoint
# operationId: addEndpoint
# --machineTags item shape: {namespace: string, name: string, value: string}
export def "organization-endpoint addEndpoint" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-5
  --body-url: string # format: uri
  --description: string
  machineTags: list # Machine tags applied to the endpoint — item shape: {namespace: string, name: string, value: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/endpoint")
  let body = {type: $type, url: $body_url, description: $description, machineTags: $machineTags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all endpoints of the record
#
# GET /node/{key}/endpoint
# operationId: getEndpoint_1
export def "node-endpoint get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, url: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, machineTags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/($key)/endpoint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an endpoint to the record
#
# POST /node/{key}/endpoint
# operationId: addEndpoint_1
# --machineTags item shape: {namespace: string, name: string, value: string}
export def "node-endpoint addEndpoint-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-5
  --body-url: string # format: uri
  --description: string
  machineTags: list # Machine tags applied to the endpoint — item shape: {namespace: string, name: string, value: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/($key)/endpoint")
  let body = {type: $type, url: $body_url, description: $description, machineTags: $machineTags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all endpoints of the record
#
# GET /network/{key}/endpoint
# operationId: getEndpoint_2
export def "network-endpoint get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, url: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, machineTags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/endpoint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an endpoint to the record
#
# POST /network/{key}/endpoint
# operationId: addEndpoint_2
# --machineTags item shape: {namespace: string, name: string, value: string}
export def "network-endpoint addEndpoint-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-5
  --body-url: string # format: uri
  --description: string
  machineTags: list # Machine tags applied to the endpoint — item shape: {namespace: string, name: string, value: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/endpoint")
  let body = {type: $type, url: $body_url, description: $description, machineTags: $machineTags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all endpoints of the record
#
# GET /installation/{key}/endpoint
# operationId: getEndpoint_3
export def "installation-endpoint get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, url: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, machineTags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/endpoint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an endpoint to the record
#
# POST /installation/{key}/endpoint
# operationId: addEndpoint_3
# --machineTags item shape: {namespace: string, name: string, value: string}
export def "installation-endpoint addEndpoint-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-5
  --body-url: string # format: uri
  --description: string
  machineTags: list # Machine tags applied to the endpoint — item shape: {namespace: string, name: string, value: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/endpoint")
  let body = {type: $type, url: $body_url, description: $description, machineTags: $machineTags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all endpoints of the record
#
# GET /dataset/{key}/endpoint
# operationId: getEndpoint_4
export def "dataset-endpoint get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, url: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, machineTags: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/endpoint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an endpoint to the record
#
# POST /dataset/{key}/endpoint
# operationId: addEndpoint_4
# --machineTags item shape: {namespace: string, name: string, value: string}
export def "dataset-endpoint addEndpoint-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-5
  --body-url: string # format: uri
  --description: string
  machineTags: list # Machine tags applied to the endpoint — item shape: {namespace: string, name: string, value: string}
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/endpoint")
  let body = {type: $type, url: $body_url, description: $description, machineTags: $machineTags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an endpoint from the record
#
# DELETE /organization/{key}/endpoint/{endpointKey}
# operationId: deleteEndpoint
export def "organization-endpoint delete" [
  key: string
  endpointKey: int
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
  let full_url = (build-url $base $"/organization/($key)/endpoint/($endpointKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an endpoint from the record
#
# DELETE /node/{key}/endpoint/{endpointKey}
# operationId: deleteEndpoint_1
export def "node-endpoint delete-by-key-endpointKey" [
  key: string
  endpointKey: int
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
  let full_url = (build-url $base $"/node/($key)/endpoint/($endpointKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an endpoint from the record
#
# DELETE /network/{key}/endpoint/{endpointKey}
# operationId: deleteEndpoint_2
export def "network-endpoint delete-by-key-endpointKey" [
  key: string
  endpointKey: int
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
  let full_url = (build-url $base $"/network/($key)/endpoint/($endpointKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an endpoint from the record
#
# DELETE /installation/{key}/endpoint/{endpointKey}
# operationId: deleteEndpoint_3
export def "installation-endpoint delete-by-key-endpointKey" [
  key: string
  endpointKey: int
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
  let full_url = (build-url $base $"/installation/($key)/endpoint/($endpointKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an endpoint from the record
#
# DELETE /dataset/{key}/endpoint/{endpointKey}
# operationId: deleteEndpoint_4
export def "dataset-endpoint delete-by-key-endpointKey" [
  key: string
  endpointKey: int
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
  let full_url = (build-url $base $"/dataset/($key)/endpoint/($endpointKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all identifiers of the record
#
# GET /organization/{key}/identifier
# operationId: getIdentifier
export def "organization-identifier get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/identifier")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an identifier to the record
#
# POST /organization/{key}/identifier
# operationId: addIdentifier
export def "organization-identifier addIdentifier" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-6
  identifier: string # Value for the identifier
  --primary: string@bool-completer # Whether this is the primary identifier for the associated entity.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/identifier")
  let body = {type: $type, identifier: $identifier, primary: $primary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all identifiers of the record
#
# GET /node/{key}/identifier
# operationId: getIdentifier_1
export def "node-identifier get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/($key)/identifier")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an identifier to the record
#
# POST /node/{key}/identifier
# operationId: addIdentifier_1
export def "node-identifier addIdentifier-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-6
  identifier: string # Value for the identifier
  --primary: string@bool-completer # Whether this is the primary identifier for the associated entity.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/($key)/identifier")
  let body = {type: $type, identifier: $identifier, primary: $primary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all identifiers of the record
#
# GET /network/{key}/identifier
# operationId: getIdentifier_2
export def "network-identifier get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/identifier")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an identifier to the record
#
# POST /network/{key}/identifier
# operationId: addIdentifier_2
export def "network-identifier addIdentifier-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-6
  identifier: string # Value for the identifier
  --primary: string@bool-completer # Whether this is the primary identifier for the associated entity.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/identifier")
  let body = {type: $type, identifier: $identifier, primary: $primary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all identifiers of the record
#
# GET /installation/{key}/identifier
# operationId: getIdentifier_3
export def "installation-identifier get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/identifier")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an identifier to the record
#
# POST /installation/{key}/identifier
# operationId: addIdentifier_3
export def "installation-identifier addIdentifier-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-6
  identifier: string # Value for the identifier
  --primary: string@bool-completer # Whether this is the primary identifier for the associated entity.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/identifier")
  let body = {type: $type, identifier: $identifier, primary: $primary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all identifiers of the record
#
# GET /grscicoll/institution/{key}/identifier
# operationId: getIdentifier_4
export def "grscicoll-institution-identifier get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/identifier")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an identifier to the record
#
# POST /grscicoll/institution/{key}/identifier
# operationId: addIdentifier_4
export def "grscicoll-institution-identifier addIdentifier-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-6
  identifier: string # Value for the identifier
  --primary: string@bool-completer # Whether this is the primary identifier for the associated entity.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/identifier")
  let body = {type: $type, identifier: $identifier, primary: $primary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all identifiers of the record
#
# GET /grscicoll/collection/{key}/identifier
# operationId: getIdentifier_5
export def "grscicoll-collection-identifier get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/identifier")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an identifier to the record
#
# POST /grscicoll/collection/{key}/identifier
# operationId: addIdentifier_5
export def "grscicoll-collection-identifier addIdentifier-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-6
  identifier: string # Value for the identifier
  --primary: string@bool-completer # Whether this is the primary identifier for the associated entity.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/identifier")
  let body = {type: $type, identifier: $identifier, primary: $primary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all identifiers of the record
#
# GET /dataset/{key}/identifier
# operationId: getIdentifier_6
export def "dataset-identifier get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, identifier: string, createdBy: string, created: string, primary: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/identifier")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an identifier to the record
#
# POST /dataset/{key}/identifier
# operationId: addIdentifier_6
export def "dataset-identifier addIdentifier-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-6
  identifier: string # Value for the identifier
  --primary: string@bool-completer # Whether this is the primary identifier for the associated entity.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/identifier")
  let body = {type: $type, identifier: $identifier, primary: $primary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an identifier from the record
#
# DELETE /organization/{key}/identifier/{identifierKey}
# operationId: deleteIdentifier
export def "organization-identifier delete" [
  key: string
  identifierKey: int
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
  let full_url = (build-url $base $"/organization/($key)/identifier/($identifierKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an identifier from the record
#
# DELETE /node/{key}/identifier/{identifierKey}
# operationId: deleteIdentifier_1
export def "node-identifier delete-by-key-identifierKey" [
  key: string
  identifierKey: int
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
  let full_url = (build-url $base $"/node/($key)/identifier/($identifierKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an identifier from the record
#
# DELETE /network/{key}/identifier/{identifierKey}
# operationId: deleteIdentifier_2
export def "network-identifier delete-by-key-identifierKey" [
  key: string
  identifierKey: int
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
  let full_url = (build-url $base $"/network/($key)/identifier/($identifierKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an identifier from the record
#
# DELETE /installation/{key}/identifier/{identifierKey}
# operationId: deleteIdentifier_3
export def "installation-identifier delete-by-key-identifierKey" [
  key: string
  identifierKey: int
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
  let full_url = (build-url $base $"/installation/($key)/identifier/($identifierKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an identifier from the record
#
# DELETE /dataset/{key}/identifier/{identifierKey}
# operationId: deleteIdentifier_4
export def "dataset-identifier delete-by-key-identifierKey" [
  key: string
  identifierKey: int
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
  let full_url = (build-url $base $"/dataset/($key)/identifier/($identifierKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an identifier for a specified entity
#
# PUT /grscicoll/institution/{key}/identifier/{identifierKey}
# operationId: updateIdentifier
export def "grscicoll-institution-identifier updateIdentifier" [
  key: string
  identifierKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/identifier/($identifierKey)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an identifier from the record
#
# DELETE /grscicoll/institution/{key}/identifier/{identifierKey}
# operationId: deleteIdentifier_5
export def "grscicoll-institution-identifier delete-by-key-identifierKey" [
  key: string
  identifierKey: int
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
  let full_url = (build-url $base $"/grscicoll/institution/($key)/identifier/($identifierKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an identifier for a specified entity
#
# PUT /grscicoll/collection/{key}/identifier/{identifierKey}
# operationId: updateIdentifier_1
export def "grscicoll-collection-identifier updateIdentifier-by-key-identifierKey" [
  key: string
  identifierKey: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/identifier/($identifierKey)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an identifier from the record
#
# DELETE /grscicoll/collection/{key}/identifier/{identifierKey}
# operationId: deleteIdentifier_6
export def "grscicoll-collection-identifier delete-by-key-identifierKey" [
  key: string
  identifierKey: int
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
  let full_url = (build-url $base $"/grscicoll/collection/($key)/identifier/($identifierKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all machine tags on the record
#
# GET /organization/{key}/machineTag
# operationId: listMachineTag
export def "organization-machine-tag listMachineTag" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/machineTag")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a machine tag to the record
#
# POST /organization/{key}/machineTag
# operationId: addMachineTag
export def "organization-machine-tag addMachineTag" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  namespace: string # The namespace for the machine tag.
  name: string # The name (within the namespace) of the machine tag.
  value: string # The value of the machine tag.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/machineTag")
  let body = {namespace: $namespace, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all machine tags on the record
#
# GET /node/{key}/machineTag
# operationId: listMachineTag_1
export def "node-machine-tag listMachineTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/($key)/machineTag")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a machine tag to the record
#
# POST /node/{key}/machineTag
# operationId: addMachineTag_1
export def "node-machine-tag addMachineTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  namespace: string # The namespace for the machine tag.
  name: string # The name (within the namespace) of the machine tag.
  value: string # The value of the machine tag.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/($key)/machineTag")
  let body = {namespace: $namespace, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all machine tags on the record
#
# GET /network/{key}/machineTag
# operationId: listMachineTag_2
export def "network-machine-tag listMachineTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/machineTag")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a machine tag to the record
#
# POST /network/{key}/machineTag
# operationId: addMachineTag_2
export def "network-machine-tag addMachineTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  namespace: string # The namespace for the machine tag.
  name: string # The name (within the namespace) of the machine tag.
  value: string # The value of the machine tag.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/machineTag")
  let body = {namespace: $namespace, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all machine tags on the record
#
# GET /installation/{key}/machineTag
# operationId: listMachineTag_3
export def "installation-machine-tag listMachineTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/machineTag")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a machine tag to the record
#
# POST /installation/{key}/machineTag
# operationId: addMachineTag_3
export def "installation-machine-tag addMachineTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  namespace: string # The namespace for the machine tag.
  name: string # The name (within the namespace) of the machine tag.
  value: string # The value of the machine tag.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/machineTag")
  let body = {namespace: $namespace, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all machine tags on the record
#
# GET /grscicoll/institution/{key}/machineTag
# operationId: listMachineTag_4
export def "grscicoll-institution-machine-tag listMachineTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/machineTag")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a machine tag to the record
#
# POST /grscicoll/institution/{key}/machineTag
# operationId: addMachineTag_4
export def "grscicoll-institution-machine-tag addMachineTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  namespace: string # The namespace for the machine tag.
  name: string # The name (within the namespace) of the machine tag.
  value: string # The value of the machine tag.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/machineTag")
  let body = {namespace: $namespace, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all machine tags on the record
#
# GET /grscicoll/collection/{key}/machineTag
# operationId: listMachineTag_5
export def "grscicoll-collection-machine-tag listMachineTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/machineTag")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a machine tag to the record
#
# POST /grscicoll/collection/{key}/machineTag
# operationId: addMachineTag_5
export def "grscicoll-collection-machine-tag addMachineTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  namespace: string # The namespace for the machine tag.
  name: string # The name (within the namespace) of the machine tag.
  value: string # The value of the machine tag.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/machineTag")
  let body = {namespace: $namespace, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all machine tags on the record
#
# GET /dataset/{key}/machineTag
# operationId: listMachineTag_6
export def "dataset-machine-tag listMachineTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, namespace: string, name: string, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/machineTag")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a machine tag to the record
#
# POST /dataset/{key}/machineTag
# operationId: addMachineTag_6
export def "dataset-machine-tag addMachineTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  namespace: string # The namespace for the machine tag.
  name: string # The name (within the namespace) of the machine tag.
  value: string # The value of the machine tag.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/machineTag")
  let body = {namespace: $namespace, name: $name, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a machine tag from the record
#
# DELETE /organization/{key}/machineTag/{machineTagKey}
# operationId: deleteMachineTag
export def "organization-machine-tag delete-by-key-machineTagKey" [
  key: string
  machineTagKey: int
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
  let full_url = (build-url $base $"/organization/($key)/machineTag/($machineTagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a machine tag from the record
#
# DELETE /node/{key}/machineTag/{machineTagKey}
# operationId: deleteMachineTag_1
export def "node-machine-tag delete-by-key-machineTagKey" [
  key: string
  machineTagKey: int
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
  let full_url = (build-url $base $"/node/($key)/machineTag/($machineTagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a machine tag from the record
#
# DELETE /network/{key}/machineTag/{machineTagKey}
# operationId: deleteMachineTag_2
export def "network-machine-tag delete-by-key-machineTagKey" [
  key: string
  machineTagKey: int
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
  let full_url = (build-url $base $"/network/($key)/machineTag/($machineTagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a machine tag from the record
#
# DELETE /installation/{key}/machineTag/{machineTagKey}
# operationId: deleteMachineTag_3
export def "installation-machine-tag delete-by-key-machineTagKey" [
  key: string
  machineTagKey: int
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
  let full_url = (build-url $base $"/installation/($key)/machineTag/($machineTagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a machine tag from the record
#
# DELETE /grscicoll/institution/{key}/machineTag/{machineTagKey}
# operationId: deleteMachineTag_4
export def "grscicoll-institution-machine-tag delete-by-key-machineTagKey" [
  key: string
  machineTagKey: int
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
  let full_url = (build-url $base $"/grscicoll/institution/($key)/machineTag/($machineTagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a machine tag from the record
#
# DELETE /grscicoll/collection/{key}/machineTag/{machineTagKey}
# operationId: deleteMachineTag_5
export def "grscicoll-collection-machine-tag delete-by-key-machineTagKey" [
  key: string
  machineTagKey: int
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
  let full_url = (build-url $base $"/grscicoll/collection/($key)/machineTag/($machineTagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a machine tag from the record
#
# DELETE /dataset/{key}/machineTag/{machineTagKey}
# operationId: deleteMachineTag_6
export def "dataset-machine-tag delete-by-key-machineTagKey" [
  key: string
  machineTagKey: int
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
  let full_url = (build-url $base $"/dataset/($key)/machineTag/($machineTagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags in a namespace from the record
#
# DELETE /organization/{key}/machineTag/{namespace}
# operationId: deleteMachineTagsInNamespace
export def "organization-machine-tag delete-by-key-namespace" [
  key: string
  namespace: string
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
  let full_url = (build-url $base $"/organization/($key)/machineTag/($namespace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags in a namespace from the record
#
# DELETE /node/{key}/machineTag/{namespace}
# operationId: deleteMachineTagsInNamespace_1
export def "node-machine-tag delete-by-key-namespace" [
  key: string
  namespace: string
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
  let full_url = (build-url $base $"/node/($key)/machineTag/($namespace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags in a namespace from the record
#
# DELETE /network/{key}/machineTag/{namespace}
# operationId: deleteMachineTagsInNamespace_2
export def "network-machine-tag delete-by-key-namespace" [
  key: string
  namespace: string
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
  let full_url = (build-url $base $"/network/($key)/machineTag/($namespace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags in a namespace from the record
#
# DELETE /installation/{key}/machineTag/{namespace}
# operationId: deleteMachineTagsInNamespace_3
export def "installation-machine-tag delete-by-key-namespace" [
  key: string
  namespace: string
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
  let full_url = (build-url $base $"/installation/($key)/machineTag/($namespace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags in a namespace from the record
#
# DELETE /grscicoll/institution/{key}/machineTag/{namespace}
# operationId: deleteMachineTagsInNamespace_4
export def "grscicoll-institution-machine-tag delete-by-key-namespace" [
  key: string
  namespace: string
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
  let full_url = (build-url $base $"/grscicoll/institution/($key)/machineTag/($namespace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags in a namespace from the record
#
# DELETE /grscicoll/collection/{key}/machineTag/{namespace}
# operationId: deleteMachineTagsInNamespace_5
export def "grscicoll-collection-machine-tag delete-by-key-namespace" [
  key: string
  namespace: string
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
  let full_url = (build-url $base $"/grscicoll/collection/($key)/machineTag/($namespace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags in a namespace from the record
#
# DELETE /dataset/{key}/machineTag/{namespace}
# operationId: deleteMachineTagsInNamespace_6
export def "dataset-machine-tag delete-by-key-namespace" [
  key: string
  namespace: string
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
  let full_url = (build-url $base $"/dataset/($key)/machineTag/($namespace)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags of a name in a namespace from the record
#
# DELETE /organization/{key}/machineTag/{namespace}/{name}
# operationId: deleteMachineTagInNamespaceName
export def "organization-machine-tag delete-by-key-namespace-name" [
  key: string
  namespace: string
  name: string
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
  let full_url = (build-url $base $"/organization/($key)/machineTag/($namespace)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags of a name in a namespace from the record
#
# DELETE /node/{key}/machineTag/{namespace}/{name}
# operationId: deleteMachineTagInNamespaceName_1
export def "node-machine-tag delete-by-key-namespace-name" [
  key: string
  namespace: string
  name: string
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
  let full_url = (build-url $base $"/node/($key)/machineTag/($namespace)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags of a name in a namespace from the record
#
# DELETE /network/{key}/machineTag/{namespace}/{name}
# operationId: deleteMachineTagInNamespaceName_2
export def "network-machine-tag delete-by-key-namespace-name" [
  key: string
  namespace: string
  name: string
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
  let full_url = (build-url $base $"/network/($key)/machineTag/($namespace)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags of a name in a namespace from the record
#
# DELETE /installation/{key}/machineTag/{namespace}/{name}
# operationId: deleteMachineTagInNamespaceName_3
export def "installation-machine-tag delete-by-key-namespace-name" [
  key: string
  namespace: string
  name: string
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
  let full_url = (build-url $base $"/installation/($key)/machineTag/($namespace)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags of a name in a namespace from the record
#
# DELETE /grscicoll/institution/{key}/machineTag/{namespace}/{name}
# operationId: deleteMachineTagInNamespaceName_4
export def "grscicoll-institution-machine-tag delete-by-key-namespace-name" [
  key: string
  namespace: string
  name: string
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
  let full_url = (build-url $base $"/grscicoll/institution/($key)/machineTag/($namespace)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags of a name in a namespace from the record
#
# DELETE /grscicoll/collection/{key}/machineTag/{namespace}/{name}
# operationId: deleteMachineTagInNamespaceName_5
export def "grscicoll-collection-machine-tag delete-by-key-namespace-name" [
  key: string
  namespace: string
  name: string
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
  let full_url = (build-url $base $"/grscicoll/collection/($key)/machineTag/($namespace)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete all machine tags of a name in a namespace from the record
#
# DELETE /dataset/{key}/machineTag/{namespace}/{name}
# operationId: deleteMachineTagInNamespaceName_6
export def "dataset-machine-tag delete-by-key-namespace-name" [
  key: string
  namespace: string
  name: string
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
  let full_url = (build-url $base $"/dataset/($key)/machineTag/($namespace)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a master source metadata record
#
# GET /grscicoll/institution/{key}/masterSourceMetadata
# operationId: getMasterSourceMetadata
export def "grscicoll-institution-master-source-metadata get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: int, source: string, sourceId: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/masterSourceMetadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add master source metadata to the record
#
# POST /grscicoll/institution/{key}/masterSourceMetadata
# operationId: addMasterSourceMetadata
export def "grscicoll-institution-master-source-metadata addMasterSourceMetadata" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-source: string@source-completer
  sourceId: string
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/masterSourceMetadata")
  let body = {source: $body_source, sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a master source metadata from a record
#
# DELETE /grscicoll/institution/{key}/masterSourceMetadata
# operationId: deleteMasterSourceMetadata
export def "grscicoll-institution-master-source-metadata delete" [
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
  let full_url = (build-url $base $"/grscicoll/institution/($key)/masterSourceMetadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a master source metadata record
#
# GET /grscicoll/collection/{key}/masterSourceMetadata
# operationId: getMasterSourceMetadata_1
export def "grscicoll-collection-master-source-metadata get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: int, source: string, sourceId: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/masterSourceMetadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add master source metadata to the record
#
# POST /grscicoll/collection/{key}/masterSourceMetadata
# operationId: addMasterSourceMetadata_1
export def "grscicoll-collection-master-source-metadata addMasterSourceMetadata-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-source: string@source-completer
  sourceId: string
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/masterSourceMetadata")
  let body = {source: $body_source, sourceId: $sourceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a master source metadata from a record
#
# DELETE /grscicoll/collection/{key}/masterSourceMetadata
# operationId: deleteMasterSourceMetadata_1
export def "grscicoll-collection-master-source-metadata delete-by-key" [
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
  let full_url = (build-url $base $"/grscicoll/collection/($key)/masterSourceMetadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all tags of the record
#
# GET /organization/{key}/tag
# operationId: getTag
export def "organization-tag get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string
]: nothing -> record<key: int, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organization/($key)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a tag to the record
#
# POST /organization/{key}/tag
# operationId: addTag
export def "organization-tag addTag" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: string # Text value of the tag
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organization/($key)/tag")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all tags of the record
#
# GET /node/{key}/tag
# operationId: getTag_1
export def "node-tag get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string
]: nothing -> record<key: int, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/node/($key)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a tag to the record
#
# POST /node/{key}/tag
# operationId: addTag_1
export def "node-tag addTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: string # Text value of the tag
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/node/($key)/tag")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all tags of the record
#
# GET /network/{key}/tag
# operationId: getTag_2
export def "network-tag get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string
]: nothing -> record<key: int, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/network/($key)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a tag to the record
#
# POST /network/{key}/tag
# operationId: addTag_2
export def "network-tag addTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: string # Text value of the tag
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/network/($key)/tag")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all tags of the record
#
# GET /installation/{key}/tag
# operationId: getTag_3
export def "installation-tag get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string
]: nothing -> record<key: int, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/installation/($key)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a tag to the record
#
# POST /installation/{key}/tag
# operationId: addTag_3
export def "installation-tag addTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: string # Text value of the tag
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/installation/($key)/tag")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all tags of the record
#
# GET /dataset/{key}/tag
# operationId: getTag_4
export def "dataset-tag get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string
]: nothing -> record<key: int, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/dataset/($key)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a tag to the record
#
# POST /dataset/{key}/tag
# operationId: addTag_4
export def "dataset-tag addTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: string # Text value of the tag
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/tag")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a tag from the record
#
# DELETE /organization/{key}/tag/{tagKey}
# operationId: deleteTag
export def "organization-tag delete" [
  key: string
  tagKey: int
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
  let full_url = (build-url $base $"/organization/($key)/tag/($tagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a tag from the record
#
# DELETE /node/{key}/tag/{tagKey}
# operationId: deleteTag_1
export def "node-tag delete-by-key-tagKey" [
  key: string
  tagKey: int
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
  let full_url = (build-url $base $"/node/($key)/tag/($tagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a tag from the record
#
# DELETE /network/{key}/tag/{tagKey}
# operationId: deleteTag_2
export def "network-tag delete-by-key-tagKey" [
  key: string
  tagKey: int
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
  let full_url = (build-url $base $"/network/($key)/tag/($tagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a tag from the record
#
# DELETE /installation/{key}/tag/{tagKey}
# operationId: deleteTag_3
export def "installation-tag delete-by-key-tagKey" [
  key: string
  tagKey: int
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
  let full_url = (build-url $base $"/installation/($key)/tag/($tagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a tag from the record
#
# DELETE /dataset/{key}/tag/{tagKey}
# operationId: deleteTag_4
export def "dataset-tag delete-by-key-tagKey" [
  key: string
  tagKey: int
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
  let full_url = (build-url $base $"/dataset/($key)/tag/($tagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all occurrence mappings of the record
#
# GET /grscicoll/institution/{key}/occurrenceMapping
# operationId: listOccurrenceMappings
export def "grscicoll-institution-occurrence-mapping listOccurrenceMappings" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, code: string, parentCode: string, identifier: string, datasetKey: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/occurrenceMapping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a occurrence mapping to the record
#
# POST /grscicoll/institution/{key}/occurrenceMapping
# operationId: addOccurrenceMapping
export def "grscicoll-institution-occurrence-mapping addOccurrenceMapping" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-key: int # format: int32
  --code: string
  --parentCode: string
  --identifier: string
  datasetKey: string # format: uuid
  --createdBy: string
  --created: string # format: date-time
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/occurrenceMapping")
  let body = {key: $body_key, code: $code, parentCode: $parentCode, identifier: $identifier, datasetKey: $datasetKey, createdBy: $createdBy, created: $created} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all occurrence mappings of the record
#
# GET /grscicoll/collection/{key}/occurrenceMapping
# operationId: listOccurrenceMappings_1
export def "grscicoll-collection-occurrence-mapping listOccurrenceMappings-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, code: string, parentCode: string, identifier: string, datasetKey: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/occurrenceMapping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a occurrence mapping to the record
#
# POST /grscicoll/collection/{key}/occurrenceMapping
# operationId: addOccurrenceMapping_1
export def "grscicoll-collection-occurrence-mapping addOccurrenceMapping-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-key: int # format: int32
  --code: string
  --parentCode: string
  --identifier: string
  datasetKey: string # format: uuid
  --createdBy: string
  --created: string # format: date-time
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/occurrenceMapping")
  let body = {key: $body_key, code: $code, parentCode: $parentCode, identifier: $identifier, datasetKey: $datasetKey, createdBy: $createdBy, created: $created} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all contact people of the record
#
# GET /grscicoll/institution/{key}/contactPerson
# operationId: listContactPeople
export def "grscicoll-institution-contact-person listContactPeople" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, primary: bool, userId: list<string>, salutation: string, firstName: string, lastName: string, position: list<string>, description: string, email: list<string>, phone: list<string>, homepage: list<string>, organization: string, address: list<string>, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/contactPerson")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a contact person to the record
#
# POST /grscicoll/institution/{key}/contactPerson
# operationId: addContactPerson
export def "grscicoll-institution-contact-person addContactPerson" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/contactPerson")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all contact people of the record
#
# GET /grscicoll/collection/{key}/contactPerson
# operationId: listContactPeople_1
export def "grscicoll-collection-contact-person listContactPeople-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: int, type: string, primary: bool, userId: list<string>, salutation: string, firstName: string, lastName: string, position: list<string>, description: string, email: list<string>, phone: list<string>, homepage: list<string>, organization: string, address: list<string>, city: string, province: string, country: string, postalCode: string, createdBy: string, modifiedBy: string, created: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/contactPerson")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a contact person to the record
#
# POST /grscicoll/collection/{key}/contactPerson
# operationId: addContactPerson_1
export def "grscicoll-collection-contact-person addContactPerson-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-4 # The type of contact.
  --primary: string@bool-completer # Whether this is the primary contact for the associated entity.
  --userId: list # A list of user identifiers for this contact.
  --salutation: string # The salutation is used in addressing an individual with a particular title, such as Dr., Ms., Mrs., Mr., etc.
  --firstName: string # The personal name of the contact.
  --lastName: string # The family name of the contact.
  --position: list # The contact's position, job title or similar within the `organization`.
  --description: string # A description of this contact.
  --email: list # Email addresses associated with this contact.
  --phone: list # Telephone numbers associated with this contact.
  --homepage: list # Homepages with further details on the contact.
  --organization: string # The organization (e.g. employer) associated with this contact.
  --address: list # Address lines other than the city, province, country andpostal code, which have their own fields.
  --city: string # The city or similar line of the contact's address.
  --province: string # The province or similar line of the contact's address.
  --country: string@country-completer # The country or other region of the contact's address.
  --postalCode: string # The postal code or similar line of the contact's address.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/contactPerson")
  let body = {type: $type, primary: $primary, userId: $userId, salutation: $salutation, firstName: $firstName, lastName: $lastName, position: $position, description: $description, email: $email, phone: $phone, homepage: $homepage, organization: $organization, address: $address, city: $city, province: $province, country: $country, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an occurrence mapping from the record
#
# DELETE /grscicoll/institution/{key}/occurrenceMapping/{occurrenceMappingKey}
# operationId: deleteOccurrenceMapping
export def "grscicoll-institution-occurrence-mapping delete" [
  key: string
  occurrenceMappingKey: int
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
  let full_url = (build-url $base $"/grscicoll/institution/($key)/occurrenceMapping/($occurrenceMappingKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an occurrence mapping from the record
#
# DELETE /grscicoll/collection/{key}/occurrenceMapping/{occurrenceMappingKey}
# operationId: deleteOccurrenceMapping_1
export def "grscicoll-collection-occurrence-mapping delete-by-key-occurrenceMappingKey" [
  key: string
  occurrenceMappingKey: int
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
  let full_url = (build-url $base $"/grscicoll/collection/($key)/occurrenceMapping/($occurrenceMappingKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all tags of the record
#
# GET /grscicoll/institution/{key}/tag
# operationId: getTag_5
export def "grscicoll-institution-tag get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string
]: nothing -> table<key: int, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/grscicoll/institution/($key)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a tag to the record
#
# POST /grscicoll/institution/{key}/tag
# operationId: addTag_5
export def "grscicoll-institution-tag addTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: string # Text value of the tag
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/tag")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all tags of the record
#
# GET /grscicoll/collection/{key}/tag
# operationId: getTag_6
export def "grscicoll-collection-tag get-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string
]: nothing -> table<key: int, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/grscicoll/collection/($key)/tag" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a tag to the record
#
# POST /grscicoll/collection/{key}/tag
# operationId: addTag_6
export def "grscicoll-collection-tag addTag-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: string # Text value of the tag
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/tag")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a tag from the record
#
# DELETE /grscicoll/institution/{key}/tag/{tagKey}
# operationId: deleteTag_5
export def "grscicoll-institution-tag delete-by-key-tagKey" [
  key: string
  tagKey: int
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
  let full_url = (build-url $base $"/grscicoll/institution/($key)/tag/($tagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a tag from the record
#
# DELETE /grscicoll/collection/{key}/tag/{tagKey}
# operationId: deleteTag_6
export def "grscicoll-collection-tag delete-by-key-tagKey" [
  key: string
  tagKey: int
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
  let full_url = (build-url $base $"/grscicoll/collection/($key)/tag/($tagKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all change suggestions of the record
#
# GET /grscicoll/institution/changeSuggestion
# operationId: listChangeSuggestion
export def "grscicoll-institution-change-suggestion listChangeSuggestion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer
  --type: string@type-completer-3
  --proposerEmail: string
  --entityKey: string # format: uuid
  --ihIdentifier: string
  --country: string
  --page: record
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, type: string, status: string, entityKey: string, entityName: string, entityCountry: string, suggestedEntity: record, proposed: string, proposedBy: string, proposerEmail: string, applied: string, appliedBy: string, discarded: string, discardedBy: string, comments: list, mergeTargetKey: string, changes: list, modified: string, modifiedBy: string, institutionForConvertedCollection: string, nameForNewInstitutionForConvertedCollection: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "proposerEmail" $proposerEmail "scalar") (serialize-qp "entityKey" $entityKey "scalar") (serialize-qp "ihIdentifier" $ihIdentifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "page" $page "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/institution/changeSuggestion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a change suggestion to the record
#
# POST /grscicoll/institution/changeSuggestion
# operationId: addChangeSuggestion
# --suggestedEntity shape: {code?: string, name: string, description?: string, types?: list, active?: bool, email?: list, phone?: list, homepage?: string, catalogUrls?: list, apiUrls?: list, institutionalGovernances?: list, disciplines?: list, latitude?: float, longitude?: float, mailingAddress?: record, address?: record, additionalNames?: list, foundingDate?: int, numberSpecimens?: int, logoUrl?: string, contactPersons?: list, alternativeCodes?: list, replacedBy?: string, convertedToCollection?: string, masterSource?: "GRSCICOLL"|"GBIF_REGISTRY"|"IH", masterSourceMetadata?: record, displayOnNHCPortal?: bool, occurrenceCount?: int, typeSpecimenCount?: int, featuredImageUrl?: string, featuredImageLicense?: "CC0_1_0"|"CC_BY_4_0"|"CC_BY_NC_4_0"|"UNSPECIFIED"|"UNSUPPORTED", featuredImageAttribution?: string}
# --changes item shape: {field?: string, suggested?: any, previous?: any, created?: string, author?: string, overwritten?: bool, outdated?: bool}
export def "grscicoll-institution-change-suggestion addChangeSuggestion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-3
  --status: string@status-completer
  --entityKey: string # format: uuid
  --entityName: string
  --entityCountry: string@entityCountry-completer
  --suggestedEntity: record # shape: {code?: string, name: string, description?: string, types?: list, active?: bool, email?: list, phone?: list, homepage?: string, catalogUrls?: list, apiUrls?: list, institutionalGovernances?: list, disciplines?: list, latitude?: float, longitude?: float, mailingAddress?: record, address?: record, additionalNames?: list, foundingDate?: int, numberSpecimens?: int, logoUrl?: string, contactPersons?: list, alternativeCodes?: list, replacedBy?: string, convertedToCollection?: string, masterSource?: "GRSCICOLL"|"GBIF_REGISTRY"|"IH", masterSourceMetadata?: record, displayOnNHCPortal?: bool, occurrenceCount?: int, typeSpecimenCount?: int, featuredImageUrl?: string, featuredImageLicense?: "CC0_1_0"|"CC_BY_4_0"|"CC_BY_NC_4_0"|"UNSPECIFIED"|"UNSUPPORTED", featuredImageAttribution?: string}
  --proposed: string # format: date-time
  --proposedBy: string
  --proposerEmail: string
  --applied: string # format: date-time
  --appliedBy: string
  --discarded: string # format: date-time
  --discardedBy: string
  --comments: list
  --mergeTargetKey: string # format: uuid
  --changes: list # item shape: {field?: string, suggested?: any, previous?: any, created?: string, author?: string, overwritten?: bool, outdated?: bool}
  --modified: string # format: date-time
  --modifiedBy: string
  --institutionForConvertedCollection: string # format: uuid
  --nameForNewInstitutionForConvertedCollection: string
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grscicoll/institution/changeSuggestion")
  let body = {type: $type, status: $status, entityKey: $entityKey, entityName: $entityName, entityCountry: $entityCountry, suggestedEntity: $suggestedEntity, proposed: $proposed, proposedBy: $proposedBy, proposerEmail: $proposerEmail, applied: $applied, appliedBy: $appliedBy, discarded: $discarded, discardedBy: $discardedBy, comments: $comments, mergeTargetKey: $mergeTargetKey, changes: $changes, modified: $modified, modifiedBy: $modifiedBy, institutionForConvertedCollection: $institutionForConvertedCollection, nameForNewInstitutionForConvertedCollection: $nameForNewInstitutionForConvertedCollection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all change suggestions of the record
#
# GET /grscicoll/collection/changeSuggestion
# operationId: listChangeSuggestion_1
export def "grscicoll-collection-change-suggestion listChangeSuggestion-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer
  --type: string@type-completer-3
  --proposerEmail: string
  --entityKey: string # format: uuid
  --ihIdentifier: string
  --country: string
  --page: record
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, type: string, status: string, entityKey: string, entityName: string, entityCountry: string, suggestedEntity: record, proposed: string, proposedBy: string, proposerEmail: string, applied: string, appliedBy: string, discarded: string, discardedBy: string, comments: list, mergeTargetKey: string, changes: list, modified: string, modifiedBy: string, ihIdentifier: string, createInstitution: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "proposerEmail" $proposerEmail "scalar") (serialize-qp "entityKey" $entityKey "scalar") (serialize-qp "ihIdentifier" $ihIdentifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "page" $page "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/collection/changeSuggestion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a change suggestion to the record
#
# POST /grscicoll/collection/changeSuggestion
# operationId: addChangeSuggestion_1
# --suggestedEntity shape: {code?: string, name: string, description?: string, contentTypes?: list, active?: bool, personalCollection?: bool, doi?: string, email?: list, phone?: list, homepage?: string, catalogUrls?: list, apiUrls?: list, preservationTypes?: list, accessionStatus?: string, institutionKey?: string, mailingAddress?: record, address?: record, numberSpecimens?: int, taxonomicCoverage?: string, geographicCoverage?: string, notes?: string, incorporatedCollections?: list, alternativeCodes?: list, replacedBy?: string, masterSource?: "GRSCICOLL"|"GBIF_REGISTRY"|"IH", masterSourceMetadata?: record, department?: string, division?: string, displayOnNHCPortal?: bool, occurrenceCount?: int, typeSpecimenCount?: int, featuredImageUrl?: string, featuredImageLicense?: "CC0_1_0"|"CC_BY_4_0"|"CC_BY_NC_4_0"|"UNSPECIFIED"|"UNSUPPORTED", temporalCoverage?: string, featuredImageAttribution?: string}
# --changes item shape: {field?: string, suggested?: any, previous?: any, created?: string, author?: string, overwritten?: bool, outdated?: bool}
export def "grscicoll-collection-change-suggestion addChangeSuggestion-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-3
  --status: string@status-completer
  --entityKey: string # format: uuid
  --entityName: string
  --entityCountry: string@entityCountry-completer
  --suggestedEntity: record # shape: {code?: string, name: string, description?: string, contentTypes?: list, active?: bool, personalCollection?: bool, doi?: string, email?: list, phone?: list, homepage?: string, catalogUrls?: list, apiUrls?: list, preservationTypes?: list, accessionStatus?: string, institutionKey?: string, mailingAddress?: record, address?: record, numberSpecimens?: int, taxonomicCoverage?: string, geographicCoverage?: string, notes?: string, incorporatedCollections?: list, alternativeCodes?: list, replacedBy?: string, masterSource?: "GRSCICOLL"|"GBIF_REGISTRY"|"IH", masterSourceMetadata?: record, department?: string, division?: string, displayOnNHCPortal?: bool, occurrenceCount?: int, typeSpecimenCount?: int, featuredImageUrl?: string, featuredImageLicense?: "CC0_1_0"|"CC_BY_4_0"|"CC_BY_NC_4_0"|"UNSPECIFIED"|"UNSUPPORTED", temporalCoverage?: string, featuredImageAttribution?: string}
  --proposed: string # format: date-time
  --proposedBy: string
  --proposerEmail: string
  --applied: string # format: date-time
  --appliedBy: string
  --discarded: string # format: date-time
  --discardedBy: string
  --comments: list
  --mergeTargetKey: string # format: uuid
  --changes: list # item shape: {field?: string, suggested?: any, previous?: any, created?: string, author?: string, overwritten?: bool, outdated?: bool}
  --modified: string # format: date-time
  --modifiedBy: string
  --ihIdentifier: string
  --createInstitution: string@bool-completer
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grscicoll/collection/changeSuggestion")
  let body = {type: $type, status: $status, entityKey: $entityKey, entityName: $entityName, entityCountry: $entityCountry, suggestedEntity: $suggestedEntity, proposed: $proposed, proposedBy: $proposedBy, proposerEmail: $proposerEmail, applied: $applied, appliedBy: $appliedBy, discarded: $discarded, discardedBy: $discardedBy, comments: $comments, mergeTargetKey: $mergeTargetKey, changes: $changes, modified: $modified, modifiedBy: $modifiedBy, ihIdentifier: $ihIdentifier, createInstitution: $createInstitution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single change suggestion of a record
#
# GET /grscicoll/institution/changeSuggestion/{key}
# operationId: getChangeSuggestion
export def "grscicoll-institution-change-suggestion get" [
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: int, type: string, status: string, entityKey: string, entityName: string, entityCountry: string, suggestedEntity: record<key: string, code: string, name: string, description: string, types: list<string>, active: bool, email: list<string>, phone: list<string>, homepage: string, catalogUrls: list<string>, apiUrls: list<string>, institutionalGovernances: list<string>, disciplines: list<string>, latitude: float, longitude: float, mailingAddress: record<key: int, address: string, city: string, province: string, postalCode: string, country: string>, address: record<key: int, address: string, city: string, province: string, postalCode: string, country: string>, additionalNames: list<string>, foundingDate: int, numberSpecimens: int, logoUrl: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, tags: list<record>, identifiers: list<record>, contactPersons: list<record>, machineTags: list<record>, alternativeCodes: list<record>, comments: list<record>, occurrenceMappings: list<record>, replacedBy: string, convertedToCollection: string, masterSource: string, masterSourceMetadata: record<key: int, source: string, sourceId: string, createdBy: string, created: string>, displayOnNHCPortal: bool, occurrenceCount: int, typeSpecimenCount: int, featuredImageUrl: string, featuredImageLicense: string, featuredImageAttribution: string>, proposed: string, proposedBy: string, proposerEmail: string, applied: string, appliedBy: string, discarded: string, discardedBy: string, comments: list<string>, mergeTargetKey: string, changes: table<field: string, suggested: any, previous: any, created: string, author: string, overwritten: bool, outdated: bool>, modified: string, modifiedBy: string, institutionForConvertedCollection: string, nameForNewInstitutionForConvertedCollection: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/changeSuggestion/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing change suggestion on the record
#
# PUT /grscicoll/institution/changeSuggestion/{key}
# operationId: updateChangeSuggestion
# --suggestedEntity shape: {code?: string, name: string, description?: string, types?: list, active?: bool, email?: list, phone?: list, homepage?: string, catalogUrls?: list, apiUrls?: list, institutionalGovernances?: list, disciplines?: list, latitude?: float, longitude?: float, mailingAddress?: record, address?: record, additionalNames?: list, foundingDate?: int, numberSpecimens?: int, logoUrl?: string, contactPersons?: list, alternativeCodes?: list, replacedBy?: string, convertedToCollection?: string, masterSource?: "GRSCICOLL"|"GBIF_REGISTRY"|"IH", masterSourceMetadata?: record, displayOnNHCPortal?: bool, occurrenceCount?: int, typeSpecimenCount?: int, featuredImageUrl?: string, featuredImageLicense?: "CC0_1_0"|"CC_BY_4_0"|"CC_BY_NC_4_0"|"UNSPECIFIED"|"UNSUPPORTED", featuredImageAttribution?: string}
# --changes item shape: {field?: string, suggested?: any, previous?: any, created?: string, author?: string, overwritten?: bool, outdated?: bool}
export def "grscicoll-institution-change-suggestion updateChangeSuggestion" [
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-3
  --status: string@status-completer
  --entityKey: string # format: uuid
  --entityName: string
  --entityCountry: string@entityCountry-completer
  --suggestedEntity: record # shape: {code?: string, name: string, description?: string, types?: list, active?: bool, email?: list, phone?: list, homepage?: string, catalogUrls?: list, apiUrls?: list, institutionalGovernances?: list, disciplines?: list, latitude?: float, longitude?: float, mailingAddress?: record, address?: record, additionalNames?: list, foundingDate?: int, numberSpecimens?: int, logoUrl?: string, contactPersons?: list, alternativeCodes?: list, replacedBy?: string, convertedToCollection?: string, masterSource?: "GRSCICOLL"|"GBIF_REGISTRY"|"IH", masterSourceMetadata?: record, displayOnNHCPortal?: bool, occurrenceCount?: int, typeSpecimenCount?: int, featuredImageUrl?: string, featuredImageLicense?: "CC0_1_0"|"CC_BY_4_0"|"CC_BY_NC_4_0"|"UNSPECIFIED"|"UNSUPPORTED", featuredImageAttribution?: string}
  --proposed: string # format: date-time
  --proposedBy: string
  --proposerEmail: string
  --applied: string # format: date-time
  --appliedBy: string
  --discarded: string # format: date-time
  --discardedBy: string
  --comments: list
  --mergeTargetKey: string # format: uuid
  --changes: list # item shape: {field?: string, suggested?: any, previous?: any, created?: string, author?: string, overwritten?: bool, outdated?: bool}
  --modified: string # format: date-time
  --modifiedBy: string
  --institutionForConvertedCollection: string # format: uuid
  --nameForNewInstitutionForConvertedCollection: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/changeSuggestion/($key)")
  let body = {type: $type, status: $status, entityKey: $entityKey, entityName: $entityName, entityCountry: $entityCountry, suggestedEntity: $suggestedEntity, proposed: $proposed, proposedBy: $proposedBy, proposerEmail: $proposerEmail, applied: $applied, appliedBy: $appliedBy, discarded: $discarded, discardedBy: $discardedBy, comments: $comments, mergeTargetKey: $mergeTargetKey, changes: $changes, modified: $modified, modifiedBy: $modifiedBy, institutionForConvertedCollection: $institutionForConvertedCollection, nameForNewInstitutionForConvertedCollection: $nameForNewInstitutionForConvertedCollection} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single change suggestion of a record
#
# GET /grscicoll/collection/changeSuggestion/{key}
# operationId: getChangeSuggestion_1
export def "grscicoll-collection-change-suggestion get-by-key" [
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: int, type: string, status: string, entityKey: string, entityName: string, entityCountry: string, suggestedEntity: record<key: string, code: string, name: string, description: string, contentTypes: list<string>, active: bool, personalCollection: bool, doi: string, email: list<string>, phone: list<string>, homepage: string, catalogUrls: list<string>, apiUrls: list<string>, preservationTypes: list<string>, accessionStatus: string, institutionKey: string, mailingAddress: record<key: int, address: string, city: string, province: string, postalCode: string, country: string>, address: record<key: int, address: string, city: string, province: string, postalCode: string, country: string>, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, tags: list<record>, identifiers: list<record>, contactPersons: list<record>, numberSpecimens: int, machineTags: list<record>, taxonomicCoverage: string, geographicCoverage: string, notes: string, incorporatedCollections: list<string>, alternativeCodes: list<record>, comments: list<record>, occurrenceMappings: list<record>, replacedBy: string, masterSource: string, masterSourceMetadata: record<key: int, source: string, sourceId: string, createdBy: string, created: string>, department: string, division: string, displayOnNHCPortal: bool, occurrenceCount: int, typeSpecimenCount: int, featuredImageUrl: string, featuredImageLicense: string, temporalCoverage: string, featuredImageAttribution: string>, proposed: string, proposedBy: string, proposerEmail: string, applied: string, appliedBy: string, discarded: string, discardedBy: string, comments: list<string>, mergeTargetKey: string, changes: table<field: string, suggested: any, previous: any, created: string, author: string, overwritten: bool, outdated: bool>, modified: string, modifiedBy: string, ihIdentifier: string, createInstitution: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/changeSuggestion/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing change suggestion on the record
#
# PUT /grscicoll/collection/changeSuggestion/{key}
# operationId: updateChangeSuggestion_1
# --suggestedEntity shape: {code?: string, name: string, description?: string, contentTypes?: list, active?: bool, personalCollection?: bool, doi?: string, email?: list, phone?: list, homepage?: string, catalogUrls?: list, apiUrls?: list, preservationTypes?: list, accessionStatus?: string, institutionKey?: string, mailingAddress?: record, address?: record, numberSpecimens?: int, taxonomicCoverage?: string, geographicCoverage?: string, notes?: string, incorporatedCollections?: list, alternativeCodes?: list, replacedBy?: string, masterSource?: "GRSCICOLL"|"GBIF_REGISTRY"|"IH", masterSourceMetadata?: record, department?: string, division?: string, displayOnNHCPortal?: bool, occurrenceCount?: int, typeSpecimenCount?: int, featuredImageUrl?: string, featuredImageLicense?: "CC0_1_0"|"CC_BY_4_0"|"CC_BY_NC_4_0"|"UNSPECIFIED"|"UNSUPPORTED", temporalCoverage?: string, featuredImageAttribution?: string}
# --changes item shape: {field?: string, suggested?: any, previous?: any, created?: string, author?: string, overwritten?: bool, outdated?: bool}
export def "grscicoll-collection-change-suggestion updateChangeSuggestion-by-key" [
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer-3
  --status: string@status-completer
  --entityKey: string # format: uuid
  --entityName: string
  --entityCountry: string@entityCountry-completer
  --suggestedEntity: record # shape: {code?: string, name: string, description?: string, contentTypes?: list, active?: bool, personalCollection?: bool, doi?: string, email?: list, phone?: list, homepage?: string, catalogUrls?: list, apiUrls?: list, preservationTypes?: list, accessionStatus?: string, institutionKey?: string, mailingAddress?: record, address?: record, numberSpecimens?: int, taxonomicCoverage?: string, geographicCoverage?: string, notes?: string, incorporatedCollections?: list, alternativeCodes?: list, replacedBy?: string, masterSource?: "GRSCICOLL"|"GBIF_REGISTRY"|"IH", masterSourceMetadata?: record, department?: string, division?: string, displayOnNHCPortal?: bool, occurrenceCount?: int, typeSpecimenCount?: int, featuredImageUrl?: string, featuredImageLicense?: "CC0_1_0"|"CC_BY_4_0"|"CC_BY_NC_4_0"|"UNSPECIFIED"|"UNSUPPORTED", temporalCoverage?: string, featuredImageAttribution?: string}
  --proposed: string # format: date-time
  --proposedBy: string
  --proposerEmail: string
  --applied: string # format: date-time
  --appliedBy: string
  --discarded: string # format: date-time
  --discardedBy: string
  --comments: list
  --mergeTargetKey: string # format: uuid
  --changes: list # item shape: {field?: string, suggested?: any, previous?: any, created?: string, author?: string, overwritten?: bool, outdated?: bool}
  --modified: string # format: date-time
  --modifiedBy: string
  --ihIdentifier: string
  --createInstitution: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/changeSuggestion/($key)")
  let body = {type: $type, status: $status, entityKey: $entityKey, entityName: $entityName, entityCountry: $entityCountry, suggestedEntity: $suggestedEntity, proposed: $proposed, proposedBy: $proposedBy, proposerEmail: $proposerEmail, applied: $applied, appliedBy: $appliedBy, discarded: $discarded, discardedBy: $discardedBy, comments: $comments, mergeTargetKey: $mergeTargetKey, changes: $changes, modified: $modified, modifiedBy: $modifiedBy, ihIdentifier: $ihIdentifier, createInstitution: $createInstitution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Discard a collection change suggestion
#
# PUT /grscicoll/institution/changeSuggestion/{key}/discard
# operationId: discardChangeSuggestion
export def "grscicoll-institution-change-suggestion-discard discardChangeSuggestion" [
  key: int
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
  let full_url = (build-url $base $"/grscicoll/institution/changeSuggestion/($key)/discard")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Discard a collection change suggestion
#
# PUT /grscicoll/collection/changeSuggestion/{key}/discard
# operationId: discardChangeSuggestion_1
export def "grscicoll-collection-change-suggestion-discard discardChangeSuggestion-by-key" [
  key: int
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
  let full_url = (build-url $base $"/grscicoll/collection/changeSuggestion/($key)/discard")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply a collection change suggestion
#
# PUT /grscicoll/institution/changeSuggestion/{key}/apply
# operationId: applyChangeSuggestion
export def "grscicoll-institution-change-suggestion-apply applyChangeSuggestion" [
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<entityCreatedKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/changeSuggestion/($key)/apply")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Apply a collection change suggestion
#
# PUT /grscicoll/collection/changeSuggestion/{key}/apply
# operationId: applyChangeSuggestion_1
export def "grscicoll-collection-change-suggestion-apply applyChangeSuggestion-by-key" [
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<entityCreatedKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/changeSuggestion/($key)/apply")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merges a record with another record
#
# POST /grscicoll/institution/{key}/merge
# operationId: merge
export def "grscicoll-institution-merge merge" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --replacementEntityKey: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/merge")
  let body = {replacementEntityKey: $replacementEntityKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Merges a record with another record
#
# POST /grscicoll/collection/{key}/merge
# operationId: merge_1
export def "grscicoll-collection-merge merge-by-key" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --replacementEntityKey: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($key)/merge")
  let body = {replacementEntityKey: $replacementEntityKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Converts an institution into a collection
#
# POST /grscicoll/institution/{key}/convertToCollection
# operationId: importCollection
export def "grscicoll-institution-convert-to-collection importCollection" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --institutionForNewCollectionKey: string # format: uuid
  --nameForNewInstitution: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/($key)/convertToCollection")
  let body = {institutionForNewCollectionKey: $institutionForNewCollectionKey, nameForNewInstitution: $nameForNewInstitution} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import a collection
#
# POST /grscicoll/collection/import
# operationId: importCollection_1
export def "grscicoll-collection-import importCollection-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --datasetKey: string # format: uuid
  --collectionCode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grscicoll/collection/import")
  let body = {datasetKey: $datasetKey, collectionCode: $collectionCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import an institution
#
# POST /grscicoll/institution/import
# operationId: importInstitution
export def "grscicoll-institution-import importInstitution" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organizationKey: string # format: uuid
  --institutionCode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/grscicoll/institution/import")
  let body = {organizationKey: $organizationKey, institutionCode: $institutionCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get details of a single collection descriptor
#
# GET /grscicoll/collection/{collectionKey}/descriptorGroup/{key}
# operationId: getCollectionDescriptorGroup
export def "grscicoll-collection-descriptor-group get" [
  collectionKey: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: int, title: string, description: string, collectionKey: string, created: string, createdBy: string, modified: string, modifiedBy: string, deleted: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing collection descriptor group
#
# PUT /grscicoll/collection/{collectionKey}/descriptorGroup/{key}
# operationId: updateCollectionDescriptorGroup
export def "grscicoll-collection-descriptor-group updateCollectionDescriptorGroup" [
  collectionKey: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # default: CSV
  --title: string
  --description: string
  --tags: list
  --descriptorsFile: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/($key)" $qp)
  let body = {descriptorsFile: $descriptorsFile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Deletes a collection descriptor group
#
# DELETE /grscicoll/collection/{collectionKey}/descriptorGroup/{key}
# operationId: deleteCollectionDescriptorGroup
export def "grscicoll-collection-descriptor-group delete" [
  collectionKey: string
  key: int
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
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the descriptor groups of the collection.
#
# GET /grscicoll/collection/{collectionKey}/descriptorGroup
# operationId: getCollectionDescriptorGroups
export def "grscicoll-collection-descriptor-group list" [
  collectionKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchRequest: record
  --title: string # Descriptor group title
  --description: string # Descriptor group description
  --deleted: string@bool-completer # Boolean flag to indicate if we want deleted descriptor groups
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, title: string, description: string, collectionKey: string, created: string, createdBy: string, modified: string, modifiedBy: string, deleted: string, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchRequest" $searchRequest "multi") (serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new collection descriptor group
#
# POST /grscicoll/collection/{collectionKey}/descriptorGroup
# operationId: createCollectionDescriptorGroup
export def "grscicoll-collection-descriptor-group createCollectionDescriptorGroup" [
  collectionKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # default: CSV
  --title: string
  --description: string
  --tags: list
  --descriptorsFile: string # format: binary
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "tags" $tags "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup" $qp)
  let body = {descriptorsFile: $descriptorsFile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# List deleted installations
#
# GET /installation/deleted
# operationId: getDeletedInstallations
export def "installation-deleted get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchParams: record
  --type: string@type-completer-1 # Filter by the type of installation.
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --modified: string # The modified date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `modified=2023-04-01,*`
  --created: string # The created date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `created=2023-04-01,*`
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, organizationKey: string, type: string, title: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, disabled: bool, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchParams" $searchParams "multi") (serialize-qp "type" $type "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "modified" $modified "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/installation/deleted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List deleted organizations
#
# GET /organization/deleted
# operationId: getDeletedOrganizations
export def "organization-deleted get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchParams: record
  --isEndorsed: string@bool-completer # Whether the organization is endorsed by a node.
  --networkKey: string # Filter for organizations publishing datasets belonging to a network. (format: uuid)
  --numPublishedDatasets: string # Filter by number of published datasets. Examples: '5' (exactly 5), '1,*' (at least 1), '*,10' (at most 10), '5,15' (between 5 and 15).
  --contactUserId: string # Filter organizations by contact user ID (e.g., ORCID).
  --contactEmail: string # Filter organizations by contact email address.
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --modified: string # The modified date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `modified=2023-04-01,*`
  --created: string # The created date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `created=2023-04-01,*`
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, endorsingNodeKey: string, endorsementApproved: bool, endorsementStatus: string, title: string, abbreviation: string, description: string, language: string, email: list, phone: list, homepage: list, logoUrl: string, address: list, city: string, province: string, country: string, postalCode: string, latitude: float, longitude: float, numPublishedDatasets: int, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, endorsed: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchParams" $searchParams "multi") (serialize-qp "isEndorsed" $isEndorsed "scalar") (serialize-qp "networkKey" $networkKey "scalar") (serialize-qp "numPublishedDatasets" $numPublishedDatasets "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "modified" $modified "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/deleted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all deleted institution records
#
# GET /grscicoll/institution/deleted
# operationId: listDeleted
export def "grscicoll-institution-deleted listDeleted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Type of a GrSciColl institution. Accepts multiple values, for example `type=Museum&type=BotanicalGarden
  --institutionalGovernance: string # Institutional governance of a GrSciColl institution. Accepts multiple values, for example `InstitutionalGovernance=NonProfit&InstitutionalGovernance=Local`
  --discipline: string # Discipline of a GrSciColl institution. Accepts multiple values, for example `discipline=Zoology&discipline=Biological`
  --sourceId: string # sourceId of MasterSourceMetadata
  --qp-source: string@source-completer # Source attribute of MasterSourceMetadata
  --code: string # Code of a GrSciColl institution or collection
  --name: string # Name of a GrSciColl institution or collection
  --alternativeCode: string # Alternative code of a GrSciColl institution or collection
  --contact: string # Filters collections and institutions whose contacts contain the person key specified (format: uuid)
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --country: string@country-completer # Filters by country given as a ISO 639-1 (2 letter) country code.
  --gbifRegion: string@gbifRegion-completer # Filters by a gbif region
  --city: string # Filters by the city of the address. It searches in both the physical and the mailing address.
  --fuzzyName: string # It searches by name fuzzily so the parameter doesn't have to be the exact name
  --active: string@bool-completer # Active status of a GrSciColl institution or collection
  --masterSourceType: string@masterSourceType-completer # The master source type of a GRSciColl institution or collection
  --numberSpecimens: string # Number of specimens. It supports ranges and a `*` can be used as a wildcard
  --displayOnNHCPortal: string@bool-completer # Flag to show this record in the NHC portal
  --replacedBy: string # Key of the entity that replaced another entity (format: uuid)
  --occurrenceCount: string # Count of occurrences linked. It supports ranges and a `*` can be used as a wildcard
  --typeSpecimenCount: string # Count of type specimens linked. It supports ranges and a `*` can be used as a wildcard
  --institutionKey: string # Keys of institutions to filter by (format: uuid)
  --sortBy: string@sortBy-completer # Field to sort the results by. It only supports the fields contained in the enum.
  --sortOrder: string@sortOrder-completer # Sort order to use with the sortBy parameter
  --contactUserId: string # Filter by contact user ID
  --contactEmail: string # Filter by contact email
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, code: string, name: string, description: string, types: list, active: bool, email: list, phone: list, homepage: string, catalogUrls: list, apiUrls: list, institutionalGovernances: list, disciplines: list, latitude: float, longitude: float, mailingAddress: record, address: record, additionalNames: list, foundingDate: int, numberSpecimens: int, logoUrl: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, tags: list, identifiers: list, contactPersons: list, machineTags: list, alternativeCodes: list, comments: list, occurrenceMappings: list, replacedBy: string, convertedToCollection: string, masterSource: string, masterSourceMetadata: record, displayOnNHCPortal: bool, occurrenceCount: int, typeSpecimenCount: int, featuredImageUrl: string, featuredImageLicense: string, featuredImageAttribution: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "institutionalGovernance" $institutionalGovernance "scalar") (serialize-qp "discipline" $discipline "scalar") (serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "alternativeCode" $alternativeCode "scalar") (serialize-qp "contact" $contact "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "gbifRegion" $gbifRegion "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuzzyName" $fuzzyName "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "masterSourceType" $masterSourceType "scalar") (serialize-qp "numberSpecimens" $numberSpecimens "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "scalar") (serialize-qp "replacedBy" $replacedBy "scalar") (serialize-qp "occurrenceCount" $occurrenceCount "scalar") (serialize-qp "typeSpecimenCount" $typeSpecimenCount "scalar") (serialize-qp "institutionKey" $institutionKey "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/institution/deleted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all deleted collection records
#
# GET /grscicoll/collection/deleted
# operationId: listDeleted_1
@deprecated --flag institution
export def "grscicoll-collection-deleted listDeleted-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --institution: string # A key for the institution. Deprecated: use institutionKey instead. (DEPRECATED, format: uuid)
  --contentType: string # Content type of a GrSciColl collection. Accepts multiple values, for example `contentType=Paleontological&contentType=EarthPlanetary`.
  --preservationType: string # Preservation type of a GrSciColl collection. Accepts multiple values, for example `preservationType=SampleCryopreserved&preservationType=SampleFluidPreserved`.
  --accessionStatus: string # Accession status of a GrSciColl collection. Accepts multiple values, for example `accessionStatus=Institutional&accessionStatus=Project
  --personalCollection: string@bool-completer # Flag for personal GRSciColl collections
  --sourceId: string # sourceId of MasterSourceMetadata
  --qp-source: string@source-completer # Source attribute of MasterSourceMetadata
  --code: string # Code of a GrSciColl institution or collection
  --name: string # Name of a GrSciColl institution or collection
  --alternativeCode: string # Alternative code of a GrSciColl institution or collection
  --contact: string # Filters collections and institutions whose contacts contain the person key specified (format: uuid)
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --country: string@country-completer # Filters by country given as a ISO 639-1 (2 letter) country code.
  --gbifRegion: string@gbifRegion-completer # Filters by a gbif region
  --city: string # Filters by the city of the address. It searches in both the physical and the mailing address.
  --fuzzyName: string # It searches by name fuzzily so the parameter doesn't have to be the exact name
  --active: string@bool-completer # Active status of a GrSciColl institution or collection
  --masterSourceType: string@masterSourceType-completer # The master source type of a GRSciColl institution or collection
  --numberSpecimens: string # Number of specimens. It supports ranges and a `*` can be used as a wildcard
  --displayOnNHCPortal: string@bool-completer # Flag to show this record in the NHC portal
  --replacedBy: string # Key of the entity that replaced another entity (format: uuid)
  --occurrenceCount: string # Count of occurrences linked. It supports ranges and a `*` can be used as a wildcard
  --typeSpecimenCount: string # Count of type specimens linked. It supports ranges and a `*` can be used as a wildcard
  --institutionKey: string # Keys of institutions to filter by (format: uuid)
  --sortBy: string@sortBy-completer # Field to sort the results by. It only supports the fields contained in the enum.
  --sortOrder: string@sortOrder-completer # Sort order to use with the sortBy parameter
  --contactUserId: string # Filter by contact user ID
  --contactEmail: string # Filter by contact email
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, code: string, name: string, description: string, contentTypes: list, active: bool, personalCollection: bool, doi: string, email: list, phone: list, homepage: string, catalogUrls: list, apiUrls: list, preservationTypes: list, accessionStatus: string, institutionKey: string, mailingAddress: record, address: record, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, tags: list, identifiers: list, contactPersons: list, numberSpecimens: int, machineTags: list, taxonomicCoverage: string, geographicCoverage: string, notes: string, incorporatedCollections: list, alternativeCodes: list, comments: list, occurrenceMappings: list, replacedBy: string, masterSource: string, masterSourceMetadata: record, department: string, division: string, displayOnNHCPortal: bool, occurrenceCount: int, typeSpecimenCount: int, featuredImageUrl: string, featuredImageLicense: string, temporalCoverage: string, featuredImageAttribution: string, institutionName: string, institutionCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "institution" $institution "scalar") (serialize-qp "contentType" $contentType "scalar") (serialize-qp "preservationType" $preservationType "scalar") (serialize-qp "accessionStatus" $accessionStatus "scalar") (serialize-qp "personalCollection" $personalCollection "scalar") (serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "alternativeCode" $alternativeCode "scalar") (serialize-qp "contact" $contact "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "gbifRegion" $gbifRegion "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuzzyName" $fuzzyName "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "masterSourceType" $masterSourceType "scalar") (serialize-qp "numberSpecimens" $numberSpecimens "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "scalar") (serialize-qp "replacedBy" $replacedBy "scalar") (serialize-qp "occurrenceCount" $occurrenceCount "scalar") (serialize-qp "typeSpecimenCount" $typeSpecimenCount "scalar") (serialize-qp "institutionKey" $institutionKey "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/collection/deleted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reinterprets all the descriptor groups
#
# POST /grscicoll/collection/reinterpretAllDescriptorGroups
# operationId: reinterpretAllDescriptorGroups
export def "grscicoll-collection-reinterpret-all-descriptor-groups reinterpretAllDescriptorGroups" [
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
  let full_url = (build-url $base "/grscicoll/collection/reinterpretAllDescriptorGroups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reinterprets a collection descriptor group
#
# POST /grscicoll/collection/{collectionKey}/descriptorGroup/{key}/reinterpret
# operationId: reinterpretCollectionDescriptorGroup
export def "grscicoll-collection-descriptor-group-reinterpret reinterpretCollectionDescriptorGroup" [
  collectionKey: string
  key: int
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
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/($key)/reinterpret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reinterprets all the descriptor groups of the collection
#
# POST /grscicoll/collection/{collectionKey}/descriptorGroup/reinterpretAll
# operationId: reinterpretCollectionDescriptorGroups
export def "grscicoll-collection-descriptor-group-reinterpret-all reinterpretCollectionDescriptorGroups" [
  collectionKey: string
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
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/reinterpretAll")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all deleted datasets
#
# GET /dataset/deleted
# operationId: getDeletedDatasets
export def "dataset-deleted get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --country: string@country-completer # The 2-letter country code (as per ISO-3166-1) of the country publishing the dataset.
  --type: string@type-completer # The primary type of the dataset.
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --modified: string # The modified date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `modified=2023-04-01,*`
  --created: string # The created date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `created=2023-04-01,*`
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, parentDatasetKey: string, duplicateOfDatasetKey: string, installationKey: string, publishingOrganizationKey: string, publishingOrganizationName: string, networkKeys: list, doi: string, version: string, external: bool, numConstituents: int, type: string, subtype: string, shortName: string, title: string, alias: string, abbreviation: string, description: string, language: string, homepage: string, logoUrl: string, citation: record, contactsCitation: list, rights: string, lockedForAutoUpdate: bool, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list, bibliographicCitations: list, curatorialUnits: list, taxonomicCoverages: list, geographicCoverageDescription: string, geographicCoverages: list, temporalCoverages: list, keywordCollections: list, project: record, samplingDescription: record, countryCoverage: list, collections: list, dataDescriptions: list, dataLanguage: string, purpose: string, introduction: string, gettingStarted: string, acknowledgements: string, additionalInfo: string, pubDate: string, maintenanceUpdateFrequency: string, maintenanceDescription: string, license: string, dwca: record, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "modified" $modified "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataset/deleted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all duplicate datasets
#
# GET /dataset/duplicate
# operationId: getDuplicateDatasets
export def "dataset-duplicate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, parentDatasetKey: string, duplicateOfDatasetKey: string, installationKey: string, publishingOrganizationKey: string, publishingOrganizationName: string, networkKeys: list, doi: string, version: string, external: bool, numConstituents: int, type: string, subtype: string, shortName: string, title: string, alias: string, abbreviation: string, description: string, language: string, homepage: string, logoUrl: string, citation: record, contactsCitation: list, rights: string, lockedForAutoUpdate: bool, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list, bibliographicCitations: list, curatorialUnits: list, taxonomicCoverages: list, geographicCoverageDescription: string, geographicCoverages: list, temporalCoverages: list, keywordCollections: list, project: record, samplingDescription: record, countryCoverage: list, collections: list, dataDescriptions: list, dataLanguage: string, purpose: string, introduction: string, gettingStarted: string, acknowledgements: string, additionalInfo: string, pubDate: string, maintenanceUpdateFrequency: string, maintenanceDescription: string, license: string, dwca: record, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataset/duplicate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List pending organizations of a node
#
# GET /node/{key}/pendingEndorsement
# operationId: getNodePendingOrganizations
export def "node-pending-endorsement get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, endorsingNodeKey: string, endorsementApproved: bool, endorsementStatus: string, title: string, abbreviation: string, description: string, language: string, email: list, phone: list, homepage: list, logoUrl: string, address: list, city: string, province: string, country: string, postalCode: string, latitude: float, longitude: float, numPublishedDatasets: int, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, endorsed: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/node/($key)/pendingEndorsement" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List pending organizations
#
# GET /organization/pending
# operationId: getPendingOrganizations
export def "organization-pending get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, endorsingNodeKey: string, endorsementApproved: bool, endorsementStatus: string, title: string, abbreviation: string, description: string, language: string, email: list, phone: list, homepage: list, logoUrl: string, address: list, city: string, province: string, country: string, postalCode: string, latitude: float, longitude: float, numPublishedDatasets: int, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, endorsed: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/pending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all possible duplicates
#
# GET /grscicoll/institution/possibleDuplicates
# operationId: listPossibleDuplicates
export def "grscicoll-institution-possible-duplicates listPossibleDuplicates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request: record
]: nothing -> record<generationDate: string, duplicates: list<list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "request" $request "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/institution/possibleDuplicates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all possible duplicates
#
# GET /grscicoll/collection/possibleDuplicates
# operationId: listPossibleDuplicates_1
export def "grscicoll-collection-possible-duplicates listPossibleDuplicates-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request: record
]: nothing -> record<generationDate: string, duplicates: list<list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "request" $request "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/collection/possibleDuplicates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List pending organizations
#
# GET /node/pendingEndorsement
# DEPRECATED
# operationId: getPendingOrganizations2
@deprecated
export def "node-pending-endorsement list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, endorsingNodeKey: string, endorsementApproved: bool, endorsementStatus: string, title: string, abbreviation: string, description: string, language: string, email: list, phone: list, homepage: list, logoUrl: string, address: list, city: string, province: string, country: string, postalCode: string, latitude: float, longitude: float, numPublishedDatasets: int, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, endorsed: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/node/pendingEndorsement" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exports a collection descriptor group.
#
# GET /grscicoll/collection/{collectionKey}/descriptorGroup/{key}/export
# operationId: CollectionDescriptorGroupExport
@deprecated --flag institution
export def "grscicoll-collection-descriptor-group-export CollectionDescriptorGroupExport" [
  collectionKey: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # default: TSV
  --institution: string # A key for the institution. Deprecated: use institutionKey instead. (DEPRECATED, format: uuid)
  --contentType: string # Content type of a GrSciColl collection. Accepts multiple values, for example `contentType=Paleontological&contentType=EarthPlanetary`.
  --preservationType: string # Preservation type of a GrSciColl collection. Accepts multiple values, for example `preservationType=SampleCryopreserved&preservationType=SampleFluidPreserved`.
  --accessionStatus: string # Accession status of a GrSciColl collection. Accepts multiple values, for example `accessionStatus=Institutional&accessionStatus=Project
  --personalCollection: string@bool-completer # Flag for personal GRSciColl collections
  --sourceId: string # sourceId of MasterSourceMetadata
  --qp-source: string@source-completer # Source attribute of MasterSourceMetadata
  --code: string # Code of a GrSciColl institution or collection
  --name: string # Name of a GrSciColl institution or collection
  --alternativeCode: string # Alternative code of a GrSciColl institution or collection
  --contact: string # Filters collections and institutions whose contacts contain the person key specified (format: uuid)
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --country: string@country-completer # Filters by country given as a ISO 639-1 (2 letter) country code.
  --gbifRegion: string@gbifRegion-completer # Filters by a gbif region
  --city: string # Filters by the city of the address. It searches in both the physical and the mailing address.
  --fuzzyName: string # It searches by name fuzzily so the parameter doesn't have to be the exact name
  --active: string@bool-completer # Active status of a GrSciColl institution or collection
  --masterSourceType: string@masterSourceType-completer # The master source type of a GRSciColl institution or collection
  --numberSpecimens: string # Number of specimens. It supports ranges and a `*` can be used as a wildcard
  --displayOnNHCPortal: string@bool-completer # Flag to show this record in the NHC portal
  --replacedBy: string # Key of the entity that replaced another entity (format: uuid)
  --occurrenceCount: string # Count of occurrences linked. It supports ranges and a `*` can be used as a wildcard
  --typeSpecimenCount: string # Count of type specimens linked. It supports ranges and a `*` can be used as a wildcard
  --institutionKey: string # Keys of institutions to filter by (format: uuid)
  --sortBy: string@sortBy-completer # Field to sort the results by. It only supports the fields contained in the enum.
  --sortOrder: string@sortOrder-completer # Sort order to use with the sortBy parameter
  --contactUserId: string # Filter by contact user ID
  --contactEmail: string # Filter by contact email
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "institution" $institution "scalar") (serialize-qp "contentType" $contentType "scalar") (serialize-qp "preservationType" $preservationType "scalar") (serialize-qp "accessionStatus" $accessionStatus "scalar") (serialize-qp "personalCollection" $personalCollection "scalar") (serialize-qp "sourceId" $sourceId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "alternativeCode" $alternativeCode "scalar") (serialize-qp "contact" $contact "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "gbifRegion" $gbifRegion "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "fuzzyName" $fuzzyName "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "masterSourceType" $masterSourceType "scalar") (serialize-qp "numberSpecimens" $numberSpecimens "scalar") (serialize-qp "displayOnNHCPortal" $displayOnNHCPortal "scalar") (serialize-qp "replacedBy" $replacedBy "scalar") (serialize-qp "occurrenceCount" $occurrenceCount "scalar") (serialize-qp "typeSpecimenCount" $typeSpecimenCount "scalar") (serialize-qp "institutionKey" $institutionKey "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortOrder" $sortOrder "scalar") (serialize-qp "contactUserId" $contactUserId "scalar") (serialize-qp "contactEmail" $contactEmail "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/($key)/export" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all datasets with no endpoint
#
# GET /dataset/withNoEndpoint
# operationId: getNoEndpointDatasets
export def "dataset-with-no-endpoint get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, parentDatasetKey: string, duplicateOfDatasetKey: string, installationKey: string, publishingOrganizationKey: string, publishingOrganizationName: string, networkKeys: list, doi: string, version: string, external: bool, numConstituents: int, type: string, subtype: string, shortName: string, title: string, alias: string, abbreviation: string, description: string, language: string, homepage: string, logoUrl: string, citation: record, contactsCitation: list, rights: string, lockedForAutoUpdate: bool, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list, bibliographicCitations: list, curatorialUnits: list, taxonomicCoverages: list, geographicCoverageDescription: string, geographicCoverages: list, temporalCoverages: list, keywordCollections: list, project: record, samplingDescription: record, countryCoverage: list, collections: list, dataDescriptions: list, dataLanguage: string, purpose: string, introduction: string, gettingStarted: string, acknowledgements: string, additionalInfo: string, pubDate: string, maintenanceUpdateFrequency: string, maintenanceDescription: string, license: string, dwca: record, category: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataset/withNoEndpoint" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List non-publishing installations
#
# GET /installation/nonPublishing
# operationId: getNonPublishingInstallations
export def "installation-non-publishing get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, organizationKey: string, type: string, title: string, description: string, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, disabled: bool, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/installation/nonPublishing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List non-publishing organizations
#
# GET /organization/nonPublishing
# operationId: getNonPublishingOrganizations
export def "organization-non-publishing get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: string, endorsingNodeKey: string, endorsementApproved: bool, endorsementStatus: string, title: string, abbreviation: string, description: string, language: string, email: list, phone: list, homepage: list, logoUrl: string, address: list, city: string, province: string, country: string, postalCode: string, latitude: float, longitude: float, numPublishedDatasets: int, createdBy: string, modifiedBy: string, created: string, modified: string, deleted: string, endorsed: string, contacts: list, endpoints: list, machineTags: list, tags: list, identifiers: list, comments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/nonPublishing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all organizations as GeoJson.
#
# GET /organization/geojson
# operationId: listOrganizationAsGeoJson
export def "organization-geojson listOrganizationAsGeoJson" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isEndorsed: string@bool-completer # Whether the organization is endorsed by a node.
  --networkKey: string # Filter for organizations publishing datasets belonging to a network. (format: uuid)
  --numPublishedDatasets: string # Filter by number of published datasets. Examples: '5' (exactly 5), '1,*' (at least 1), '*,10' (at most 10), '5,15' (between 5 and 15).
  --identifierType: string@identifierType-completer # An identifier type for the identifier parameter.
  --identifier: string # An identifier of the type given by the identifierType parameter, for example a DOI or UUID.
  --machineTagNamespace: string # Filters for entities with a machine tag in the specified namespace.
  --machineTagName: string # Filters for entities with a machine tag with the specified name (use in combination with the machineTagNamespace parameter).
  --machineTagValue: string # Filters for entities with a machine tag with the specified value (use in combination with the machineTagNamespace and machineTagName parameters).
  --modified: string # The modified date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `modified=2023-04-01,*`
  --created: string # The created date of the dataset. Accepts ranges and a `*` can be used as a wildcard, e.g. `created=2023-04-01,*`
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<crs: record<type: string, properties: record>, bbox: list<float>, features: table<crs: record, bbox: list, properties: record, geometry: any, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isEndorsed" $isEndorsed "scalar") (serialize-qp "networkKey" $networkKey "scalar") (serialize-qp "numPublishedDatasets" $numPublishedDatasets "scalar") (serialize-qp "identifierType" $identifierType "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "machineTagNamespace" $machineTagNamespace "scalar") (serialize-qp "machineTagName" $machineTagName "scalar") (serialize-qp "machineTagValue" $machineTagValue "scalar") (serialize-qp "modified" $modified "scalar") (serialize-qp "created" $created "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organization/geojson" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the descriptors.
#
# GET /grscicoll/collection/{collectionKey}/descriptorGroup/{key}/descriptor
# operationId: getCollectionDescriptors
export def "grscicoll-collection-descriptor-group-descriptor list" [
  collectionKey: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchRequest: record
  --descriptorGroupKey: int # Key of the descriptor group (format: int64)
  --usageKey: int # Taxon usage key of the descriptor (format: int32)
  --usageName: string # Taxon usage name of the descriptor
  --usageRank: string@usageRank-completer # Taxon usage rank of the descriptor
  --taxonKey: int # Taxon key of the descriptor (format: int32)
  --country: string@country-completer # Country of the descriptor
  --individualCount: string # Individual count of the descriptor. It supports ranges and a `*` can be used as a wildcard
  --identifiedBy: string # Identified by field of the descriptor
  --dateIdentified: string # Date identified field of the descriptor. It supports ranges and a `*` can be used as a wildcard (format: date-time)
  --typeStatus: string # Type status of the descriptor
  --recordedBy: string # RecordedBy of the descriptor
  --discipline: string # Discipline of the descriptor
  --objectClassification: string # Object classification of the descriptor
  --biome: string # Biome of the descriptor
  --biomeType: string # Biome type of the descriptor
  --issues: string # Issues of the descriptor
  --taxonIssues: string # Taxon Issues of the descriptor
  --checklistKey: string # Checklist key to use with the taxonomy filters.
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, descriptorGroupKey: int, usageKey: string, usageName: string, usageRank: string, country: string, individualCount: int, identifiedBy: list, dateIdentified: string, typeStatus: list, recordedBy: list, discipline: string, objectClassification: string, biome: string, biomeType: string, taxonClassification: list, defaultChecklistKey: string, otherTaxonClassifications: record, issues: list, verbatim: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchRequest" $searchRequest "multi") (serialize-qp "descriptorGroupKey" $descriptorGroupKey "scalar") (serialize-qp "usageKey" $usageKey "scalar") (serialize-qp "usageName" $usageName "scalar") (serialize-qp "usageRank" $usageRank "scalar") (serialize-qp "taxonKey" $taxonKey "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "individualCount" $individualCount "scalar") (serialize-qp "identifiedBy" $identifiedBy "scalar") (serialize-qp "dateIdentified" $dateIdentified "scalar") (serialize-qp "typeStatus" $typeStatus "scalar") (serialize-qp "recordedBy" $recordedBy "scalar") (serialize-qp "discipline" $discipline "scalar") (serialize-qp "objectClassification" $objectClassification "scalar") (serialize-qp "biome" $biome "scalar") (serialize-qp "biomeType" $biomeType "scalar") (serialize-qp "issues" $issues "scalar") (serialize-qp "taxonIssues" $taxonIssues "scalar") (serialize-qp "checklistKey" $checklistKey "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/($key)/descriptor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists the descriptor records.
#
# GET /grscicoll/collection/{collectionKey}/descriptorGroup/{descriptorGroupKey}/descriptor/{key}
# operationId: getCollectionDescriptor
export def "grscicoll-collection-descriptor-group-descriptor get" [
  collectionKey: string
  descriptorGroupKey: int
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: int, descriptorGroupKey: int, usageKey: string, usageName: string, usageRank: string, country: string, individualCount: int, identifiedBy: list<string>, dateIdentified: string, typeStatus: list<string>, recordedBy: list<string>, discipline: string, objectClassification: string, biome: string, biomeType: string, taxonClassification: table<key: string, name: string, rank: string, authorship: string>, defaultChecklistKey: string, otherTaxonClassifications: record, issues: list<string>, verbatim: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/($collectionKey)/descriptorGroup/($descriptorGroupKey)/descriptor/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a batch
#
# GET /grscicoll/institution/batch/{key}
# operationId: getBatch
export def "grscicoll-institution-batch get" [
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: int, state: string, entityType: string, errors: list<string>, created: string, createdBy: string, resultFileLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/institution/batch/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get details of a batch
#
# GET /grscicoll/collection/batch/{key}
# operationId: getBatch_1
export def "grscicoll-collection-batch get-by-key" [
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: int, state: string, entityType: string, errors: list<string>, created: string, createdBy: string, resultFileLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/grscicoll/collection/batch/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a file with the result of a batch that includes keys of the new entities created and errors found
#
# GET /grscicoll/institution/batch/{key}/resultFile
# operationId: getBatchResultFile
export def "grscicoll-institution-batch-result-file get" [
  key: int
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
  let full_url = (build-url $base $"/grscicoll/institution/batch/($key)/resultFile")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a file with the result of a batch that includes keys of the new entities created and errors found
#
# GET /grscicoll/collection/batch/{key}/resultFile
# operationId: getBatchResultFile_1
export def "grscicoll-collection-batch-result-file get-by-key" [
  key: int
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
  let full_url = (build-url $base $"/grscicoll/collection/batch/($key)/resultFile")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Process a batch of GRSciColl entities
#
# POST /grscicoll/institution/batch
# operationId: importBatch
export def "grscicoll-institution-batch importBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Format of the files(CSV or TSV)
  --entitiesFile: string # File with the entities of the batch
  --contactsFile: string # File with the contacts associated to the entities
  entitiesFile: string # format: binary
  contactsFile: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "entitiesFile" $entitiesFile "scalar") (serialize-qp "contactsFile" $contactsFile "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/institution/batch" $qp)
  let body = {entitiesFile: $entitiesFile, contactsFile: $contactsFile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Process a batch of GRSciColl entities
#
# POST /grscicoll/collection/batch
# operationId: importBatch_1
export def "grscicoll-collection-batch importBatch-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # Format of the files(CSV or TSV)
  --entitiesFile: string # File with the entities of the batch
  --contactsFile: string # File with the contacts associated to the entities
  entitiesFile: string # format: binary
  contactsFile: string # format: binary
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "entitiesFile" $entitiesFile "scalar") (serialize-qp "contactsFile" $contactsFile "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/collection/batch" $qp)
  let body = {entitiesFile: $entitiesFile, contactsFile: $contactsFile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Lookup collections and institutions
#
# GET /grscicoll/lookup
# operationId: lookupCollectionsInstitutions
export def "grscicoll-lookup lookupCollectionsInstitutions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --datasetKey: string # Institutions and collections can be linked manually to datasets by using occurrence mappings. If the dataset key parameter is set it will be used to try to match an occurrence mapping that contains that dataset. This manual mapping only happens if no exact matches were found (format: uuid)
  --institutionCode: string # The code of an institution
  --institutionId: string # The identifier of an institution
  --ownerInstitutionCode: string # The code of the owner institution. This parameter is only used to detect the cases when the institution and the owner institution are different. If that happens, the match is not considered accepted
  --collectionCode: string # The code of a collection
  --collectionId: string # The identifier of a collection
  --country: string@country-completer # The 2-letter country code (as per ISO-3166-1) of the country.
  --verbose: string@bool-completer # If set, it returns the accepted matches and other alternatives that were also found. Otherwise, it only returns the accepted ones
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --hl: string@bool-completer # Set `hl=true` to highlight terms matching the query when in fulltext search fields. The highlight will be an emphasis tag of class `gbifHl`.
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<institutionMatch: record<matchType: string, status: string, reasons: list<string>, entityMatched: record<key: string, selfLink: string, name: string, code: string, active: bool>>, collectionMatch: record<matchType: string, status: string, reasons: list<string>, entityMatched: record<key: string, selfLink: string, name: string, code: string, active: bool, institutionKey: string, institutionLink: string, institutionCode: string, institutionName: string>>, alternativeMatches: record<institutionMatches: list<record>, collectionMatches: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasetKey" $datasetKey "scalar") (serialize-qp "institutionCode" $institutionCode "scalar") (serialize-qp "institutionId" $institutionId "scalar") (serialize-qp "ownerInstitutionCode" $ownerInstitutionCode "scalar") (serialize-qp "collectionCode" $collectionCode "scalar") (serialize-qp "collectionId" $collectionId "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "verbose" $verbose "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "hl" $hl "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lookup collections and institutions
#
# GET /grscicoll/auditLog
# operationId: lookupCollectionsInstitutions_1
export def "grscicoll-audit-log lookupCollectionsInstitutions-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --traceId: int # Trace ID of a GRSciColl audit log (format: int64)
  --collectionEntityType: string@collectionEntityType-completer # Entity type used in the GRSciColl audit log
  --subEntityType: string # Subentity type used in the GRSciColl audit log: Identifier, MachineTag, Comment, Tag, OccurrenceMapping, Person, ChangeSuggestion
  --operation: string # Operation of a GRSciColl audit log: CREATE, UPDATE, DELETE, LINK, UNLINK, REPLACE, CONVERSION_TO_COLLECTION, APPLY_SUGGESTION, DISCARD_SUGGESTION
  --collectionEntityKey: string # Key of the institution, collection or person being modified (format: uuid)
  --createdBy: string # TODO
  --dateFrom: string # Filters GRSciColl audit logs after a specific date (format yyyy-MM-dd) (format: date-time)
  --dateTo: string # Filters GRSciColl audit logs until a specific date (format yyyy-MM-dd) (format: date-time)
  --subEntityKey: string # TODO
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "traceId" $traceId "scalar") (serialize-qp "collectionEntityType" $collectionEntityType "scalar") (serialize-qp "subEntityType" $subEntityType "scalar") (serialize-qp "operation" $operation "scalar") (serialize-qp "collectionEntityKey" $collectionEntityKey "scalar") (serialize-qp "createdBy" $createdBy "scalar") (serialize-qp "dateFrom" $dateFrom "scalar") (serialize-qp "dateTo" $dateTo "scalar") (serialize-qp "subEntityKey" $subEntityKey "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grscicoll/auditLog" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Make an OAI-PMH request
#
# GET /oai-pmh/registry
# Docs: https://www.openarchives.org/OAI/openarchivesprotocol.html#ProtocolMessages — The Open Archives Initiative Protocol for Metadata Harvesting § Protocol Requests and, Responses.
# operationId: oaipmh
export def "oai-pmh-registry oaipmh" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --params: record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "params" $params "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/oai-pmh/registry" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Checklist dataset metrics
#
# GET /dataset/{key}/metrics
# operationId: getDatasetMetrics
export def "dataset-metrics get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<key: int, datasetKey: string, usagesCount: int, synonymsCount: int, distinctNamesCount: int, nubMatchingCount: int, colMatchingCount: int, nubCoveragePct: int, colCoveragePct: int, countByConstituent: record, countByKingdom: record, countByRank: record, countNamesByLanguage: record, countExtRecordsByExtension: record, countByOrigin: record, countByIssue: record, otherCount: record, created: string, downloaded: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/dataset/($key)/metrics")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
