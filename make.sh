#!/bin/bash

function _die() {
    echo "$2" > /dev/stderr
    exit "$1"
}

if [[ -e "$2" ]]; then
    for arg in "$@"; do
        ./make.sh "$arg" || die $? "[FATAL] Something happened."
    done
    exit $?
fi



case "$1" in
    pr | submit) 
        VER="$(tomlq -r .package.version src/typst.toml)"
        universe_dir_pref=../typst-packages-universe/packages/preview/shipshop
        universe_dir=../typst-packages-universe/packages/preview/shipshop/"$VER"
        [[ -d ../typst-packages-universe ]] &&
        [[ -d "$universe_dir_pref" ]] &&
        # [[ ! -d "$universe_dir" ]] &&
        rsync --dry-run -auv ./src/ --exclude shipshop.pdf "$universe_dir/" &&
        echo "Seems that we can do this!" &&
        echo '    ' rsync -auv ./src/ --exclude shipshop.pdf "$universe_dir/"

        ;;
    src/ )
        echo "[INFO] This is a simple project requiring no building at all."
        ;;
    examples/*.typ )
        command -v typst || _die 1 "ERROR: Make target 'install_local' requires typst"
        typst c --root . "$1"
        ;;
    docs/*.typ )
        typst c --root . "$1"
        ;;
    install_local | i )
        command -v tomlq || _die 1 "ERROR: Make target 'install_local' requires tomlq"
        command -v rsync || _die 1 "ERROR: Make target 'install_local' requires rsync"
        VER="$(tomlq -r .package.version src/typst.toml)"
        rsync -auv --delete --mkpath src/ "$HOME"/.local/share/typst/packages/local/shipshop/"$VER"
        ;;
    fast | f )
        ./make.sh install_local
        ;;
    '' )
        ./make.sh i
        ;;
    * )
        die 1 "WARNING: No rule to make target '$1'"
        ;;
esac
