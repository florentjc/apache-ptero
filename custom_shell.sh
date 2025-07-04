#!/bin/bash
echo "Welcome to the limited shell."
current_dir="$HOME"
while true; do
  read -p "$current_dir$ " cmd args
  case "$cmd" in
    cd)
      # change directory if valid and allowed
      if [ -d "$args" ]; then
        # empêche de sortir de $HOME (exemple)
        if [[ "$args" == /* ]] && [[ "$args" != "$HOME"* ]]; then
          echo "Access denied"
        else
          cd "$args" && current_dir=$(pwd)
        fi
      else
        echo "No such directory"
      fi
      ;;
    ls|cat|echo|exit|php)
      $cmd $args
      ;;
    *)
      echo "Command not allowed."
      ;;
  esac
done
