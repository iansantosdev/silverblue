# shellcheck shell=bash

HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"

if [ "$(id -u)" -ne 0 ] && [[ -d "$HOMEBREW_PREFIX" ]]; then
    export HOMEBREW_PREFIX="$HOMEBREW_PREFIX"
    export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
    export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew"

    case ":$PATH:" in
        *":$HOMEBREW_PREFIX/bin:"*) ;;
        *) export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin${PATH:+:$PATH}" ;;
    esac

    export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
    export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
fi
