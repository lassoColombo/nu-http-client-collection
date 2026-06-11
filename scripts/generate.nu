#!/usr/bin/env nu

# Generate one or more clients listed in clients.yaml.
#
# By default, only clients whose output file does not yet exist are generated.
# Pass --force to regenerate regardless.
#
# Examples:
#   nu scripts/generate.nu                              # generate every missing client
#   nu scripts/generate.nu --force                      # regenerate every client
#   nu scripts/generate.nu --name countries             # generate `countries` if missing
#   nu scripts/generate.nu --name countries --force     # regenerate `countries`
#   nu scripts/generate.nu --category ai --force        # regenerate every client in `ai`
#
# Clients are written to `<out-dir>/<category>/<name>.nu`. Names must be
# unique across categories (validated at startup).
#
# The generator (nu-http-client-generator) must be available at the path passed
# via --generator (default: ./_generator). Locally:
#   git clone https://github.com/lassoColombo/nu-http-client-generator _generator

def main [
    --name: string                           # restrict to a single client by name (mutually exclusive with --category)
    --category: string                       # restrict to every client in this category (mutually exclusive with --name)
    --config: path = "clients.yaml"          # path to the registry file
    --generator: path = "_generator"         # path to the nu-http-client-generator directory
    --out-dir: path = "clients"              # where to write generated `.nu` files
    --list-file: path = "CLIENTS.md"         # markdown file listing the registry; fully overwritten
    --list-only                              # skip generation; only refresh the list file from `clients.yaml`
    --force                                  # regenerate even if the output file already exists (default: skip existing)
] {
    if ($name != null) and ($category != null) {
        error make { msg: "--name and --category are mutually exclusive" }
    }
    if not ($config | path exists) {
        error make { msg: $"config file not found: ($config)" }
    }
    let registry = open $config
    let grouped = ($registry.clients? | default {})
    let all_clients = (flatten-registry $grouped)
    if ($all_clients | is-empty) {
        error make { msg: $"no clients defined in ($config)" }
    }
    validate-unique-names $all_clients

    if $list_only {
        write-list-file $list_file $all_clients $out_dir
        print $"Refreshed clients list in ($list_file)."
        return
    }

    if not (($generator | path join "mod.nu") | path exists) {
        error make { msg: $"generator not found at ($generator). Clone it with: git clone https://github.com/lassoColombo/nu-http-client-generator ($generator)" }
    }

    let matched = (filter-clients $all_clients $name $category)
    mkdir $out_dir

    let generator_path = ($generator | into string)
    let generator_name = ($generator | path basename)

    let partitioned = if $force {
        { selected: $matched, skipped: [] }
    } else {
        let with_path = ($matched | each {|c| $c | insert out_path ($out_dir | path join $c.category $"($c.name).nu") })
        {
            selected: ($with_path | where {|c| not ($c.out_path | path exists) })
            skipped:  ($with_path | where {|c| $c.out_path | path exists })
        }
    }
    let selected = $partitioned.selected
    for s in $partitioned.skipped {
        print $"  - ($s.category)/($s.name) \(exists; use --force to regenerate\)"
    }

    print $"Generating ($selected | length) client\(s\) into ($out_dir)/ in parallel"
    let results = (
        $selected
        | par-each {|c|
            let label = $"($c.category)/($c.name)"
            try {
                generate-one $c $out_dir $generator_path $generator_name
                print $"  ✓ ($label)"
                { ok: true, label: $label, error: null }
            } catch {|e|
                let msg = ($e.msg? | default ($e | to nuon))
                print -e $"  ✗ ($label): ($msg)"
                { ok: false, label: $label, error: $msg }
            }
        }
    )
    let failures = ($results | where ok == false)

    write-list-file $list_file $all_clients $out_dir

    if not ($failures | is-empty) {
        print -e ""
        print -e $"($failures | length) of ($selected | length) client\(s\) failed:"
        for f in $failures { print -e $"  - ($f.label)" }
        # Exit non-zero so CI surfaces the failure, but only after the list
        # file is refreshed — so any partially-successful clients still get
        # committed by the workflow's commit step \(run with `if: always()`\).
        exit 1
    }
    print "Done."
}

