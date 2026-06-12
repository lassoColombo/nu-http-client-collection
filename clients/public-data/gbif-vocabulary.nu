# Auto-generated client for Vocabulary API vv1
# Source: https://techdocs.gbif.org/openapi/vocabulary.json
# Auth: --token flag or $env.VOCABULARY_API_TOKEN

const BASE_URL = "https://api.gbif.org/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VOCABULARY_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.gbif.org/v1" "https://api.gbif-uat.org/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def locale-completer [] { ["" "aa-ER" "ach-UG" "ae-IR" "af-ZA" "ak-GH" "am-ET" "an-ES" "ar" "ar-BH" "ar-EG" "ar-SA" "ar-YE" "arn-CL" "as-IN" "ast-ES" "av-DA" "ay-BO" "az-AZ" "ba-RU" "bal-BA" "ban-ID" "be-BY" "ber-DZ" "bfo-BF" "bg-BG" "bh-IN" "bi-VU" "bm-ML" "bn-BD" "bn-IN" "bo-BT" "br-FR" "bs-BA" "ca-ES" "ce-CE" "ceb-PH" "ch-GU" "chr-US" "ckb-IR" "co-FR" "cr-NT" "crs-SC" "cs-CZ" "csb-PL" "cv-CU" "cy-GB" "da-DK" "de-AT" "de-BE" "de-CH" "de-DE" "de-LI" "de-LU" "dsb-DE" "dv-MV" "dz-BT" "ee-GH" "el-CY" "el-GR" "en" "en-AR" "en-AU" "en-BZ" "en-CA" "en-CB" "en-CN" "en-DK" "en-GB" "en-HK" "en-ID" "en-IE" "en-IN" "en-JA" "en-JM" "en-MY" "en-NO" "en-NZ" "en-PH" "en-PR" "en-PT" "en-SE" "en-SG" "en-US" "en-ZA" "en-ZW" "eo-UY" "es-AR" "es-BO" "es-CL" "es-CO" "es-CR" "es-DO" "es-EC" "es-ES" "es-GT" "es-HN" "es-MX" "es-NI" "es-PA" "es-PE" "es-PR" "es-PY" "es-SV" "es-US" "es-UY" "es-VE" "et-EE" "eu-ES" "fa-AF" "fa-IR" "ff-ZA" "fi-FI" "fil-PH" "fj-FJ" "fo-FO" "fr-BE" "fr-CA" "fr-CH" "fr-FR" "fr-LU" "fr-QC" "fra-DE" "frp-IT" "fur-IT" "fy-NL" "ga-IE" "gaa-GH" "gd-GB" "gl-ES" "gn-PY" "gu-IN" "gv-IM" "ha-HG" "haw-US" "he-IL" "hi-IN" "hil-PH" "hmn-CN" "ho-PG" "hr-HR" "hsb-DE" "ht-HT" "hu-HU" "hy-AM" "hz-NA" "id-ID" "ig-NG" "ii-CN" "ilo-PH" "io-EN" "is-IS" "it-CH" "it-IT" "iu-NU" "ja-JP" "jbo-EN" "jv-ID" "ka-GE" "kab-KAB" "kdh-KDH" "kg-CG" "kj-AO" "kk-KZ" "kl-GL" "km-KH" "kmr-TR" "kn-IN" "ko-KR" "kok-IN" "ks-IN" "ks-PK" "ku-TR" "kv-KO" "kw-GB" "ky-KG" "la-LA" "lb-LU" "lg-UG" "li-LI" "lij-IT" "ln-CD" "lo-LA" "lol-US" "lt-LT" "luy-KE" "lv-LV" "mai-IN" "me-ME" "mg-MG" "mh-MH" "mi-NZ" "mk-MK" "ml-IN" "mn-MN" "moh-CA" "mos-MOS" "mr-IN" "ms-BN" "ms-MY" "mt-MT" "my-MM" "na-NR" "nb-NO" "nds-DE" "ne-IN" "ne-NP" "ng-NA" "nl-BE" "nl-NL" "nl-SR" "nn-NO" "no-NO" "nr-ZA" "ns-ZA" "ny-MW" "oc-FR" "oj-CA" "om-ET" "or-IN" "os-SE" "pa-IN" "pa-PK" "pam-PH" "pap-PAP" "pcm-NG" "pi-IN" "pl-PL" "ps-AF" "pt-BR" "pt-PT" "qu-PE" "quc-GT" "rm-CH" "rn-BI" "ro-RO" "ru-BY" "ru-MD" "ru-RU" "ru-UA" "rw-RW" "ry-UA" "sa-IN" "sah-SAH" "sat-IN" "sc-IT" "sco-GB" "sd-PK" "se-NO" "sg-CF" "sh-HR" "si-LK" "sk-SK" "sl-SI" "sma-NO" "sn-ZW" "so-SO" "son-ZA" "sq-AL" "sr-CS" "sr-Cyrl-ME" "sr-SP" "ss-ZA" "st-ZA" "su-ID" "sv-FI" "sv-SE" "sw" "sw-KE" "sw-TZ" "syc-SY" "ta-IN" "tay-TW" "te-IN" "tg-TJ" "th-TH" "ti-ER" "tk-TM" "tl-PH" "tlh-AA" "tn-ZA" "tr-CY" "tr-TR" "ts-ZA" "tt-RU" "tw-TW" "ty-PF" "tzl-TZL" "ug-CN" "uk-UA" "ur-IN" "ur-PK" "uz-UZ" "val-ES" "ve-ZA" "vec-IT" "vi-VN" "vls-BE" "wa-BE" "wo-SN" "xh-ZA" "yi-DE" "yo-NG" "zea-ZEA" "zh-CN" "zh-HK" "zh-MO" "zh-SG" "zh-TW" "zu-ZA"] }
def fallbackLocale-completer [] { ["" "aa-ER" "ach-UG" "ae-IR" "af-ZA" "ak-GH" "am-ET" "an-ES" "ar" "ar-BH" "ar-EG" "ar-SA" "ar-YE" "arn-CL" "as-IN" "ast-ES" "av-DA" "ay-BO" "az-AZ" "ba-RU" "bal-BA" "ban-ID" "be-BY" "ber-DZ" "bfo-BF" "bg-BG" "bh-IN" "bi-VU" "bm-ML" "bn-BD" "bn-IN" "bo-BT" "br-FR" "bs-BA" "ca-ES" "ce-CE" "ceb-PH" "ch-GU" "chr-US" "ckb-IR" "co-FR" "cr-NT" "crs-SC" "cs-CZ" "csb-PL" "cv-CU" "cy-GB" "da-DK" "de-AT" "de-BE" "de-CH" "de-DE" "de-LI" "de-LU" "dsb-DE" "dv-MV" "dz-BT" "ee-GH" "el-CY" "el-GR" "en" "en-AR" "en-AU" "en-BZ" "en-CA" "en-CB" "en-CN" "en-DK" "en-GB" "en-HK" "en-ID" "en-IE" "en-IN" "en-JA" "en-JM" "en-MY" "en-NO" "en-NZ" "en-PH" "en-PR" "en-PT" "en-SE" "en-SG" "en-US" "en-ZA" "en-ZW" "eo-UY" "es-AR" "es-BO" "es-CL" "es-CO" "es-CR" "es-DO" "es-EC" "es-ES" "es-GT" "es-HN" "es-MX" "es-NI" "es-PA" "es-PE" "es-PR" "es-PY" "es-SV" "es-US" "es-UY" "es-VE" "et-EE" "eu-ES" "fa-AF" "fa-IR" "ff-ZA" "fi-FI" "fil-PH" "fj-FJ" "fo-FO" "fr-BE" "fr-CA" "fr-CH" "fr-FR" "fr-LU" "fr-QC" "fra-DE" "frp-IT" "fur-IT" "fy-NL" "ga-IE" "gaa-GH" "gd-GB" "gl-ES" "gn-PY" "gu-IN" "gv-IM" "ha-HG" "haw-US" "he-IL" "hi-IN" "hil-PH" "hmn-CN" "ho-PG" "hr-HR" "hsb-DE" "ht-HT" "hu-HU" "hy-AM" "hz-NA" "id-ID" "ig-NG" "ii-CN" "ilo-PH" "io-EN" "is-IS" "it-CH" "it-IT" "iu-NU" "ja-JP" "jbo-EN" "jv-ID" "ka-GE" "kab-KAB" "kdh-KDH" "kg-CG" "kj-AO" "kk-KZ" "kl-GL" "km-KH" "kmr-TR" "kn-IN" "ko-KR" "kok-IN" "ks-IN" "ks-PK" "ku-TR" "kv-KO" "kw-GB" "ky-KG" "la-LA" "lb-LU" "lg-UG" "li-LI" "lij-IT" "ln-CD" "lo-LA" "lol-US" "lt-LT" "luy-KE" "lv-LV" "mai-IN" "me-ME" "mg-MG" "mh-MH" "mi-NZ" "mk-MK" "ml-IN" "mn-MN" "moh-CA" "mos-MOS" "mr-IN" "ms-BN" "ms-MY" "mt-MT" "my-MM" "na-NR" "nb-NO" "nds-DE" "ne-IN" "ne-NP" "ng-NA" "nl-BE" "nl-NL" "nl-SR" "nn-NO" "no-NO" "nr-ZA" "ns-ZA" "ny-MW" "oc-FR" "oj-CA" "om-ET" "or-IN" "os-SE" "pa-IN" "pa-PK" "pam-PH" "pap-PAP" "pcm-NG" "pi-IN" "pl-PL" "ps-AF" "pt-BR" "pt-PT" "qu-PE" "quc-GT" "rm-CH" "rn-BI" "ro-RO" "ru-BY" "ru-MD" "ru-RU" "ru-UA" "rw-RW" "ry-UA" "sa-IN" "sah-SAH" "sat-IN" "sc-IT" "sco-GB" "sd-PK" "se-NO" "sg-CF" "sh-HR" "si-LK" "sk-SK" "sl-SI" "sma-NO" "sn-ZW" "so-SO" "son-ZA" "sq-AL" "sr-CS" "sr-Cyrl-ME" "sr-SP" "ss-ZA" "st-ZA" "su-ID" "sv-FI" "sv-SE" "sw" "sw-KE" "sw-TZ" "syc-SY" "ta-IN" "tay-TW" "te-IN" "tg-TJ" "th-TH" "ti-ER" "tk-TM" "tl-PH" "tlh-AA" "tn-ZA" "tr-CY" "tr-TR" "ts-ZA" "tt-RU" "tw-TW" "ty-PF" "tzl-TZL" "ug-CN" "uk-UA" "ur-IN" "ur-PK" "uz-UZ" "val-ES" "ve-ZA" "vec-IT" "vi-VN" "vls-BE" "wa-BE" "wo-SN" "xh-ZA" "yi-DE" "yo-NG" "zea-ZEA" "zh-CN" "zh-HK" "zh-MO" "zh-SG" "zh-TW" "zu-ZA"] }
def lang-completer [] { ["" "aa-ER" "ach-UG" "ae-IR" "af-ZA" "ak-GH" "am-ET" "an-ES" "ar" "ar-BH" "ar-EG" "ar-SA" "ar-YE" "arn-CL" "as-IN" "ast-ES" "av-DA" "ay-BO" "az-AZ" "ba-RU" "bal-BA" "ban-ID" "be-BY" "ber-DZ" "bfo-BF" "bg-BG" "bh-IN" "bi-VU" "bm-ML" "bn-BD" "bn-IN" "bo-BT" "br-FR" "bs-BA" "ca-ES" "ce-CE" "ceb-PH" "ch-GU" "chr-US" "ckb-IR" "co-FR" "cr-NT" "crs-SC" "cs-CZ" "csb-PL" "cv-CU" "cy-GB" "da-DK" "de-AT" "de-BE" "de-CH" "de-DE" "de-LI" "de-LU" "dsb-DE" "dv-MV" "dz-BT" "ee-GH" "el-CY" "el-GR" "en" "en-AR" "en-AU" "en-BZ" "en-CA" "en-CB" "en-CN" "en-DK" "en-GB" "en-HK" "en-ID" "en-IE" "en-IN" "en-JA" "en-JM" "en-MY" "en-NO" "en-NZ" "en-PH" "en-PR" "en-PT" "en-SE" "en-SG" "en-US" "en-ZA" "en-ZW" "eo-UY" "es-AR" "es-BO" "es-CL" "es-CO" "es-CR" "es-DO" "es-EC" "es-ES" "es-GT" "es-HN" "es-MX" "es-NI" "es-PA" "es-PE" "es-PR" "es-PY" "es-SV" "es-US" "es-UY" "es-VE" "et-EE" "eu-ES" "fa-AF" "fa-IR" "ff-ZA" "fi-FI" "fil-PH" "fj-FJ" "fo-FO" "fr-BE" "fr-CA" "fr-CH" "fr-FR" "fr-LU" "fr-QC" "fra-DE" "frp-IT" "fur-IT" "fy-NL" "ga-IE" "gaa-GH" "gd-GB" "gl-ES" "gn-PY" "gu-IN" "gv-IM" "ha-HG" "haw-US" "he-IL" "hi-IN" "hil-PH" "hmn-CN" "ho-PG" "hr-HR" "hsb-DE" "ht-HT" "hu-HU" "hy-AM" "hz-NA" "id-ID" "ig-NG" "ii-CN" "ilo-PH" "io-EN" "is-IS" "it-CH" "it-IT" "iu-NU" "ja-JP" "jbo-EN" "jv-ID" "ka-GE" "kab-KAB" "kdh-KDH" "kg-CG" "kj-AO" "kk-KZ" "kl-GL" "km-KH" "kmr-TR" "kn-IN" "ko-KR" "kok-IN" "ks-IN" "ks-PK" "ku-TR" "kv-KO" "kw-GB" "ky-KG" "la-LA" "lb-LU" "lg-UG" "li-LI" "lij-IT" "ln-CD" "lo-LA" "lol-US" "lt-LT" "luy-KE" "lv-LV" "mai-IN" "me-ME" "mg-MG" "mh-MH" "mi-NZ" "mk-MK" "ml-IN" "mn-MN" "moh-CA" "mos-MOS" "mr-IN" "ms-BN" "ms-MY" "mt-MT" "my-MM" "na-NR" "nb-NO" "nds-DE" "ne-IN" "ne-NP" "ng-NA" "nl-BE" "nl-NL" "nl-SR" "nn-NO" "no-NO" "nr-ZA" "ns-ZA" "ny-MW" "oc-FR" "oj-CA" "om-ET" "or-IN" "os-SE" "pa-IN" "pa-PK" "pam-PH" "pap-PAP" "pcm-NG" "pi-IN" "pl-PL" "ps-AF" "pt-BR" "pt-PT" "qu-PE" "quc-GT" "rm-CH" "rn-BI" "ro-RO" "ru-BY" "ru-MD" "ru-RU" "ru-UA" "rw-RW" "ry-UA" "sa-IN" "sah-SAH" "sat-IN" "sc-IT" "sco-GB" "sd-PK" "se-NO" "sg-CF" "sh-HR" "si-LK" "sk-SK" "sl-SI" "sma-NO" "sn-ZW" "so-SO" "son-ZA" "sq-AL" "sr-CS" "sr-Cyrl-ME" "sr-SP" "ss-ZA" "st-ZA" "su-ID" "sv-FI" "sv-SE" "sw" "sw-KE" "sw-TZ" "syc-SY" "ta-IN" "tay-TW" "te-IN" "tg-TJ" "th-TH" "ti-ER" "tk-TM" "tl-PH" "tlh-AA" "tn-ZA" "tr-CY" "tr-TR" "ts-ZA" "tt-RU" "tw-TW" "ty-PF" "tzl-TZL" "ug-CN" "uk-UA" "ur-IN" "ur-PK" "uz-UZ" "val-ES" "ve-ZA" "vec-IT" "vi-VN" "vls-BE" "wa-BE" "wo-SN" "xh-ZA" "yi-DE" "yo-NG" "zea-ZEA" "zh-CN" "zh-HK" "zh-MO" "zh-SG" "zh-TW" "zu-ZA"] }
def language-completer [] { ["" "aa-ER" "ach-UG" "ae-IR" "af-ZA" "ak-GH" "am-ET" "an-ES" "ar" "ar-BH" "ar-EG" "ar-SA" "ar-YE" "arn-CL" "as-IN" "ast-ES" "av-DA" "ay-BO" "az-AZ" "ba-RU" "bal-BA" "ban-ID" "be-BY" "ber-DZ" "bfo-BF" "bg-BG" "bh-IN" "bi-VU" "bm-ML" "bn-BD" "bn-IN" "bo-BT" "br-FR" "bs-BA" "ca-ES" "ce-CE" "ceb-PH" "ch-GU" "chr-US" "ckb-IR" "co-FR" "cr-NT" "crs-SC" "cs-CZ" "csb-PL" "cv-CU" "cy-GB" "da-DK" "de-AT" "de-BE" "de-CH" "de-DE" "de-LI" "de-LU" "dsb-DE" "dv-MV" "dz-BT" "ee-GH" "el-CY" "el-GR" "en" "en-AR" "en-AU" "en-BZ" "en-CA" "en-CB" "en-CN" "en-DK" "en-GB" "en-HK" "en-ID" "en-IE" "en-IN" "en-JA" "en-JM" "en-MY" "en-NO" "en-NZ" "en-PH" "en-PR" "en-PT" "en-SE" "en-SG" "en-US" "en-ZA" "en-ZW" "eo-UY" "es-AR" "es-BO" "es-CL" "es-CO" "es-CR" "es-DO" "es-EC" "es-ES" "es-GT" "es-HN" "es-MX" "es-NI" "es-PA" "es-PE" "es-PR" "es-PY" "es-SV" "es-US" "es-UY" "es-VE" "et-EE" "eu-ES" "fa-AF" "fa-IR" "ff-ZA" "fi-FI" "fil-PH" "fj-FJ" "fo-FO" "fr-BE" "fr-CA" "fr-CH" "fr-FR" "fr-LU" "fr-QC" "fra-DE" "frp-IT" "fur-IT" "fy-NL" "ga-IE" "gaa-GH" "gd-GB" "gl-ES" "gn-PY" "gu-IN" "gv-IM" "ha-HG" "haw-US" "he-IL" "hi-IN" "hil-PH" "hmn-CN" "ho-PG" "hr-HR" "hsb-DE" "ht-HT" "hu-HU" "hy-AM" "hz-NA" "id-ID" "ig-NG" "ii-CN" "ilo-PH" "io-EN" "is-IS" "it-CH" "it-IT" "iu-NU" "ja-JP" "jbo-EN" "jv-ID" "ka-GE" "kab-KAB" "kdh-KDH" "kg-CG" "kj-AO" "kk-KZ" "kl-GL" "km-KH" "kmr-TR" "kn-IN" "ko-KR" "kok-IN" "ks-IN" "ks-PK" "ku-TR" "kv-KO" "kw-GB" "ky-KG" "la-LA" "lb-LU" "lg-UG" "li-LI" "lij-IT" "ln-CD" "lo-LA" "lol-US" "lt-LT" "luy-KE" "lv-LV" "mai-IN" "me-ME" "mg-MG" "mh-MH" "mi-NZ" "mk-MK" "ml-IN" "mn-MN" "moh-CA" "mos-MOS" "mr-IN" "ms-BN" "ms-MY" "mt-MT" "my-MM" "na-NR" "nb-NO" "nds-DE" "ne-IN" "ne-NP" "ng-NA" "nl-BE" "nl-NL" "nl-SR" "nn-NO" "no-NO" "nr-ZA" "ns-ZA" "ny-MW" "oc-FR" "oj-CA" "om-ET" "or-IN" "os-SE" "pa-IN" "pa-PK" "pam-PH" "pap-PAP" "pcm-NG" "pi-IN" "pl-PL" "ps-AF" "pt-BR" "pt-PT" "qu-PE" "quc-GT" "rm-CH" "rn-BI" "ro-RO" "ru-BY" "ru-MD" "ru-RU" "ru-UA" "rw-RW" "ry-UA" "sa-IN" "sah-SAH" "sat-IN" "sc-IT" "sco-GB" "sd-PK" "se-NO" "sg-CF" "sh-HR" "si-LK" "sk-SK" "sl-SI" "sma-NO" "sn-ZW" "so-SO" "son-ZA" "sq-AL" "sr-CS" "sr-Cyrl-ME" "sr-SP" "ss-ZA" "st-ZA" "su-ID" "sv-FI" "sv-SE" "sw" "sw-KE" "sw-TZ" "syc-SY" "ta-IN" "tay-TW" "te-IN" "tg-TJ" "th-TH" "ti-ER" "tk-TM" "tl-PH" "tlh-AA" "tn-ZA" "tr-CY" "tr-TR" "ts-ZA" "tt-RU" "tw-TW" "ty-PF" "tzl-TZL" "ug-CN" "uk-UA" "ur-IN" "ur-PK" "uz-UZ" "val-ES" "ve-ZA" "vec-IT" "vi-VN" "vls-BE" "wa-BE" "wo-SN" "xh-ZA" "yi-DE" "yo-NG" "zea-ZEA" "zh-CN" "zh-HK" "zh-MO" "zh-SG" "zh-TW" "zu-ZA"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "vocabularies-concepts listConcepts" } } | get name | first)
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

