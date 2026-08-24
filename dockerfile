FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    libcurl4 \
    libssl3 \
    ca-certificates \
    tini \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /mcbe

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 19132/udp

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/start.sh"]