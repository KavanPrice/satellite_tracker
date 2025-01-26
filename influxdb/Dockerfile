FROM influxdb:2.7

ENV DOCKER_INFLUXDB_INIT_MODE=setup
ENV DOCKER_INFLUXDB_INIT_USERNAME=admin
ENV DOCKER_INFLUXDB_INIT_PASSWORD=admin_password
ENV DOCKER_INFLUXDB_INIT_ORG=satellites
ENV DOCKER_INFLUXDB_INIT_BUCKET=satellites
ENV DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=your_admin_token_here

RUN mkdir -p /var/lib/influxdb2 && \
    mkdir -p /var/lib/influxdb2/data && \
    mkdir -p /var/lib/influxdb2/config

EXPOSE 8086

VOLUME /var/lib/influxdb2

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:8086/health || exit 1

ENTRYPOINT ["influxd"]