# List all concepts of the vocabulary
#
# GET /vocabularies/{vocabularyName}/concepts
# operationId: listConcepts
export def "vocabularies-concepts listConcepts" [
  vocabularyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --arg1: record
  --tags: string # Tags of the concept
  --parentKey: int # The key of the parent concept. (format: int64)
  --parent: string # The name of the parent concept.
  --replacedByKey: int # The key of the replacement of the concept. (format: int64)
  --name: string # The name of the concept
  --deprecated: oneof<nothing, bool> # Is the concept deprecated?
  --key: int # The key of the concept. (format: int64)
  --hasParent: oneof<nothing, bool> # Does the concept have parent?
  --hasReplacement: oneof<nothing, bool> # Does the concept have replacement?
  --includeChildrenCount: oneof<nothing, bool> # Should the search results include the count of the children of the concept?
  --includeChildren: oneof<nothing, bool> # Should the search results include the children of the concept?
  --includeParents: oneof<nothing, bool> # Should the search results include the parents of the concept?
  --hiddenLabel: string # The hidden label to filter by
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, name: string, externalDefinitions: list, editorialNotes: list, replacedByKey: int, deprecated: string, deprecatedBy: string, created: string, createdBy: string, modified: string, modifiedBy: string, vocabularyKey: int, definition: list, label: list, parentKey: int, sameAsUris: list, tags: list, vocabularyName: string, parents: list, childrenCount: int, children: list, alternativeLabelsLink: string, hiddenLabelsLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "arg1" $arg1 "multi") (serialize-qp "tags" $tags "scalar") (serialize-qp "parentKey" $parentKey "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "replacedByKey" $replacedByKey "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "deprecated" $deprecated "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "hasParent" $hasParent "scalar") (serialize-qp "hasReplacement" $hasReplacement "scalar") (serialize-qp "includeChildrenCount" $includeChildrenCount "scalar") (serialize-qp "includeChildren" $includeChildren "scalar") (serialize-qp "includeParents" $includeParents "scalar") (serialize-qp "hiddenLabel" $hiddenLabel "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new concept
#
# POST /vocabularies/{vocabularyName}/concepts
# operationId: createConcept
# --definition item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string, modifiedBy?: string, modified?: string}
# --label item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string}
# --tags item shape: {key?: int, name: string, description?: string, color?: string, created?: string, createdBy?: string, modified?: string, modifiedBy?: string}
export def "vocabularies-concepts createConcept" [
  vocabularyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: int # format: int64
  name: string
  --externalDefinitions: list
  --editorialNotes: list
  --replacedByKey: int # format: int64
  --deprecated: string # format: date-time
  --deprecatedBy: string
  --created: string # format: date-time
  --createdBy: string
  --modified: string # format: date-time
  --modifiedBy: string
  vocabularyKey: int # format: int64
  --definition: list # item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string, modifiedBy?: string, modified?: string}
  --label: list # item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string}
  --parentKey: int # format: int64
  --sameAsUris: list
  --tags: list # item shape: {key?: int, name: string, description?: string, color?: string, created?: string, createdBy?: string, modified?: string, modifiedBy?: string}
]: any -> record<key: int, name: string, externalDefinitions: list<string>, editorialNotes: list<string>, replacedByKey: int, deprecated: string, deprecatedBy: string, created: string, createdBy: string, modified: string, modifiedBy: string, vocabularyKey: int, definition: table<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string>, label: table<key: int, language: string, value: string, createdBy: string, created: string>, parentKey: int, sameAsUris: list<string>, tags: table<key: int, name: string, description: string, color: string, created: string, createdBy: string, modified: string, modifiedBy: string>, vocabularyName: string, parents: list<string>, childrenCount: int, children: list<string>, alternativeLabelsLink: string, hiddenLabelsLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts")
  let body = {key: $key, name: $name, externalDefinitions: $externalDefinitions, editorialNotes: $editorialNotes, replacedByKey: $replacedByKey, deprecated: $deprecated, deprecatedBy: $deprecatedBy, created: $created, createdBy: $createdBy, modified: $modified, modifiedBy: $modifiedBy, vocabularyKey: $vocabularyKey, definition: $definition, label: $label, parentKey: $parentKey, sameAsUris: $sameAsUris, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all languages
#
# GET /vocabularyLanguage
# operationId: listLanguages
export def "vocabulary-language listLanguages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vocabularyLanguage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all tags
#
# GET /vocabularyTags
# operationId: listTags
export def "vocabulary-tags listTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Query for full-text search.
  --name: string # The name of the tag. Useful to use with the isInUse parameter.
  --isInUse: oneof<nothing, bool> # If true it searches for tags that are currently being used in at least one concept.
  --arg3: record
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, name: string, description: string, color: string, created: string, createdBy: string, modified: string, modifiedBy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "isInUse" $isInUse "scalar") (serialize-qp "arg3" $arg3 "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vocabularyTags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new tag
#
# POST /vocabularyTags
# operationId: createTag
export def "vocabulary-tags createTag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: int # format: int32
  name: string
  --description: string
  --color: string
  --created: string # format: date-time
  --createdBy: string
  --modified: string # format: date-time
  --modifiedBy: string
]: any -> record<key: int, name: string, description: string, color: string, created: string, createdBy: string, modified: string, modifiedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vocabularyTags")
  let body = {key: $key, name: $name, description: $description, color: $color, created: $created, createdBy: $createdBy, modified: $modified, modifiedBy: $modifiedBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all vocabularies
#
# GET /vocabularies
# operationId: listVocabularies
export def "vocabularies listVocabularies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --arg0: record
  --name: string # The name of the vocabulary.
  --namespace: string # The namespace of the vocabulary.
  --deprecated: oneof<nothing, bool> # Is the vocabulary deprecated?
  --key: int # The key of the vocabulary. (format: int64)
  --hasUnreleasedChanges: oneof<nothing, bool> # Has the vocabulary changes that haven't been released yet?
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, name: string, externalDefinitions: list, editorialNotes: list, replacedByKey: int, deprecated: string, deprecatedBy: string, created: string, createdBy: string, modified: string, modifiedBy: string, namespace: string, definition: list, label: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "arg0" $arg0 "multi") (serialize-qp "name" $name "scalar") (serialize-qp "namespace" $namespace "scalar") (serialize-qp "deprecated" $deprecated "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "hasUnreleasedChanges" $hasUnreleasedChanges "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vocabularies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new vocabulary
#
# POST /vocabularies
# operationId: createVocabulary
# --definition item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string, modifiedBy?: string, modified?: string}
# --label item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string}
export def "vocabularies createVocabulary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: int # format: int64
  name: string
  --externalDefinitions: list
  --editorialNotes: list
  --replacedByKey: int # format: int64
  --deprecated: string # format: date-time
  --deprecatedBy: string
  --created: string # format: date-time
  --createdBy: string
  --modified: string # format: date-time
  --modifiedBy: string
  --namespace: string
  --definition: list # item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string, modifiedBy?: string, modified?: string}
  --label: list # item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string}
]: any -> record<key: int, name: string, externalDefinitions: list<string>, editorialNotes: list<string>, replacedByKey: int, deprecated: string, deprecatedBy: string, created: string, createdBy: string, modified: string, modifiedBy: string, namespace: string, definition: table<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string>, label: table<key: int, language: string, value: string, createdBy: string, created: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vocabularies")
  let body = {key: $key, name: $name, externalDefinitions: $externalDefinitions, editorialNotes: $editorialNotes, replacedByKey: $replacedByKey, deprecated: $deprecated, deprecatedBy: $deprecatedBy, created: $created, createdBy: $createdBy, modified: $modified, modifiedBy: $modifiedBy, namespace: $namespace, definition: $definition, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get details of a single concept
#
# GET /vocabularies/{vocabularyName}/concepts/{name}
# operationId: getConcept
export def "vocabularies-concepts get" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeParents: oneof<nothing, bool>
  --includeChildren: oneof<nothing, bool>
]: nothing -> record<key: int, name: string, externalDefinitions: list<string>, editorialNotes: list<string>, replacedByKey: int, deprecated: string, deprecatedBy: string, created: string, createdBy: string, modified: string, modifiedBy: string, vocabularyKey: int, definition: table<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string>, label: table<key: int, language: string, value: string, createdBy: string, created: string>, parentKey: int, sameAsUris: list<string>, tags: table<key: int, name: string, description: string, color: string, created: string, createdBy: string, modified: string, modifiedBy: string>, vocabularyName: string, parents: list<string>, childrenCount: int, children: list<string>, alternativeLabelsLink: string, hiddenLabelsLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeParents" $includeParents "scalar") (serialize-qp "includeChildren" $includeChildren "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing concept
#
# PUT /vocabularies/{vocabularyName}/concepts/{name}
# operationId: updateConcept
# --definition item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string, modifiedBy?: string, modified?: string}
# --label item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string}
# --tags item shape: {key?: int, name: string, description?: string, color?: string, created?: string, createdBy?: string, modified?: string, modifiedBy?: string}
export def "vocabularies-concepts updateConcept" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: int # format: int64
  --body-name: string
  --externalDefinitions: list
  --editorialNotes: list
  --replacedByKey: int # format: int64
  --deprecated: string # format: date-time
  --deprecatedBy: string
  --created: string # format: date-time
  --createdBy: string
  --modified: string # format: date-time
  --modifiedBy: string
  vocabularyKey: int # format: int64
  --definition: list # item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string, modifiedBy?: string, modified?: string}
  --label: list # item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string}
  --parentKey: int # format: int64
  --sameAsUris: list
  --tags: list # item shape: {key?: int, name: string, description?: string, color?: string, created?: string, createdBy?: string, modified?: string, modifiedBy?: string}
]: any -> record<key: int, name: string, externalDefinitions: list<string>, editorialNotes: list<string>, replacedByKey: int, deprecated: string, deprecatedBy: string, created: string, createdBy: string, modified: string, modifiedBy: string, vocabularyKey: int, definition: table<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string>, label: table<key: int, language: string, value: string, createdBy: string, created: string>, parentKey: int, sameAsUris: list<string>, tags: table<key: int, name: string, description: string, color: string, created: string, createdBy: string, modified: string, modifiedBy: string>, vocabularyName: string, parents: list<string>, childrenCount: int, children: list<string>, alternativeLabelsLink: string, hiddenLabelsLink: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)")
  let body = {key: $key, name: $body_name, externalDefinitions: $externalDefinitions, editorialNotes: $editorialNotes, replacedByKey: $replacedByKey, deprecated: $deprecated, deprecatedBy: $deprecatedBy, created: $created, createdBy: $createdBy, modified: $modified, modifiedBy: $modifiedBy, vocabularyKey: $vocabularyKey, definition: $definition, label: $label, parentKey: $parentKey, sameAsUris: $sameAsUris, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get details of a single tag
#
# GET /vocabularyTags/{name}
# operationId: getTag
export def "vocabulary-tags get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: int, name: string, description: string, color: string, created: string, createdBy: string, modified: string, modifiedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularyTags/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing tag
#
# PUT /vocabularyTags/{name}
# operationId: updateTag
export def "vocabulary-tags updateTag" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: int # format: int32
  --body-name: string
  --description: string
  --color: string
  --created: string # format: date-time
  --createdBy: string
  --modified: string # format: date-time
  --modifiedBy: string
]: any -> record<key: int, name: string, description: string, color: string, created: string, createdBy: string, modified: string, modifiedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularyTags/($name)")
  let body = {key: $key, name: $body_name, description: $description, color: $color, created: $created, createdBy: $createdBy, modified: $modified, modifiedBy: $modifiedBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an existing tag
#
# DELETE /vocabularyTags/{name}
# operationId: deleteTag
export def "vocabulary-tags delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularyTags/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details of a single vocabulary
#
# GET /vocabularies/{name}
# operationId: getVocabulary
export def "vocabularies get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: int, name: string, externalDefinitions: list<string>, editorialNotes: list<string>, replacedByKey: int, deprecated: string, deprecatedBy: string, created: string, createdBy: string, modified: string, modifiedBy: string, namespace: string, definition: table<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string>, label: table<key: int, language: string, value: string, createdBy: string, created: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing vocabulary
#
# PUT /vocabularies/{name}
# operationId: updateVocabulary
# --definition item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string, modifiedBy?: string, modified?: string}
# --label item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string}
export def "vocabularies updateVocabulary" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: int # format: int64
  --body-name: string
  --externalDefinitions: list
  --editorialNotes: list
  --replacedByKey: int # format: int64
  --deprecated: string # format: date-time
  --deprecatedBy: string
  --created: string # format: date-time
  --createdBy: string
  --modified: string # format: date-time
  --modifiedBy: string
  --namespace: string
  --definition: list # item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string, modifiedBy?: string, modified?: string}
  --label: list # item shape: {key?: int, language: "ach-UG"|"aa-ER"|"af-ZA"|"ak-GH"|"tw-TW"|"sq-AL"|"am-ET"|"ar"|"ar-BH"|"ar-EG"|"ar-SA"|"ar-YE"|"an-ES"|"hy-AM"|"frp-IT"|"as-IN"|"ast-ES"|"tay-TW"|"av-DA"|"ae-IR"|"ay-BO"|"az-AZ"|"ban-ID"|"bal-BA"|"bm-ML"|"ba-RU"|"eu-ES"|"be-BY"|"bn-BD"|"bn-IN"|"ber-DZ"|"bh-IN"|"bfo-BF"|"bi-VU"|"bs-BA"|"br-FR"|"bg-BG"|"my-MM"|"ca-ES"|"ceb-PH"|"ch-GU"|"ce-CE"|"chr-US"|"ny-MW"|"zh-CN"|"zh-TW"|"zh-HK"|"zh-MO"|"zh-SG"|"cv-CU"|"kw-GB"|"co-FR"|"cr-NT"|"hr-HR"|"cs-CZ"|"da-DK"|"fa-AF"|"dv-MV"|"nl-NL"|"nl-BE"|"nl-SR"|"dz-BT"|"en"|"en-AR"|"en-AU"|"en-BZ"|"en-CA"|"en-CB"|"en-CN"|"en-DK"|"en-HK"|"en-IN"|"en-ID"|"en-IE"|"en-JM"|"en-JA"|"en-MY"|"en-NZ"|"en-NO"|"en-PH"|"en-PR"|"en-SG"|"en-ZA"|"en-SE"|"en-GB"|"en-US"|"en-ZW"|"eo-UY"|"et-EE"|"ee-GH"|"fo-FO"|"fj-FJ"|"fil-PH"|"fi-FI"|"vls-BE"|"fra-DE"|"fr-FR"|"fr-BE"|"fr-CA"|"fr-LU"|"fr-QC"|"fr-CH"|"fy-NL"|"fur-IT"|"ff-ZA"|"gaa-GH"|"gl-ES"|"ka-GE"|"de-DE"|"de-AT"|"de-BE"|"de-LI"|"de-LU"|"de-CH"|"el-GR"|"el-CY"|"kl-GL"|"gn-PY"|"gu-IN"|"ht-HT"|"ha-HG"|"haw-US"|"he-IL"|"hz-NA"|"hil-PH"|"hi-IN"|"ho-PG"|"hmn-CN"|"hu-HU"|"is-IS"|"io-EN"|"ig-NG"|"ilo-PH"|"id-ID"|"iu-NU"|"ga-IE"|"it-IT"|"it-CH"|"ja-JP"|"jv-ID"|"quc-GT"|"kab-KAB"|"kn-IN"|"pam-PH"|"ks-IN"|"ks-PK"|"csb-PL"|"kk-KZ"|"km-KH"|"rw-RW"|"tlh-AA"|"kv-KO"|"kg-CG"|"kok-IN"|"ko-KR"|"ku-TR"|"kmr-TR"|"kj-AO"|"ky-KG"|"lo-LA"|"la-LA"|"lv-LV"|"lij-IT"|"li-LI"|"ln-CD"|"lt-LT"|"jbo-EN"|"lol-US"|"nds-DE"|"dsb-DE"|"lg-UG"|"luy-KE"|"lb-LU"|"mk-MK"|"mai-IN"|"mg-MG"|"ms-MY"|"ms-BN"|"ml-IN"|"mt-MT"|"gv-IM"|"mi-NZ"|"arn-CL"|"mr-IN"|"mh-MH"|"moh-CA"|"mn-MN"|"sr-Cyrl-ME"|"me-ME"|"mos-MOS"|"na-NR"|"ng-NA"|"ne-NP"|"ne-IN"|"pcm-NG"|"se-NO"|"ns-ZA"|"no-NO"|"nb-NO"|"nn-NO"|"oc-FR"|"or-IN"|"oj-CA"|"om-ET"|"os-SE"|"pi-IN"|"pap-PAP"|"ps-AF"|"fa-IR"|"en-PT"|"pl-PL"|"pt-PT"|"pt-BR"|"pa-IN"|"pa-PK"|"qu-PE"|"ro-RO"|"rm-CH"|"rn-BI"|"ru-RU"|"ru-BY"|"ru-MD"|"ru-UA"|"ry-UA"|"sah-SAH"|"sg-CF"|"sa-IN"|"sat-IN"|"sc-IT"|"sco-GB"|"gd-GB"|"sr-SP"|"sr-CS"|"sh-HR"|"crs-SC"|"sn-ZW"|"ii-CN"|"sd-PK"|"si-LK"|"sk-SK"|"sl-SI"|"so-SO"|"son-ZA"|"ckb-IR"|"nr-ZA"|"sma-NO"|"st-ZA"|"es-ES"|"es-AR"|"es-BO"|"es-CL"|"es-CO"|"es-CR"|"es-DO"|"es-EC"|"es-SV"|"es-GT"|"es-HN"|"es-MX"|"es-NI"|"es-PA"|"es-PY"|"es-PE"|"es-PR"|"es-US"|"es-UY"|"es-VE"|"su-ID"|"sw"|"sw-KE"|"sw-TZ"|"ss-ZA"|"sv-SE"|"sv-FI"|"syc-SY"|"tl-PH"|"ty-PF"|"tg-TJ"|"tzl-TZL"|"ta-IN"|"tt-RU"|"te-IN"|"kdh-KDH"|"th-TH"|"bo-BT"|"ti-ER"|"ts-ZA"|"tn-ZA"|"tr-TR"|"tr-CY"|"tk-TM"|"uk-UA"|"hsb-DE"|"ur-IN"|"ur-PK"|"ug-CN"|"uz-UZ"|"val-ES"|"ve-ZA"|"vec-IT"|"vi-VN"|"wa-BE"|"cy-GB"|"wo-SN"|"xh-ZA"|"yi-DE"|"yo-NG"|"zea-ZEA"|"zu-ZA"|"", value: string, createdBy?: string, created?: string}
]: any -> record<key: int, name: string, externalDefinitions: list<string>, editorialNotes: list<string>, replacedByKey: int, deprecated: string, deprecatedBy: string, created: string, createdBy: string, modified: string, modifiedBy: string, namespace: string, definition: table<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string>, label: table<key: int, language: string, value: string, createdBy: string, created: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($name)")
  let body = {key: $key, name: $body_name, externalDefinitions: $externalDefinitions, editorialNotes: $editorialNotes, replacedByKey: $replacedByKey, deprecated: $deprecated, deprecatedBy: $deprecatedBy, created: $created, createdBy: $createdBy, modified: $modified, modifiedBy: $modifiedBy, namespace: $namespace, definition: $definition, label: $label} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Suggest concepts.
