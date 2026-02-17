#!/bin/bash
set -uo pipefail

CMD="${1:-}"

case "$CMD" in
    push)
        echo "ERROR: git push is blocked in this sandbox." >&2
        echo "Push operations are disabled in this sandbox." >&2
        exit 1
        ;;
    send-email)
        echo "ERROR: git send-email is blocked in this sandbox." >&2
        exit 1
        ;;
    request-pull)
        echo "ERROR: git request-pull is blocked in this sandbox." >&2
        exit 1
        ;;
    remote)
        SUBCMD="${2:-}"
        case "$SUBCMD" in
            add|set-url|remove|rename)
                echo "ERROR: git remote $SUBCMD is blocked in this sandbox." >&2
                exit 1
                ;;
        esac
        ;;
    lfs)
        SUBCMD="${2:-}"
        if [ "$SUBCMD" = "push" ]; then
            echo "ERROR: git lfs push is blocked in this sandbox." >&2
            exit 1
        fi
        ;;
esac

/usr/local/lib/git-bin/git "$@"
EXIT_CODE=$?

if [ "$1" = "checkout" ] && echo "$PWD" | grep -q '/workspace/odoo'; then
    source /home/claude/odoo-venv/bin/activate
    pip install --quiet "setuptools<81"
    for req in /workspace/*/requirements.txt; do
        [ -f "$req" ] && pip install --quiet -r "$req"
    done
fi

exit $EXIT_CODE
