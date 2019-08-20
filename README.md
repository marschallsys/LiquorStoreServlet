# POC for DSIRF
[![Build Status](https://drone.poc.marschall.systems/api/badges/marschallsys/LiquorStoreServlet/status.svg)](https://drone.poc.marschall.systems/marschallsys/LiquorStoreServlet)

Proof of Concept for a simple CD pipeline powered by [drone.io](https://drone.io/).
Drone is setup with a simple docker-compose file:
```yaml
version: "2"
networks:
  web:
    external: true
services:
  server:
    image: drone/drone:1
    privileged: true
    environment:
     - DRONE_USER_FILTER=marschallsys,cbaykam,drale2k
     - DRONE_GITHUB_CLIENT_ID=<id>
     - DRONE_GITHUB_CLIENT_SECRET=<secret>
     - DRONE_GIT_ALWAYS_AUTH=false
     - DRONE_RUNNER_CAPACITY=2
     - DRONE_SERVER_HOST=drone.poc.marschall.systems
     - DRONE_ADMIN=marschallsys
     - DRONE_LOGS_DEBUG=true
     - DRONE_HOST=https://drone.poc.marschall.systems
    restart: always
    networks:
     - web
    volumes:
     - /var/run/docker.sock:/var/run/docker.sock
     - /data/drone_poc_marschall_systems:/data
     - "/etc/timezone:/etc/timezone:ro"
     - "/etc/localtime:/etc/localtime:ro"
    labels:
     - "traefik.backend=drone"
     - "traefik.port=80"
     - "traefik.docker.network=web"
     - "traefik.frontend.rule=Host:drone.poc.marschall.systems"
     - "traefik.enable=true"
```
The drone-pipeline is defined by [ .drone.yml](https://github.com/marschallsys/LiquorStoreServlet/blob/master/.drone.yml)

The pipeline is hosted at [drone.poc.marschall.systems](https://drone.poc.marschall.systems)

The staging Environment is hosted at [rev.poc.marschall.systems](https://rev.poc.marschall.systems)

The production Environment is hosted at [prod.poc.marschall.systems](https://prod.poc.marschall.systems)

A Healthcheck is implemented with the Docker Healthcheck API -> [Dockerfile](https://github.com/marschallsys/LiquorStoreServlet/blob/master/Dockerfile#L16)

## Monitoring
- docker-compose:  
```
version: "2"

networks:
  web:
    external: true

services:
  server:
    image: prom/prometheus
    restart: always
    networks:
     - web
     - default
    volumes:
     - ${PWD}/prometheus.yml:/etc/prometheus/prometheus.yml
     - "/etc/timezone:/etc/timezone:ro"
     - "/etc/localtime:/etc/localtime:ro"
    labels:
     - "traefik.backend=prom"
     - "traefik.port=9090"
     - "traefik.docker.network=web"
     - "traefik.frontend.rule=Host:prom.poc.marschall.systems"
     - "traefik.enable=true"
  cadvisor:
    image: google/cadvisor:latest
    container_name: cadvisor
    #ports:
    #- 8080:8080
    volumes:
    - /:/rootfs:ro
    - /var/run:/var/run:rw
    - /sys:/sys:ro
    - /var/lib/docker/:/var/lib/docker:ro
    - "/etc/timezone:/etc/timezone:ro"
    - "/etc/localtime:/etc/localtime:ro"
    depends_on:
    - redis
  redis:
    image: redis:latest
    container_name: redis
    #ports:
    #- 6379:6379
  grafana:
    image: grafana/grafana
    networks:
     - web
     - default
    volumes:
     - ${PWD}/grafana:/var/lib/grafana
     - "/etc/timezone:/etc/timezone:ro"
     - "/etc/localtime:/etc/localtime:ro"
    labels:
     - "traefik.backend=poc_gf"
     - "traefik.port=3000"
     - "traefik.docker.network=web"
     - "traefik.frontend.rule=Host:gf.poc.marschall.systems"
     - "traefik.enable=true"
```
- [Prometheus](https://prom.poc.marschall.systems)  
```
global:
  scrape_interval:     10s
  evaluation_interval: 10s
  external_labels:
      monitor: 'codelab-monitor'
rule_files:
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'docker'
    static_configs:
      - targets: ['172.28.0.1:9323']
  - job_name: cadvisor
    scrape_interval: 5s
    static_configs:
    - targets:
      - cadvisor:8080
```
- CAdvisor
- [Grafana](https://gf.poc.marschall.systems)  
-> is handling alerting (alert dashboard)

## Deploying in Production

You need [drone-cli](https://docs.drone.io/cli/install/) installed and following environment variables:  
```
export DRONE_SERVER=https://drone.poc.marschall.systems
export DRONE_TOKEN=<your access token goes here>
```
Let's stage Build Nr 62 to Production:  
`drone build promote marschallsys/LiquorStoreServlet 62 production`

## Future bottlenecks

- If multiple people are working on the repo the pipeline needs to be adjusted to depoly individual staging environments for each branch
- If the production and staging environments are clusters (Dockerswarm/Kubernetes) the run commands in the pipeline need to be adjusted ([line 22-23](https://github.com/marschallsys/LiquorStoreServlet/blob/master/.drone.yml#L22-L23) and [line 9-10](https://github.com/marschallsys/LiquorStoreServlet/blob/master/.drone.yml#L9-L10)) and the Container needs to be pushed to a registry accessable by both clusters (private or public)
- If testing is needed the pipline needs to be extended