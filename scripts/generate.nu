#!/usr/bin/env nu

# Generate the clients listed in `clients.yaml`.
#
# By default, only clients whose output file does not yet exist are generated.
# Pass `--force` to regenerate regardless.
#
# Examples:
#   nu scripts/generate.nu                     # generate every missing client
#   nu scripts/generate.nu --force             # regenerate every client
#   nu scripts/generate.nu --name countries    # generate `countries` if missing
#   nu scripts/generate.nu --timeout 5min      # allow 5 minutes per client
#
# Clients are written flat to `<out-dir>/<name>.nu`. Names and sources must
# both be globally unique (validated at startup).
#
# The generator must be available at the path passed via --generator
# (default: ./_generator). Locally:
#   git clone https://github.com/lassoColombo/nu-http-client-generator _generator

def main [
    --name: string                           # restrict to a single client by name
    --config: path = "clients.yaml"          # path to the registry file
    --generator: path = "_generator"         # path to the nu-http-client-generator directory
    --out-dir: path = "clients"              # where to write generated `.nu` files
    --jobs: int = 8                          # par-each thread count
    --timeout: string = "1min"               # abort a single client generation after this long (e.g. 90sec, 5min)
    --force                                  # regenerate even if the output file already exists
] {
    if not ($config | path exists) {
        error make { msg: $"config file not found: ($config)" }
    }
    let clients = (open $config | get -o clients | default [])
    if ($clients | is-empty) {
        print $"No clients defined in ($config). Nothing to do."
        return
    }
    let timeout = (try { $timeout | into duration } catch {
        error make { msg: $"invalid --timeout '($timeout)': expected a duration like 90sec or 5min" }
    })
    if $timeout <= 0sec {
        error make { msg: $"invalid --timeout '($timeout)': must be positive" }
    }

    validate-unique-sources $clients
    validate-unique-names $clients

    if not (($generator | path join "mod.nu") | path exists) {
        error make { msg: $"generator not found at ($generator). Clone it with: git clone https://github.com/lassoColombo/nu-http-client-generator ($generator)" }
    }

    let matched = if $name != null and $name != "" {
        let m = ($clients | where name == $name)
        if ($m | is-empty) {
            error make { msg: $"no client named '($name)'" }
        }
        $m
    } else {
        $clients
    }

    mkdir $out_dir

    let selected = if $force {
        $matched
    } else {
        $matched | where {|c| not (($out_dir | path join $"($c.name).nu") | path exists) }
    }
    let skipped = (($matched | length) - ($selected | length))
    if $skipped > 0 {
        print $"Skipping ($skipped) existing client\(s\); pass --force to regenerate."
    }

    print $"Generating ($selected | length) client\(s\) into ($out_dir) with ($jobs) job\(s\)..."
    let generator_path = ($generator | into string)
    let generator_name = ($generator | path basename)

    let results = (
        $selected
        | par-each --threads $jobs {|c|
            try {
                generate-one $c $out_dir $generator_path $generator_name $timeout
                print $"  ✓ ($c.name)"
                { ok: true, name: $c.name }
            } catch {|e|
                let msg = ($e.msg? | default ($e | to nuon))
                print -e $"  ✗ ($c.name): ($msg)"
                { ok: false, name: $c.name, error: $msg }
            }
        }
    )

    let failures = ($results | where ok == false)
    if not ($failures | is-empty) {
        print -e ""
        print -e $"($failures | length) of ($selected | length) client\(s\) failed."
        # Exit non-zero so CI surfaces the failure; commit step runs `if: always()`
        # so any partial progress is still captured.
        exit 1
    }
    print "Done."
}

# Sources must be globally unique: two entries pointing at the same spec
# would generate identical clients under different names.
def validate-unique-sources [clients: list] {
    let dupes = (
        $clients
        | group-by source
        | transpose source entries
        | where ($it.entries | length) > 1
    )
    if not ($dupes | is-empty) {
        let details = ($dupes | each {|d|
            let names = ($d.entries | get name | str join ", ")
            $"  - ($d.source) → ($names)"
        } | str join "\n")
        error make { msg: $"client sources must be unique — found duplicates:\n($details)" }
    }
}

