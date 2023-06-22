---
title: "Getting Started"
menu:
  main:
    weight: 1
showDate: false
---
This page will take you through getting started feeding ADS-B data into Plane Watch!

## Equipment
You'll want a few piece of kit before we get started:
- An SDR of some sort that can capture 1090Mhz
- A Micro PC such as a Raspberry Pi that can interface with the SDR

## Register a Feeder
Head over to <https://atc.plane.watch> and sign up for an account. 

{{< button href="https://atc.plane.watch/users/sign_up" target="_blank" >}}
Sign Up
{{< /button >}}

ATC is the portal you'll use to administer your feeder on Plane Watch. Here you'll be able to view your feeder status and provide some information that'll allow us to use your feed data.

## Create your feeder
Login to <https://atc.plane.watch>, click on **Feeders**, **+ New Feeder**. Fill out your details.

When you save your feeder, an **API Key** will be generated. Take note of this, as it will be required when deploying the feeder container.


## Basic Up-and-Running
Our feeder container can be deployed with `docker run` as follows:

```shell
docker run \
  -d \
  --rm \
  --name planewatch \
  -e TZ=YOUR_TIMEZONE \
  -e BEASTHOST=YOUR_BEASTHOST \
  -e API_KEY=YOUR_API_KEY \
  -e LAT=YOUR_LATITUDE \
  -e LONG=YOUR_LONGITUDE \
  -e ALT=YOUR_ALTITUDE \
  --tmpfs=/run:exec,size=64M \
  --tmpfs=/var/log \
  ghcr.io/plane-watch/docker-plane-watch:latest
```

Where:

* `YOUR_TIMEZONE` is your timezone in "TZ database name" format (eg: Australia/Perth)
* `YOUR_BEASTHOST` is the hostname, IP address or container name of a beast protocol provider (eg: piaware)
* `YOUR_API_KEY` is your plane.watch feeder API Key
* `YOUR_LATITUDE` is the latitude of your antenna (xx.xxxxx)
* `YOUR_LONGITUDE` is the longitude of your antenna (xx.xxxxx)
* `YOUR_ALTITUDE` is the your antenna altitude, and should be suffixed with either m or ft. If no suffix, will default to m.
You can test to ensure your container is seeing ADS-B data by running:

```
docker exec -it planewatch viewadsb
```

## Using Docker Compose

```yaml
version: '3.8'

services:
  planewatch:
    image: ghcr.io/plane-watch/docker-plane-watch:latest
    tty: true
    container_name: planewatch
    restart: always
    environment:
      - BEASTHOST=YOUR_BEASTHOST
      - TZ=YOUR_TIMEZONE
      - API_KEY=YOUR_API_KEY
      - LAT=YOUR_LATITUDE
      - LONG=YOUR_LONGITUDE
      - ALT=YOUR_ALTITUDE
    tmpfs:
      - /run:exec,size=64M
      - /var/log
```

Where:

* `YOUR_TIMEZONE` is your timezone in ["TZ database name" format](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List) (eg: `Australia/Perth`)
* `YOUR_BEASTHOST` is the hostname, IP address or container name of a beast protocol provider (eg: `piaware`)
* `YOUR_API_KEY` is your plane.watch feeder API Key
* `YOUR_LATITUDE` is the latitude of your antenna (xx.xxxxx)
* `YOUR_LONGITUDE` is the longitude of your antenna (xx.xxxxx)
* `YOUR_ALTITUDE` is the your antenna altitude, and should be suffixed with either `m` or `ft`. If no suffix, will default to `m`.

You can test to ensure your container is seeing ADS-B data by running:

```
docker exec -it planewatch viewadsb
```

<!-- ## Advanced Configuration

