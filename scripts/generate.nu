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
    --readme: path = "README.md"             # README to refresh the clients table in
    --readme-only                            # skip generation; only refresh the README table from `clients.yaml`
] {
    if not ($config | path exists) {
        error make { msg: $"config file not found: ($config)" }
    }
    let registry = open $config
    let all_clients = ($registry.clients? | default [])
    if ($all_clients | is-empty) {
        error make { msg: $"no clients defined in ($config)" }
    }

    if $readme_only {
        update-readme-table $readme $all_clients $out_dir
        print $"Refreshed clients table in ($readme)."
        return
    }

    if not (($generator | path join "mod.nu") | path exists) {
        error make { msg: $"generator not found at ($generator). Clone it with: git clone https://github.com/lassoColombo/nu-http-client-generator ($generator)" }
    }

    let selected = (filter-clients $all_clients $client)
    mkdir $out_dir

    let generator_path = ($generator | into string)
    let generator_name = ($generator | path basename)

    print $"Generating ($selected | length) client\(s\) into ($out_dir)/"
    for c in $selected {
        generate-one $c $out_dir $generator_path $generator_name
    }

    update-readme-table $readme $all_clients $out_dir
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

# Replace the section between BEGIN/END marker comments in `readme_path`
# with a markdown table rendered from `clients`.
def update-readme-table [readme_path: path, clients: list, out_dir: path] {
    if not ($readme_path | path exists) {
        error make { msg: $"README not found at ($readme_path)" }
    }
    let begin = "<!-- BEGIN CLIENTS TABLE -->"
    let end_  = "<!-- END CLIENTS TABLE -->"
    let content = (open --raw $readme_path)
    if not ($content | str contains $begin) or not ($content | str contains $end_) {
        error make { msg: $"README is missing the BEGIN/END CLIENTS TABLE marker comments" }
    }

    let table = (render-clients-table $clients $out_dir)
    let replacement = $"($begin)\n($table)\n($end_)"
    let pattern = $"\(?s\)($begin).*?($end_)"
    $content
    | str replace --regex $pattern $replacement
    | save -f $readme_path
}

def render-clients-table [clients: list, out_dir: path]: nothing -> string {
    $clients
    | each {|c|
        {
            Client: $"[($c.name)]\(($out_dir)/($c.name).nu\)"
            Type: $c.type
            Source: $"<($c.source)>"
        }
    }
    | to md --pretty
}
