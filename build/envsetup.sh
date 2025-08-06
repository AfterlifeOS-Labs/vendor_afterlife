CLANG_VERSION=$(${ANDROID_BUILD_TOP}/build/soong/scripts/get_clang_version.py)
export LLVM_AOSP_PREBUILTS_VERSION="${CLANG_VERSION}"

RUST_VERSION=$(grep 'RustDefaultVersion =' ${ANDROID_BUILD_TOP}/build/soong/rust/config/global.go | awk '{print $3}' | awk -F '"' '{print $2}')
export RUST_AOSP_PREBUILTS_VERSION="${RUST_VERSION}"

# check to see if the supplied product is one we can build
function check_product()
{
    local T=$(gettop)
    if [ ! "$T" ]; then
        echo "Couldn't locate the top of the tree. Try setting TOP." >&2
        return
    fi
    if (echo -n $1 | grep -q -e "^afterlife_") ; then
        AFTERLIFE_BUILD=$(echo -n $1 | sed -e 's/^afterlife_//g')
    else
        AFTERLIFE_BUILD=
    fi
    export AFTERLIFE_BUILD

        TARGET_PRODUCT=$1 \
        TARGET_RELEASE=$2 \
        TARGET_BUILD_VARIANT= \
        TARGET_BUILD_TYPE= \
        TARGET_BUILD_APPS= \
        _get_build_var_cached TARGET_DEVICE > /dev/null
    # hide successful answers, but allow the errors to show
}

# ==============================================================================
# AFTERLIFE OS - MODERN CLI DASHBOARD
# ==============================================================================

function setup_ccache() {
    if [ -z "${CCACHE_EXEC}" ]; then
        if command -v ccache &>/dev/null; then
            export USE_CCACHE=1
            export CCACHE_EXEC=$(command -v ccache)
            [ -z "${CCACHE_DIR}" ] && export CCACHE_DIR="$HOME/.ccache"

            export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-75G}"
            DIRECT_MODE="${DIRECT_MODE:-true}"
            export CCACHE_SLOPPINESS="time_macros,include_file_ctime,file_stat_matches"

            $CCACHE_EXEC -o compression=true -o compression_level=1 -o direct_mode="${DIRECT_MODE}" -M "${CCACHE_MAXSIZE}" > /dev/null

            if [ -d "$CCACHE_DIR" ]; then
                CURRENT_CCACHE_SIZE_BYTES=$(du -sb "$CCACHE_DIR" 2>/dev/null | awk '{print $1}')
                export CURRENT_CCACHE_SIZE_GB=$(echo "$CURRENT_CCACHE_SIZE_BYTES" | awk '{printf "%.2f\n", $1 / 1024 / 1024 / 1024}')
            fi
        fi
    fi
}

