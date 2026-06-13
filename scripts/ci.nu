#!/usr/bin/env nu

# Git plumbing the registry / collection workflows run after populate /
# generate / template. Lives here, not in the workflow YAML, so the same
# commands can be invoked locally when debugging a CI run.
#
# Subcommands:
#   commit-and-push   — stage clients/, clients.yaml, README.md; commit if there's a diff; push
#   tag-datever       — tag the new HEAD with v<UTC-date>[.N] and push the tag

def main [] {
    print "usage: nu scripts/ci.nu <commit-and-push|tag-datever> [flags]"
    print "       nu scripts/ci.nu commit-and-push --message <msg>"
    print "       nu scripts/ci.nu tag-datever --pre-sha <sha>"
}

def "main commit-and-push" [
    --message: string = "chore: regenerate clients"
    --user-name: string = "github-actions[bot]"
    --user-email: string = "41898282+github-actions[bot]@users.noreply.github.com"
    --paths: list<string> = [clients/ clients.yaml CLIENTS.md README.md]
] {
    ^git config user.name $user_name
    ^git config user.email $user_email
    ^git add -A ...$paths

    let staged = (^git diff --cached --quiet | complete)
    if $staged.exit_code == 0 {
        print "No changes — nothing to commit."
        return
    }

    ^git commit -m $message
    ^git push
}

def "main tag-datever" [
    --pre-sha: string                   # HEAD sha *before* the commit step ran; skip tagging if HEAD didn't move
    --remote: string = "origin"
] {
    if ($pre_sha | is-empty) {
        error make { msg: "--pre-sha is required" }
    }
    let head = (^git rev-parse HEAD | str trim)
    if $head == $pre_sha {
        print "No new commit produced — skipping tag."
        return
    }

    ^git fetch --tags

    let base = $"v(date now | date to-timezone UTC | format date '%Y.%m.%d')"
    mut tag = $base
    mut n = 1
    while (tag-exists $tag $remote) {
        $n = $n + 1
        $tag = $"($base).($n)"
    }

    ^git tag -a $tag -m $tag
    ^git push $remote $tag
    print $"Tagged ($tag)"
}

# A tag is "taken" if it exists locally OR on the remote — we check both so
# a partially-pushed previous run can't lead us to reuse a tag.
def tag-exists [tag: string, remote: string]: nothing -> bool {
    let local = (^git rev-parse -q --verify $"refs/tags/($tag)" | complete)
    if $local.exit_code == 0 { return true }
    let upstream = (^git ls-remote --exit-code --tags $remote $"refs/tags/($tag)" | complete)
    $upstream.exit_code == 0
}
