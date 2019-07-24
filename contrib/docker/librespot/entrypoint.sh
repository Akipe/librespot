#!/bin/bash
set -e

arguments=$@

########
## Default options for librespot
########

if [ -d "/tmp/librespot_fifo" ]
then
    echo 'ERROR: "/tmp/librespot_fifo" is a directory !'
    exit 2
fi

if [ ! -p "/tmp/librespot_fifo" ] && [ ! -e "/tmp/librespot_fifo" ] && [ ! -L "/tmp/librespot_fifo" ]
then
    mkfifo "/tmp/librespot_fifo"
fi

arguments="$arguments--name $LIBRESPOT_NAME --backend pipe --device /tmp/librespot_fifo"


########
## Optional options for librespot
########

if [[ $LIBRESPOT_AUDIO_CACHE == "yes" ]]
then
    if [ ! -d "/tmp/librespot_cache" ]
    then
        mkdir -p "/tmp/librespot_cache"
    fi

    arguments="$arguments --cache=/tmp/librespot_cache"
else
    arguments="$arguments --disable-audio-cache"
fi

if [ ! -z ${LIBRESPOT_DEVICE_TYPE} ]
then
    arguments="$arguments --device-type $LIBRESPOT_DEVICE_TYPE"
fi

if [ ! -z ${LIBRESPOT_BITRATE} ]
then
    arguments="$arguments --bitrate $LIBRESPOT_BITRATE"
fi

if [ ! -z ${LIBRESPOT_ON_EVENT} ]
then
    arguments="$arguments --onevent $LIBRESPOT_ON_EVENT"
fi

if [[ "$LIBRESPOT_ENABLE_VERBOSE" == "yes" ]] || [[ $LIBRESPOT_DEBUG = "yes" ]]
then
    arguments="$arguments --verbose"
fi

####
## Use a file to get Spotify credentials if it exist
####
# 
####

if [ -e "/tmp/librespot_credentials" ]
then
    echo "Read the file /tmp/librespot_credentials for getting account credentials"
    LIBRESPOT_SPOTIFY_USERNAME=$(sed -n '/^USERNAME/ s/^USERNAME=\(.*\)/\1/p' /tmp/librespot_credentials)
    LIBRESPOT_SPOTIFY_PASSWORD=$(sed -n '/^PASSWORD/ s/^PASSWORD=\(.*\)/\1/p' /tmp/librespot_credentials)
fi

if [ ! -z $LIBRESPOT_SPOTIFY_USERNAME ] && [ ! -z $LIBRESPOT_SPOTIFY_PASSWORD ]
then
    arguments="$arguments --username $LIBRESPOT_SPOTIFY_USERNAME --password $LIBRESPOT_SPOTIFY_PASSWORD"
fi

if [[ "$LIBRESPOT_DISABLE_DISCOVERY" == "yes" ]]
then
    arguments="$arguments --disable-discovery"
fi

if [ ! -z ${LIBRESPOT_MIXER} ]
then
    arguments="$arguments --mixer $LIBRESPOT_MIXER"
fi

if [ ! -z ${LIBRESPOT_MIXER_NAME} ]
then
    arguments="$arguments --mixer-name $LIBRESPOT_MIXER_NAME"
fi

if [ ! -z ${LIBRESPOT_MIXER_CARD} ]
then
    arguments="$arguments --mixer-card $LIBRESPOT_MIXER_CARD"
fi

if [ ! -z ${LIBRESPOT_MIXER_INDEX} ]
then
    arguments="$arguments --mixer-index $LIBRESPOT_MIXER_INDEX"
fi

if [ ! -z ${LIBRESPOT_INITIAL_VOLUME} ]
then
    arguments="$arguments --initial-volume $LIBRESPOT_INITIAL_VOLUME"
fi

if [[ "$LIBRESPOT_ENABLE_VOLUME_NORMALISATION" == "yes" ]]
then
    arguments="$arguments --enable-volume-normalisation"
fi

if [ ! -z ${LIBRESPOT_NORMALISATION_PREGAIN} ]
then
    arguments="$arguments --normalisation-pregain $LIBRESPOT_NORMALISATION_PREGAIN"
fi

if [[ "$LIBRESPOT_ENABLE_LINEAR_VOLUME" == "yes" ]]
then
    arguments="$arguments --linear-volume"
fi

if [ ! -z ${LIBRESPOT_ZEROCONF_PORT} ]
then
    arguments="$arguments --zeroconf-port $LIBRESPOT_ZEROCONF_PORT"
fi

if [ ! -z ${LIBRESPOT_PROXY} ]
then
    arguments="$arguments --proxy $LIBRESPOT_PROXY"
fi



if [[ $LIBRESPOT_DEBUG = "yes" ]]
then
    echo "bash -c RUST_BACKTRACE=1 RUST_LOG=mdns=trace exec /usr/local/bin/librespot $arguments"
    bash -c "RUST_BACKTRACE=1 RUST_LOG=mdns=trace exec /usr/local/bin/librespot $arguments"
else
    # Log the command
    echo "/usr/local/bin/librespot $arguments"
    exec /usr/local/bin/librespot $arguments
fi

exit 1