# Names must be globally unique (flat layout: clients/<name>.nu) AND must
# avoid characters that prevent `use clients/<name>.nu` from parsing —
# spaces, parens, brackets. Underscores and ampersands are tolerated for
# backward compatibility with existing entries (they parse-load when the
# path is quoted).
def validate-unique-names [clients: list] {
    let dupes = (
        $clients
        | group-by name
        | transpose name entries
        | where ($it.entries | length) > 1
    )
    if not ($dupes | is-empty) {
        let names = ($dupes | get name | str join ", ")
        error make { msg: $"client names must be unique — found duplicates: ($names)" }
    }
    let bad = ($clients | where ($it.name =~ '[ ()\[\]{}]'))
    if not ($bad | is-empty) {
        let names = ($bad | get name | str join ", ")
        error make { msg: $"client names must not contain spaces, parens, or brackets — invalid: ($names)" }
    }
}

def generate-one [
    client: record
    out_dir: path
    generator_path: string
    generator_name: string
    timeout: duration
] {
    let required = ["name" "source"]
    for key in $required {
        if ($client | get -o $key) == null {
            error make { msg: $"client entry missing required key '($key)': ($client | to nuon)" }
        }
    }

    let out_path = ($out_dir | path join $"($client.name).nu")
    let flags_str = (build-flag-args ($client.flags? | default {}))
    let source_lit = ($client.source | to nuon)
    let out_lit = ($out_path | to nuon)
    let gen_lit = ($generator_path | to nuon)

    let cmd = $"use ($gen_lit); ($generator_name) ($source_lit) -o ($out_lit) ($flags_str)"

    # A killed generator may leave a truncated file behind, so keep a copy of
    # the previous output and put it back rather than losing a good client to
    # a transient hang.
    let backup = if ($out_path | path exists) {
        let b = (mktemp -t nu-http-client-prev-XXXXXX)
        cp $out_path $b
        $b
    } else { null }

    let result = (run-with-timeout $cmd $timeout)

    if $result.timed_out {
        if $backup != null { mv -f $backup $out_path } else { rm -f $out_path }
        error make { msg: $"timed out after ($timeout)" }
    }
    if $backup != null { rm -f $backup }
    if $result.exit_code != 0 {
        let detail = ($result.stderr | str trim | lines | last 5 | str join "\n")
        error make { msg: $"generator exited ($result.exit_code): ($detail)" }
    }
}

# Run `nu -c <cmd>` in a background job, killing it if it outlives `timeout`.
#
# `job kill` terminates the job's child processes too, so an aborted generation
# leaves nothing running. The job writes its `complete` record to a temp file
# because job mailboxes are shared per-thread and would interleave under
# `par-each`; polling `job list` keeps each waiter independent.
def run-with-timeout [cmd: string, timeout: duration]: nothing -> record {
    let tmp = (mktemp -t nu-http-client-gen-XXXXXX)
    let job = (job spawn { nu -c $cmd | complete | to nuon | save -f $tmp })

    mut waited = 0ms
    mut timed_out = false
    loop {
        if not ($job in (job list | get id)) { break }
        if $waited >= $timeout {
            job kill $job
            $timed_out = true
            break
        }
        sleep 100ms
        $waited = $waited + 100ms
    }

    if $timed_out {
        rm -f $tmp
        return { stdout: "", stderr: "", exit_code: 124, timed_out: true }
    }
    let result = (open $tmp | from nuon)
    rm -f $tmp
    $result | insert timed_out false
}

# Render a record of {flag-name: value} pairs as CLI args.
# Values are encoded with `to nuon` so lists/records round-trip safely.
# Booleans become switches (only when true).
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
