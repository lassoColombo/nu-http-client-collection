# Auto-generated client for Image-Charts v6.1.19
# Source: https://api.apis.guru/v2/specs/image-charts.com/6.1.19/swagger.json
# Auth: --token flag or $env.IMAGE_CHARTS_TOKEN

const BASE_URL = "https://image-charts.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o IMAGE_CHARTS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://image-charts.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def cht-completer [] { ["bb" "bhg" "bhs" "bvg" "bvo" "bvs" "gv" "gv:circo" "gv:dot" "gv:fdp" "gv:neato" "gv:osage" "gv:twopi" "lc" "lc:nda" "ls" "ls:nda" "lxy" "lxy:nda" "p" "p3" "pa" "pc" "pd" "qr" "r"] }
def choe-completer [] { ["UTF-8"] }
def icff-completer [] { ["ABeeZee" "Abel" "Abhaya Libre" "Abril Fatface" "Aclonica" "Acme" "Actor" "Adamina" "Advent Pro" "Aguafina Script" "Akronim" "Aladin" "Aldrich" "Alef" "Alegreya" "Alegreya SC" "Alegreya Sans" "Alegreya Sans SC" "Aleo" "Alex Brush" "Alfa Slab One" "Alice" "Alike" "Alike Angular" "Allan" "Allerta" "Allerta Stencil" "Allura" "Almarai" "Almendra" "Almendra Display" "Almendra SC" "Amarante" "Amaranth" "Amatic SC" "Amethysta" "Amiko" "Amiri" "Amita" "Anaheim" "Andada" "Andika" "Angkor" "Annie Use Your Telescope" "Anonymous Pro" "Antic" "Antic Didone" "Antic Slab" "Anton" "Arapey" "Arbutus" "Arbutus Slab" "Architects Daughter" "Archivo" "Archivo Black" "Archivo Narrow" "Aref Ruqaa" "Arima Madurai" "Arimo" "Arizonia" "Armata" "Arsenal" "Artifika" "Arvo" "Arya" "Asap" "Asap Condensed" "Asar" "Asset" "Assistant" "Astloch" "Asul" "Athiti" "Atma" "Atomic Age" "Aubrey" "Audiowide" "Autour One" "Average" "Average Sans" "Averia Gruesa Libre" "Averia Libre" "Averia Sans Libre" "Averia Serif Libre" "B612" "B612 Mono" "Bad Script" "Bahiana" "Bahianita" "Bai Jamjuree" "Baloo" "Baloo Bhai" "Baloo Bhaijaan" "Baloo Bhaina" "Baloo Chettan" "Baloo Da" "Baloo Paaji" "Baloo Tamma" "Baloo Tammudu" "Baloo Thambi" "Balthazar" "Bangers" "Barlow" "Barlow Condensed" "Barlow Semi Condensed" "Barriecito" "Barrio" "Basic" "Battambang" "Baumans" "Bayon" "Be Vietnam" "Belgrano" "Bellefair" "Belleza" "BenchNine" "Bentham" "Berkshire Swash" "Beth Ellen" "Bevan" "Big Shoulders Display" "Big Shoulders Text" "Bigelow Rules" "Bigshot One" "Bilbo" "Bilbo Swash Caps" "BioRhyme" "BioRhyme Expanded" "Biryani" "Bitter" "Black And White Picture" "Black Han Sans" "Black Ops One" "Blinker" "Bokor" "Bonbon" "Boogaloo" "Bowlby One" "Bowlby One SC" "Brawler" "Bree Serif" "Bubblegum Sans" "Bubbler One" "Buda" "Buenard" "Bungee" "Bungee Hairline" "Bungee Inline" "Bungee Outline" "Bungee Shade" "Butcherman" "Butterfly Kids" "Cabin" "Cabin Condensed" "Cabin Sketch" "Caesar Dressing" "Cagliostro" "Cairo" "Calligraffitti" "Cambay" "Cambo" "Candal" "Cantarell" "Cantata One" "Cantora One" "Capriola" "Cardo" "Carme" "Carrois Gothic" "Carrois Gothic SC" "Carter One" "Catamaran" "Caudex" "Caveat" "Caveat Brush" "Cedarville Cursive" "Ceviche One" "Chakra Petch" "Changa" "Changa One" "Chango" "Charm" "Charmonman" "Chathura" "Chau Philomene One" "Chela One" "Chelsea Market" "Chenla" "Cherry Cream Soda" "Cherry Swash" "Chewy" "Chicle" "Chilanka" "Chivo" "Chonburi" "Cinzel" "Cinzel Decorative" "Clicker Script" "Coda" "Coda Caption" "Codystar" "Coiny" "Combo" "Comfortaa" "Coming Soon" "Concert One" "Condiment" "Content" "Contrail One" "Convergence" "Cookie" "Copse" "Corben" "Cormorant" "Cormorant Garamond" "Cormorant Infant" "Cormorant SC" "Cormorant Unicase" "Cormorant Upright" "Courgette" "Cousine" "Coustard" "Covered By Your Grace" "Crafty Girls" "Creepster" "Crete Round" "Crimson Pro" "Crimson Text" "Croissant One" "Crushed" "Cuprum" "Cute Font" "Cutive" "Cutive Mono" "DM Sans" "DM Serif Display" "DM Serif Text" "Damion" "Dancing Script" "Dangrek" "Darker Grotesque" "David Libre" "Dawning of a New Day" "Days One" "Dekko" "Delius" "Delius Swash Caps" "Delius Unicase" "Della Respira" "Denk One" "Devonshire" "Dhurjati" "Didact Gothic" "Diplomata" "Diplomata SC" "Do Hyeon" "Dokdo" "Domine" "Donegal One" "Doppio One" "Dorsa" "Dosis" "Dr Sugiyama" "Duru Sans" "Dynalight" "EB Garamond" "Eagle Lake" "East Sea Dokdo" "Eater" "Economica" "Eczar" "El Messiri" "Electrolize" "Elsie" "Elsie Swash Caps" "Emblema One" "Emilys Candy" "Encode Sans" "Encode Sans Condensed" "Encode Sans Expanded" "Encode Sans Semi Condensed" "Encode Sans Semi Expanded" "Engagement" "Englebert" "Enriqueta" "Erica One" "Esteban" "Euphoria Script" "Ewert" "Exo" "Exo 2" "Expletus Sans" "Fahkwang" "Fanwood Text" "Farro" "Farsan" "Fascinate" "Fascinate Inline" "Faster One" "Fasthand" "Fauna One" "Faustina" "Federant" "Federo" "Felipa" "Fenix" "Finger Paint" "Fira Code" "Fira Mono" "Fira Sans" "Fira Sans Condensed" "Fira Sans Extra Condensed" "Fjalla One" "Fjord One" "Flamenco" "Flavors" "Fondamento" "Fontdiner Swanky" "Forum" "Francois One" "Frank Ruhl Libre" "Freckle Face" "Fredericka the Great" "Fredoka One" "Freehand" "Fresca" "Frijole" "Fruktur" "Fugaz One" "GFS Didot" "GFS Neohellenic" "Gabriela" "Gaegu" "Gafata" "Galada" "Galdeano" "Galindo" "Gamja Flower" "Gayathri" "Gentium Basic" "Gentium Book Basic" "Geo" "Geostar" "Geostar Fill" "Germania One" "Gidugu" "Gilda Display" "Give You Glory" "Glass Antiqua" "Glegoo" "Gloria Hallelujah" "Goblin One" "Gochi Hand" "Gorditas" "Gothic A1" "Goudy Bookletter 1911" "Graduate" "Grand Hotel" "Gravitas One" "Great Vibes" "Grenze" "Griffy" "Gruppo" "Gudea" "Gugi" "Gurajada" "Habibi" "Halant" "Hammersmith One" "Hanalei" "Hanalei Fill" "Handlee" "Hanuman" "Happy Monkey" "Harmattan" "Headland One" "Heebo" "Henny Penny" "Hepta Slab" "Herr Von Muellerhoff" "Hi Melody" "Hind" "Hind Guntur" "Hind Madurai" "Hind Siliguri" "Hind Vadodara" "Holtwood One SC" "Homemade Apple" "Homenaje" "IBM Plex Mono" "IBM Plex Sans" "IBM Plex Sans Condensed" "IBM Plex Serif" "IM Fell DW Pica" "IM Fell DW Pica SC" "IM Fell Double Pica" "IM Fell Double Pica SC" "IM Fell English" "IM Fell English SC" "IM Fell French Canon" "IM Fell French Canon SC" "IM Fell Great Primer" "IM Fell Great Primer SC" "Iceberg" "Iceland" "Imprima" "Inconsolata" "Inder" "Indie Flower" "Inika" "Inknut Antiqua" "Irish Grover" "Istok Web" "Italiana" "Italianno" "Itim" "Jacques Francois" "Jacques Francois Shadow" "Jaldi" "Jim Nightshade" "Jockey One" "Jolly Lodger" "Jomhuria" "Jomolhari" "Josefin Sans" "Josefin Slab" "Joti One" "Jua" "Judson" "Julee" "Julius Sans One" "Junge" "Jura" "Just Another Hand" "Just Me Again Down Here" "K2D" "Kadwa" "Kalam" "Kameron" "Kanit" "Kantumruy" "Karla" "Karma" "Katibeh" "Kaushan Script" "Kavivanar" "Kavoon" "Kdam Thmor" "Keania One" "Kelly Slab" "Kenia" "Khand" "Khmer" "Khula" "Kirang Haerang" "Kite One" "Knewave" "KoHo" "Kodchasan" "Kosugi" "Kosugi Maru" "Kotta One" "Koulen" "Kranky" "Kreon" "Kristi" "Krona One" "Krub" "Kumar One" "Kumar One Outline" "Kurale" "La Belle Aurore" "Lacquer" "Laila" "Lakki Reddy" "Lalezar" "Lancelot" "Lateef" "Lato" "League Script" "Leckerli One" "Ledger" "Lekton" "Lemon" "Lemonada" "Lexend Deca" "Lexend Exa" "Lexend Giga" "Lexend Mega" "Lexend Peta" "Lexend Tera" "Lexend Zetta" "Libre Barcode 128" "Libre Barcode 128 Text" "Libre Barcode 39" "Libre Barcode 39 Extended" "Libre Barcode 39 Extended Text" "Libre Barcode 39 Text" "Libre Baskerville" "Libre Caslon Display" "Libre Caslon Text" "Libre Franklin" "Life Savers" "Lilita One" "Lily Script One" "Limelight" "Linden Hill" "Literata" "Liu Jian Mao Cao" "Livvic" "Lobster" "Lobster Two" "Londrina Outline" "Londrina Shadow" "Londrina Sketch" "Londrina Solid" "Long Cang" "Lora" "Love Ya Like A Sister" "Loved by the King" "Lovers Quarrel" "Luckiest Guy" "Lusitana" "Lustria" "M PLUS 1p" "M PLUS Rounded 1c" "Ma Shan Zheng" "Macondo" "Macondo Swash Caps" "Mada" "Magra" "Maiden Orange" "Maitree" "Major Mono Display" "Mako" "Mali" "Mallanna" "Mandali" "Manjari" "Mansalva" "Manuale" "Marcellus" "Marcellus SC" "Marck Script" "Margarine" "Markazi Text" "Marko One" "Marmelad" "Martel" "Martel Sans" "Marvel" "Mate" "Mate SC" "Maven Pro" "McLaren" "Meddon" "MedievalSharp" "Medula One" "Meera Inimai" "Megrim" "Meie Script" "Merienda" "Merienda One" "Merriweather" "Merriweather Sans" "Metal" "Metal Mania" "Metamorphous" "Metrophobic" "Michroma" "Milonga" "Miltonian" "Miltonian Tattoo" "Mina" "Miniver" "Miriam Libre" "Mirza" "Miss Fajardose" "Mitr" "Modak" "Modern Antiqua" "Mogra" "Molengo" "Molle" "Monda" "Monofett" "Monoton" "Monsieur La Doulaise" "Montaga" "Montez" "Montserrat" "Montserrat Alternates" "Montserrat Subrayada" "Moul" "Moulpali" "Mountains of Christmas" "Mouse Memoirs" "Mr Bedfort" "Mr Dafoe" "Mr De Haviland" "Mrs Saint Delafield" "Mrs Sheppards" "Mukta" "Mukta Mahee" "Mukta Malar" "Mukta Vaani" "Muli" "Mystery Quest" "NTR" "Nanum Brush Script" "Nanum Gothic" "Nanum Gothic Coding" "Nanum Myeongjo" "Nanum Pen Script" "Neucha" "Neuton" "New Rocker" "News Cycle" "Niconne" "Niramit" "Nixie One" "Nobile" "Nokora" "Norican" "Nosifer" "Notable" "Nothing You Could Do" "Noticia Text" "Noto Sans" "Noto Sans HK" "Noto Sans JP" "Noto Sans KR" "Noto Sans SC" "Noto Sans TC" "Noto Serif" "Noto Serif JP" "Noto Serif KR" "Noto Serif SC" "Noto Serif TC" "Nova Cut" "Nova Flat" "Nova Mono" "Nova Oval" "Nova Round" "Nova Script" "Nova Slim" "Nova Square" "Numans" "Nunito" "Nunito Sans" "Odor Mean Chey" "Offside" "Old Standard TT" "Oldenburg" "Oleo Script" "Oleo Script Swash Caps" "Open Sans" "Open Sans Condensed" "Oranienbaum" "Orbitron" "Oregano" "Orienta" "Original Surfer" "Oswald" "Over the Rainbow" "Overlock" "Overlock SC" "Overpass" "Overpass Mono" "Ovo" "Oxygen" "Oxygen Mono" "PT Mono" "PT Sans" "PT Sans Caption" "PT Sans Narrow" "PT Serif" "PT Serif Caption" "Pacifico" "Padauk" "Palanquin" "Palanquin Dark" "Pangolin" "Paprika" "Parisienne" "Passero One" "Passion One" "Pathway Gothic One" "Patrick Hand" "Patrick Hand SC" "Pattaya" "Patua One" "Pavanam" "Paytone One" "Peddana" "Peralta" "Permanent Marker" "Petit Formal Script" "Petrona" "Philosopher" "Piedra" "Pinyon Script" "Pirata One" "Plaster" "Play" "Playball" "Playfair Display" "Playfair Display SC" "Podkova" "Poiret One" "Poller One" "Poly" "Pompiere" "Pontano Sans" "Poor Story" "Poppins" "Port Lligat Sans" "Port Lligat Slab" "Pragati Narrow" "Prata" "Preahvihear" "Press Start 2P" "Pridi" "Princess Sofia" "Prociono" "Prompt" "Prosto One" "Proza Libre" "Puritan" "Purple Purse" "Quando" "Quantico" "Quattrocento" "Quattrocento Sans" "Questrial" "Quicksand" "Quintessential" "Qwigley" "Racing Sans One" "Radley" "Rajdhani" "Rakkas" "Raleway" "Raleway Dots" "Ramabhadra" "Ramaraja" "Rambla" "Rammetto One" "Ranchers" "Rancho" "Ranga" "Rasa" "Rationale" "Ravi Prakash" "Red Hat Display" "Red Hat Text" "Redressed" "Reem Kufi" "Reenie Beanie" "Revalia" "Rhodium Libre" "Ribeye" "Ribeye Marrow" "Righteous" "Risque" "Roboto" "Roboto Condensed" "Roboto Mono" "Roboto Slab" "Rochester" "Rock Salt" "Rokkitt" "Romanesco" "Ropa Sans" "Rosario" "Rosarivo" "Rouge Script" "Rozha One" "Rubik" "Rubik Mono One" "Ruda" "Rufina" "Ruge Boogie" "Ruluko" "Rum Raisin" "Ruslan Display" "Russo One" "Ruthie" "Rye" "Sacramento" "Sahitya" "Sail" "Saira" "Saira Condensed" "Saira Extra Condensed" "Saira Semi Condensed" "Saira Stencil One" "Salsa" "Sanchez" "Sancreek" "Sansita" "Sarabun" "Sarala" "Sarina" "Sarpanch" "Satisfy" "Sawarabi Gothic" "Sawarabi Mincho" "Scada" "Scheherazade" "Schoolbell" "Scope One" "Seaweed Script" "Secular One" "Sedgwick Ave" "Sedgwick Ave Display" "Sevillana" "Seymour One" "Shadows Into Light" "Shadows Into Light Two" "Shanti" "Share" "Share Tech" "Share Tech Mono" "Shojumaru" "Short Stack" "Shrikhand" "Siemreap" "Sigmar One" "Signika" "Signika Negative" "Simonetta" "Single Day" "Sintony" "Sirin Stencil" "Six Caps" "Skranji" "Slabo 13px" "Slabo 27px" "Slackey" "Smokum" "Smythe" "Sniglet" "Snippet" "Snowburst One" "Sofadi One" "Sofia" "Song Myung" "Sonsie One" "Sorts Mill Goudy" "Source Code Pro" "Source Sans Pro" "Source Serif Pro" "Space Mono" "Special Elite" "Spectral" "Spectral SC" "Spicy Rice" "Spinnaker" "Spirax" "Squada One" "Sree Krushnadevaraya" "Sriracha" "Srisakdi" "Staatliches" "Stalemate" "Stalinist One" "Stardos Stencil" "Stint Ultra Condensed" "Stint Ultra Expanded" "Stoke" "Strait" "Stylish" "Sue Ellen Francisco" "Suez One" "Sumana" "Sunflower" "Sunshiney" "Supermercado One" "Sura" "Suranna" "Suravaram" "Suwannaphum" "Swanky and Moo Moo" "Syncopate" "Tajawal" "Tangerine" "Taprom" "Tauri" "Taviraj" "Teko" "Telex" "Tenali Ramakrishna" "Tenor Sans" "Text Me One" "Thasadith" "The Girl Next Door" "Tienne" "Tillana" "Timmana" "Tinos" "Titan One" "Titillium Web" "Trade Winds" "Trirong" "Trocchi" "Trochut" "Trykker" "Tulpen One" "Turret Road" "Ubuntu" "Ubuntu Condensed" "Ubuntu Mono" "Ultra" "Uncial Antiqua" "Underdog" "Unica One" "UnifrakturCook" "UnifrakturMaguntia" "Unkempt" "Unlock" "Unna" "VT323" "Vampiro One" "Varela" "Varela Round" "Vast Shadow" "Vesper Libre" "Vibes" "Vibur" "Vidaloka" "Viga" "Voces" "Volkhov" "Vollkorn" "Vollkorn SC" "Voltaire" "Waiting for the Sunrise" "Wallpoet" "Walter Turncoat" "Warnes" "Wellfleet" "Wendy One" "Wire One" "Work Sans" "Yanone Kaffeesatz" "Yantramanav" "Yatra One" "Yellowtail" "Yeon Sung" "Yeseva One" "Yesteryear" "Yrsa" "ZCOOL KuaiLe" "ZCOOL QingKe HuangYou" "ZCOOL XiaoWei" "Zeyada" "Zhi Mang Xing" "Zilla Slab" "Zilla Slab Highlight"] }
def icfs-completer [] { ["italic" "normal"] }
def iclocale-completer [] { ["de" "en" "fr"] }
def icwt-completer [] { ["0" "1" "false" "true"] }
def icretina-completer [] { ["0" "1"] }
def accept-completer [] { ["application/gif" "application/png" "image/svg+xml"] }
def encoding-completer [] { ["base64" "url"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "chart get" } } | get name | first)
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

