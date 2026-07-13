#!/usr/bin/env nu

# Fetch the apis.guru directory and rewrite `clients.yaml` from it.
#
# Used only by the update-registry action. Forkers building their own
# collection should NOT run this — it overwrites clients.yaml in place.
#
# Writes atomically via `<out>.tmp` + `mv`.

const APIS_GURU_LIST = "https://api.apis.guru/v2/list.json"

def main [
    --out: path = "clients.yaml"
] {
    print $"Fetching ($APIS_GURU_LIST)..."
    let raw = (http get $APIS_GURU_LIST)
    let entries = (
        $raw
        | transpose key entry
        | each {|row|
            let pref = ($row.entry.preferred? | default null)
            if $pref == null { return null }
            let ver = ($row.entry.versions | get -o $pref)
            if $ver == null { return null }
            let url = ($ver | get -o swaggerUrl | default ($ver | get -o openapiUrl))
            if $url == null { return null }
            { name: (slug $row.key), source: $url }
        }
        | compact
        | sort-by name
        | dedup-names
    )

    let tmp = $"($out).tmp"
    { clients: $entries } | to yaml | save -f --raw $tmp
    mv $tmp $out
    print $"Wrote ($entries | length) entries to ($out)."
}

# Match the slugging the mirror used: lowercase, `:` and `.` → `-`. Also strip
# characters that break `use clients/<name>.nu` parsing — spaces become `-`,
# parens/brackets are dropped — so names pass validate-unique-names in generate.nu.
# Slugging can map distinct upstream keys to the same name (e.g. `Marketplace-APIs`
# and `Marketplace-APIs-` both trim to `marketplace-apis`). Keep the first occurrence
# and suffix later collisions with `-2`, `-3`, … so names stay globally unique.
def dedup-names []: list -> list {
    $in | reduce --fold { seen: {}, out: [] } {|c, acc|
        let n = $c.name
        let count = ($acc.seen | get -o $n | default 0)
        let name = (if $count == 0 { $n } else { $"($n)-($count + 1)" })
        {
            seen: ($acc.seen | upsert $n ($count + 1))
            out: ($acc.out | append ($c | update name $name))
        }
    } | get out
}

def slug [s: string]: nothing -> string {
    $s
    | str lowercase
    | str replace --all ':' '-'
    | str replace --all '.' '-'
    | str replace --all ' ' '-'
    | str replace --all --regex '[()\[\]{}]' ''
    | str replace --all --regex '-+' '-'
    | str trim --char '-'
}