function afterlife_dashboard() {
    # Colors variable
    local R='\033[0;31m'   # Red
    local G='\033[0;32m'   # Green
    local Y='\033[1;33m'   # Yellow
    local B='\033[0;34m'   # Blue
    local P='\033[0;35m'   # Purple
    local C='\033[0;36m'   # Cyan
    local W='\033[1;37m'   # White Bold
    local N='\033[0m'      # Null/Reset

    local VERSION_FILE="vendor/afterlife/config/version.mk"
    local AL_VERSION="Unknown"
    
    if [ -f "$VERSION_FILE" ]; then
        local VER_MAJ=$(grep "PRODUCT_VERSION_MAJOR" $VERSION_FILE | head -n 1 | awk -F '=' '{print $2}' | tr -d '[:space:]')
        local VER_MIN=$(grep "PRODUCT_VERSION_MINOR" $VERSION_FILE | head -n 1 | awk -F '=' '{print $2}' | tr -d '[:space:]')
        local VER_CODE=$(grep "AFTERLIFE_CODENAME" $VERSION_FILE | head -n 1 | awk -F ':=' '{print $2}' | tr -d '[:space:]')
        AL_VERSION="${VER_MAJ}.${VER_MIN} (${VER_CODE})"
    fi

    # Clear terminal screen
    # clear 

    # 3. Header & ASCII Art
    echo -e "${P}"
    echo " _____ ___ _           _ _ ___     _____     "
    echo "|  _  |  _| |_ ___ ___| |_|  _|___|     |___ "
    echo "|     |  _|  _| -_|  _| | |  _| -_|  |  |_ -|"
    echo "|__|__|_| |_| |___|_| |_|_|_| |___|_____|___|"
    echo -e "${N}"
    
    echo -e "${B}======================================================${N}"
    echo -e "   ${W}WELCOME TO AFTERLIFE OS BUILD ENVIRONMENT${N}"
    echo -e "${B}======================================================${N}"

    # 4. System Info Section
    setup_ccache
    local HOST_NAME=$(hostname)
    local USER_NAME=$(whoami)
    local DATE_NOW=$(date +"%A, %d %B %Y")
    
    echo -e "  ${Y}User${N}      : ${C}$USER_NAME${N}"
    echo -e "  ${Y}Host${N}      : ${C}$HOST_NAME${N}"
    echo -e "  ${Y}Date${N}      : ${C}$DATE_NOW${N}"
    echo -e "  ${Y}Version${N}   : ${C}$AL_VERSION${N}"
    if [ "${USE_CCACHE}" = "1" ]; then
        echo -e "  ${Y}CCache${N}    : ${C}${CURRENT_CCACHE_SIZE_GB}GB / ${CCACHE_MAXSIZE}${N}"
    fi
    echo -e "${B}------------------------------------------------------${N}"

    # Quick Guide / Instructions
    echo -e "  ${W}HOW TO BUILD:${N}"
    echo -e ""
    echo -e "  ${G}1. Start Build${N}"
    echo -e "     Syntax  : ${Y}goafterlife <codename> [jobs] [options] [variant]${N}"
    echo -e "     Example : ${C}goafterlife surya 16 --dirty${N}"
    echo -e ""
    echo -e "  ${G}2. Upload${N}"
    echo -e "     Command : ${Y}gorelease <codename>${N}"
    echo -e ""
    
    # Options & Variants Info
    echo -e "${B}------------------------------------------------------${N}"
    echo -e "  ${W}ARGUMENTS & OPTIONS:${N}"
    echo -e "  ${Y}<jobs>${N}      : Number of CPU threads (e.g., 16, 32). Default: ${C}$(nproc --all)${N}"
    echo -e "  ${Y}--dirty${N}     : Skip 'make installclean' (faster for incremental builds)"
    echo -e "  ${Y}--release${N}   : Automatically upload build to Gofile after completion"
    echo -e ""
    echo -e "  ${W}VARIANTS:${N}"
    echo -e "  ${Y}user${N}        : Limited access, for public release (secure)"
    echo -e "  ${Y}userdebug${N}   : Root access + debugging enabled (Default)"
    echo -e "  ${Y}eng${N}         : Engineering mode with extra debug tools"
    echo -e "${B}======================================================${N}"
    echo -e ""
    echo -e "  ${P}Enjoy building! #NeverDie${N}"
    echo -e ""
}

function goafterlife()
{
    target=$1
    local variant="userdebug"
    local clean_build="true"
    local upload_zip="false"
    local jobs=$(nproc --all)

    source ${ANDROID_BUILD_TOP}/vendor/afterlife/vars/aosp_target_release

    if [ $# -eq 0 ]; then
        # No arguments, so let's have the full menu
        lunch
    else
        if [[ "$target" =~ -(user|userdebug|eng)$ ]]; then
            # A buildtype was specified, assume a full device name
            lunch $target
        else
            while [[ $# -gt 0 ]]; do
                case "${1}" in
                    --dirty)
                        clean_build="false"
                        shift
                        ;;
                    --release)
                        upload_zip="true"
                        shift
                        ;;
                    user)
                        variant="user"
                        shift
                        ;;
                    userdebug)
                        variant="userdebug"
                        shift
                        ;;
                    eng)
                        variant="eng"
                        shift
                        ;;
                    *)
                        # Check if argument is a number (CPU cores)
                        if [[ "${1}" =~ ^[0-9]+$ ]]; then
                            jobs="${1}"
                        else
                            # Assume this is the device codename
                            target="${1}"
                        fi
                        shift
                        ;;
                esac
            done

            if [ -z "$variant" ]; then
                variant="userdebug"
            fi

            lunch afterlife_${target}-${aosp_target_release}-${variant}
        fi
    fi

    if [ $? -ne 0 ]; then
        echo "Error: Lunch failed. Aborting build process."
        return 1
    fi

    rm -rf out/target/product/$target/AfterlifeOS*zip*

    if [ "$clean_build" = "true" ]; then
        echo "Cleaning build (installclean)..."
        make installclean
    fi

    echo "Starting build with -j${jobs}..."
    m afterlife -j${jobs}

    if [ $? -ne 0 ]; then
        echo "Error: Build failed. Aborting release."
        return 1
    fi

    if [ "$upload_zip" = "true" ]; then
        gorelease $target
    fi

    return $?
}