# Image-Charts API
#
# GET /chart
# operationId: getChart
export def "chart get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --cht: string@cht-completer # Chart type
  --chd: string # chart data
  --chds: string # data format with custom scaling
  --choe: string@choe-completer # QRCode data encoding
  --chld: string # QRCode error correction level and optional margin (default: L|4)
  --chxr: string # Axis data-range
  --chxp: string # axis label positions
  --chof: string # Image output format (default: .png)
  --chs: string # Chart size (x)
  --chdl: string # Text for each series, to display in the legend (default: )
  --chdls: string # Chart legend text and style (default: 000000)
  --chg: string # Solid or dotted grid lines
  --chco: string # series colors (default: F56991,FF9F80,FFC48C,D1F2A5,EFFAB4)
  --chtt: string # chart title (default: )
  --chts: string # chart title colors and font size (default: )
  --chxt: string # Display values on your axis lines or change which axes are shown (default: )
  --chxl: string # Custom string axis labels on any axis (default: )
  --chxs: string # Font size, color for axis labels, both custom labels and default label values
  --chm: string # compound charts and line fills (default: )
  --chls: string # line thickness and solid/dashed style (default: )
  --chl: string # bar, pie slice, doughnut slice and polar slice chart labels (default: )
  --chlps: string # Position and style of labels on data (default: )
  --chma: string # chart margins
  --chdlp: string # Position of the legend and order of the legend entries (default: r)
  --chf: string # Background Fills (default: bg,s,FFFFFF)
  --chbh: string # Bar Width and Spacing. (not supported) You can optionally specify custom values for bar widths and spacing between bars and groups. You can only specify one set of width values for all bars. If you don't specify chbh, all bars will be 23 pixels wide, which means that the end bars can be clipped if the total bar + space width is wider than the chart width. (default: 10)
  --chbr: string # Bar corner radius. Display bars with rounded corner. (default: 0)
  --chan: string # gif configuration
  --chli: string # doughnut chart inside label
  --icac: string # image-charts enterprise `account_id`
  --ichm: string # HMAC-SHA256 signature required to activate paid features
  --icff: string@icff-completer # Default font family for all text from Google Fonts. Use same syntax as Google Font CSS API
  --icfs: string@icfs-completer # Default font style for all text
  --iclocale: string@iclocale-completer # localization (ISO 639-1)
  --icwt: oneof<nothing, bool> # (Private) Force to display the watermark EVEN IF the chart was signed with an enterprise account (default: false)
  --icretina: string@icretina-completer # retina mode
  --icqrb: string # Background color for QR Codes (default: FFFFFF)
  --icqrf: string # Foreground color for QR Codes (default: 000000)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cht" $cht "scalar") (serialize-qp "chd" $chd "scalar") (serialize-qp "chds" $chds "scalar") (serialize-qp "choe" $choe "scalar") (serialize-qp "chld" $chld "scalar") (serialize-qp "chxr" $chxr "scalar") (serialize-qp "chxp" $chxp "scalar") (serialize-qp "chof" $chof "scalar") (serialize-qp "chs" $chs "scalar") (serialize-qp "chdl" $chdl "scalar") (serialize-qp "chdls" $chdls "scalar") (serialize-qp "chg" $chg "scalar") (serialize-qp "chco" $chco "scalar") (serialize-qp "chtt" $chtt "scalar") (serialize-qp "chts" $chts "scalar") (serialize-qp "chxt" $chxt "scalar") (serialize-qp "chxl" $chxl "scalar") (serialize-qp "chxs" $chxs "scalar") (serialize-qp "chm" $chm "scalar") (serialize-qp "chls" $chls "scalar") (serialize-qp "chl" $chl "scalar") (serialize-qp "chlps" $chlps "scalar") (serialize-qp "chma" $chma "scalar") (serialize-qp "chdlp" $chdlp "scalar") (serialize-qp "chf" $chf "scalar") (serialize-qp "chbh" $chbh "scalar") (serialize-qp "chbr" $chbr "scalar") (serialize-qp "chan" $chan "scalar") (serialize-qp "chli" $chli "scalar") (serialize-qp "icac" $icac "scalar") (serialize-qp "ichm" $ichm "scalar") (serialize-qp "icff" $icff "scalar") (serialize-qp "icfs" $icfs "scalar") (serialize-qp "iclocale" $iclocale "scalar") (serialize-qp "icwt" $icwt "scalar") (serialize-qp "icretina" $icretina "scalar") (serialize-qp "icqrb" $icqrb "scalar") (serialize-qp "icqrf" $icqrf "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chart" $qp)
  let accept_val = ($accept | default "application/png")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Chart.js as image API
