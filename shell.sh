#!/bin/bash
cd /home/container

set +e

handle_command() {
    case "$1" in
        cd)
            shift
            TARGET_DIR="/home/container/$*"
            REAL_DIR=$(realpath "$TARGET_DIR" 2>/dev/null || echo "") || true
            if [[ "$REAL_DIR" == /home/container/* ]]; then
                cd "$REAL_DIR" && echo "$(pwd)" || echo -e "\033[31mCannot cd to $*\033[0m"
            else
                cd /home/container
                echo "$(pwd)"
            fi
            ;;
        rm)
            shift
            for file in "$@"; do
                REAL_FILE=$(realpath "$file" 2>/dev/null || echo "") || true
                if [[ "$REAL_FILE" == /home/container/* ]]; then
                    rm -rf -- "$REAL_FILE" && echo "Deleted: $REAL_FILE" || echo -e "\033[31mDelete error: $file\033[0m"
                else
                    echo -e "\033[31mAccess denied: $file\033[0m"
                fi
            done
            ;;
        ls)
            shift
            if [ -z "$*" ]; then
                ls -la . 2>/dev/null || ls .
            else
                REAL_TARGET=$(realpath "$*" 2>/dev/null || echo "") || true
                if [[ "$REAL_TARGET" == /home/container/* ]]; then
                    ls -la "$*" 2>/dev/null || ls "$*"
                else
                    echo -e "\033[31mAccess denied: $*\033[0m"
                fi
            fi
            ;;
        php|npm|composer)
            CMD="$1"
            shift
            case "$CMD" in
                php)
                    timeout 30 bash -c "php $*" 2>/dev/null && echo "php OK" || echo -e "\033[31mphp error\033[0m"
                    ;;
                npm)
                    timeout 60 bash -c "npm $*" 2>/dev/null && echo "npm OK" || echo -e "\033[31mnpm error\033[0m"
                    ;;
                composer)
                    timeout 120 bash -c "composer $*" 2>/dev/null && echo "composer OK" || echo -e "\033[31mcomposer error\033[0m"
                    ;;
            esac
            ;;
        echo)
            shift
            echo "$*"
            ;;
        help)
            echo "Available commands:"
            echo "- cd <dir>      : change directory (safe)"
            echo "- ls [dir]      : list files (safe)"
            echo "- rm <files>    : delete files (safe)"
            echo "- php <args>    : run PHP (timeout 30s)"
            echo "- npm <args>    : run NPM (timeout 60s)"
            echo "- composer <args>: run Composer (timeout 120s)"
            echo "- echo <text>   : print text"
            echo "- help          : this help"
            ;;
        pwd)
            echo "$(pwd)"
            ;;
        *)
            echo -e "\033[31mUnknown command: $*\033[0m"
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
    fi
done