function gorelease()
{
    if [ $# -eq 0 ]; then
      echo "Device is null!"
      exit
    fi

    # Check for jq dependency since Gofile API requires parsing JSON
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed. Please install jq to proceed with Gofile upload."
        return 1
    fi

    echo "##############################################################"
    local target=$1
    echo "Device: $target"
    local srcdir="out/target/product/$target"
    echo "Directory: $srcdir"
    local srcfile=$(find $srcdir -type f -name "AfterlifeOS*.zip")
    local fname="${srcfile##*/}"
    echo "Filename: $fname"
    echo "##############################################################"
    echo ""

    for upfile in "$srcfile"
    do
        echo "Uploading $fname to Gofile..."
        local dlink=$(curl -# -X POST https://upload.gofile.io/uploadfile -F "file=@$upfile" | jq -r '.data.downloadPage')

        if [ -z "$dlink" ] || [ "$dlink" == "null" ]; then
            echo "Error: Upload failed or download link not found."
            continue
        fi
        
        echo "Upload success: $dlink"

        upmsg="${target}: ${dlink}"
        
        echo "Sending Telegram notification..."
        
        local tg_status=$(curl -s -o /dev/null -w "%{http_code}" \
            -F document=@"out/target/product/$target/$target.json" \
            "https://api.telegram.org/bot5478001056:AAFXt9jrRlb54Ttx_OtGaZ7NqNCWci_bw4o/sendDocument?chat_id=-1001834737844" \
            -F caption="$upmsg")

        if [ "$tg_status" -eq 200 ]; then
            echo "Telegram notification sent successfully."
        else
            echo "Error: Failed to send Telegram notification. HTTP Code: $tg_status"
        fi
        
        echo ""
    done
}

function breakfast()
{
    target=$1
    local variant=$2
    source ${ANDROID_BUILD_TOP}/vendor/afterlife/vars/aosp_target_release

    if [ $# -eq 0 ]; then
        # No arguments, so let's have the full menu
        lunch
    else
        if [[ "$target" =~ -(user|userdebug|eng)$ ]]; then
            # A buildtype was specified, assume a full device name
            lunch $target
        else
            # This is probably just the afterlife model name
            if [ -z "$variant" ]; then
                variant="user"
            fi

            lunch afterlife_$target-$aosp_target_release-$variant
        fi
    fi
    return $?
}

alias bib=breakfast

function aospremote()
{
    local T=`git rev-parse --show-toplevel 2> /dev/null`
    if [ -z "$T" ]
    then
        echo "Git repository not found. Please run this from the directory of the Android repository you wish to set up."
        return 1
    fi
    git remote rm aosp 2> /dev/null

    if [ -f "$T/.gitupstream" ]; then
        local REMOTE=$(cat "$T/.gitupstream" | cut -d ' ' -f 1)
        git remote add aosp ${REMOTE}
    else
        local PROJECT=$(pwd -P | sed -e "s#$ANDROID_BUILD_TOP\/##; s#-caf.*##; s#\/default##")
        # Google moved the repo location in Oreo
        if [ $PROJECT = "build/make" ]
        then
            PROJECT="build"
        fi
        if (echo $PROJECT | grep -qv "^device")
        then
            local PFX="platform/"
        fi
        git remote add aosp https://android.googlesource.com/$PFX$PROJECT
    fi
    echo "Remote 'aosp' created"
}

function cloremote()
{
    local T=`git rev-parse --show-toplevel 2> /dev/null`
    if [ -z "$T" ]
    then
        echo "Git repository not found. Please run this from the directory of the Android repository you wish to set up."
        return 1
    fi
    git remote rm clo 2> /dev/null

    if [ -f "$T/.gitupstream" ]; then
        local REMOTE=$(cat "$T/.gitupstream" | cut -d ' ' -f 1)
        git remote add clo ${REMOTE}
    else
        local PROJECT=$(pwd -P | sed -e "s#$ANDROID_BUILD_TOP\/##; s#-caf.*##; s#\/default##")
        # Google moved the repo location in Oreo
        if [ $PROJECT = "build/make" ]
        then
            PROJECT="build_repo"
        fi
        if [[ $PROJECT =~ "qcom/opensource" ]];
        then
            PROJECT=$(echo $PROJECT | sed -e "s#qcom\/opensource#qcom-opensource#")
        fi
        if (echo $PROJECT | grep -qv "^device")
        then
            local PFX="platform/"
        fi
        git remote add clo https://git.codelinaro.org/clo/la/$PFX$PROJECT
    fi
    echo "Remote 'clo' created"
}

function githubremote()
{
    if ! git rev-parse --git-dir &> /dev/null
    then
        echo ".git directory not found. Please run this from the root directory of the Android repository you wish to set up."
        return 1
    fi
    git remote rm github 2> /dev/null
    local REMOTE=$(git config --get remote.aosp.projectname)

    if [ -z "$REMOTE" ]
    then
        REMOTE=$(git config --get remote.clo.projectname)
    fi

    local PROJECT=$(echo $REMOTE | sed -e "s#platform/#android/#g; s#/#_#g")

    git remote add github https://github.com/AfterlifeOS/$PROJECT
    echo "Remote 'github' created"
}

function privateremote()
{
    if ! git rev-parse --git-dir &> /dev/null
    then
        echo ".git directory not found. Please run this from the root directory of the Android repository you wish to set up."
        return 1
    fi
    git remote rm private 2> /dev/null
    local PROJECT=$(git config --get remote.github.projectname)

    git remote add private git@github.com:$PROJECT.git
    echo "Remote 'private' created"
}

function mka() {
    m "$@"
}

function cmka() {
    if [ ! -z "$1" ]; then
        for i in "$@"; do
            case $i in
                bacon|otapackage|systemimage)
                    mka installclean
                    mka $i
                    ;;
                *)
                    mka clean-$i
                    mka $i
                    ;;
            esac
        done
    else
        mka clean
        mka
    fi
}

function repolastsync() {
    RLSPATH="$ANDROID_BUILD_TOP/.repo/.repo_fetchtimes.json"
    RLSLOCAL=$(date -d "$(stat -c %z $RLSPATH)" +"%e %b %Y, %T %Z")
    RLSUTC=$(date -d "$(stat -c %z $RLSPATH)" -u +"%e %b %Y, %T %Z")
    echo "Last repo sync: $RLSLOCAL / $RLSUTC"
}

function reposync() {
    repo sync -j 4 "$@"
}

function repodiff() {
    if [ -z "$*" ]; then
        echo "Usage: repodiff <ref-from> [[ref-to] [--numstat]]"
        return
    fi
    diffopts=$* repo forall -c \
      'echo "$REPO_PATH ($REPO_REMOTE)"; git diff ${diffopts} 2>/dev/null ;'
}

function sort-blobs-list() {
    T=$(gettop)
    $T/tools/extract-utils/sort-blobs-list.py $@
}

function fixup_common_out_dir() {
    common_out_dir=$(_get_build_var_cached OUT_DIR)/target/common
    target_device=$(_get_build_var_cached TARGET_DEVICE)
    common_target_out=common-${target_device}
    if [ ! -z $AFTERLIFE_FIXUP_COMMON_OUT ]; then
        if [ -d ${common_out_dir} ] && [ ! -L ${common_out_dir} ]; then
            mv ${common_out_dir} ${common_out_dir}-${target_device}
            ln -s ${common_target_out} ${common_out_dir}
        else
            [ -L ${common_out_dir} ] && rm ${common_out_dir}
            mkdir -p ${common_out_dir}-${target_device}
            ln -s ${common_target_out} ${common_out_dir}
        fi
    else
        [ -L ${common_out_dir} ] && rm ${common_out_dir}
        mkdir -p ${common_out_dir}
    fi
}

function generate_host_overrides() {
    export BUILD_USERNAME=android-build
    HEX=$(openssl rand -hex 8)
    ALPHA=$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c 4)
    export BUILD_HOSTNAME="r-${HEX}-${ALPHA}"
    echo "BUILD_USERNAME=$BUILD_USERNAME"
    echo "BUILD_HOSTNAME=$BUILD_HOSTNAME"
}

generate_host_overrides

afterlife_dashboard

export SKIP_ABI_CHECKS=true
