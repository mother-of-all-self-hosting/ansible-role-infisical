#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Slavi Pantaleev
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Exercises bin/compute-next-tag.sh against throwaway git repositories.
#
# Usage: bin/test-compute-next-tag.sh
#
# Every scenario creates a repository in a temporary directory, gives it role
# files and a release history, and then replays a series of merges through the
# real script, tagging as it goes just like the autotag workflow does. This
# repository is never touched and no network access is needed.

set -euo pipefail

script_under_test="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/compute-next-tag.sh"

failures=0
workdir=''

cleanup() {
	cd /
	if [ -n "$workdir" ]; then
		rm -rf "$workdir"
		workdir=''
	fi
}

trap cleanup EXIT

# The decoys are the lines that surround `infisical_version` in the real
# defaults/main.yml. Anything reading the version out of a Jinja expression
# instead of the leaf literal picks up `{{ infisical_version }}` verbatim, and
# anything matching `infisical_version` unanchored picks up the commented-out
# line or `infisical_versioning_note` instead of the value being released.
write_defaults() {
	local version="$1"

	cat > defaults/main.yml <<-YAML
		---
		infisical_identifier: infisical

		# An older pin, kept here as a comment for reference:
		# infisical_version: v0.43.19
		infisical_versioning_note: "infisical_version: not-a-version"

		# renovate: datasource=docker depName=infisical/infisical versioning=semver
		infisical_version: $version

		infisical_container_image: "{{ infisical_container_image_registry_prefix }}infisical/infisical:{{ infisical_container_image_tag }}"
		infisical_container_image_tag: "{{ infisical_version }}"
	YAML
}

# Starts a scenario with a repository at Infisical v0.162.20 which has already
# seen two releases of it (v0.162.20-0 and v0.162.20-1).
scenario() {
	echo "$1"

	cleanup
	workdir="$(mktemp -d)"

	mkdir -p "$workdir/bin" "$workdir/defaults" "$workdir/meta" "$workdir/tasks" "$workdir/templates"
	cp "$script_under_test" "$workdir/bin/"
	cd "$workdir"

	git init -q -b main .
	git config user.email 'test@example.com'
	git config user.name 'Test'
	git config commit.gpgsign false

	write_defaults v0.162.20
	printf 'placeholder\n' > meta/main.yml
	printf 'placeholder\n' > tasks/main.yml
	printf 'placeholder\n' > templates/env.j2
	printf 'placeholder\n' > README.md
	mkdir -p molecule/default
	printf 'placeholder\n' > molecule/default/verify.yml

	git add -A
	git commit -qm 'Initial commit'

	local release_number
	for release_number in 0 1; do
		git tag "v0.162.20-$release_number"
	done
}

# Applies a change, commits it, and tags whatever the script says it should be.
# Prints the tag, or nothing when the script decided against a release.
merge() {
	local change="$1" tag

	eval "$change"
	git add -A
	git commit -qm 'Merge'

	tag="$(bin/compute-next-tag.sh 2>/dev/null)"

	if [ -n "$tag" ]; then
		git tag "$tag"
	fi

	printf '%s' "$tag"
}

expect() {
	local description="$1" expected="$2" actual="$3"

	if [ "$actual" = "$expected" ]; then
		printf '  ok   | %s -> %s\n' "$description" "${actual:-no release}"
	else
		printf '  FAIL | %s -> expected %s, got %s\n' "$description" "${expected:-no release}" "${actual:-no release}"
		failures=$((failures + 1))
	fi
}

bump_version='write_defaults v0.162.21'
quote_version='write_defaults "\"v0.162.21\""'
revert_version='write_defaults v0.162.20'
edit_task="printf 'a task\n' >> tasks/main.yml"
edit_template="printf 'a line\n' >> templates/env.j2"
edit_meta="printf 'a platform\n' >> meta/main.yml"
edit_readme="printf 'documentation\n' >> README.md"
edit_molecule="printf 'an assertion\n' >> molecule/default/verify.yml"
edit_script="printf '# a comment\n' >> bin/compute-next-tag.sh"

# The two merge orders below apply the same updates and must each end up with
# every update released exactly once, whichever order they arrive in.

scenario 'A version bump merged before other role changes'
expect 'version bump' v0.162.21-0 "$(merge "$bump_version")"
expect 'task edit'    v0.162.21-1 "$(merge "$edit_task")"
expect 'template'     v0.162.21-2 "$(merge "$edit_template")"

scenario 'A version bump merged after other role changes'
expect 'task edit'    v0.162.20-2 "$(merge "$edit_task")"
expect 'version bump' v0.162.21-0 "$(merge "$bump_version")"

scenario 'Commits that do not affect the role'
expect 'README'   ''            "$(merge "$edit_readme")"
expect 'Molecule' ''            "$(merge "$edit_molecule")"
expect 'a script' ''            "$(merge "$edit_script")"
expect 'meta'     v0.162.20-2   "$(merge "$edit_meta")"

scenario 'Release numbers past 9'
for release_number in 2 3 4 5 6 7 8 9 10; do
	git tag "v0.162.20-$release_number"
done
expect 'a task' v0.162.20-11 "$(merge "$edit_task")"

scenario 'Reverting to an already released version'
merge "$bump_version" > /dev/null
# The role is now identical to what v0.162.20-1 already published, so there is
# nothing new to release.
expect 'a revert' ''            "$(merge "$revert_version")"

scenario 'Reverting to an already released version, with a change'
merge "$bump_version" > /dev/null
expect 'a revert' v0.162.20-2   "$(merge "$revert_version && $edit_task")"

# Renovate writes the version unquoted, but a human editing defaults/main.yml
# may well quote it. Both spellings name the same release.
scenario 'A quoted version value'
expect 'quoted bump' v0.162.21-0 "$(merge "$quote_version")"
expect 'task edit'   v0.162.21-1 "$(merge "$edit_task")"

# Nothing here changes `infisical_version` itself, so no new version is
# released - but a script reading the commented-out pin, the decoy variable or
# the Jinja-derived `infisical_container_image_tag` would announce v0.43.19,
# `not-a-version` or `{{ infisical_version }}` instead of v0.162.20.
scenario 'Decoys around the version in defaults/main.yml'
expect 'a task' v0.162.20-2 "$(merge "$edit_task")"

if [ "$failures" -gt 0 ]; then
	echo >&2 "$failures scenario(s) behaved unexpectedly"
	exit 1
fi

echo 'All scenarios behaved as expected'
