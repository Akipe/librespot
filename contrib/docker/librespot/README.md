# What is librespot?

[librespot](https://github.com/librespot-org/librespot) is an open source client library for Spotify. It enables applications to use Spotify's service, without using the official but closed-source libspotify. Additionally, it will provide extra features which are not available in the official library.

Note: librespot only works with Spotify Premium. This will remain the case for the forseeable future, as we are unlikely to work on implementing the features such as limited skips and adverts that would be required to make librespot compliant with free accounts.

> [github.com/librespot-org/librespot/wiki](https://github.com/librespot-org/librespot/wiki)

## Information about this repository
This Docker image is generated from the [Akipe/librespot](https://github.com/akipe/librespot) repository, which is a fork of [librespot-org/librespot](https://github.com/librespot-org/librespot).

**So this is not an official image managed by the development team.**

# How to use this image

## Before launch the container

This Docker image only suppports the librespot **pipe backend**. You can play the music on the host machine with any software that can read a pipeline. You will need to create a FIFO file that will act as a gateway between the container and the host system :

```console
$ mkfifo ./librespot_fifo
```

You will then have to mount this file to the **/tmp/librespot_fifo** location in the container (see below).

To read the music from your host machine, use one of these commands when the librespot container is started :

```console
$ pacat --latency-msec=100 -p ./librespot_fifo ## With PulseAudio
$ sox -t raw -c 2 -r 44k -e signed-integer -L -b 16 ./librespot_fifo  -t .wav - | aplay ## With Alsa
```

If you want to automate the execution of this command , you can use Systemd services :

```conf
## /etc/systemd/user/librespot-read_on_host.service
[Unit]
Description=Read Spotify music with librespot on host.
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/pacat --latency-msec=100 -p /path/to/librespot_fifo ## Change the path
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
```

Next reload systemd configuration and start the service:

```console
$ sudo systemctl daemon-reload
$ systemctl --user daemon-reload
$ systemctl --user enable librespot-read_on_host.service --now ## Start the service with your user rights and activate the automatic start 
```

You must start the service with a user with sufficient rights to play audio (usually a user in the audio group). You cannot run this service with root rights.

## Librespot - the easy way

This is the simplest way to launch librespot. **You will need to enter your Spotify credentials**, and **the Zeroconf feature will not work**.

```console
$ docker run --name librespot -v ./librespot_fifo:/tmp/librespot_fifo -e LIBRESPOT_NAME=librespot_with_account -e LIBRESPOT_SPOTIFY_USERNAME=my_spotify_account@email.com -e LIBRESPOT_SPOTIFY_PASSWORD=my_spotify_pass -e LIBRESPOT_AUDIO_CACHE=no -d ak1pe/librespot
```

The same command for docker-compose:

```yaml
version: '2'

services:
    librespot:
        image: ak1pe/librespot
        environment:
            LIBRESPOT_NAME: librespot_with_account
            LIBRESPOT_SPOTIFY_USERNAME: my_spotify_account@email.com
            LIBRESPOT_SPOTIFY_PASSWORD: my_spotify_pass
            LIBRESPOT_AUDIO_CACHE: 'no'
        volumes:
            - ./librespot_fifo:/tmp/librespot_fifo # Mount audio pipe
        restart: always
```

You can use a file to store your credentials, for more informations on this method see below.


## Librespot with Zeroconf support (more complex)

It is possible to launch a container with the Zeroconf feature, but you will have to assign an IP address of your local network to your container. In this case it is not mandatory to fill in your Spotify credentials (but you can always do this).

First you need to create a new Docker network with the macvlan driver and your LAN information :

```console
$ docker network create -d macvlan --subnet={$MY_LAN_SUBNET_IP} --gateway={$MY_LAN_GATEWAY_IP} -o parent={$CONTROLER_NAME_CONNECT_TO_MY_LAN} lan_network
## Example:
$ docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 -o parent=eth0 lan_network
```

You can then run the container:

```console
$ docker run --name librespot -v ./librespot_fifo:/tmp/librespot_fifo --network lan_network --ip 192.168.1.234 -e LIBRESPOT_NAME=librespot_with_zeroconf -e LIBRESPOT_AUDIO_CACHE=no -d ak1pe/librespot
```

Or with docker-compose :

```yaml
version: '2'

services:
    librespot:
        image: ak1pe/librespot
        environment:
            LIBRESPOT_NAME: librespot_with_zeroconf
            LIBRESPOT_AUDIO_CACHE: 'no'
        volumes:
            - ./librespot_fifo:/tmp/librespot_fifo
        networks:
        lan_network:
            ipv4_address: 192.168.1.234 # Define an IP unused in your LAN
        restart: always

# You can choose to create the Docker network with "docker network create" command or inside your docker-compose.yml

# If you have use "docker network create" :
networks:
    lan_network:
        external:
            name: lan_network

# If not :
networks:
  lan_network:
    # Use macvlan for using LAN IP network
    driver: macvlan
    driver_opts:
      # Define your network card name who is connected to your LAN,
      # In some Linux distribution use "$ ip addr show"
      parent: eth0
    ipam:
      config:
        # Set your IP LAN network
        - subnet: 192.168.1.0/24
        # Set your router IP
          gateway: 192.168.1.1
```

## Using environment variables

Almost all launch options are configuratble with environment variables :

| Environment variable                  | Equivalent options            | Description                         |
|---------------------------------------|-------------------------------|-----------------------------------------|
| LIBRESPOT_AUDIO_CACHE *(yes/no)*      | cache / disable-audio-cache   | If **"yes"**, the cache will be write to Path to */tmp/librespot_cache* inside the container, if **"no"** disable caching of the audio data (*--disable-audio-cache*)  |
| LIBRESPOT_NAME                        | name                          | Device name                                    |
| LIBRESPOT_DEVICE_TYPE                 | device-type                   | Displayed device type                          |
| LIBRESPOT_BITRATE                     | bitrate                       | Bitrate (96, 160 or 320). Defaults to 160      |
| LIBRESPOT_ON_EVENT                    | onevent                       | The path to a script that gets run when one of librespot's events is triggered.  |
| LIBRESPOT_ENABLE_VERBOSE              | verbose                       | Enable verbose output                          |
| LIBRESPOT_SPOTIFY_USERNAME            | username                      | Username to sign in with                       |
| LIBRESPOT_SPOTIFY_PASSWORD            | password                      | Password                                       |
| LIBRESPOT_DISABLE_DISCOVERY           | disable-discovery             | Disable discovery mode                         |
| LIBRESPOT_DEVICE                      | device                        | Audio device to use. Use '?' to list options  (Only with the `portaudio`/`alsa` backend)  |
| LIBRESPOT_INITIAL_VOLUME              | initial-volume                | Initial volume in %, once connected [0-100]    |
| LIBRESPOT_ENABLE_VOLUME_NORMALISATION | enable-volume-normalisation   | Enables volume normalisation for librespot     |
| LIBRESPOT_NORMALISATION_PREGAIN       | normalisation-pregain         | A numeric value for pregain (dB). Only used when normalisation active.  |
| LIBRESPOT_ENABLE_LINEAR_VOLUME        | linear-volume                 | Enables linear volume scaling instead of logarithmic (default) scaling  |
| LIBRESPOT_ZEROCONF_PORT               | zeroconf-port                 | The port that the HTTP server advertised on zeroconf will use [1-65535]. Ports <= 1024 may require root priviledges.  |
| LIBRESPOT_PROXY                       | proxy                         | Use a proxy for resolving the access point. Proxy should be an HTTP proxy in the form ```http://ip:port```, and can also be passed using the ```HTTP_PROXY``` environment variable.  |
| LIBRESPOT_DEBUG                       |                               | This active verbose options and run librespot with RUST_BACKTRACE=1 and RUST_LOG=mdns=trace  |

*Backend* and *mixer* options are not supported. You can get more informations about the options by visiting the wiki : [github.com/librespot-org/librespot/wiki/Options](https://github.com/librespot-org/librespot/wiki/Options)

### How to use the cache

If you want use the cache, mount the path **/tmp/librespot_cache** to your host :

```yaml
version: '2'

services:
    librespot:
        image: ak1pe/librespot
        environment:
            LIBRESPOT_NAME: librespot
            LIBRESPOT_SPOTIFY_USERNAME: my_spotify_account@email.com
            LIBRESPOT_SPOTIFY_PASSWORD: my_spotify_pass
            LIBRESPOT_AUDIO_CACHE: 'yes' # Active the cache
        volumes:
            - ./librespot_fifo:/tmp/librespot_fifo
            - ./librespot_cache:/tmp/librespot_cache # Mount the cache directory where you want
        restart: always
```

### Store your Spotify credentials inside a file

You can save your credentials in a file. This file should be written like this:

```conf
# ./credentials_example
USERNAME=my_spotify_account@email.com
PASSWORD=my_spotify_pass
```

Then you will have to mount this file to the **/tmp/librespot_credentials** path in the container: 

```yaml
version: '2'

services:
    librespot:
        image: ak1pe/librespot
        environment:
            LIBRESPOT_NAME: librespot
        volumes:
            - ./librespot_fifo:/tmp/librespot_fifo
            - ./credentials_example:/tmp/librespot_credentials
        restart: always
```

# License

View [license information](https://github.com/librespot-org/librespot/blob/master/LICENSE) for the software contained in this image (**MIT License**).

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.