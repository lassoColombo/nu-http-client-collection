#!/usr/bin/env nu

# (Re)generate one or more clients listed in clients.yaml.
#
# Examples:
#   nu scripts/generate.nu               # regenerate every client
#   nu scripts/generate.nu all           # same as above
#   nu scripts/generate.nu countries     # regenerate only the `countries` client
#
# The generator (nu-http-client-generator) must be available at the path passed
# via --generator (default: ./_generator). Locally:
#   git clone https://github.com/lassoColombo/nu-http-client-generator _generator

def main [
    client?: string                          # client name to regenerate; omit, "", or "all" to regenerate all
    --config: path = "clients.yaml"          # path to the registry file
    --generator: path = "_generator"         # path to the nu-http-client-generator directory
    --out-dir: path = "clients"              # where to write generated `.nu` files
] {
    if not ($config | path exists) {
        error make { msg: $"config file not found: ($config)" }
    }
    if not (($generator | path join "mod.nu") | path exists) {
        error make { msg: $"generator not found at ($generator). Clone it with: git clone https://github.com/lassoColombo/nu-http-client-generator ($generator)" }
    }

    let registry = open $config
    let all_clients = ($registry.clients? | default [])
    if ($all_clients | is-empty) {
        error make { msg: $"no clients defined in ($config)" }
    }

    let selected = (filter-clients $all_clients $client)
    mkdir $out_dir

    let generator_path = ($generator | into string)
    let generator_name = ($generator | path basename)

    print $"Generating ($selected | length) client\(s\) into ($out_dir)/"
    for c in $selected {
        generate-one $c $out_dir $generator_path $generator_name
    }
    print "Done."
}

def filter-clients [clients: list, name: any]: nothing -> list {
    if ($name == null or $name == "" or $name == "all") {
        return $clients
    }
    let matched = ($clients | where name == $name)
    if ($matched | is-empty) {
        let known = ($clients | get name | str join ", ")
        error make { msg: $"no client named '($name)'. Known clients: ($known)" }
    }
    $matched
}

def generate-one [
    client: record
    out_dir: path
    generator_path: string
    generator_name: string
] {
    let required = ["name" "type" "source"]
    for key in $required {
        if ($client | get -o $key) == null {
            error make { msg: $"client entry missing required key '($key)': ($client | to nuon)" }
        }
    }
    if not ($client.type in ["openapi" "graphql"]) {
        error make { msg: $"unsupported type '($client.type)' for client '($client.name)' — must be 'openapi' or 'graphql'" }
    }

    let out_path = ($out_dir | path join $"($client.name).nu")
    let flags_str = (build-flag-args ($client.flags? | default {}))
    let source_lit = ($client.source | to nuon)
    let out_lit = ($out_path | to nuon)
    let gen_lit = ($generator_path | to nuon)

    let cmd = $"use ($gen_lit); ($generator_name) ($client.type) ($source_lit) -o ($out_lit) ($flags_str)"

    print $"  → ($client.name)  [($client.type)]  ($client.source)"
    nu -c $cmd
}

# Render a record of {flag-name: value} pairs as a string of CLI args.
# Values are encoded with `to nuon` so lists/records/strings round-trip safely.
# Booleans are emitted as switches (only when true).
def build-flag-args [flags: record]: nothing -> string {
    $flags
    | transpose key value
    | each {|f|
        let flag = $"--($f.key)"
        if ($f.value | describe) == "bool" {
            if $f.value { $flag } else { null }
        } else {
            $"($flag) ($f.value | to nuon)"
        }
    }
    | compact
    | str join " "
}
