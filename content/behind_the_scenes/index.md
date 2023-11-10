---
title: "Behind The Scenes"
menu:
  main:
    weight: 1
showDate: false
draft: false
---

## Overview ##

How the sausage is made. The sometimes unpleasant way in which a process or activity is carried on behind the scenes...

This article aims to explain how we at [plane.watch][plane.watch] have architected the back-end. It may provide insight to those of you curious to what happens to the data you send us.

![plane.watch back-end diagram](Architecture%20Overview.drawio.png)

## Anatomy of a Connection ##

![plane.watch feeder connection anatomy](Connection%20Anatomy.drawio.png)

1. [pw-feeder][pw-feeder] opens two connections to [Bordercontrol](#bordercontrol) - one connection for [BEAST][beast protocol], and another for [MLAT][mlat-client].
2. During connection establishment, [Bordercontrol](#bordercontrol) checks the validity of the feeder's API key. If invalid, the connection is dropped. If valid, the connection is allowed, and [bordercontrol](#bordercontrol) starts a "feed-in" container for the client.
3. Bordercontrol proxies [BEAST][beast protocol] traffic to the feed-in container.
4. Bordercontrol proxies [MLAT][mlat-client] traffic to an [mlat_server][mlat-server] instance running on the regional multiplexer.
5. For the "new" environment, [pw_ingest](#pw_ingest) running within the feed-in container decodes the [BEAST][beast protocol] data, and publishes the data as a message onto the NATS message bus. The data is processed through the [pw-pipeline][pw-pipeline].
6. For the "legacy" environment, the [BEAST][beast protocol] data for each region is multiplexed in each regional multiplexer. Virtual Radar Server then consumes this data for the legacy front-end.

## Component Detail ##

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

**pw-enrichment** consumes decoded ADS-B frames from the [NATS][nats] message queue and adds additional information relating to the plane, route and other items.

### pw_router ###

[**pw_router**][pw-pipeline] takes enriched data and reduces it down to significant events. Optionally, it will publish messages out to individual tile queues for low and high speed updates.

### pw_ws_broker ###

[**pw_ws_broker**][pw-pipeline] provides the aircraft position data to website clients. When [pw-ui](#pw-ui) is rendered on the client's browser, the client starts a websocket session and requests which tiles it are interested in (depending on which part of the world they are looking at, and what zoom level).

### pw-ui ###

**pw-ui** provides the client HTML, CSS and Javascript for [beta.plane.watch][beta].

<!-- links -->
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