#
# GET /vocabularies/{vocabularyName}/concepts/suggest
# operationId: suggestConcepts
export def "vocabularies-concepts-suggest suggestConcepts" [
  vocabularyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --locale: string@locale-completer # Locale to filter by
  --fallbackLocale: string@fallbackLocale-completer # The locale to fall back when there are no results in the locale specified.
  --limit: int # The number of results returned. The maximum allowed is 20. (format: int32)
]: nothing -> table<name: string, label: string, labelLanguage: string, parents: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "fallbackLocale" $fallbackLocale "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Suggest vocabularies.
#
# GET /vocabularies/suggest
# operationId: suggestVocabularies
export def "vocabularies-suggest suggestVocabularies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --locale: string@locale-completer # Locale to filter by
  --fallbackLocale: string@fallbackLocale-completer # The locale to fall back when there are no results in the locale specified.
  --limit: int # The number of results returned. The maximum allowed is 20. (format: int32)
]: nothing -> table<name: string, label: string, labelLanguage: string, parents: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "fallbackLocale" $fallbackLocale "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/vocabularies/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deprecate an existing concept
#
# PUT /vocabularies/{vocabularyName}/concepts/{name}/deprecate
# operationId: deprecateConcept
export def "vocabularies-concepts-deprecate deprecateConcept" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --replacementKey: int # format: int64
  --deprecateChildren: oneof<nothing, bool>
  --deprecatedBy: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/deprecate")
  let body = {replacementKey: $replacementKey, deprecateChildren: $deprecateChildren, deprecatedBy: $deprecatedBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restores a deprecated concept
#
# DELETE /vocabularies/{vocabularyName}/concepts/{name}/deprecate
# operationId: restoreDeprecatedConcept
export def "vocabularies-concepts-deprecate restoreDeprecatedConcept" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --restoreDeprecatedChildren: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "restoreDeprecatedChildren" $restoreDeprecatedChildren "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/deprecate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deprecate an existing vocabulary
#
# PUT /vocabularies/{name}/deprecate
# operationId: deprecateVocabulary
export def "vocabularies-deprecate deprecateVocabulary" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --replacementKey: int # format: int64
  --deprecateConcepts: oneof<nothing, bool>
  --deprecatedBy: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($name)/deprecate")
  let body = {replacementKey: $replacementKey, deprecateConcepts: $deprecateConcepts, deprecatedBy: $deprecatedBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restores a deprecated vocabulary
#
# DELETE /vocabularies/{name}/deprecate
# operationId: restoreDeprecatedVocabulary
export def "vocabularies-deprecate restoreDeprecatedVocabulary" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --restoreDeprecatedConcepts: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "restoreDeprecatedConcepts" $restoreDeprecatedConcepts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($name)/deprecate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Exports a vocabulary
#
# GET /vocabularies/{name}/export
# operationId: exportVocabulary
export def "vocabularies-export exportVocabulary" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($name)/export")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the definitions of the concept
#
# GET /vocabularies/{vocabularyName}/concepts/{name}/definition
# operationId: listConceptDefinitions
export def "vocabularies-concepts-definition listConceptDefinitions" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # Languages to filter by
]: nothing -> table<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/definition" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a definition to a concept
#
# POST /vocabularies/{vocabularyName}/concepts/{name}/definition
# operationId: addConceptDefinition
export def "vocabularies-concepts-definition addConceptDefinition" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: int # format: int64
  language: string@language-completer
  value: string
  --createdBy: string
  --created: string # format: date-time
  --modifiedBy: string
  --modified: string # format: date-time
]: any -> record<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/definition")
  let body = {key: $key, language: $language, value: $value, createdBy: $createdBy, created: $created, modifiedBy: $modifiedBy, modified: $modified} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the definition of a concept
