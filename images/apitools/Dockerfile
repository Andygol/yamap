FROM debian:stable-slim

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    osmosis \
    curl \
    bzip2 \
    osmctools \
    osmium-tool \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ADD ./apidb-tools.sh /
RUN ["chmod", "+x", "/apidb-tools.sh"]
CMD /apidb-tools.sh replicate