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
    )

    let tmp = $"($out).tmp"
    { clients: $entries } | to yaml | save -f --raw $tmp
    mv $tmp $out
    print $"Wrote ($entries | length) entries to ($out)."
}

# Match the slugging the mirror used: lowercase, `:` and `.` → `-`.
def slug [s: string]: nothing -> string {
    $s | str downcase | str replace --all ':' '-' | str replace --all '.' '-'
}
