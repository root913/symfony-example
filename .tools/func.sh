BOLD="$(tput bold)"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
RESET="$(tput sgr0)"

if [ ${0##*/} == ${BASH_SOURCE[0]##*/} ]; then
    echo "${YELLOW}WARNING${RESET}"
    echo "${RED}This script is not meant to be executed directly!${RESET}"
    echo "${RED}Use this script only by sourcing it.${RESET}"
    echo
    exit 1
fi

BASEDIR=$(dirname "$0")
ENV_FILE="$BASEDIR/../.env"

eval "$(grep ^DOCKER_PREFIX= "$ENV_FILE")"
eval "$(grep ^DBNAME= "$ENV_FILE")"
eval "$(grep ^DOCKER_IP= "$ENV_FILE")"
eval "$(grep ^DOCKER_PORT= "$ENV_FILE")"
eval "$(grep ^DOCKER_IMAGE_PHP= "$ENV_FILE")"
eval "$(grep ^DOCKER_IMAGE_DB= "$ENV_FILE")"

AbortIfNoEnvFile() {
    if [ -f "$ENV_FILE" ]; then
        echo "${BOLD}${RED}$ENV_FILE does not exist.${RESET}"
        exit 1
    fi
}

options=" $@ "
HasOption() {
    name=$1
    if [[ "$options" == *" $name "* ]]; then
        return 0
    fi

    return 1
}

HasIdeoImages() {
    if [[ "$DOCKER_IMAGE_PHP" == *"ideo"* ]]; then
        return 0
    fi

    if [[ "$DOCKER_IMAGE_DB" == *"ideo"* ]]; then
        return 0
    fi

    return 1
}

HasAlpineImage() {
    if [[ "$DOCKER_IMAGE_PHP" == *"alpine"* ]]; then
        return 0
    fi

    return 1
}

spinner_pid=
spinner_prev=''
spinner_prev_time=0
CursorBack() {
  echo -en "\033[$1D"
}

StartSpinner() {
    spinner_prev_time=$(date +%s)
    tput civis
    set +m
    spinner_prev="$1"
    local frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
    { while : ; do for frame in ${frames[*]} ; do echo -ne " $frame $1\033[0K\r"; sleep .1; done; done & } 2>/dev/null

    spinner_pid=$!
}

StopSpinner() {
    { kill -9 $spinner_pid && wait; } 2>/dev/null
    if [ -z "$1" ]
    then
        return
    fi

    set -m
    echo -en "\033[2K\r"
    tput cnorm

    local end_time=$(date +%s)
    local elapsed_time="$((end_time-spinner_prev_time))"

    echo -e " ⠿ $spinner_prev  ${GREEN}$1${RESET}    ${elapsed_time}s";
    spinner_prev=''
    spinner_prev_time=0
}

trap StopSpinner EXIT

write() {
    echo -e " $2$1${RESET}"
}

writeBold() {
    echo -e " ${BOLD}$2$1${RESET}"
}

writeNewLine() {
    echo ""
}

line() {
    echo "${BOLD}${RED}--------------------------------------------------------------------------------${RESET}"
}