[plane.watch](https://plane.watch) now supports receiving ACARS and VDLM2! If you have multiple SDRs and feel so inclined, we would love your ACARS & VDLM2 data.

Here is an example configuration:

```yaml
  acarsdec:
    image: ghcr.io/sdr-enthusiasts/docker-acarsdec:latest
    tty: true
    container_name: acarsdec
    restart: always
    devices:
      - /dev/bus/usb:/dev/bus/usb
    environment:
      - TZ=YOUR_TIMEZONE
      - SERIAL=ACARS_SERIAL
      - FREQUENCIES=YOUR_FREQUENCIES
      - GAIN=YOUR_GAIN
      - SERVER=acars_router
      - SERVER_PORT=5550
    depends_on:
      - acars_router
    tmpfs:
      - /run:exec,size=64M
      - /var/log

  dumpvdl2:
    image: ghcr.io/sdr-enthusiasts/docker-dumpvdl2:latest
    tty: true
    container_name: dumpvdl2
    restart: always
    devices:
      - /dev/bus/usb:/dev/bus/usb
    environment:
      - TZ=YOUR_TIMEZONE
      - SERIAL=VDLM2_SERIAL
      - FREQUENCIES=YOUR_FREQUENCIES
      - GAIN=YOUR_GAIN
      - SERVER=acars_router
      - SERVER_PORT=5555
      - ZMQ_MODE=server
      - ZMQ_ENDPOINT=tcp://0.0.0.0:45555
    depends_on:
      - acars_router
    tmpfs:
      - /run:exec,size=64M
      - /var/log

  acars_router:
    image: ghcr.io/sdr-enthusiasts/acars_router:latest
    tty: true
    container_name: acars_router
    restart: always
    environment:
      - TZ=YOUR_TIMEZONE
      - AR_SEND_UDP_ACARS=acarshub:5550
      - AR_SEND_UDP_VDLM2=acarshub:5555
      - AR_RECV_ZMQ_VDLM2=dumpvdl2:45555
      - AR_OVERRIDE_STATION_NAME=YOUR_STATION_NAME
    tmpfs:
      - /run:exec,size=64M
      - /var/log

  planewatch:
    image: planewatch/plane-watch:latest
    tty: true
    container_name: planewatch
    restart: always
    depends_on:
      - readsb
    environment:
      - BEASTHOST=YOUR_BEASTHOST
      - ACARS_HOST=acars_router
      - VDLM2_HOST=acars_router
      - TZ=YOUR_TIMEZONE
      - API_KEY=YOUR_API_KEY
      - LAT=YOUR_LATITUDE
      - LONG=YOUR_LONGITUDE
      - ALT=YOUR_ALTITUDE
    tmpfs:
      - /run:exec,size=64M
      - /var/log
```

Where:

* `YOUR_TIMEZONE` is your timezone in ["TZ database name" format](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List) (eg: `Australia/Perth`)
* `YOUR_BEASTHOST` is the hostname, IP address or container name of a beast protocol provider (eg: `piaware`)
* `YOUR_API_KEY` is your plane.watch feeder API Key
* `YOUR_STATION_NAME` is the name of your station
* `ACARS_SERIAL` the serial of your ACARS SDR
* `VDLM2_SERIAL` the serial of your VDLM2 SDR
* `YOUR_FREQUENCIES` the ACARS/VDLM2 frequencies
* `YOUR_GAIN` the ACARS/VDLM2 gain
* `YOUR_LATITUDE` is the latitude of your antenna (xx.xxxxx)
* `YOUR_LONGITUDE` is the longitude of your antenna (xx.xxxxx)
* `YOUR_ALTITUDE` is the your antenna altitude, and should be suffixed with either `m` or `ft`. If no suffix, will default to `m`.

For more information on ACARS/VDLM2, please see:

* [sdr-enthusiasts/docker-acarshub](https://github.com/sdr-enthusiasts/docker-acarshub/blob/main/README.md)
* [sdr-enthusiasts/docker-acarsdec](https://github.com/sdr-enthusiasts/docker-acarsdec/blob/main/README.md)
* [sdr-enthusiasts/docker-dumpvdl2](https://github.com/sdr-enthusiasts/docker-dumpvdl2/blob/main/README.md)
* [sdr-enthusiasts/acars_router](https://github.com/sdr-enthusiasts/acars_router/blob/main/README.md) -->

## Environment Variables

There are a series of available environment variables:

| Environment Variable | Purpose | Default |
| --- | --- | --- |
| `API_KEY` | Required. Your plane.watch API Key | |
| `BEASTHOST` | Required. IP, hostname or container name of a Mode-S/BEAST provider (readsb/dump1090) | |
| `BEASTPORT` | Optional. TCP port number of Mode-S/BEAST provider (readsb/dump1090) | `30005` |
| `LAT` | Required for MLAT | Latitude of receiver antenna | |
| `LONG` | Required for MLAT | Longitude of receiver antenna | |
| `ALT` | Required for MLAT | Altitude of receiver antenna. Suffixed with `ft` or `m`. | |
| `ENABLE_MLAT` | Optional. Set to `false` to disable MLAT | `true` |
| `MLAT_DATASOURCE` | Optional. IP/Hostname and port of an MLAT data source | `BEASTHOST:BEASTPORT` setting if omitted |
| `TZ` | Optional. Your local timezone | `GMT` |
| `ACARS_HOST` | Optional. IP, hostname or container name of a TCP ACARS source (eg: acars_router) | |
| `ACARS_PORT` | Optional. TCP port number of TCP ACARS source (eg: acars_router) | `15550` |
| `VDLM2_HOST` | Optional. IP, hostname or container name of a TCP VDLM2 source (eg: acars_router) | |
| `VDLM2_PORT` | Optional. TCP port number of TCP VDLM2 source (eg: acars_router) | `15555` | -->

## Logging

* All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting help

Please feel free to:

* [Open an issue on the project's GitHub](https://github.com/plane-watch/docker-plane-watch/issues).
* [Join our Discord](https://discord.gg/QjKdHDFgkj) and say g'day.