# Flatten the nested {category: [client, ...]} structure into a list of records,
# each with a `category` field merged in.
def flatten-registry [grouped: record]: nothing -> list {
    $grouped
    | transpose category entries
    | each {|grp|
        let kind = ($grp.entries | describe)
        if not (($kind | str starts-with "list") or ($kind | str starts-with "table")) {
            error make { msg: $"category '($grp.category)' must hold a list of clients, got: ($kind)" }
        }
        $grp.entries | each {|e| $e | insert category $grp.category }
    }
    | flatten
}

def validate-unique-names [clients: list] {
    let dupes = (
        $clients
        | group-by name
        | transpose name entries
        | where ($it.entries | length) > 1
    )
    if not ($dupes | is-empty) {
        let names = ($dupes | get name | str join ", ")
        error make { msg: $"client names must be unique across categories — found duplicates: ($names)" }
    }
}

def filter-clients [clients: list, name: any, category: any]: nothing -> list {
    if $name != null and $name != "" {
        let matched = ($clients | where name == $name)
        if ($matched | is-empty) {
            let known = ($clients | each {|c| $"($c.category)/($c.name)" } | str join ", ")
            error make { msg: $"no client named '($name)'. Known clients: ($known)" }
        }
        return $matched
    }
    if $category != null and $category != "" {
        let matched = ($clients | where category == $category)
        if ($matched | is-empty) {
            let known = ($clients | get category | uniq | str join ", ")
            error make { msg: $"no clients in category '($category)'. Known categories: ($known)" }
        }
        return $matched
    }
    $clients
}

def generate-one [
    client: record
    out_dir: path
    generator_path: string
    generator_name: string
] {
    let required = ["category" "name" "type" "source"]
    for key in $required {
        if ($client | get -o $key) == null {
            error make { msg: $"client entry missing required key '($key)': ($client | to nuon)" }
        }
    }
    if not ($client.type in ["openapi" "graphql"]) {
        error make { msg: $"unsupported type '($client.type)' for client '($client.name)' — must be 'openapi' or 'graphql'" }
    }

    let category_dir = ($out_dir | path join $client.category)
    mkdir $category_dir

    let out_path = ($category_dir | path join $"($client.name).nu")
    let flags_str = (build-flag-args ($client.flags? | default {}))
    let source_lit = ($client.source | to nuon)
    let out_lit = ($out_path | to nuon)
    let gen_lit = ($generator_path | to nuon)

    let cmd = $"use ($gen_lit); ($generator_name) ($client.type) ($source_lit) -o ($out_lit) ($flags_str)"
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

# Overwrite `list_path` with a markdown document listing every client in `clients`,
# one table per category. Fully owned by this script — do not edit by hand.
def write-list-file [list_path: path, clients: list, out_dir: path] {
    let count = ($clients | length)
    let header = $"# Available clients\n\n_This file is auto-generated from `clients.yaml` by `scripts/generate.nu`. Do not edit by hand._\n\nThis collection contains ($count) clients.\n"
    let body = (render-clients-sections $clients $out_dir)
    $header + "\n" + $body + "\n" | save -f $list_path
}

def render-clients-sections [clients: list, out_dir: path]: nothing -> string {
    $clients
    | group-by category
    | transpose category entries
    | sort-by category
    | each {|grp|
        let rows = ($grp.entries | each {|c|
            {
                Client: $"[($c.name)]\(($out_dir)/($c.category)/($c.name).nu\)"
                Type: $c.type
                Source: $"<($c.source)>"
            }
        })
        $"## ($grp.category)\n\n" + ($rows | to md --pretty)
    }
    | str join "\n\n"
}
