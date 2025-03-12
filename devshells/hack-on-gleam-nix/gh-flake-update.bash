# This script is run daily on CI.
# It tries to build the latest gleam source with the current rust version.
# It will only update the gleam input and try to run `gleam --version`
# If successful, a new PR updating only flake.lock will be automatically created and merged.
# Otherwise a new Issue will be created indicating the gleam revision that failed to build.

set -e -u -o pipefail

if test -z "${CI:-}"; then
  echo "This program is inteded to be run as part of CI."
  echo "If you still wish to run it, make sure all environment variables are set."
  exit 1
fi

echo "Running with CI=${CI} OUT=${OUT} ASSIGNEE=${ASSIGNEE}"

# Generate markdown code block with the result of running a command
blockquote='```'
singlequote='`'
function mdcode() {
  local blocktype="$1"
  shift
  local outfile="$1"
  shift
  local title="$1"
  shift
  test -z "$1" && return 1
  (
    echo "${title}"
    echo -ne "\n\n${blockquote}${blocktype}\n"
    "${@}"
    echo -ne "${blockquote}\n\n"
  ) | tee -a "$outfile"
}

# shellcheck disable=SC2317
function callback() {
  show-gleam-version | tee "$OUT"/previous-gleam.json
}
mdcode json "$OUT/output.md" "Updating FROM Gleam:" callback

# shellcheck disable=SC2317
function callback() {
  show-rust-version | tee "$OUT"/previous-rust.json
}
mdcode json "$OUT/output.md" "Using Rust:" callback

# shellcheck disable=SC2317
function callback() {
  nix flake update gleam --accept-flake-config 2>&1 | tee "$OUT"/flake-update.out || true
}
# shellcheck disable=SC2016
mdcode shell "$OUT/output.md" "Running ${singlequote}nix flake update gleam${singlequote}" callback

changes="$(git status -s | grep -c 'M ')"
if test "0" -eq "$changes"; then
  echo "Nothing changed. Doing nothing."
  exit 0
fi

# shellcheck disable=SC2317
function callback() {
  nix develop .#hack-on-gleam-nix --accept-flake-config -c show-gleam-version | tee "$OUT"/next-gleam.json
}
mdcode shell "$OUT/output.md" "Will update to Gleam:" callback

# shellcheck disable=SC2317
function callback() {
  nix run .#gleam --accept-flake-config --print-build-logs -- --version 2>"$OUT/build.out"
  if test "0" -eq "$?"; then
    mv "$OUT/build.out" "$OUT/success.out"
  else
    echo "*FAILURE*"
    mv "$OUT/build.out" "$OUT/failure.out"
  fi
}

# shellcheck disable=SC2016
mdcode shell "$OUT/output.md" "Building Gleam and running ${singlequote}gleam --version${singlequote}:" callback

##
# Preparing for generating a pull-request
##
function git_commit() {
  git status -s | grep 'M ' | cut -d 'M' -f 2 | xargs git add
  git commit --no-post-rewrite --no-signoff --no-verify --trailer "request-checks:true" --no-edit --cleanup=verbatim "${@}"
}

prev_gleam_rev="$(jq -r .revision "$OUT"/previous-gleam.json)"
prev_gleam_ver="$(jq -r .version "$OUT"/previous-gleam.json)"
prev_rust_ver="$(jq -r .version "$OUT"/previous-rust.json)"
next_gleam_rev="$(jq -r .revision "$OUT"/next-gleam.json)"
next_gleam_ver="$(jq -r .version "$OUT"/next-gleam.json)"

if test -f "$OUT/success.out"; then
  status_label="success"
  status_emoji="🎉"
else
  status_label="failure"
  status_emoji="💥"
fi

gh label list --search 'rust-|gleam-' --json name --jq '.[].name' >"$OUT/labels"
grep "rust-${prev_rust_ver}" "$OUT/labels" || gh label create "rust-${prev_rust_ver}"
grep "gleam-${prev_gleam_ver}" "$OUT/labels" || gh label create "gleam-${prev_gleam_ver}"
grep "gleam-${next_gleam_ver}" "$OUT/labels" || gh label create "gleam-${next_gleam_ver}"

arrow="${prev_gleam_ver} (${prev_gleam_rev}) -> ${next_gleam_ver} (${next_gleam_rev})"
title="[gleam $status_emoji] $arrow"
echo -ne "${title}\n\n" | tee -a "$OUT/commit-message.md"
echo -ne "*${status_label}*\n" | tee -a "$OUT/commit-message.md"
mdcode json "$OUT/commit-message.md" "Previous Gleam:" cat "$OUT"/previous-gleam.json
mdcode json "$OUT/commit-message.md" "Next Gleam:" cat "$OUT"/next-gleam.json
mdcode json "$OUT/commit-message.md" "With Rust:" cat "$OUT"/previous-rust.json

branch="update-gleam/${prev_gleam_rev}-to-${next_gleam_rev}"
git checkout -b "$branch"
git_commit -F "$OUT/commit-message.md"
git push origin "$branch:$branch" --force

pr_title="Update Gleam $arrow $status_emoji"
gh pr create \
  --title "${pr_title}" --body-file "$OUT/output.md" \
  --base main --head "$branch" \
  --label "${status_label},gleam-${next_gleam_ver},rust-${prev_rust_ver}" \
  --assignee "$ASSIGNEE" |
  tee "$OUT/pr-url"
pr_url="$(<"$OUT/pr-url")"

if test -f "$OUT/success.out"; then
  gh pr merge "${pr_url}" --auto --delete-branch --rebase
else

  if test -f "$OUT/failure.out"; then
    mdcode shell "$OUT/failure.md" "##### Nix build logs (*FAILURE*)" cat "$OUT"/failure.out
  fi
  gh pr comment "${pr_url}" --body-file "$OUT/failure.md"
  gh pr comment "${pr_url}" --body "@${ASSIGNEE}, maybe this can be fixed by updating the URL for ${singlequote}inputs.rust-manifest${singlequote} on ${singlequote}flake.nix${singlequote}.\n\nBut I have not learned how to do that automatically."
fi
