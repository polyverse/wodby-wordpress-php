ARG BASE_IMAGE_TAG

FROM golang as polyscripter

COPY polyscript/src/tokenizer /polyscripting/
COPY polyscript/scripts /polyscripting/

COPY ./polyscript/src/scrambler/* /go/src/github.com/polyverse/scrambler/

WORKDIR  /go/src/github.com/polyverse/scrambler
RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o /polyscripting/php-scrambler

FROM wodby/php:${BASE_IMAGE_TAG}

USER root

#add polyscripting
ENV POLYSCRIPT_PATH "/usr/local/bin/polyscripting"
ENV PHP_SRC_PATH "/usr/src/php"
ENV PHP_DEPS \
        argon2-dev \
        curl-dev \
        libsodium-dev \
	gcc \
        libedit-dev \
        sqlite-dev \
        oniguruma-dev
ARG POLY_BUILD
WORKDIR $POLYSCRIPT_PATH
COPY --from=polyscripter /polyscripting/ ./

RUN apk add --update --no-cache -t .wodby-ps-php-build-deps \
                        $PHP_DEPS; \
		mkdir "${PHP_SRC_PATH}"; \
		tar -xvf /usr/src/php.tar.xz --directory $PHP_SRC_PATH --strip-components 1; \
                cd "${PHP_SRC_PATH}"; \
                ./configure $(php-config --configure-options); \
                make; \
                make install; \
                cd -; 


RUN set -ex; \
    \
    apk add --no-cache -t .fetch-deps gnupg; \
    \
    cd /tmp; \
    wp_cli_version="2.4.0"; \
    url="https://github.com/wp-cli/wp-cli/releases/download/v${wp_cli_version}/wp-cli-${wp_cli_version}.phar"; \
    curl -o wp.phar -fSL "${url}"; \
    curl -o wp.phar.asc -fSL "${url}.asc"; \
    \
    GPG_KEYS=63AF7AA15067C05616FDDD88A3A2E8F226F0BC06 gpg_verify /tmp/wp.phar.asc /tmp/wp.phar; \
    \
    sha512="4049c7e45e14276a70a41c3b0864be7a6a8cfa8ea65ebac8b184a4f503a91baa1a0d29260d03248bc74aef70729824330fb6b396336172a624332e16f64e37ef"; \
	echo "${sha512} *wp.phar" | sha512sum -c -; \
	\
    chmod +x wp.phar; \
    mv wp.phar /usr/local/bin/wp; \
    \
    url="https://raw.githubusercontent.com/wp-cli/wp-cli/v${wp_cli_version}/utils/wp-completion.bash"; \
    curl -o /usr/local/include/wp-completion.bash -fSL "${url}"; \
    cd /home/wodby; \
    echo "source /usr/local/include/wp-completion.bash" | tee -a .bash_profile .bashrc; \
    \
    if [[ -z "${PHP_DEV}" ]]; then \
        echo "$(cat /etc/sudoers.d/wodby), /usr/local/bin/init_wordpress" > /etc/sudoers.d/wodby; \
    fi; \
    \
    mv /usr/local/bin/actions.mk /usr/local/bin/php.mk; \
    \
    apk del --purge .fetch-deps; \
    rm -rf /var/cache/apk/* /tmp/*

RUN echo "Set disable_coredump false" >> /etc/sudo.conf


USER wodby

COPY templates /etc/gotpl/
COPY bin /usr/local/bin
COPY init /docker-entrypoint-init.d/
