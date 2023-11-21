---
title: "Behind The Scenes"
menu:
  main:
    weight: 1
showDate: false
draft: false
---

## Overview ##

This article aims to explain how we have re-designed and re-written the backend used to collect, enrich and display the ADSB data our community sends us. 

## Anatomy of a Feeder Connection ##
When you follow our [docker_planewatch] 
![plane.watch feeder connection anatomy](Connection%20Anatomy.drawio.png)

1. [pw-feeder][pw-feeder] opens two connections to [Bordercontrol](#bordercontrol) - one connection for [BEAST][beast protocol], and another for [MLAT][mlat-client].
2. During connection establishment, [Bordercontrol](#bordercontrol) checks the validity of the feeder's API key. If invalid, the connection is dropped. If valid, the connection is allowed, and [bordercontrol](#bordercontrol) starts a "feed-in" container for the client.
3. Bordercontrol proxies [BEAST][beast protocol] traffic to the feed-in container.
4. Bordercontrol proxies [MLAT][mlat-client] traffic to an [mlat_server][mlat-server] instance running on the regional multiplexer.
5. For the "new" environment, [pw_ingest](#pw_ingest) running within the feed-in container decodes the [BEAST][beast protocol] data, and publishes the data as a message onto the NATS message bus. The data is processed through the [pw-pipeline][pw-pipeline].
6. For the "legacy" environment, the [BEAST][beast protocol] data for each region is multiplexed in each regional multiplexer. Virtual Radar Server then consumes this data for the legacy front-end.

## Components ##

### ADS-B Traffic Control (ATC) ###

[ATC][atc] is [plane.watch][plane.watch]'s feeder portal. It provides:

* User sign-up and account management
* Feeder creation and management
* Databases containing aircraft types, airports, routes, operators and waypoints

[ATC][atc] provides both public and private APIs. The public API is used by [pw-feeder](#pw-feeder) to report the feeder's status back to the client.

The private API is used to:

* Authenticate feeders upon connection to [bordercontrol](#bordercontrol)
* Provide aircraft types, airports, routes, operators and waypoints to the [Enrichment Centre](#pw-enrichment)

### pw-feeder ###

[pw-feeder][pw-feeder], simply put, it is a [BEAST][beast protocol] and [MLAT][mlat] protocol specific [stunnel][stunnel] client, that securely proxies data from the client to [plane.watch][plane.watch]'s servers (specifically [bordercontrol](#bordercontrol) - see below).

[pw-feeder][pw-feeder] runs on the feeder client computer, and receives [BEAST protocol][beast protocol] data from software such as [dump1090][dump1090] and [readsb][readsb], or from hardware devices such as the [Jetvision Radarcape][radarcape]. It also communicates with [mlat-client][mlat-client] software running on the client, and mlat-server software running within [plane.watch][plane.watch].

[Stunnel][stunnel] is used to ensure that the data you send to us is encrypted and tamper resistant. Furthermore, we send the feeder's plane.watch API key in the TLS request's [Server Name Indication (SNI)][sni] field, allowing us to determine which data is associated to which feeder.

### bordercontrol ###

**Bordercontrol** is our custom-written feed receiver. Its job is to handle the many incoming connections from feeders running our [pw-feeder][pw-feeder] client software.

When a [pw-feeder][pw-feeder] client connects:

1. The feeder's API key is read from the stunnel's [SNI][sni] information.
2. Bordercontrol queries [ATC](#ads-b-traffic-control-atc) to determine if the API key matches that of a valid feeder.
3. If the API key is valid, a unique "feed-in" container is spun up for that client. If the API key is invalid, the connection is dropped.
4. The incoming [BEAST][beast protocol] connection is proxied to the feed-in container.
5. The incoming [MLAT][mlat] connection is proxied to an instance of [mlat-server][mlat-server] running on the regional multiplexer.

### pw_ingest ###

[**pw_ingest**][pw-pipeline] runs on each feed-in container. It decodes [BEAST][beast protocol] protocol frames, and publishes the data as messages to [NATS][nats], for processing through the [plane.watch pipeline][pw-pipeline]. Messages are tagged with the feeder's API key, so the source of the data can be tracked throughout the processing pipeline.

### pw-enrichment ###

**pw-enrichment**, also known as EC (enrichment centre), consumes decoded ADS-B frames from the [NATS][nats] message queue and adds additional information relating to the aircraft, route and other metadata. The EC maintains an internal memory-cache so as to not overwhelm the ATC database, given the message rate can be in the thousands of messages a second.

### pw_router ###

[**pw_router**][pw-pipeline] takes enriched data and reduces it down to significant events, thus cutting the message rate significantly. The router also publishes two feeds to the NATS bus - a high resolution and a low resolution - these are used in the UI to not overwhelm the browser with messages.

Router also connects to an instance of [ClickHouse], a highly scalable columnar database designed for storing timeseries data - perfect for ADSB. Both high and low resolution feeds are stored to Clickhouse for later analysis and for drawing the historical paths in the UI.

### pw_ws_broker ###

[**pw_ws_broker**][pw-pipeline] is a horizontally scalable service that provides a [WebSocket][websocket] interface to connect the public web interface with the backend pipeline. When a user loads the public website, a websocket is dialed up to this service to stream ADSB updates from the pipeline directly to the user.

The broker also provides streaming APIs for querying ATC for more detailed route and airframe information as well as querying ClickHouse for historical track information.


### pw-ui ###

**pw-ui** is a lightweight Ruby on Rails app that serves the HTML/CSS/Javascript for the [beta.plane.watch][beta] frontend. [Stimulus] is the Javascript framework we chose as it models functionality through flexible controllers that integrate with HTML, in-line, to bind dynamic behaviour. 

The map view is based on the [OpenLayers] framework which provides a high-performance interface to the HTML Canvas API or WebGL. 

## In Conclusion ##

We are aiming to launch our new UI (currently accessible via [https://beta.plane.watch][beta]) in December of 2023. At this point in time, our private [GitHub repositories][pwgithub] will become public, making this project fully open source.

### How Can I Get Involved? ###

* [Join our Discord][pwdiscord]. Come say G'day!
* [Become a Feeder][pwgettingstarted]. Share your ADSB data!
* [Contribute Financially][pwpatreon]. Help us fund our server and hosting costs!
* Submit code to our repositories. We would recommend discussing your proposed code changes in our Discord prior to submitting any pull requests.

<!-- links -->
[docker_planewatch]: https://github.com/plane-watch/docker-plane-watch "Docker Plane Watch"
[beast protocol]: https://github.com/firestuff/adsb-tools/blob/master/protocols/beast.md
[dump1090]: https://github.com/flightaware/dump1090 "dump1090"
[mlat]: https://www.icao.int/APAC/Documents/edocs/mlat_concept.pdf "Multilateration (MLAT)"
[plane.watch]: https://plane.watch "plane.watch website"
[pw-feeder]: https://github.com/plane-watch/pw-feeder "pw-feeder client software"
[radarcape]: https://jetvision.de/radarcape-ads-b-receiver/ "Jetvision Radarcape"
[readsb]: https://github.com/Mictronics/readsb-protobuf "readsb-protobuf"
[sni]: https://en.wikipedia.org/wiki/Server_Name_Indication "Server Name Indication"
[stunnel]: https://en.wikipedia.org/wiki/Stunnel "stunnel Wikipedia page"
[mlat-client]: https://github.com/mutability/mlat-client "mlat-client"
[mlat-server]: https://github.com/mutability/mlat-server "mlat-server"
[atc]: https://atc.plane.watch "ADS-B Traffic Control (ATC)"
[pw-pipeline]: https://github.com/plane-watch/pw-pipeline "Plane.Watch Pipeline"
[nats]: https://nats.io "NATS.io"
[beta]: https://beta.plane.watch "beta.plane.watch"
[clickhouse]: https://github.com/ClickHouse/ClickHouse?utm_source=clickhouse&utm_medium=website&utm_campaign=website-nav "ClickHouse"
[websocket]: https://en.wikipedia.org/wiki/WebSocket "WebSocket"
[stimulus]: https://en.wikipedia.org/wiki/WebSocket "Stimulus"
[openlayers]: https://openlayers.org "OpenLayers"
[pwgithub]: https://github.com/orgs/plane-watch/repositories "plane.watch GitHub"
[pwdiscord]: https://discord.gg/wgDRk8JZCt "Join our Discord!"
[pwgettingstarted]: https://web.plane.watch/getting_started/ "Getting Started"
[pwpatreon]: https://www.patreon.com/planewatch "Support us on Patreon"
