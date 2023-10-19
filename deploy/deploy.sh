#!/bin/bash

echo "------------------------- deploy start -------------------------"
cd /home/ubuntu/backend/deploy
pwd

# blue up if no blue, green up if blue
if docker ps | grep -q yangcheon-road-api-blue; then
  echo "green up"
  docker compose -p yangcheon-road-api-green -f ./docker-compose.green.yml up -d
  BEFORE_COMPOSE_COLOR="blue"
  AFTER_COMPOSE_COLOR="green"
else
  echo "blue up"
  docker compose -p yangcheon-road-api-blue -f ./docker-compose.blue.yml up -d
  BEFORE_COMPOSE_COLOR="green"
  AFTER_COMPOSE_COLOR="blue"
fi

# check if new container is still up after 10s
sleep 10s
if docker ps | grep -q yangcheon-road-api-${AFTER_COMPOSE_COLOR}; then
  # if no nginx, run new nginx container
  if docker ps | grep -q yangcheon-road-nginx; then
    docker cp ./nginx.${AFTER_COMPOSE_COLOR}.conf yangcheon-road-nginx:/etc/nginx/conf.d/nginx.backend.conf
    docker exec yangcheon-road-nginx nginx -s reload
    echo "nginx reloaded"
  else
    docker image build -t yangcheon-road-nginx:0.0.1 -f ./Dockerfile_nginx . --build-arg COMPOSE_COLOR="${AFTER_COMPOSE_COLOR}"
    docker run -d -p 80:80 -v /var/log/nginx:/var/log/nginx --name yangcheon-road-nginx yangcheon-road-nginx:0.0.1
    echo "new nginx started"
  fi

  # previous app down
  docker compose -p yangcheon-road-api-${BEFORE_COMPOSE_COLOR} -f ./docker-compose.${BEFORE_COMPOSE_COLOR}.yml down

  # remove all images without at least one container associated to them
  docker image prune -af

  echo "$BEFORE_COMPOSE_COLOR down"
fi
