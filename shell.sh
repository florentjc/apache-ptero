#!/bin/bash
cd /home/container || exit 1

set +e

BASE_DIR="/home/container"
LOG_FILE="$BASE_DIR/tmp/shell.log"

print_err() {
    echo -e "\033[31m$*\033[0m"
}

print_ok() {
    echo -e "\033[32m$*\033[0m"
}

show_exit() {
    local code="$1"
    if [ "$code" -eq 0 ]; then
        print_ok "[exit: 0]"
    else
        print_err "[exit: $code]"
    fi
}

safe_path() {
    local input="$1"
    local resolved

    if [ -z "$input" ]; then
        resolved="$(pwd)"
    elif [[ "$input" == /* ]]; then
        resolved="$(realpath -m -- "$input" 2>/dev/null || echo "")" || true
    else
        resolved="$(realpath -m -- "$(pwd)/$input" 2>/dev/null || echo "")" || true
    fi

    if [[ -n "$resolved" && "$resolved" == "$BASE_DIR"* ]]; then
        printf '%s\n' "$resolved"
        return 0
    fi

    return 1
}

run_cmd() {
    local timeout_s="$1"
    shift
    timeout "$timeout_s" "$@" 2>&1 | tee -a "$LOG_FILE"
    local code=${PIPESTATUS[0]}
    show_exit "$code"
    return "$code"
}

handle_command() {
    case "$1" in
        cd)
            shift
            TARGET="${1:-$BASE_DIR}"
            REAL_DIR=$(safe_path "$TARGET") || {
                print_err "Access denied: $TARGET"
                return 1
            }
            cd "$REAL_DIR" || {
                print_err "Cannot cd to $TARGET"
                return 1
            }
            pwd
            ;;
        pwd)
            pwd
            ;;
        ls)
            shift
            if [ -z "$1" ]; then
                run_cmd 15 ls -la .
            else
                REAL_TARGET=$(safe_path "$1") || {
                    print_err "Access denied: $1"
                    return 1
                }
                run_cmd 15 ls -la "$REAL_TARGET"
            fi
            ;;
        cat)
            shift
            REAL_FILE=$(safe_path "$1") || {
                print_err "Access denied: $1"
                return 1
            }
            run_cmd 15 cat "$REAL_FILE"
            ;;
        head)
            shift
            REAL_FILE=$(safe_path "$1") || {
                print_err "Access denied: $1"
                return 1
            }
            run_cmd 15 head "$REAL_FILE"
            ;;
        tail)
            shift
            REAL_FILE=$(safe_path "$1") || {
                print_err "Access denied: $1"
                return 1
            }
            run_cmd 15 tail "$REAL_FILE"
            ;;
        touch)
            shift
            REAL_FILE=$(safe_path "$1") || {
                print_err "Access denied: $1"
                return 1
            }
            run_cmd 15 touch "$REAL_FILE"
            ;;
        mkdir)
            shift
            REAL_DIR=$(safe_path "$1") || {
                print_err "Access denied: $1"
                return 1
            }
            run_cmd 15 mkdir -p "$REAL_DIR"
            ;;
        cp)
            shift
            [ -n "$1" ] && [ -n "$2" ] || { print_err "Usage: cp <src> <dest>"; return 1; }
            SRC=$(safe_path "$1") || { print_err "Access denied: $1"; return 1; }
            DST=$(safe_path "$2") || { print_err "Access denied: $2"; return 1; }
            run_cmd 30 cp -r "$SRC" "$DST"
            ;;
        mv)
            shift
            [ -n "$1" ] && [ -n "$2" ] || { print_err "Usage: mv <src> <dest>"; return 1; }
            SRC=$(safe_path "$1") || { print_err "Access denied: $1"; return 1; }
            DST=$(safe_path "$2") || { print_err "Access denied: $2"; return 1; }
            run_cmd 30 mv "$SRC" "$DST"
            ;;
        rm)
            shift
            [ $# -gt 0 ] || { print_err "Usage: rm <file...>"; return 1; }
            for file in "$@"; do
                REAL_FILE=$(safe_path "$file") || {
                    print_err "Access denied: $file"
                    continue
                }
                run_cmd 30 rm -rf "$REAL_FILE"
            done
            ;;
        find)
            shift
            REAL_DIR=$(safe_path "${1:-.}") || {
                print_err "Access denied: ${1:-.}"
                return 1
            }
            if [ -n "$2" ]; then
                run_cmd 30 find "$REAL_DIR" -name "$2"
            else
                run_cmd 30 find "$REAL_DIR"
            fi
            ;;
        grep)
            shift
            [ -n "$1" ] && [ -n "$2" ] || { print_err "Usage: grep <text> <file>"; return 1; }
            PATTERN="$1"
            REAL_FILE=$(safe_path "$2") || {
                print_err "Access denied: $2"
                return 1
            }
            run_cmd 30 grep -n "$PATTERN" "$REAL_FILE"
            ;;
        php)
            shift
            [ $# -gt 0 ] || { print_err "Usage: php <args>"; return 1; }
            run_cmd 30 php "$@"
            ;;
        npm)
            shift
            [ $# -gt 0 ] || { print_err "Usage: npm <args>"; return 1; }
            run_cmd 90 npm "$@"
            ;;
        composer)
            shift
            [ $# -gt 0 ] || { print_err "Usage: composer <args>"; return 1; }
            run_cmd 180 composer "$@"
            ;;
        node)
            shift
            [ $# -gt 0 ] || { print_err "Usage: node <args>"; return 1; }
            run_cmd 30 node "$@"
            ;;
        npx)
            shift
            [ $# -gt 0 ] || { print_err "Usage: npx <tool> [args]"; return 1; }
            run_cmd 90 npx --no-install "$@"
            ;;
        artisan)
            shift
            [ $# -gt 0 ] || { print_err "Usage: artisan <command>"; return 1; }
            run_cmd 90 php artisan "$@"
            ;;
        echo)
            shift
            echo "$*"
            ;;
        help)
            cat <<'HELP'
Web shell ready.

Useful commands:
- cd <folder>          : go to a folder
- pwd                  : show the current folder
- ls [folder]          : list files
- cat <file>           : show a file
- head <file>          : show the beginning of a file
- tail <file>          : show the end of a file
- touch <file>         : create a file
- mkdir <folder>       : create a folder
- cp <src> <dest>      : copy files or folders
- mv <src> <dest>      : move or rename files or folders
- rm <file...>         : delete files or folders
- find [dir] [pattern] : search for files
- grep <text> <file>   : search text in a file
- php ...              : run PHP commands
- artisan ...          : run Laravel commands
- composer ...         : manage PHP dependencies
- node ...             : run Node.js commands
- npm ...              : manage Node dependencies and scripts
- npx <tool> [...]     : run a local Node tool
HELP
            ;;
        *)
            print_err "Unknown command: $*"
            echo "Type 'help' for list"
            ;;
    esac
}

echo "Shell ready - Type 'help'"

while true; do
    if IFS= read -r line 2>/dev/null; then
        read -r -a args <<< "$line"
        if [ ${#args[@]} -gt 0 ]; then
            handle_command "${args[@]}"
        fi
    else
        break
    fi
done
