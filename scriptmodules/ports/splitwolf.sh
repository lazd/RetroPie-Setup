#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="splitwolf"
rp_module_desc="SplitWolf - 2-4 player split-screen Wolfenstein 3D / Spear of Destiny"
rp_module_licence="NONCOM https://bitbucket.org/linuxwolf6/split_wolf4sdl_pr/raw/2d0bbd80abee2d4b2ab11b45ab5d95773be0cbcc/license-mame.txt"
rp_module_section="opt"
rp_module_flags="dispmanx !mali !kms"

function depends_splitwolf() {
    getDepends libsdl2-dev libsdl2-mixer-dev
}

function sources_splitwolf() {
    gitPullOrClone "$md_build" git@bitbucket.org:lazd/split_wolf4sdl_pr.git
}

function _get_opts_splitwolf() {
    echo 'splitwolf-wolf3d VERSION_WOLF3D_SHAREWARE=y' # shareware v1.4
    echo 'splitwolf-wolf3d_apogee VERSION_WOLF3D_APOGEE=y' # 3d realms / apogee v1.4 full
    echo 'splitwolf-wolf3d_full VERSION_WOLF3D=y' # gt / id / activision v1.4 full
    echo 'splitwolf-sod VERSION_SPEAR=y' # spear of destiny
    # echo 'splitwolf-spear_demo VERSION_SPEAR_DEMO=y' # spear of destiny
}

function add_games_splitwolf() {
    local cmd="$1"
    declare -A games=(
        ['vswap.wl1']="Splitwolf - Wolf 3D Demo"
        ['vswap.wl6']="Splitwolf - Wolf 3D"
        ['vswap.sod']="Splitwolf - Spear of Destiny Ep 1"
        ['vswap.sd2']="Splitwolf - Spear of Destiny Ep 2"
        ['vswap.sd3']="Splitwolf - Spear of Destiny Ep 3"
        # ['vswap.sdm']="Splitwolf - Spear of Destiny Demo"
    )
    local game
    local wad

    for game in "${!games[@]}"; do
        wad="$romdir/ports/splitwolf/$game"
        if [[ -f "$wad" ]]; then
            addPort "$md_id" "splitwolf" "${games[$game]}" "$cmd" "$wad"
        fi
    done
}

function build_splitwolf() {
    mkdir "bin"
    local opt
    while read -r opt; do
        local bin="${opt%% *}"
        local defs="${opt#* }"
        make clean
        make $defs DATADIR="$romdir/ports/splitwolf/"
        mv $bin "bin/$bin"
        md_ret_require+=("bin/$bin")
    done < <(_get_opts_splitwolf)
}

function install_splitwolf() {
    # mkdir -p "$md_inst/share/man"
    # cp -Rv "$md_build/man6" "$md_inst/share/man/"
    cp -r lwmp bin/
    md_ret_files=('bin')
}

function game_data_splitwolf() {
    pushd "$romdir/ports/splitwolf"
    rename 'y/A-Z/a-z/' *
    popd
    if [[ ! -f "$romdir/ports/splitwolf/vswap.wl1" ]]; then
        cd "$__tmpdir"
        # Get shareware game data
        downloadAndExtract "http://maniacsvault.net/ecwolf/files/shareware/wolf3d14.zip" "$romdir/ports/splitwolf" "-j -LL"
    fi
    # if [[ ! -f "$romdir/ports/splitwolf/vswap.sdm" ]]; then
    #     cd "$__tmpdir"
    #     # Get shareware game data
    #     downloadAndExtract "http://maniacsvault.net/ecwolf/files/shareware/soddemo.zip" "$romdir/ports/splitwolf" "-j -LL"
    # fi
    if [[ ! -f "$romdir/ports/splitwolf/vswap.sod" ]]; then
        cd "$__tmpdir"
        # Get shareware game data
        downloadAndExtract "http://archive.org/download/DOS.Memories.Project.1980-2003/DOS.Memories.Project.1980-2003.zip/Spear%20Of%20Destiny%20%281992%29%28Formgen%29.zip" "$romdir/ports/splitwolf" "-j -LL"
    fi
    if [[ ! -f "$romdir/ports/splitwolf/vswap.sd2"  || ! -f "$romdir/ports/splitwolf/vswap.sd3" ]]; then
        cd "$__tmpdir"
        # Get shareware game data
        downloadAndExtract "http://archive.org/download/DOS.Memories.Project.1980-2003/DOS.Memories.Project.1980-2003.zip/Spear%20of%20Destiny%20Mission%20Packs%20%281994%29%28FormGen%20Inc%29.zip" "$romdir/ports/splitwolf" "-j -LL"
    fi

    chown -R $user:$user "$romdir/ports/splitwolf"
}

function configure_splitwolf() {
    local game

    mkRomDir "ports/splitwolf"

    # remove obsolete emulator entries
    while read game; do
        delEmulator "${game%% *}" "splitwolf"
    done < <(_get_opts_splitwolf)

    if [[ "$md_mode" == "install" ]]; then
        game_data_splitwolf
        cat > "$md_inst/bin/splitwolf.sh" << _EOF_
#!/bin/bash

function get_md5sum() {
    local file="\$1"

    [[ -n "\$file" ]] && md5sum "\$file" 2>/dev/null | cut -d" " -f1
}

function launch_splitwolf() {
    local wad_file="\$1"
    declare -A game_checksums=(
        ['6efa079414b817c97db779cecfb081c9']="splitwolf-wolf3d"
        ['a6d901dfb455dfac96db5e4705837cdb']="splitwolf-wolf3d_apogee"
        ['b8ff4997461bafa5ef2a94c11f9de001']="splitwolf-wolf3d_full"
        ['b1dac0a8786c7cdbb09331a4eba00652']="splitwolf-sod"
        ['25d92ac0ba012a1e9335c747eb4ab177']="splitwolf-sod --mission 2"
        ['94aeef7980ef640c448087f92be16d83']="splitwolf-sod --mission 3"
    )
        if [[ "\${game_checksums[\$(get_md5sum \$wad_file)]}" ]] 2>/dev/null; then
            $md_inst/bin/\${game_checksums[\$(get_md5sum \$wad_file)]} --splitdatadir /opt/retropie/ports/splitwolf/bin/lwmp/ --split 2 --splitlayout 2x1
        else
            echo "Error: \$wad_file (md5: \$(get_md5sum \$wad_file)) is not a supported version"
        fi
}

launch_splitwolf "\$1"
_EOF_
        chmod +x "$md_inst/bin/splitwolf.sh"
    fi

    add_games_splitwolf "$md_inst/bin/splitwolf.sh %ROM%"

    moveConfigDir "$home/.splitwolf" "$md_conf_root/splitwolf"

    setDispmanx "$md_id" 1
}
