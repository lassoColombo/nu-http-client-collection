# Auto-generated client for Orders v2.32
# Source: https://raw.githubusercontent.com/paypal/paypal-rest-api-specifications/main/openapi/checkout_orders_v2.json
# Auth: --token flag or $env.PAYPAL_TOKEN

const BASE_URL = "https://api-m.paypal.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAYPAL_TOKEN | default "" }
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

def base-url-completer [] { ["https://api-m.paypal.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def intent-completer [] { ["AUTHORIZE" "CAPTURE"] }
def carrier-completer [] { ["3PE_EXPRESS" "99MINUTOS" "A1POST" "A2B_BA" "AAA_COOPER" "ABCUSTOM" "ABCUSTOM_SFTP" "ABXEXPRESS_MY" "ACILOGISTIX" "ACOMMERCE" "ACSWORLDWIDE" "ACS_GR" "ACTIVOS24_API" "ADERONLINE" "ADICIONAL" "ADICIONAL_PT" "ADS" "ADSONE" "ADUIEPYLE" "AEROFLASH" "AERONET" "AEX" "AFLLOG_FTP" "AGEDISS_SFTP" "AGILITY" "AGSYSTEMS" "AIRMEE_WEBHOOK" "AIRSPEED" "AIRTERRA" "AIR_21" "AIR_CANADA" "AIR_CANADA_GLOBAL" "AITWORLDWIDE_API" "AITWORLDWIDE_SFTP" "ALFATREX" "ALLEGRO" "ALLIEDEXPRESS" "ALLIED_EXPRESS_FTP" "ALLJOY" "ALPHAFAST" "ALWAYS_EXPRESS" "AMAZON" "AMAZON_EMAIL_PUSH" "AMAZON_FBA_SWISHIP" "AMAZON_FBA_SWISHIP_IN" "AMAZON_ORDER" "AMAZON_SHIP_MCF" "AMAZON_UK_API" "AMSTAN" "AMS_GRP" "ANDREANI" "ANDREANI_API" "ANICAM_BOX" "ANJUN" "ANSERX" "ANTERAJA" "AN_POST" "AOYUE" "AO_COURIER" "AO_DEUTSCHLAND" "APC_OVERNIGHT" "APC_OVERNIGHT_CONNUM" "APG" "APRISAEXPRESS" "AQUILINE" "ARAMEX" "ARAMEX_API" "ARAMEX_AU" "ARASKARGO" "ARCO_SPEDIZIONI" "ARE_EMIRATES_POST" "ARGENTS_WEBHOOK" "ARG_OCA" "ARIHANTCOURIER" "ARK_LOGISTICS" "ASE" "ASENDIA" "ASENDIA_DE" "ASENDIA_HK" "ASENDIA_UK" "ASENDIA_US" "ASIGNA" "ASSOCIATED_COURIERS" "ASYADEXPRESS" "ATA" "ATSHEALTHCARE" "ATSHEALTHCARE_REFERENCE" "AUEXPRESS" "AUPOST_CN" "AUSTRALIA_POST_API" "AUSTRIAN_POST_EXPRESS" "AUS_STARTRACK" "AU_AUSTRIAN_POST" "AU_AU_POST" "AVERITT" "AWEST" "AXLEHIRE" "AXLEHIRE_FTP" "BARSAN" "BEL_BELGIUM_POST" "BEL_DHL" "BEL_RS" "BERT" "BESTTRANSPORT_SFTP" "BESTWAYPARCEL" "BETTERTRUCKS" "BE_BPOST" "BE_KIALA" "BG_BULGARIAN_POST" "BH_POSTA" "BH_WORLDWIDE" "BIGSMART" "BIOCAIR_FTP" "BIRDSYSTEM" "BJSHOMEDELIVERY" "BJSHOMEDELIVERY_FTP" "BLINKLASTMILE" "BLR_BELPOST" "BLUECARE" "BLUEDART" "BLUEDART_API" "BLUESTAR" "BLUEX" "BNEED" "BOLLORE_LOGISTICS" "BOMBINOEXP" "BOMI" "BOND" "BONDSCOURIERS" "BORDEREXPRESS" "BOX_BERRY" "BPOST_API" "BPOST_INT" "BRAUNSEXPRESS" "BRA_CORREIOS" "BRING" "BRINGER" "BROUWER_TRANSPORT" "BRT_IT" "BRT_IT_API" "BRT_IT_PARCELID" "BRT_IT_SENDER_REF" "BUDBEE_WEBHOOK" "BUFFALO" "BURD" "BUYLOGIC" "B_TWO_C_EUROPE" "CACESA" "CAE_DELIVERS" "CAGO" "CAINIAO" "CANPAR" "CAPITAL" "CARIBOU" "CARRIERS" "CARRY_FLAP" "CASTLEPARCELS" "CA_CANADA_POST" "CBL_LOGISTICA" "CBL_LOGISTICA_API" "CDEK" "CDEK_TR" "CDLDELIVERS" "CELERITAS" "CELLO_SQUARE" "CESKAPOSTA_API" "CESKA_CZ" "CEVA" "CEVA_TRACKING" "CFL_LOGISTICS" "CGS_EXPRESS" "CHAMPION_LOGISTICS" "CHAZKI" "CHIENVENTURE_WEBHOOK" "CHILEXPRESS" "CHITCHATS" "CHOIR_EXP" "CHROBINSON" "CHRONOPOST_FR" "CHUKOU1" "CIRROTRACK" "CITY56_WEBHOOK" "CITYLINK_MY" "CJPACKET" "CJ_CENTURY" "CJ_GLS" "CJ_HK_INTERNATIONAL" "CJ_INT_MY" "CJ_KR" "CJ_LOGISTICS" "CJ_PHILIPPINES" "CLEVY_LINKS" "CLE_LOGISTICS" "CLICKLINK_SFTP" "CLOUDWISH_ASIA" "CNDEXPRESS" "CNEXPS" "CNWANGTONG" "CN_17POST" "CN_BESTEXPRESS" "CN_BOXC" "CN_CHINA_POST_EMS" "CN_DPEX" "CN_EQUICK" "CN_EXPRESS" "CN_JCEX" "CN_LOGISTICS" "CN_PAYPAL_PACKAGE" "CN_POST56" "CN_SF_EXPRESS" "CN_STO" "CN_WEDO" "CN_WISHPOST" "CN_YUNDA" "COLIS_PRIVE" "COLLECTCO" "COLLECTPLUS" "COLLIVERY" "COM1EXPRESS" "COMET_TECH" "CONCISE" "CONCISE_API" "CONCISE_WEBHOOK" "CONTINENTAL" "CON_WAY" "COORDINADORA" "COORDINADORA_API" "COPA_COURIER" "COPE" "CORETRAILS" "CORPORATECOURIERS_WEBHOOK" "CORREOSEXPRESS_API" "CORREOS_DE_ESPANA" "CORREOS_DE_MEXICO" "CORREOS_ES" "CORREOS_EXPRESS" "CORREO_UY" "COSTMETICSNOW" "COURANT_PLUS" "COURANT_PLUS_API" "COUREX" "COURIERPLUS" "COURIERS_PLEASE" "COURIER_POST" "CPACKET" "CPEX" "CRLEXPRESS" "CROSHOT" "CROSSFLIGHT" "CRYOPDP_FTP" "CSE" "CTC_EXPRESS" "CUBYN" "CUCKOOEXPRESS" "CUSTOMCO_API" "CYPRUS_POST_CYP" "DACHSER" "DACHSER_WEB" "DAESHIN" "DAIGLOBALTRACK" "DAIICHI" "DAJIN" "DANNIAO" "DANSKE_FRAGT" "DAO365" "DASHLINK" "DAWN_WING" "DAYROSS" "DAYTON_FREIGHT" "DBSCHENKER_API" "DBSCHENKER_B2B" "DBSCHENKER_ICELAND" "DBSCHENKER_SE" "DBSCHENKER_SV" "DDEXPRESS" "DEALERSEND" "DELCART_IN" "DELIVERE" "DELIVERR_SFTP" "DELIVERYONTIME" "DELIVERYOURPARCEL_ZA" "DELIVER_IT" "DELNEXT" "DELTEC_DE" "DELTEC_UK" "DEMANDSHIP" "DESCARTES" "DESIGNERTRANSPORT_WEBHOOK" "DESTINY" "DEUTSCHE_DE" "DEXPRESS_WEBHOOK" "DEX_I" "DE_DHL" "DE_DHL_EXPRESS" "DE_DPD_DELISTRACK" "DHL" "DHLPARCEL_UK" "DHL_ACTIVE_TRACING" "DHL_API" "DHL_AT" "DHL_AU" "DHL_BENELUX" "DHL_ECOMERCE_ASA" "DHL_ECOMMERCE_GC" "DHL_ES" "DHL_ES_SFTP" "DHL_FR" "DHL_FREIGHT" "DHL_GLOBAL_FORWARDING_API" "DHL_GLOBAL_MAIL" "DHL_GLOBAL_MAIL_API" "DHL_GLOBAL_MAIL_ASIA" "DHL_GT_API" "DHL_HK" "DHL_IT" "DHL_JP" "DHL_PARCEL_ES" "DHL_PARCEL_NL" "DHL_PARCEL_RU" "DHL_PA_API" "DHL_PIECEID" "DHL_PL" "DHL_REFERENCE_API" "DHL_REFR" "DHL_SFTP" "DHL_SG" "DHL_SUPPLYCHAIN_ID" "DHL_SUPPLYCHAIN_IN" "DHL_SUPPLY_CHAIN" "DHL_SUPPLY_CHAIN_AU" "DHL_UK" "DIALOGO_LOGISTICA" "DIALOGO_LOGISTICA_API" "DIAMOND_EUROGISTICS" "DICOM" "DIDADI" "DIMERCO" "DIRECTCOURIERS" "DIRECTFREIGHT_AU_REF" "DIRECTLOG" "DIRECTPARCELS" "DIREX" "DIRMENSAJERIA" "DISCOUNTPOST" "DKSH" "DMFGROUP" "DMM_NETWORK" "DMS_MATRIX" "DNJ_EXPRESS" "DOBROPOST" "DOMINO" "DOORA" "DOORDASH_WEBHOOK" "DOTZOT" "DPD" "DPD_AT" "DPD_AT_SFTP" "DPD_CH_SFTP" "DPD_DE" "DPD_DELISTRACK" "DPD_FR" "DPD_FR_REFERENCE" "DPD_HGRY" "DPD_HK" "DPD_IR" "DPD_LOCAL" "DPD_LOCAL_REF" "DPD_NL" "DPD_POLAND" "DPD_PRT" "DPD_RO" "DPD_RU" "DPD_RU_API" "DPD_SK_SFTP" "DPD_UK" "DPD_UK_SFTP" "DPEX" "DPE_EXPRESS" "DPE_SOUTH_AFRC" "DSV" "DSV_REFERENCE" "DTDC_AU" "DTDC_EXPRESS" "DTDC_IN" "DTD_EXPR" "DX" "DX_B2B_CONNUM" "DX_FREIGHT" "DX_SFTP" "DYLT" "DYNALOGIC" "EARLYBIRD" "EASTWESTCOURIER_FTP" "EASYPARCEL" "EASYROUTES" "EASY_MAIL" "ECARGO" "ECEXPRESS" "ECHO" "ECMS" "ECOFREIGHT" "ECOSCOOTING" "ECOURIER" "ECOUTIER" "ECPARCEL" "EC_CN" "EDF_FTP" "EFEX" "EFS" "EFWNOW_API" "EKART" "ELIAN_POST" "ELITE_CO" "ELOGISTICA" "ELTA_GR" "EMEGA" "EMPS_CN" "EMS" "EMS_CN" "ENDEAVOUR_DELIVERY" "ENERGOLOGISTIC" "ENSENDA" "ENVIALIA_REFERENCE" "EPARCEL_KR" "EPST_GLBL" "EP_BOX" "ESDEX" "ESHIPPER" "ESHIPPING" "ESP_ASM" "ESP_ENVIALIA" "ESP_MRW" "ESP_NACEX" "ESP_PACKLINK" "ESP_REDUR" "ETOMARS" "ETONAS" "ETOTAL" "ETOWER" "ETS_EXPRESS" "EURODIS" "EUROPAKET_API" "EU_FLEET_SOLUTIONS" "EWE" "EXELOT_FTP" "EXPEDITORS" "EXPEDITORS_API_REF" "EXPRESSONE" "EXPRESSONE_SV" "EXPRESSSALE" "FAIRSENDEN_API" "FAN" "FARGOOD" "FAR_INTERNATIONAL" "FASTBOX" "FASTDESPATCH" "FASTRACK" "FASTRK_SERV" "FASTSHIP" "FASTTRACK" "FASTWAY_AU" "FASTWAY_IR" "FASTWAY_NZ" "FASTWAY_UK" "FASTWAY_US" "FASTWAY_ZA" "FAXECARGO" "FDSEXPRESS" "FEDEX" "FEDEX_API" "FEDEX_CHINA" "FEDEX_CROSSBORDER" "FEDEX_FR" "FEDEX_INTL_MLSERV" "FEDEX_POLAND" "FEDEX_UK" "FERCAM_IT" "FETCHR" "FETCHR_WEBHOOK" "FIEGE" "FIEGE_NL" "FINMILE" "FIRSTMILE" "FIRST_LOGISITCS" "FIRST_LOGISTICS_API" "FITZMARK_API" "FLASHEXPRESS" "FLASHEXPRESS_WEBHOOK" "FLEETOPTICSINC" "FLIGHTLG" "FLIPXP" "FLOSHIP" "FLYTEXPRESS" "FMX" "FNF_ZA" "FONSEN" "FORRUN" "FORWARDAIR" "FOURKITES" "FOUR_PX_EXPRESS" "FRAGILEPAK_SFTP" "FRANCO" "FREIGHTQUOTE" "FRETERAPIDO" "FRONTDOORCORP" "FR_COLIS" "FR_COLISSIMO" "FR_EXAPAQ" "FR_MONDIAL" "FUJEXP" "FULFILLA" "FULFILLME" "FURDECO" "FXTRAN" "GAC" "GANGBAO" "GATI_KWE_API" "GBA" "GBS_BROKER" "GB_APC" "GB_ARROW" "GB_NORSK" "GB_PANTHER" "GB_TUFFNELLS" "GCX" "GDPHARM" "GEIS" "GEL_EXPRESS" "GEMWORLDWIDE" "GENERAL_OVERNIGHT" "GENIKI_GR" "GEODIS" "GEODIS_API" "GEODIS_ESPACE" "GESWL" "GIAO_HANG" "GIO_ECOURIER" "GIO_ECOURIER_API" "GIO_EXPRESS" "GLOBALTRANZ" "GLOBAL_ABF" "GLOBAL_ESTES" "GLOBAL_EXPRESS" "GLOBAL_IPARCEL" "GLOBAL_TNT" "GLOBAVEND" "GLOBEGISTICS" "GLOVO" "GLS" "GLS_CROTIA" "GLS_CZ" "GLS_DE" "GLS_ES" "GLS_FR" "GLS_HUN" "GLS_IT" "GLS_ITALY" "GLS_ITALY_FTP" "GLS_ROMANIA" "GLS_SLOV" "GLS_SLOVEN" "GLS_SPAIN" "GLS_SPAIN_API" "GLS_US" "GOBOLT" "GODEPENDABLE" "GOFO_EXPRESS" "GOGLOBALPOST" "GOJEK" "GOLS" "GOPEOPLE" "GORUSH" "GPOST" "GPS" "GRAB_WEBHOOK" "GRANDSLAMEXPRESS" "GREYHOUND" "GRUPO" "GSI_EXPRESS" "GSO" "GTAGSM" "GWLOGIS_API" "GW_WORLD" "HANJIN" "HAPPY2POINT" "HCT_LOGISTICS" "HDB" "HDB_BOX" "HELLENIC_POST" "HELLMANN" "HELTHJEM" "HELTHJEM_API" "HEPPNER" "HEPPNER_FR" "HEPSIJET" "HERMES" "HERMESWORLD_UK" "HERMES_2MANN_HANDLING" "HERMES_DE" "HERMES_DE_FTP" "HERMES_IT" "HERMES_UK_SFTP" "HEROEXPRESS" "HFD" "HH_EXP" "HIPSHIPPER" "HKD" "HK_POST" "HK_RPX" "HK_TGX" "HOLISOL" "HOMELOGISTICS" "HOMERUNNER" "HOME_DELIVERY_SOLUTIONS" "HOTSIN_CARGO" "HOUNDEXPRESS" "HRPARCEL" "HRV_HRVATSKA" "HSDEXPRESS" "HSM_GLOBAL" "HUAHAN_EXPRESS" "HUANTONG" "HUBBED" "HUNTER_EXPRESS" "HUNTER_EXPRESS_SFTP" "HUODULL" "HX_EXPRESS" "IBEONE" "IBVENTURE_WEBHOOK" "ICSCOURIER" "ICUMULUS" "IDEXPRESS" "IDEXPRESS_ID" "IDN_JNE" "IDN_POS" "IDS_LOGISTICS" "ILYANGLOGIS" "IMEXGLOBALSOLUTIONS" "IMILE_API" "IML" "IMX" "INDIA_POST" "INDIA_POST_INT" "INDOPAKET" "IND_DELHIVERY" "IND_DELIVREE" "IND_ECOM" "IND_FIRSTFLIGHT" "IND_GATI" "IND_GOJAVAS" "IND_SAFEEXPRESS" "INEXPOST" "INNTRALOG_SFTP" "INPOST_IT" "INPOST_PACZKOMATY" "INPOST_UK" "INSTABOX_WEBHOOK" "INTEGRA2_FTP" "INTELCOM_CA" "INTELIPOST" "INTEL_VALLEY" "INTERNATIONAL_SEUR_API" "INTERPARCEL_AU" "INTERPARCEL_NZ" "INTERPARCEL_UK" "INTERSMARTTRANS" "INTEXPRESS" "INTEX_DE" "INTIME_FTP" "IORDIRECT" "ISRAEL_POST" "ISR_POST_DOMESTIC" "ITHINKLOGISTICS" "IT_DHL_ECOMMERCE" "IT_NEXIVE" "IT_POSTE_ITALIA" "IVOY_WEBHOOK" "I_DIKA" "JADLOG" "JANCO" "JANIO" "JAVIT" "JAWAR" "JD_EXPRESS" "JD_WORLDWIDE" "JERSEYPOST_ATLAS" "JERSEY_POST" "JETSHIP_MY" "JET_SHIP" "JINDOUYUN" "JINSUNG" "JITSU" "JNE_API" "JOCOM" "JOOM_LOGIS" "JOYINGBOX" "JOYING_BOX" "JPN_JAPAN_POST" "JS_EXPRESS" "JTCARGO" "JTEXPRESS" "JTEXPRESS_PH" "JTEXPRESS_SG_API" "JTEXPRESS_VN" "JT_LOGISTICS" "JUMPPOINT" "JUSDASR" "JX" "J_NET" "K1_EXPRESS" "KANGAROO_MY" "KARGOMKOLAY" "KEC" "KEDAEX" "KERRYTJ" "KERRYTTC_VN" "KERRY_ECOMMERCE" "KERRY_EXPRESS_TH_WEBHOOK" "KERRY_EXPRESS_TW_API" "KGMHUB" "KHM_CAMBODIA_POST" "KINISI" "KNG" "KOLAY_GELSIN" "KOMON_EXPRESS" "KPOST" "KRONOS" "KRONOS_WEBHOOK" "KR_KOREA_POST" "KUEHNE" "KURASI" "KWE_GLOBAL" "KWT" "KYUNGDONG_PARCEL" "KY_EXPRESS" "LALAMOVE" "LALAMOVE_API" "LANDMARK_GLOBAL" "LANDMARK_GLOBAL_REFERENCE" "LAND_LOGISTICS" "LATVIJAS_PASTS" "LA_POSTE_SUIVI" "LBCEXPRESS_API" "LBCEXPRESS_FTP" "LCTBR_API" "LEADER" "LEGION_EXPRESS" "LEMAN" "LEXSHIP" "LHT_EXPRESS" "LICCARDI_EXPRESS" "LIEFERGRUN" "LIEFERY" "LINE" "LINKBRIDGE" "LION_PARCEL" "LIVRAPIDE" "LMPARCEL" "LOCUS_WEBHOOK" "LOGGI" "LOGINEXT_WEBHOOK" "LOGISTERS" "LOGISTICSWORLDWIDE_HK" "LOGISTICSWORLDWIDE_KR" "LOGISTICSWORLDWIDE_MY" "LOGISTIKA" "LOGISTYX_TRANSGROUP" "LOGISYSTEMS_SFTP" "LOGOIX" "LOGWIN_LOGISTICS" "LOGYSTO" "LONESTAR" "LOOMIS_EXPRESS" "LOTTE" "LTIANEXP" "LTL" "LTU_LIETUVOS" "LUWJISTIK" "M3LOGISTICS" "MADROOEX" "MAERGO" "MAGYAR_HU" "MAGYAR_POSTA_API" "MAILAMERICAS" "MAILPLUS_JPN" "MAIL_BOX_ETC" "MAIL_PLUS" "MAINFREIGHT" "MAINWAY" "MALCA_AMIT" "MALCA_AMIT_API" "MARKEN" "MATDESPATCH" "MATKAHUOLTO" "MAZET" "MBW" "MEDAFRICA" "MEDLINE" "MEEST" "MEGASAVE" "MENSAJEROSURBANOS_API" "METROSCG" "MEX_ESTAFETA" "MEX_REDPACK" "MEX_SENDA" "MGLOBAL" "MHI" "MIKROPAKKET" "MIKROPAKKET_BE" "MILKMAN" "MISUMI_CN" "MNG_KARGO" "MNX" "MOBI_BR" "MONDIALRELAY_ES" "MONDIALRELAY_FR" "MONDIAL_BE" "MOOVA" "MOOVIN" "MORE_LINK" "MORNINGLOBAL" "MORNING_EXPRESS" "MOTHERSHIP_API" "MOVIANTO" "MRW" "MRW_FTP" "MUDITA" "MULTIENTREGAPANAMA" "MWD" "MWD_API" "MXE" "MX_CARGO" "MYDYNALOGIC" "MYHERMES" "MYHERMES_UK_API" "MYSENDLE_API" "MYS_AIRPAK" "MYS_EMS" "MYS_GDEX" "MYS_MYPOST_ONLINE" "MYS_MYS_POST" "MYS_SKYNET" "M_XPRESS" "NACEX" "NACEX_ES" "NACEX_SPAIN_REFERENCE" "NAEKO_FTP" "NANJINGWOYUAN" "NAQEL_EXPRESS" "NATIONAL_SAMEDAY" "NATIONEX" "NATIONWIDE_MY" "NAVLUNGO" "NETLOGIXGROUP" "NEWAY" "NEWEGGEXPRESS" "NEWGISTICS" "NEWGISTICSAPI" "NEWZEALAND_COURIERS" "NHANS_SOLUTIONS" "NIGHTLINE_UK" "NIMBUSPOST" "NIM_EXPRESS" "NINJAVAN_MY" "NINJAVAN_SG" "NINJAVAN_THAI" "NINJAVAN_VN" "NINJAVAN_WB" "NIPOST_NG" "NIPPON_EXPRESS" "NIPPON_EXPRESS_FTP" "NLD_DHL" "NLD_GLS" "NLD_POSTNL" "NMTRANSFER" "NORTHLINE" "NOVA_POSHTA" "NOVA_POSHTA_API" "NOVA_POSHTA_INT" "NOVOFARMA_WEBHOOK" "NOWLOG_API" "NOX_NACHTEXPRESS" "NOX_NIGHT_TIME_EXPRESS" "NTL" "NTLOGISTICS_VN" "NYTLOGISTICS" "NZ_NZ_POST" "OAKH" "OBIBOX" "OCS" "OCS_WORLDWIDE" "OHI_WEBHOOK" "OKAYPARCEL" "OMLOGISTICS_API" "OMNIPARCEL" "OMNIRPS_WEBHOOK" "OMNIVA" "ONECLICK" "ONEWORLDEXPRESS" "ONTRAC" "OPTIMACOURIER" "ORANGECONNEX" "ORANGE_DS" "OSM_WORLDWIDE" "OSM_WORLDWIDE_SFTP" "OTHER" "OTSCHILE" "OVERSE_EXP" "OZEPARTS_SHIPPING" "P2P" "P2P_TRC" "PAACK_WEBHOOK" "PACKALY" "PACKETA" "PACKFLEET" "PACKS" "PACK_MAN" "PACK_UP" "PADTF" "PAGO" "PAIKEDA" "PAKAJO" "PALEXPRESS" "PALLETWAYS" "PALLET_NETWORK" "PANDAGO_API" "PANDION" "PANDU" "PANTHER_ORDER_NUMBER" "PANTHER_REFERENCE" "PANTHER_REFERENCE_API" "PAN_ASIA" "PAPA_WEBHOOK" "PAPERFLY" "PAPER_EXPRESS" "PAQUETEXPRESS" "PARCEL2GO" "PARCELFORCE" "PARCELINKLOGISTICS" "PARCELJET" "PARCELLED_IN" "PARCELONE" "PARCELPAL_WEBHOOK" "PARCELPOINT" "PARCELPOST_SG" "PARCELRIGHT" "PARCELSTARS" "PARCELSTARS_WEBHOOK" "PARCEL_2_POST" "PARCLL" "PARKNPARCEL" "PASSPORTSHIPPING" "PATHEON" "PAYO" "PB_USPSFLATS_FTP" "PCFCORP" "PCHOME_API" "PFCEXPRESS" "PFLOGISTICS" "PGEON_API" "PHL_JAMEXPRESS" "PHSE_API" "PICKRR" "PICKUP" "PICKUPP_MYS" "PICKUPP_SGP" "PICKUPP_VNM" "PIDGE" "PIGGYSHIP" "PILOT_FREIGHT" "PIL_LOGISTICS" "PITNEY_BOWES" "PITTOHIO" "PIXSELL" "PLANZER" "PLUS_LOG_UK" "PLYCONGROUP" "PL_POCZTA_POLSKA" "POLARSPEED" "PONY_EXPRESS" "POSTAPLUS" "POSTA_PLUS" "POSTA_RO" "POSTA_UKR" "POSTEN_NORGE" "POSTE_ITALIANE_PACCOCELERE" "POSTI" "POSTI_API" "POSTNL_INTERNATIONAL" "POSTNL_INTL_3S" "POSTNL_INT_3_S" "POSTNORD_LOGISTICS" "POSTNORD_LOGISTICS_DK" "POSTONE" "POSTPLUS" "POSTUR_IS" "POST_SERBIA" "POST_SLOVENIA" "PPL" "PRESIDENT_TRANS" "PRESSIODE" "PRIMAMULTICIPTA" "PROCARRIER" "PRODUCTCAREGROUP_SFTP" "PROFESSIONAL_COURIERS" "PROMEDDELIVERY" "PRT_CHRONOPOST" "PRT_CTT" "PRT_INT_SEUR" "PRT_SEUR" "PTS" "PTT_KARGO" "PTT_POST" "PUROLATOR" "PUROLATOR_INTERNATIONAL" "QINTL_API" "QTRACK" "QUALITYPOST" "QUANTIUM" "QUIQUP" "QWINTRY" "RABEN_GROUP" "RAF_PH" "RAIDEREX" "RAM" "RANSA_WEBHOOK" "RCL" "REDJEPAKKETJE" "REIMAGINEDELIVERY" "RELAISCOLIS" "RELAY" "RHENUS_GROUP" "RHENUS_ITALY" "RHENUS_UK" "RHENUS_UK_API" "RICHMOM" "RINCOS" "RIXONHK_API" "RL_US" "ROADBULL" "ROADRUNNER_FREIGHT" "ROCHE_INTERNAL_SFTP" "ROCKET_PARCEL" "RODONAVES" "ROUTIFIC_WEBHOOK" "ROYAL_MAIL" "ROYAL_MAIL_FTP" "RPD2MAN" "RPM" "RPX" "RPXLOGISTICS" "RPX_ID" "RRDONNELLEY" "RUSSIAN_POST" "RUSTON" "RZYEXPRESS" "SAEE" "SAGAWA" "SAGAWA_API" "SAIA_FREIGHT" "SAILPOST" "SAP_EXPRESS" "SAU_SAUDI_POST" "SBERLOGISTICS_RU" "SCOTTY" "SCUDEX_EXPRESS" "SDA_IT" "SDH_SCM" "SECRETLAB_WEBHOOK" "SEFL" "SEINO" "SEINO_API" "SEINO_SUPER_EXPRESS" "SEKOLOGISTICS" "SEKO_SFTP" "SENDEO_KARGO" "SENDING" "SENDIT" "SENDLE" "SENDPARCEL" "SENDY" "SERVIENTREGA" "SERVIP_WEBHOOK" "SETEL" "SEUR_ES" "SEUR_SP_API" "SFB2C" "SFCSERVICE" "SFC_LOGISTICS" "SFPLUS_WEBHOOK" "SFYDEXPRESS" "SF_EX" "SF_EXPRESS_CN" "SGLINK" "SGT_IT" "SG_DETRACK" "SG_QXPRESS" "SG_SG_POST" "SG_SPEEDPOST" "SHADOWFAX" "SHENZHEN" "SHERPA" "SHIPA" "SHIPBOB" "SHIPENTEGRA" "SHIPGLOBAL_US" "SHIPPIE" "SHIPPIFY" "SHIPPIT" "SHIPROCKET" "SHIPTER" "SHIPTOR" "SHIPX" "SHIPXPRES" "SHIP_GATE" "SHIP_IT_ASIA" "SHOPFANS" "SHOPLINE" "SHOPOLIVE" "SHOWL" "SHREENANDANCOURIER" "SHREETIRUPATI" "SHREE_ANJANI_COURIER" "SHREE_MARUTI" "SHUNBANG_EXPRESS" "SHYPLITE" "SIC_TELIWAY" "SIMPLETIRE_WEBHOOK" "SIMPLYPOST" "SIMSGLOBAL" "SINOTRANS" "SINO_SCM" "SIN_GLBL" "SIODEMKA" "SKYBOX" "SKYEXPRESS_INTERNATIONAL" "SKYKING" "SKYNET_UAE" "SKYNET_UK" "SKYNET_WORLDWIDE" "SKYNET_ZA" "SKY_POSTAL" "SK_POSTA" "SMARTCAT" "SMARTKARGO" "SMG_EXPRESS" "SMOOTH" "SMSA_EXPRESS" "SMSA_EXPRESS_WEBHOOK" "SMTL" "SNTGLOBAL_API" "SOLISTICA_API" "SONICTL" "SOUTH_AFRICAN_POST_OFFICE" "SPANISH_SEUR_FTP" "SPECTRAN" "SPEDISCI" "SPEEDAF" "SPEEDCOURIERS_GR" "SPEEDEE" "SPEEDEX" "SPEEDEXCOURIER" "SPEEDX" "SPEEDY" "SPOTON" "SPREETAIL_API" "SPRING_GDS" "SPRINT_PACK" "SPX" "SPX_TH" "SRE_KOREA" "SRT_TRANSPORT" "STALLIONEXPRESS" "STARKEN" "STARLINKS_API" "STARTRACK" "STARTRACK_EXPRESS" "STAR_TRACK_EXPRESS" "STAR_TRACK_NEXT_FLIGHT" "STAR_TRACK_WEBHOOK" "STATOVERNIGHT" "STEPFORWARDFS" "STONE3PL" "STRECK_TRANSPORT" "SUPERPACKLINE" "SURAT_KARGO" "SUTTON" "SWE" "SWE_POSTNORD" "SWIFTX" "SWISHIP" "SWISHIP_DE" "SWISHIP_JP" "SWISS_POST" "SWISS_POST_FTP" "SWISS_UNIVERSAL_EXPRESS" "SYPOST" "SZENDEX" "TAMERGROUP_WEBHOOK" "TANET" "TAQBIN_HK" "TAQBIN_MY" "TAQBIN_SG" "TAQBIN_SG_API" "TARRIVE" "TAZMANIAN_FREIGHT" "TCK_EXPRESS" "TCS" "TCS_API" "TDN" "TEAMEXPRESSLLC" "TECOR" "TELEPORT_WEBHOOK" "TESTING_COURIER" "TESTING_COURIER_WEBHOOK" "TFM" "TFORCE_FINALMILE" "TFORCE_FREIGHT" "THABIT_LOGISTICS" "THAIPARCELS" "THA_DYNAMIC_LOGISTICS" "THA_KERRY" "THA_THAILAND_POST" "THECOURIERGUY" "THEDELIVERYGROUP" "THENILE_WEBHOOK" "THIJS_NL" "THUNDEREXPRESS" "TH_CJ" "TIGFREIGHT" "TIKI_ID" "TIPSA" "TIPSA_API" "TIPSA_REF" "TNT" "TNT_AU" "TNT_CLICK_IT" "TNT_CN" "TNT_DE" "TNT_ES" "TNT_FR" "TNT_FR_REFERENCE" "TNT_IT" "TNT_JP" "TNT_NL" "TNT_PL" "TNT_REFR" "TNT_UK" "TNT_UK_REFR" "TOLL" "TOLL_IPEC" "TOLL_NZ" "TOLL_PRIORITY" "TOLL_WEBHOOK" "TOLOS" "TOMYDOOR" "TONAMI_FTP" "TOPHATTEREXPRESS" "TOPTRANS" "TOPYOU" "TOTAL_EXPRESS" "TOTAL_EXPRESS_API" "TOURLINE" "TOURLINE_REFERENCE" "TRACKON" "TRANS2U" "TRANSMISSION" "TRANSPAK" "TRANSVIRTUAL" "TRANS_KARGO" "TRUMPCARD" "TRUNKRS" "TRUNKRS_WEBHOOK" "TRUSK" "TUFFNELLS_REFERENCE" "TUSKLOGISTICS" "TWO_GO" "TW_TAIWAN_POST" "TYP" "T_CAT" "T_CAT_API" "UBER_WEBHOOK" "UBI_LOGISTICS" "UCS" "UC_EXPRE" "UDS" "UK_UK_MAIL" "UK_XDP" "UK_YODEL" "UNIUNI" "UPARCEL" "UPS" "UPS_API" "UPS_CHECKER" "UPS_FREIGHT" "UPS_MAIL_INNOVATIONS" "UPS_REFERENCE" "UP_EXPRESS" "URBIFY" "URB_IT" "URGENT_CARGUS" "USF_REDDAWAY" "USHIP" "USPS" "USPS_API" "USPS_WEBHOOK" "US_APC" "US_LASERSHIP" "US_OLD_DOMINION" "US_YRC" "U_ENVIOS" "VALUE_WEBHOOK" "VAMOX" "VDTRACK" "VEHO" "VENIPAK" "VESYL" "VIAEUROPE" "VIAXPRESS" "VIA_EXPRESS" "VIRTRANSPORT" "VIRTRANSPORT_SFTP" "VIWO" "VNM_VIETNAM_POST" "VNM_VIETTELPOST" "VNPOST_API" "VNPOST_EMS" "VOX" "VTFE" "WAHANA_ID" "WANBEXPRESS" "WATKINS_SHEPARD" "WEASHIP" "WEEE" "WELIVERY" "WEPOST" "WESHIP" "WESHIP_API" "WESTBANK_COURIER" "WESTGATE_GL" "WEWORLDEXPRESS" "WHISTL" "WHISTL_SFTP" "WINESHIPPING" "WINESHIPPING_WEBHOOK" "WINIT" "WISELOADS" "WISE_EXPRESS" "WISH_EMAIL_PUSH" "WIZMO" "WMG" "WNDIRECT" "WOOYOUNG_LOGISTICS_SFTP" "WORLDCOURIER" "WORLDNET" "WSPEXPRESS" "WYNGS" "XDE_WEBHOOK" "XDP_UK_REFERENCE" "XGS" "XINDUS" "XL_EXPRESS" "XMSZM" "XPEDIGO" "XPERT_DELIVERY" "XPOST" "XPO_LOGISTICS" "XPRESSBEES" "XPRESSEN_DK" "XQ_EXPRESS" "XYY" "YAKIT" "YAMATO" "YANWEN" "YANWEN_EXPRESS" "YDH_EXPRESS" "YIFAN" "YINGNUO_LOGISTICS" "YODEL" "YODEL_API" "YODEL_DIR" "YODEL_INTNL" "YOUPARCEL" "YTO" "YUNANT" "YUNEXPRESS" "YUNHUIPOST" "YURTICI_KARGO" "YUSEN" "YUSEN_SFTP" "YYCOM" "YYEXPRESS" "ZAJIL_EXPRESS" "ZA_COURIERIT" "ZA_SPECIALISED_FREIGHT" "ZEEK_2_DOOR" "ZELERIS" "ZEPTO_EXPRESS" "ZES_EXPRESS" "ZIINGFINALMILE" "ZINC" "ZJS_EXPRESS" "ZOOM_RED" "ZTO_DOMESTIC" "ZTO_EXPRESS" "ZUELLIGPHARMA_SFTP" "ZYLLEM" "ZYOU" "_2EBOX" "_360LION" "_3JMSLOGISTICS" "_4_72" "_6LS"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "checkout-orders orderscreate" } } | get name | first)
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

# Create order
#
# POST /v2/checkout/orders
# operationId: orders.create
# --purchase_units item shape: {reference_id?: string, amount: any, payee?: any, payment_instruction?: record, description?: string, custom_id?: string, invoice_id?: string, soft_descriptor?: string, items?: list, shipping?: any, supplementary_data?: any}
# --payment_source shape: {card?: record, token?: record, paypal?: any, bancontact?: any, blik?: any, eps?: any, giropay?: any, ideal?: any, mybank?: any, p24?: any, sofort?: any, trustly?: any, apple_pay?: any, google_pay?: any, venmo?: any, crypto?: any}
export def "checkout-orders orderscreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PayPal-Request-Id: string # The server stores keys for 6 hours. The API callers can request the times to up to 72 hours by speaking to their Account Manager. It is mandatory for all single-step create order calls (E.g. Create Order Request with payment source information like Card, PayPal.vault_id, PayPal.billing_agreement_id, etc).
  --PayPal-Partner-Attribution-Id: string # PayPal Partner can send a PayPal-Partner-Attribution-Id request header with the value that they have been assigned by the PayPal Partner program. This value is known as a BN Code. In order to reward such partners (through partner programs), all the activities (including API calls) that they are doing on behalf of the merchants need to be tracked.
  --PayPal-Client-Metadata-Id: string # A GUID value originating from Fraudnet and Dyson passed from external API clients via HTTP header. The value is used by Risk decisions to correlate calls which, in turn, might result in lower decline rates..
  --Prefer: string # The preferred server response upon successful completion of the request. Value is:<ul><li><code>return=minimal</code>. The server returns a minimal response to optimize communication between the API caller and the server. A minimal response includes the <code>id</code>, <code>status</code> and HATEOAS links.</li><li><code>return=representation</code>. The server returns a complete resource representation, including the current state of the resource.</li></ul>
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
  intent: string@intent-completer # The intent to either capture payment immediately or authorize a payment for an order after order creation.
  --payer: any
  purchase_units: list # An array of purchase units. Each purchase unit establishes a contract between a payer and the payee. Each purchase unit represents either a full or partial order that the payer intends to purchase from the payee. — item shape: {reference_id?: string, amount: any, payee?: any, payment_instruction?: record, description?: string, custom_id?: string, invoice_id?: string, soft_descriptor?: string, items?: list, shipping?: any, supplementary_data?: any}
  --payment-source: record # The payment source definition. — shape: {card?: record, token?: record, paypal?: any, bancontact?: any, blik?: any, eps?: any, giropay?: any, ideal?: any, mybank?: any, p24?: any, sofort?: any, trustly?: any, apple_pay?: any, google_pay?: any, venmo?: any, crypto?: any}
  --application-context: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/checkout/orders")
  let body = {intent: $intent, payer: $payer, purchase_units: $purchase_units, payment_source: $payment_source, application_context: $application_context} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"PayPal-Request-Id": $PayPal_Request_Id, "PayPal-Partner-Attribution-Id": $PayPal_Partner_Attribution_Id, "PayPal-Client-Metadata-Id": $PayPal_Client_Metadata_Id, "Prefer": $Prefer, "Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Show order details
#
# GET /v2/checkout/orders/{id}
# operationId: orders.get
export def "checkout-orders ordersget" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # A comma-separated list of fields that should be returned for the order. Valid filter field is `payment_source`.
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/checkout/orders/($id)" $qp)
  let extra_headers = {"Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update order
#
# PATCH /v2/checkout/orders/{id}
# operationId: orders.patch
export def "checkout-orders orderspatch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/checkout/orders/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Confirm the Order
#
# POST /v2/checkout/orders/{id}/confirm-payment-source
# operationId: orders.confirm
# --payment_source shape: {card?: record, token?: record, paypal?: any, bancontact?: any, blik?: any, eps?: any, giropay?: any, ideal?: any, mybank?: any, p24?: any, sofort?: any, trustly?: any, apple_pay?: any, google_pay?: any, venmo?: any, crypto?: any}
# --application_context shape: {brand_name?: string, locale?: any, return_url?: string, cancel_url?: string, stored_payment_source?: record}
export def "checkout-orders-confirm-payment-source ordersconfirm" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PayPal-Client-Metadata-Id: string # A GUID value originating from Fraudnet and Dyson passed from external API clients via HTTP header. The value is used by Risk decisions to correlate calls which, in turn, might result in lower decline rates..
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
  --Prefer: string # The preferred server response upon successful completion of the request. Value is:<ul><li><code>return=minimal</code>. The server returns a minimal response to optimize communication between the API caller and the server. A minimal response includes the <code>id</code>, <code>status</code> and HATEOAS links.</li><li><code>return=representation</code>. The server returns a complete resource representation, including the current state of the resource.</li></ul>
  payment_source: record # The payment source definition. — shape: {card?: record, token?: record, paypal?: any, bancontact?: any, blik?: any, eps?: any, giropay?: any, ideal?: any, mybank?: any, p24?: any, sofort?: any, trustly?: any, apple_pay?: any, google_pay?: any, venmo?: any, crypto?: any}
  --application-context: record # Customizes the payer confirmation experience. — shape: {brand_name?: string, locale?: any, return_url?: string, cancel_url?: string, stored_payment_source?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/checkout/orders/($id)/confirm-payment-source")
  let body = {payment_source: $payment_source, application_context: $application_context} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"PayPal-Client-Metadata-Id": $PayPal_Client_Metadata_Id, "Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion, "Prefer": $Prefer} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authorize payment for order
#
# POST /v2/checkout/orders/{id}/authorize
# operationId: orders.authorize
export def "checkout-orders-authorize ordersauthorize" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PayPal-Request-Id: string # The server stores keys for 6 hours. The API callers can request the times to up to 72 hours by speaking to their Account Manager. It is mandatory for all single-step create order calls (E.g. Create Order Request with payment source information like Card, PayPal.vault_id, PayPal.billing_agreement_id, etc).
  --Prefer: string # The preferred server response upon successful completion of the request. Value is:<ul><li><code>return=minimal</code>. The server returns a minimal response to optimize communication between the API caller and the server. A minimal response includes the <code>id</code>, <code>status</code> and HATEOAS links.</li><li><code>return=representation</code>. The server returns a complete resource representation, including the current state of the resource.</li></ul>
  --PayPal-Client-Metadata-Id: string # A GUID value originating from Fraudnet and Dyson passed from external API clients via HTTP header. The value is used by Risk decisions to correlate calls which, in turn, might result in lower decline rates..
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
  --payment-source: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/checkout/orders/($id)/authorize")
  let body = {payment_source: $payment_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"PayPal-Request-Id": $PayPal_Request_Id, "Prefer": $Prefer, "PayPal-Client-Metadata-Id": $PayPal_Client_Metadata_Id, "Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Capture payment for order
#
# POST /v2/checkout/orders/{id}/capture
# operationId: orders.capture
export def "checkout-orders-capture orderscapture" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PayPal-Request-Id: string # The server stores keys for 6 hours. The API callers can request the times to up to 72 hours by speaking to their Account Manager. It is mandatory for all single-step create order calls (E.g. Create Order Request with payment source information like Card, PayPal.vault_id, PayPal.billing_agreement_id, etc).
  --Prefer: string # The preferred server response upon successful completion of the request. Value is:<ul><li><code>return=minimal</code>. The server returns a minimal response to optimize communication between the API caller and the server. A minimal response includes the <code>id</code>, <code>status</code> and HATEOAS links.</li><li><code>return=representation</code>. The server returns a complete resource representation, including the current state of the resource.</li></ul>
  --PayPal-Client-Metadata-Id: string # A GUID value originating from Fraudnet and Dyson passed from external API clients via HTTP header. The value is used by Risk decisions to correlate calls which, in turn, might result in lower decline rates..
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
  --payment-source: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/checkout/orders/($id)/capture")
  let body = {payment_source: $payment_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"PayPal-Request-Id": $PayPal_Request_Id, "Prefer": $Prefer, "PayPal-Client-Metadata-Id": $PayPal_Client_Metadata_Id, "Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add tracking information for an Order.
#
# POST /v2/checkout/orders/{id}/track
# operationId: orders.track.create
# --items item shape: {name?: string, quantity?: string, sku?: string, url?: string, image_url?: string, upc?: any}
export def "checkout-orders-track orderstrackcreate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
  tracking_number: string # The tracking number for the shipment. This property supports Unicode.
  carrier: string@carrier-completer # The carrier for the shipment. Some carriers have a global version as well as local subsidiaries. The subsidiaries are repeated over many countries and might also have an entry in the global list. Choose the carrier for your country. If the carrier is not available for your country, choose the global version of the carrier. If your carrier name is not in the list, set `carrier` to `OTHER` and set carrier name in `carrier_name_other`. For allowed values, see <a href="/docs/tracking/reference/carriers/">Carriers</a>.
  --carrier-name-other: string # The name of the carrier for the shipment. Provide this value only if the carrier parameter is OTHER. This property supports Unicode.
  capture_id: string # The PayPal capture ID.
  --notify-payer: oneof<nothing, bool> # If true, PayPal will send an email notification to the payer of the PayPal transaction. The email contains the tracking details provided through the Orders tracking API request. Independent of any value passed for `notify_payer`, the payer may receive tracking notifications within the PayPal app, based on the user's notification preferences. (default: false)
  --items: list # An array of details of items in the shipment. — item shape: {name?: string, quantity?: string, sku?: string, url?: string, image_url?: string, upc?: any}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/checkout/orders/($id)/track")
  let body = {tracking_number: $tracking_number, carrier: $carrier, carrier_name_other: $carrier_name_other, capture_id: $capture_id, notify_payer: $notify_payer, items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update or cancel tracking information for an order
#
# PATCH /v2/checkout/orders/{id}/trackers/{tracker_id}
# operationId: orders.trackers.patch
export def "checkout-orders-trackers orderstrackerspatch" [
  id: string
  tracker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Holds authorization information for external API calls.
  --PayPal-Auth-Assertion: string # Header for an API client-provided JWT assertion that identifies the merchant. Establishing the consent to act-on-behalf of a merchant is a prerequisite for using this header.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/checkout/orders/($id)/trackers/($tracker_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "PayPal-Auth-Assertion": $PayPal_Auth_Assertion} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Receive updated order information via callback URL
#
# POST /v2/checkout/orders/order-update-callback
# operationId: server.callback
# --purchase_units item shape: {reference_id?: string, amount: any, payee?: any, payment_instruction?: record, description?: string, custom_id?: string, invoice_id?: string, soft_descriptor?: string, items?: list, shipping?: any, supplementary_data?: any}
export def "checkout-orders-order-update-callback servercallback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Holds authorization information for external API calls.
  --shipping-address: any
  --shipping-option: any
  purchase_units: list # An array of purchase units. At present only 1 purchase_unit is supported. Each purchase unit establishes a contract between a payer and the payee. Each purchase unit represents either a full or partial order that the payer intends to purchase from the payee. — item shape: {reference_id?: string, amount: any, payee?: any, payment_instruction?: record, description?: string, custom_id?: string, invoice_id?: string, soft_descriptor?: string, items?: list, shipping?: any, supplementary_data?: any}
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/checkout/orders/order-update-callback")
  let body = {shipping_address: $shipping_address, shipping_option: $shipping_option, purchase_units: $purchase_units} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