#
# GET /vocabularies/{vocabularyName}/concepts/{name}/definition/{key}
# operationId: getConceptDefinition
export def "vocabularies-concepts-definition get" [
  vocabularyName: string
  name: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/definition/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a definition
#
# PUT /vocabularies/{vocabularyName}/concepts/{name}/definition/{key}
# operationId: updateConceptDefinition
export def "vocabularies-concepts-definition updateConceptDefinition" [
  vocabularyName: string
  name: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-key: int # format: int64
  language: string@language-completer
  value: string
  --createdBy: string
  --created: string # format: date-time
  --modifiedBy: string
  --modified: string # format: date-time
]: any -> record<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/definition/($key)")
  let body = {key: $body_key, language: $language, value: $value, createdBy: $createdBy, created: $created, modifiedBy: $modifiedBy, modified: $modified} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a definition from a concept
#
# DELETE /vocabularies/{vocabularyName}/concepts/{name}/definition/{key}
# operationId: deleteConceptDefinition
export def "vocabularies-concepts-definition delete" [
  vocabularyName: string
  name: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/definition/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the releases of a vocabulary
#
# GET /vocabularies/{name}/releases
# operationId: listVocabularyReleases
export def "vocabularies-releases listVocabularyReleases" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # The version to filter by. To get the latest one you can specify 'latest'.
  --arg2: string
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, vocabularyKey: int, version: string, exportUrl: string, created: string, createdBy: string, comment: string, exportFile: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar") (serialize-qp "arg2" $arg2 "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($name)/releases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details of a single vocabulary release
#
# GET /vocabularies/{name}/releases/{version}
# operationId: getRelease
export def "vocabularies-releases get" [
  name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: int, vocabularyKey: int, version: string, exportUrl: string, created: string, createdBy: string, comment: string, exportFile: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($name)/releases/($version)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the exported release
#
# GET /vocabularies/{name}/releases/{version}/export
# operationId: getReleaseExport
export def "vocabularies-releases-export get" [
  name: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($name)/releases/($version)/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the tags of the concept
#
# GET /vocabularies/{vocabularyName}/concepts/{name}/tags
# operationId: listConceptTags
export def "vocabularies-concepts-tags listConceptTags" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<key: int, name: string, description: string, color: string, created: string, createdBy: string, modified: string, modifiedBy: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Links a tag to a concept
#
# PUT /vocabularies/{vocabularyName}/concepts/{name}/tags
# operationId: addConceptTag
export def "vocabularies-concepts-tags addConceptTag" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tagName: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/tags")
  let body = {tagName: $tagName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all the definitions of the vocabulary
#
# GET /vocabularies/{name}/definition
# operationId: listVocabularyDefinitions
export def "vocabularies-definition listVocabularyDefinitions" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # Languages to filter by
]: nothing -> table<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($name)/definition" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a definition to a vocabulary
#
# POST /vocabularies/{name}/definition
# operationId: addVocabularyDefinition
export def "vocabularies-definition addVocabularyDefinition" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: int # format: int64
  language: string@language-completer
  value: string
  --createdBy: string
  --created: string # format: date-time
  --modifiedBy: string
  --modified: string # format: date-time
]: any -> record<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($name)/definition")
  let body = {key: $key, language: $language, value: $value, createdBy: $createdBy, created: $created, modifiedBy: $modifiedBy, modified: $modified} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the definition of a vocabulary
#
# GET /vocabularies/{name}/definition/{key}
# operationId: getVocabularyDefinition
export def "vocabularies-definition get" [
  name: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($name)/definition/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a definition
#
# PUT /vocabularies/{name}/definition/{key}
# operationId: updateVocabularyDefinition
export def "vocabularies-definition updateVocabularyDefinition" [
  name: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-key: int # format: int64
  language: string@language-completer
  value: string
  --createdBy: string
  --created: string # format: date-time
  --modifiedBy: string
  --modified: string # format: date-time
]: any -> record<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($name)/definition/($key)")
  let body = {key: $body_key, language: $language, value: $value, createdBy: $createdBy, created: $created, modifiedBy: $modifiedBy, modified: $modified} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a definition from a vocabulary
#
# DELETE /vocabularies/{name}/definition/{key}
# operationId: deleteVocabularyDefinition
export def "vocabularies-definition delete" [
  name: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($name)/definition/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unlinks a tag from a concept
#
# DELETE /vocabularies/{vocabularyName}/concepts/{name}/tags/{tagName}
# operationId: removeConceptTag
export def "vocabularies-concepts-tags removeConceptTag" [
  vocabularyName: string
  name: string
  tagName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/tags/($tagName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the labels of the concept
#
# GET /vocabularies/{vocabularyName}/concepts/{name}/label
# operationId: listConceptLabels
export def "vocabularies-concepts-label listConceptLabels" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # Languages to filter by
]: nothing -> table<key: int, language: string, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/label" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a label to a concept
#
# POST /vocabularies/{vocabularyName}/concepts/{name}/label
# operationId: addConceptLabel
export def "vocabularies-concepts-label addConceptLabel" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: int # format: int64
  language: string@language-completer
  value: string
  --createdBy: string
  --created: string # format: date-time
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/label")
  let body = {key: $key, language: $language, value: $value, createdBy: $createdBy, created: $created} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all the labels of the vocabulary
#
# GET /vocabularies/{name}/label
# operationId: listVocabularyLabels
export def "vocabularies-label listVocabularyLabels" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # Languages to filter by
]: nothing -> table<key: int, language: string, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($name)/label" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a label to a vocabulary
#
# POST /vocabularies/{name}/label
# operationId: addVocabularyLabel
export def "vocabularies-label addVocabularyLabel" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: int # format: int64
  language: string@language-completer
  value: string
  --createdBy: string
  --created: string # format: date-time
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($name)/label")
  let body = {key: $key, language: $language, value: $value, createdBy: $createdBy, created: $created} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a label from a concept
#
# DELETE /vocabularies/{vocabularyName}/concepts/{name}/label/{key}
# operationId: deleteConceptLabel
export def "vocabularies-concepts-label delete" [
  vocabularyName: string
  name: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/label/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a label from a vocabulary
#
# DELETE /vocabularies/{name}/label/{key}
# operationId: deleteVocabularyLabel
export def "vocabularies-label delete" [
  name: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($name)/label/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the alternative labels of the concept
#
# GET /vocabularies/{vocabularyName}/concepts/{name}/alternativeLabels
# operationId: listConceptAlternativeLabels
export def "vocabularies-concepts-alternative-labels listConceptAlternativeLabels" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # Languages to filter by
  --arg3: record
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, language: string, value: string, createdBy: string, created: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "arg3" $arg3 "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/alternativeLabels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds an alternative label to a concept
#
# POST /vocabularies/{vocabularyName}/concepts/{name}/alternativeLabels
# operationId: addConceptAlternativeLabel
export def "vocabularies-concepts-alternative-labels addConceptAlternativeLabel" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: int # format: int64
  language: string@language-completer
  value: string
  --createdBy: string
  --created: string # format: date-time
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/alternativeLabels")
  let body = {key: $key, language: $language, value: $value, createdBy: $createdBy, created: $created} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an alternative label from a concept
#
# DELETE /vocabularies/{vocabularyName}/concepts/{name}/alternativeLabels/{key}
# operationId: deleteConceptAlternativeLabel
export def "vocabularies-concepts-alternative-labels delete" [
  vocabularyName: string
  name: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/alternativeLabels/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the hidden labels of the concept
#
# GET /vocabularies/{vocabularyName}/concepts/{name}/hiddenLabels
# operationId: listConceptHiddenLabels
export def "vocabularies-concepts-hidden-labels listConceptHiddenLabels" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search term to filter hidden labels
  --arg3: record
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, value: string, createdBy: string, created: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "arg3" $arg3 "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/hiddenLabels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a hidden label to a concept
#
# POST /vocabularies/{vocabularyName}/concepts/{name}/hiddenLabels
# operationId: addConceptHiddenLabel
export def "vocabularies-concepts-hidden-labels addConceptHiddenLabel" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: int # format: int64
  value: string
  --createdBy: string
  --created: string # format: date-time
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/hiddenLabels")
  let body = {key: $key, value: $value, createdBy: $createdBy, created: $created} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a hidden label from a concept
#
# DELETE /vocabularies/{vocabularyName}/concepts/{name}/hiddenLabels/{key}
# operationId: deleteConceptHiddenLabel
export def "vocabularies-concepts-hidden-labels delete" [
  vocabularyName: string
  name: string
  key: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/($name)/hiddenLabels/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all concepts of the vocabulary from its latest release
#
# GET /vocabularies/{vocabularyName}/concepts/latestRelease
# operationId: listConceptsFromLatestRelease
export def "vocabularies-concepts-latest-release listConceptsFromLatestRelease" [
  vocabularyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --arg1: record
  --parentKey: int # The key of the parent concept. (format: int64)
  --parent: string # The name of the parent concept.
  --replacedByKey: int # The key of the replacement of the concept. (format: int64)
  --name: string # The name of the concept
  --deprecated: oneof<nothing, bool> # Is the concept deprecated?
  --key: int # The key of the concept. (format: int64)
  --hasParent: oneof<nothing, bool> # Does the concept have parent?
  --hasReplacement: oneof<nothing, bool> # Does the concept have replacement?
  --includeChildrenCount: oneof<nothing, bool> # Should the search results include the count of the children of the concept?
  --includeChildren: oneof<nothing, bool> # Should the search results include the children of the concept?
  --includeParents: oneof<nothing, bool> # Should the search results include the parents of the concept?
  --hiddenLabel: string # The hidden label to filter by
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, name: string, externalDefinitions: list, editorialNotes: list, replacedByKey: int, deprecated: string, deprecatedBy: string, created: string, createdBy: string, modified: string, modifiedBy: string, vocabularyKey: int, definition: list, label: list, parentKey: int, sameAsUris: list, tags: list, vocabularyName: string, parents: list, childrenCount: int, children: list, alternativeLabelsLink: string, hiddenLabelsLink: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "arg1" $arg1 "multi") (serialize-qp "parentKey" $parentKey "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "replacedByKey" $replacedByKey "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "deprecated" $deprecated "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "hasParent" $hasParent "scalar") (serialize-qp "hasReplacement" $hasReplacement "scalar") (serialize-qp "includeChildrenCount" $includeChildrenCount "scalar") (serialize-qp "includeChildren" $includeChildren "scalar") (serialize-qp "includeParents" $includeParents "scalar") (serialize-qp "hiddenLabel" $hiddenLabel "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/latestRelease" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Suggest concepts from the latest release of the vocabulary.
#
# GET /vocabularies/{vocabularyName}/concepts/latestRelease/suggest
# operationId: suggestConceptsFromLatestRelease
export def "vocabularies-concepts-latest-release-suggest suggestConceptsFromLatestRelease" [
  vocabularyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Simple full text search parameter. The value for this parameter can be a simple word or a phrase. Wildcards are not supported
  --locale: string@locale-completer # Locale to filter by
  --fallbackLocale: string@fallbackLocale-completer # The locale to fall back when there are no results in the locale specified.
  --limit: int # The number of results returned. The maximum allowed is 20. (format: int32)
]: nothing -> table<name: string, label: string, labelLanguage: string, parents: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "fallbackLocale" $fallbackLocale "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/latestRelease/suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details of a single concept from the latest release of the vocabulary
#
# GET /vocabularies/{vocabularyName}/concepts/latestRelease/{name}
# operationId: getConceptFromLatestRelease
export def "vocabularies-concepts-latest-release get" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeParents: oneof<nothing, bool>
  --includeChildren: oneof<nothing, bool>
]: nothing -> record<key: int, name: string, externalDefinitions: list<string>, editorialNotes: list<string>, replacedByKey: int, deprecated: string, deprecatedBy: string, created: string, createdBy: string, modified: string, modifiedBy: string, vocabularyKey: int, definition: table<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string>, label: table<key: int, language: string, value: string, createdBy: string, created: string>, parentKey: int, sameAsUris: list<string>, tags: table<key: int, name: string, description: string, color: string, created: string, createdBy: string, modified: string, modifiedBy: string>, vocabularyName: string, parents: list<string>, childrenCount: int, children: list<string>, alternativeLabelsLink: string, hiddenLabelsLink: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeParents" $includeParents "scalar") (serialize-qp "includeChildren" $includeChildren "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/latestRelease/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the definitions of the concept from the latest release of the vocabulary
#
# GET /vocabularies/{vocabularyName}/concepts/latestRelease/{name}/definition
# operationId: listConceptDefinitionsFromLatestRelease
export def "vocabularies-concepts-latest-release-definition listConceptDefinitionsFromLatestRelease" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # Languages to filter by
]: nothing -> table<key: int, language: string, value: string, createdBy: string, created: string, modifiedBy: string, modified: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/latestRelease/($name)/definition" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the labels of the concept from the latest release of the vocabulary
#
# GET /vocabularies/{vocabularyName}/concepts/latestRelease/{name}/label
# operationId: listConceptLabelsFromLatestRelease
export def "vocabularies-concepts-latest-release-label listConceptLabelsFromLatestRelease" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # Languages to filter by
]: nothing -> table<key: int, language: string, value: string, createdBy: string, created: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/latestRelease/($name)/label" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the alternative labels of the concept from the latest release of the vocabulary
#
# GET /vocabularies/{vocabularyName}/concepts/latestRelease/{name}/alternativeLabels
# operationId: listConceptAlternativeLabelsFromLatestRelease
export def "vocabularies-concepts-latest-release-alternative-labels listConceptAlternativeLabelsFromLatestRelease" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # Languages to filter by
  --arg3: record
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, language: string, value: string, createdBy: string, created: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "arg3" $arg3 "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/latestRelease/($name)/alternativeLabels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the hidden labels of the concept from the latest release of the vocabulary
#
# GET /vocabularies/{vocabularyName}/concepts/latestRelease/{name}/hiddenLabels
# operationId: listConceptHiddenLabelsFromLatestRelease
export def "vocabularies-concepts-latest-release-hidden-labels listConceptHiddenLabelsFromLatestRelease" [
  vocabularyName: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string
  --arg3: record
  --limit: int # Controls the number of results in the page. Using too high a value will be overwritten with the default maximum threshold, depending on the service. Sensible defaults are used so this may be omitted. (format: int32)
  --offset: int # Determines the offset for the search results. A limit of 20 and offset of 40 will get the third page of 20 results. Some services have a maximum offset. (format: int32)
]: nothing -> record<endOfRecords: bool, count: int, results: table<key: int, value: string, createdBy: string, created: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "arg3" $arg3 "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/latestRelease/($name)/hiddenLabels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Concept lookup
#
# GET /vocabularies/{vocabularyName}/concepts/lookup
# operationId: lookup
export def "vocabularies-concepts-lookup lookup" [
  vocabularyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Value to do the lookup against to
  --lang: string@lang-completer # Lang to discriminate the lookup
]: nothing -> table<conceptName: string, conceptLink: string, matchedLabel: string, matchedLabelLanguage: string, matchedAlternativeLabel: string, matchedAlternativeLabelLanguage: string, matchedHiddenLabel: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Concept lookup in the latest release
#
# GET /vocabularies/{vocabularyName}/concepts/latestRelease/lookup
# operationId: lookupLatestRelease
export def "vocabularies-concepts-latest-release-lookup lookupLatestRelease" [
  vocabularyName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Value to do the lookup against to
  --lang: string@lang-completer # Lang to discriminate the lookup
]: nothing -> table<conceptName: string, conceptLink: string, matchedLabel: string, matchedLabelLanguage: string, matchedAlternativeLabel: string, matchedAlternativeLabelLanguage: string, matchedHiddenLabel: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/vocabularies/($vocabularyName)/concepts/latestRelease/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
