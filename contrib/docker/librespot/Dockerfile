# Create a Docker image for x86 and x86-64 system
# Build the docker image from the root of the project with the following command :
#
# $ docker build -t librespot -f ./contrib/docker/librespot/Dockerfile .
# 
# Inspired by :
# - https://github.com/djmaze/librespot-snapserver/blob/master/Dockerfile
# - https://github.com/karafior/docker-librespot

FROM rust:1.36 as librespot_build_image

## librespot dependencies for build
RUN apt-get update && apt-get install -y \
        build-essential \
        portaudio19-dev \
        libasound2-dev \
        pkg-config \
        curl \
    && apt-get clean && rm -fR /var/lib/apt/lists

ADD . /src
WORKDIR /src

RUN cargo build \
        --release \
        --no-default-features


FROM debian:buster

ENV LIBRESPOT_NAME librespot

## librespot dependencies for run
RUN apt-get update && apt-get install -y \ 
        libportaudio2 \
    && apt-get clean && rm -fR /var/lib/apt/lists

COPY --from=librespot_build_image \
        /src/target/release/librespot \
        /usr/local/bin/librespot

RUN chmod +x /usr/local/bin/librespot

# Create user librespot for running librespot
RUN groupadd -r librespot \
    && useradd -ms /bin/bash -g librespot librespot

WORKDIR /

COPY ./contrib/docker/librespot/entrypoint.sh /

# RUN chmod +x /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    && chown -R librespot:librespot /entrypoint.sh

USER librespot


ENTRYPOINT ["/entrypoint.sh"]
