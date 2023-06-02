# show help by default
default:
    @just --list --justfile {{ justfile() }}

lint:
    ansible-lint .