#
# GET /chart.js/2.8.0
# operationId: getChartjs280
export def "chart-js-2-8-0 get-chartjs280" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --c: string # Javascript/JSON definition of the chart. Use a Chart.js configuration object.
  --chart: string # Javascript/JSON definition of the chart. Use a Chart.js configuration object.
  --width: int # Width of the chart (default: 500)
  --height: int # Height of the chart (default: 300)
  --background-color: string # Background of the chart canvas. Accepts rgb (rgb(255,255,120)), colors (red), and url-encoded hex values (%23ff00ff). Abbreviated as "bkg"
  --bkg: string # Background of the chart canvas. Accepts rgb (rgb(255,255,120)), colors (red), and url-encoded hex values (%23ff00ff). Abbreviated as "bkg"
  --encoding: string@encoding-completer # Encoding of your "chart" parameter. Accepted values are url and base64. (default: url)
  --icac: string # image-charts enterprise `account_id`
  --ichm: string # HMAC-SHA256 signature required to activate paid features
  --icretina: string@icretina-completer # retina mode
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "c" $c "scalar") (serialize-qp "chart" $chart "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "backgroundColor" $background_color "scalar") (serialize-qp "bkg" $bkg "scalar") (serialize-qp "encoding" $encoding "scalar") (serialize-qp "icac" $icac "scalar") (serialize-qp "ichm" $ichm "scalar") (serialize-qp "icretina" $icretina "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chart.js/2.8.0" $qp)
  let accept_val = ($accept | default "application/png")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
