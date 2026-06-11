#!/usr/bin/env nu

# Diff `clients.yaml` between two git refs and print the actions to take.
#
# Output is two lines, each space-separated:
#   regen: <name> <name> ...     # clients to (re)generate
#   delete: <path> <path> ...    # generated files to remove
#
# Either list may be empty. If the `before` ref doesn't have `clients.yaml`
# (first commit, force-push, etc.), every current entry is treated as new.
#
# Example:
#   nu scripts/diff-clients.nu HEAD~1 HEAD

def main [
    before: string
    after: string
    --config: string = "clients.yaml"
    --out-dir: string = "clients"
] {
    let after_yaml = (^git show $"($after):($config)" | complete)
    if $after_yaml.exit_code != 0 {
        error make { msg: $"could not read ($config) at ($after): ($after_yaml.stderr)" }
    }
    let after_clients = (parse-yaml $after_yaml.stdout)

    let before_yaml = (^git show $"($before):($config)" | complete)
    if $before_yaml.exit_code != 0 {
        # `before` lacks the file — treat every current client as new.
        let names = ($after_clients | get name | str join " ")
        print $"regen: ($names)"
        print "delete:"
        return
    }
    let before_clients = (parse-yaml $before_yaml.stdout)

    let before_by_name = ($before_clients | reduce -f {} {|c, acc| $acc | upsert $c.name $c })
    let after_by_name  = ($after_clients  | reduce -f {} {|c, acc| $acc | upsert $c.name $c })

    let regen = (
        $after_clients
        | where {|c|
            let prior = ($before_by_name | get -o $c.name)
            $prior == null or (($prior | to nuon) != ($c | to nuon))
        }
        | get name
    )

    let delete = (
        $before_clients
        | where {|c| ($after_by_name | get -o $c.name) == null }
        | each {|c| $"($out_dir)/($c.category)/($c.name).nu" }
    )

    print $"regen: ($regen | str join ' ')"
    print $"delete: ($delete | str join ' ')"
}

def parse-yaml [text: string]: nothing -> list {
    let registry = ($text | from yaml)
    let grouped = ($registry.clients? | default {})
    $grouped
    | transpose category entries
    | each {|grp| $grp.entries | each {|e| $e | insert category $grp.category } }
    | flatten
}
