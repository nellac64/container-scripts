#!/bin/bash

LOG_FILE="/var/log/apps/docker_starter/starter.log"

REDIS_STR="redis"
RABBITMQ_STR="rabbitmq"
MYSQL_STR="mysql"
NGINX_STR="nginx"
NACOS_STR="nacos"
SENTINAL_STR="sentinal"
PROMETHEUS_STR="promethues"

log() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $msg" >> "$LOG_FILE"
}

# start_docker_service 启动 docker 服务 删除旧的 stop 状态容器
start_docker_service() {
    log "enter start_docker_service"
    
    systemctl is-active --quiet docker
    if [[ "$?" -eq 0 ]]; then
        log "exit  do not need to restart docker service"
        return
    fi
    
    systemctl start docker

    sleep 1
    deleted_ids=$(docker rm -v $(docker ps -aq -f status=exited) 2>/dev/null)
    if [ -n "$deleted_ids" ]; then
        log "delete: $deleted_ids"
    fi
}

# is_docker_exist 判断 name_fix 的容器是否存在
is_docker_exist() {
    local name_fix="$1"
    docker_id=$(docker ps --filter "name=${name_fix}" -q)
    
    if [[ -z "$docker_id" ]]; then
        log "${name_fix} do not exist."
        echo 0
    else
        log "${name_fix} ${docker_id} exist."
        echo 1 
    fi
}

# start_redis_container_docker 启动 redis
start_redis_container_docker() {
    log "enter start_redis_container_docker."
    
    if [[ $(is_docker_exist "$REDIS_STR") -eq 1 ]]; then
        log "exit  start_redis_container_docker, redis exist."
        return
    fi
    
    docker run -d \
        -p 6389:6379 \
        --name myredis_1217 \
        --privileged=true \
        -v /app/redis/redis.conf:/etc/redis/redis.conf \
        -v /app/redis/data:/data \
        docker.1ms.run/redis:6.0.8 \
        redis-server /etc/redis/redis.conf
        
    if [[ "$?" -eq 0 ]]; then
        log "fin   start_redis_container_docker"
    else
        log "fail  start_redis_container_docker"
    fi
}

# start_rabbitmq_container_docker 启动 rabbitmq
start_rabbitmq_container_docker() {
    log "enter start_rabbitmq_container_docker."

    if [[ $(is_docker_exist "$RABBITMQ_STR") -eq 1 ]]; then
        log "exit  start_rabbitmq_container_docker, rabbitmq exist."
        return
    fi

    docker run -itd \
        --name my_rabbitmq \
        -p 5672:5672 \
        -p 15672:15672 \
        -e RABBITMQ_DEFAULT_USER=root \
        -e RABBITMQ_DEFAULT_PASS=123456 \
        -v /app/rabbitmq/data:/var/lib/rabbitmq \
        docker.1ms.run/library/rabbitmq:3.13-management-alpine
        
    if [[ "$?" -eq 0 ]]; then
        log "fin   start_rabbitmq_container_docker"
    else
        log "fail  start_rabbitmq_container_docker"
    fi
}

# start_mysql_container_docker 启动 mysql
start_mysql_container_docker() {
    log "enter start_mysql_container_docker."

    if [[ $(is_docker_exist "$MYSQL_STR") -eq 1 ]]; then
        log "exit  start_mysql_container_docker, mysql exist."
        return
    fi

    docker run \
        --name mysql \
        -p 3306:3306 \
        -e MYSQL_ROOT_PASSWORD=123456 \
        -v /app/mysql/conf/my.cnf:/etc/my.cnf \
        -v /app/mysql/data:/var/lib/mysql \
        -d \
        docker.1ms.run/mysql/mysql-server:5.7

    if [[ "$?" -eq 0 ]]; then
        log "fin   start_mysql_container_docker"
    else
        log "fail  start_mysql_container_docker"
    fi
}

# start_nginx_container_docker 启动 nginx
start_nginx_container_docker() {
    log "enter start_nginx_container_docker."

    if [[ $(is_docker_exist "$NGINX_STR") -eq 1 ]]; then
        log "exit  start_nginx_container_docker, nginx exist."
        return
    fi

    docker run \
        --name nginx \
        -p 80:80 \
        -p 443:443 \
        -v /app/nginx/html:/usr/share/nginx/html \
        -v /app/nginx/conf/nginx.conf:/etc/nginx/nginx.conf/ \
        -v /app/nginx/conf.d:/etc/nginx/conf.d/ \
        -v /app/nginx/logs:/var/log/nginx \
        -v /app/nginx/ssl:/etc/ssl \
        -d \
        docker.1ms.run/library/nginx:stable-alpine3.23

    if [[ "$?" -eq 0 ]]; then
        log "fin   start_nginx_container_docker"
    else
        log "fail  start_nginx_container_docker"
    fi
}

# start_nacos_container_docker 启动 nacos
start_nacos_container_docker() {
    log "enter start_nacos_container_docker."

    if [[ $(is_docker_exist "$NACOS_STR") -eq 1 ]]; then
        log "exit  start_nacos_container_docker, nacos exist."
        return
    fi
    
    docker run --name nacos -d \
        --name my_nacos \
        -p 8848:8848 \
        -p 9848:9848 \
        -e MODE=standalone \
        docker.1ms.run/nacos/nacos-server:v2.4.3
        
    if [[ "$?" -eq 0 ]]; then
        log "fin   start_nacos_container_docker"
    else
        log "fail  start_nacos_container_docker"
    fi
}

# start_sentinel_container_docker 启动 sentinel
start_sentinel_container_docker() {
    log "enter start_sentinel_container_docker."

    if [[ $(is_docker_exist "$SENTINAL_STR") -eq 1 ]]; then
        log "exit  start_sentinel_container_docker, nacos exist."
        return
    fi
    
    docker run \
        --name sentinel \
        -d \
        -p 8858:8858 \
        -p 8719:8719 \
        docker.1ms.run/bladex/sentinel-dashboard:1.8.6
        
    if [[ "$?" -eq 0 ]]; then
        log "fin   start_sentinel_container_docker"
    else
        log "fail  start_sentinel_container_docker"
    fi
}

# start_promethues_container_docker 启动 promethues
start_promethues_container_docker() {
    log "enter start_promethues_container_docker."

    if [[ $(is_docker_exist "$PROMETHEUS_STR") -eq 1 ]]; then
        log "exit  start_promethues_container_docker, promethues exist."
        return
    fi

    docker run -d \
        --name promethues \
        -p 9090:9090 \
        -v /app/prometheus/config:/etc/prometheus \
        -v /app/prometheus/data/prometheus:/prometheus \
        docker.1ms.run/prom/prometheus:v3.5.1
        
    if [[ "$?" -eq 0 ]]; then
        log "fin   start_promethues_container_docker"
    else
        log "fail  start_promethues_container_docker"
    fi
}

main() {
    log "====== enter starter ======"
    start_docker_service
    start_redis_container_docker
    start_rabbitmq_container_docker
    start_mysql_container_docker
    start_nginx_container_docker
    start_nacos_container_docker
    start_sentinel_container_docker
    start_promethues_container_docker
    log "====== exit  starter ======"
}

main