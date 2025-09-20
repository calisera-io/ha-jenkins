#!/usr/bin/env bash
set -euo pipefail

check_first_line() {
    local FILE="$1"
    local STRING="$2"

    local FIRSTLINE=$(head -n 1 "$FILE")

    if [[ "$FIRSTLINE" == "$STRING" ]]; then
        return 0 
    else
        return 1   
    fi
}

check_first_line_starts_with() {
    local FILE="$1"
    local STRING="$2"

    local FIRSTLINE=$(head -n 1 "$FILE")

    if [[ "$FIRSTLINE" == $STRING* ]]; then
        return 0 
    else
        return 1   
    fi
}

check_last_non_empty_line() {
    local FILE="$1"
    local STRING="$2"

    local LASTLINE=$(awk 'NF {line=$0} END {print line}' "$FILE")

    if [[ "$LASTLINE" == "$STRING" ]]; then
        return 0   
    else
        return 1  
    fi
}

check_private_key_format() {
    local FILE="$1"
    local FIRSTLINE="-----BEGIN OPENSSH PRIVATE KEY-----"
    local LASTLINE="-----END OPENSSH PRIVATE KEY-----"

    if check_first_line "$FILE" "$FIRSTLINE" && check_last_non_empty_line "$FILE" "$LASTLINE"; then
        return 0 
    else
        return 1  
    fi
}

check_authorized_keys_format() {
    local FILE="$1"
    local STRING="ssh-rsa"

    if check_first_line_starts_with "$FILE" "$STRING"; then
        return 0 
    else
        return 1  
    fi
}

check_file_perms() {
    local FILE="$1"
    local EXPECTED="$2"
    local PERMS=$(stat -c '%a' "$FILE" 2>/dev/null) || return 1

    if [[ "$PERMS" == "$EXPECTED" ]]; then
        return 0  
    else
        return 1 
    fi
}

check_override_conf() {
    local FILE="$1"
    if ! grep -q After=network-online.target < <(grep -A2 'Unit' $FILE); then
        return 1
    fi
    if ! grep -q Wants=network-online.target < <(grep -A2 'Unit' $FILE); then
        return 1
    fi
    if ! grep -qE '^Environment="JENKINS_ADMIN_ID=' "$FILE"; then
        return 1
    fi
    if ! grep -qE '^Environment="JENKINS_ADMIN_PASSWORD=' "$FILE"; then
        return 1
    fi
    if  [ $(wc -l < <(grep -A3 'Service' "$FILE")) -gt 3 ]; then
        if ! grep -qE '^Environment="JAVA_OPTS=' "$FILE"; then
            return 1
        fi
    fi
    return 0
}