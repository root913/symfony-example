#!/bin/bash

set -e

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [OPTIONS]

Project setup script.

Available options:

-h, --help                           Print this help and exit
--skip-database                      Skips database import
--skip-migration                     Skips migration
--skip-lint                          Skips ESLINT
--skip-build                         Skips Webpack build
--skip-install                       Skips Composer/Yarn install
--skip-index                         Skips search indexing
EOF
  exit
}

# Load helper functions
chmod +x "$(dirname "$0")/func.sh"
source "$(dirname "$0")/func.sh"

DOCKER_PHP_USER="www-data"
if $(HasAlpineImage); then
    DOCKER_PHP_USER="app"
fi

if $(HasOption "-h") || $(HasOption "--help"); then
    usage
fi

Login() {
    if ! $(HasIdeoImages); then
        return
    fi

    line
    writeBold "Logowanie do rejestru\n" "${YELLOW}"

    docker login docker.ideo.pl
    writeNewLine
}

DockerUp() {
    line
    writeBold "Uruchomienie kontenerów dla projektu ${BOLD}${DOCKER_PREFIX}\n" "${YELLOW}"
    docker-compose up -d --remove-orphans
}

ComposerInstall() {
    if $(HasOption "--skip-install"); then
        return
    fi

    line
    writeBold "Instalacja Composera\n" "${YELLOW}"
    docker exec -it -u www-data "$DOCKER_PREFIX"_php env COMPOSER_MEMORY_LIMIT=-1 composer install
}

Migrate() {
    if $(HasOption "--skip-migration"); then
        return
    fi

    line
    writeBold "Uruchomienie migracji\n" "${YELLOW}"
    docker exec -u www-data "$DOCKER_PREFIX"_php php bin/console doctrine:migrations:migrate --allow-no-migration
}

YarnInstall() {
    if $(HasOption "--skip-install"); then
        return
    fi

    line
    writeBold "Instalacja node modules\n" "${YELLOW}"
    docker exec -it "$DOCKER_PREFIX"_php yarn install
}

BuildAssets() {
    if $(HasOption "--skip-build"); then
        return
    fi

    line
    writeBold "Kompilacja assetów\n" "${YELLOW}"
    docker exec -it "$DOCKER_PREFIX"_php yarn build:dev
}

Eslint() {
    if $(HasOption "--skip-lint"); then
        return
    fi

    line
    writeBold "ESLINT\n" "${YELLOW}"
    docker exec -it "$DOCKER_PREFIX"_php yarn lint:fix
}

PhpCsFixer() {
    if $(HasOption "--skip-lint"); then
        return
    fi

    line
    writeBold "PHP-FIXER\n" "${YELLOW}"
    docker exec -it "$DOCKER_PREFIX"_php vendor/bin/php-cs-fixer fix --using-cache=no --verbose
}

Finish() {
    line
    writeBold "Panel jest dostępny pod adresami:" "${YELLOW}"
    writeBold "    http://${DOCKER_IP}:${DOCKER_PORT}/admin" "${GREEN}"
    writeBold "    http://localhost:${DOCKER_PORT}/admin" "${GREEN}"
}

# Run functions
Login
DockerUp
ComposerInstall
Migrate
#YarnInstall
#BuildAssets
#Eslint
#PhpCsFixer
Finish
