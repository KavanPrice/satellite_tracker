FROM influxdb:2.7

RUN mkdir -p /var/lib/influxdb2 && \
    mkdir -p /var/lib/influxdb2/data && \
    mkdir -p /var/lib/influxdb2/config

EXPOSE 8086

VOLUME /var/lib/influxdb2

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:8086/health || exit 1

ENTRYPOINT ["influxd"]
