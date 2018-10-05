# kumite73_microservices
kumite73 microservices repository

## Docker 1

Устанавливаем Docker
Зваускаем контейнер `hello-world`

    docker run hello-world
    
Вывод запущенных контейнеров

    docker ps
    
Список всех контейнеров

    docker ps -a

Список сохранненных образов

    docker images
    
Команда `run ` создает и запускает контейнер `из image`

    docker run -it ubuntu:16.04 /bin/bash
    
Docker run каждый раз запускает новый контейнер
Если не указывать флаг --rm при запуске docker run, то после остановки контейнер вместе с содержимым остается на диске

`docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.CreatedAt}}\t{{.Names}}"`

```
docker start af78c1107e98
docker attach af78c1107e98
root@af78c1107e98:/#
root@af78c1107e98:/#  cat /tmp/file
Hello world!
root@af78c1107e98:/#
```

Отсоединяемся от контейнера `Ctrl + p, Ctrl + q`

docker run = docker create + docker start + docker attach* `* при наличии опции -i`
docker create используется, когда не нужно стартовать контейнер сразу 
в большинстве случаев используется docker run
```
-i – запускает контейнер в foreground режиме (docker attach)
-d – запускает контейнер в background режиме
-t создает TTY
docker run -it ubuntu:16.04 bash
docker run -dt nginx:latest
```

`Docker exec` Запускает новый процесс внутри контейнера

```
docker exec -it af78c1107e98 bash
root@af78c1107e98:/# ps axf
  PID TTY      STAT   TIME COMMAND
   18 pts/1    Ss     0:00 bash
   28 pts/1    R+     0:00  \_ ps axf
    1 pts/0    Ss+    0:00 /bin/bash
```

`Docker commit` Создает image из контейнера контейнер при этом остается запущенным

```
docker commit af78c1107e98 yourname/ubuntu-tmp-file
sha256:18519eef19be36d820b21db33809c23a97d6a52485271f42b84707c7da769138
mkdir docker-monolith
cd docker-monolith
docker images > docker-1.log
```

## Docker 2

Создал проект `docker`
Инициализировал `gcloud init`
Создал сервсиный ключ и задал в переменной `export GOOGLE_APPLICATION_CREDENTIALS=/home/user/docker-1111111111.json`
```
docker-machine create --driver google \
  --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
  --google-machine-type n1-standard-1 \
  --google-zone europe-west1-b \
  --google-project docker-111111 \
  docker-host

docker-machine ls
NAME          ACTIVE   DRIVER   STATE     URL                       SWARM   DOCKER        ERRORS
docker-host   *        google   Running   tcp://35.195.1.217:2376           v18.06.0-ce  

eval $(docker-machine env docker-host)
```

`docker run --rm -ti tehbilly/htop` видим 1 процесс с PID 1 запущенный от root

`docker run --rm --pid host -ti tehbilly/htop` видны все процессы хоста

mongod.conf
```
# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
    journal:
    enabled: true
# where to write logging data.
systemLog:
  destination: file
  logAppend: true
path: /var/log/mongodb/mongod.log
# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1
```

db_config
```
DATABASE_URL=127.0.0.1
```

start.sh
```
#!/bin/bash

/usr/bin/mongod --fork --logpath /var/log/mongod.log --config /etc/mongodb.conf

source /reddit/db_config

cd /reddit && puma || exit
```

Dockerfile
```
FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential git
RUN gem install bundler
RUN git clone -b monolith https://github.com/express42/reddit.git

COPY mongod.conf /etc/mongod.conf
COPY db_config /reddit/db_config
COPY start.sh /start.sh

RUN cd /reddit && bundle install
RUN chmod 0777 /start.sh

CMD ["/start.sh"]
```

Выполняем `docker build -t reddit:latest .`
Смотрим все образы `docker images -a`
Запускаем контейнер `docker run --name reddit -d --network=host reddit:latest`
Проверяем результат `docker-machine ls`
```
NAME          ACTIVE   DRIVER   STATE     URL                       SWARM   DOCKER        ERRORS
docker-host   *        google   Running   tcp://35.195.1.217:2376           v18.06.0-ce
```
Разрешаем входящий триафик для 9292
```
gcloud compute firewall-rules create reddit-app \
  --allow tcp:9292 \
  --target-tags=docker-machine \
  --description="Allow PUMA connections" \
  --direction=INGRESS
```
Заходим в учетную запись DockerHub `docker login`

Устанавливаем тег `docker tag reddit:latest kumite/otus-reddit:1.0`
Загружаем образ в DockerHub `docker push kumite/otus-reddit:1.0`
Выполняем на другой машине `docker run --name reddit -d -p 9292:9292 kumite/otus-reddit:1.0`
Проверки
```
docker logs reddit -f
docker exec -it reddit bash
   ps aux 
   killall5 1
docker start reddit
docker stop reddit && docker rm reddit
docker run --name reddit --rm -it kumite/otus-reddit:1.0 bash
  ps aux
  exit
docker inspect kumite/otus-reddit:1.0
docker inspect kumite/otus-reddit:1.0 -f '{{.ContainerConfig.Cmd}}'
docker run --name reddit -d -p 9292:9292 <your-login>/otus-reddit:1.0
docker exec -it reddit bash
  mkdir /test1234
  touch /test1234/testfile
  rmdir /opt
  exit
docker diff reddit
docker stop reddit && docker rm reddit
docker run --name reddit --rm -it <your-login>/otus-reddit:1.0 bash
  ls / 
```

## Docker 3

Подключаемся 
```
docker-machine ls
eval $(docker-machine env docker-host)
```
Подготавливаем архив
Создаем файл `./post-py/Dockerfile`
Оптимизируем структуру, меняем ADD на COPY
```
FROM python:3.6.0-alpine
ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts
WORKDIR /app
COPY . /app
RUN pip install -r /app/requirements.txt
ENTRYPOINT ["python3", "post_app.py"]
```

Создаем файл `./comment/Dockerfile`
Оптимизируем структуру, меняем ADD на COPY
```
FROM ruby:2.2
RUN apt-get update -qq && apt-get install -y build-essential
ENV APP_HOME /app
ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY . $APP_HOME/
RUN bundle install
CMD ["puma"]
```
Создаем файл `./ui/Dockerfile`
Оптимизируем структуру, меняем ADD на COPY
```
FROM ruby:2.2
RUN apt-get update -qq && apt-get install -y build-essential
ENV APP_HOME /app
ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY . $APP_HOME
RUN bundle install
CMD ["puma"]
```
Для сборки и запуска создаем `build.sh`
```
docker pull mongo:latest
docker build -t kumite/post:1.0 ./post-py
docker build -t kumite/comment:1.0 ./comment
docker build -t kumite/ui:1.0 ./ui
docker network create reddit
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post kumite/post:1.0
docker run -d --network=reddit --network-alias=comment kumite/comment:1.0
docker run -d --network=reddit -p 9292:9292 kumite/ui:1.0
```
Сборка началась не с 1 шага, потому-что образ `ruby:2.2` уже в кеше
Меняем `./ui/Dockerfile`
```
FROM ubuntu:16.04
RUN apt-get update \
    && apt-get install -y ruby-full ruby-dev build-essential \
    && gem install bundler --no-ri --no-rdoc
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME
ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292
CMD ["puma"]
```

### Задание *

Ортимизируем `ui/Docker` для этого испольpуем образ `ruby:2.2-alpine` чистим кэш после установки пакетов, убираем лишние вызовы
```
FROM ruby:2.2-alpine
RUN apk update \
    &&apk add  build-base  \
    && rm -rf /var/cache/apk/
ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY . $APP_HOME
RUN bundle install
CMD ["puma"]
```

Результат
```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
kumite/ui           2.0                 9d7b3ff5bc91        22 seconds ago      301MB
kumite/ui           1.0                 7b519c32219e        7 minutes ago       460MB
```
Создадим docker volume `docker volume create reddit_db`
Изменим команду запуска для монго
```
docker run -d --network=reddit --network-alias=comment_db \
  --network-alias=comment_db \
  -v reddit_db:/data/db mongo:latest
```
Перезапусим контейнеры


## Docker 4
Подключаемся к докер машине
```
docker-machine ls
eval $(docker-machine env docker-host)
```
Выполняем `docker run --network none --rm -d --name net_test joffotron/docker-net-tools -c "sleep 100"`
Проверяем `docker exec -ti net_test ifconfig`
Запускаем контейнер в сетевом пространстве docker-хоста `docker run --network host --rm -d --name net_test joffotron/docker-net-tools -c "sleep 100"`
Сравниваем выводы команд:
```
docker exec -ti net_test ifconfig
docker-machine ssh docker-host ifconfig
```
Они одинаковые, разница только в трафике.
Выполняем 4 раза
```
docker run --network host -d nginx
docker run --network host -d nginx
docker run --network host -d nginx
docker run --network host -d nginx
```
Запущен первый котенйер, остальные закрываются, так-как 80 порт хостовой системы заянт первым.
На docker-host машине выполняем `sudo ln -s /var/run/docker/netns /var/run/netns`
Смотрим `net-namespaces` с помощью команды `sudo ip netns`
Создаем bridge-сеть в docker `docker network create reddit --driver bridge`
Запускаем приложение с использованием сети  `reddit`
```
docker run -d --network=reddit mongo:latest
docker run -d --network=reddit kumite/post:1.0
docker run -d --network=reddit kumite/comment:1.0
docker run -d --network=reddit -p 9292:9292 kumite/ui:1.0
```
Остановим старые копии контейнеров `docker kill $(docker ps -q)`
```
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
docker run -d --network=reddit --network-alias=post kumite/post:1.0
docker run -d --network=reddit --network-alias=comment kumite/comment:1.0
docker run -d --network=reddit -p 9292:9292 kumite/ui:1.0
```
Остановим старые копии контейнеров `docker kill $(docker ps -q)`
Создаем docker-сети
```
docker network create back_net --subnet=10.0.2.0/24
docker network create front_net --subnet=10.0.1.0/24
```
Разбиваем контейнеры по сетям
```
docker run -d --network=back_net --name mongo_db --network-alias=comment_db --network-alias=post_db mongo:latest
docker run -d --network=back_net --name post kumite/post:1.0
docker run -d --network=back_net --name comment kumite/comment:1.0
docker run -d --network=front_net -p 9292:9292 --name ui kumite/ui:1.0
```
Подключим контейнеры ко второй сети
```
docker network connect front_net post
docker network connect front_net comment
```
Заходим на машину `docker-machine ssh docker-host`
Ставим пакет `bridge-utils`
```
sudo apt-get update && sudo apt-get install bridge-utils
```
ID сетей созданных  в проекте `sudo docker network ls`
```
NETWORK ID          NAME                DRIVER              SCOPE
246ba0e1e0d0        back_net            bridge              local
51f29fab138c        front_net           bridge              local
64138b78c525        reddit              bridge              local
```

```
ifconfig | grep br
br-246ba0e1e0d0 Link encap:Ethernet  HWaddr 02:42:86:f7:c3:9f
br-51f29fab138c Link encap:Ethernet  HWaddr 02:42:35:58:81:9e
br-64138b78c525 Link encap:Ethernet  HWaddr 02:42:1f:3a:8d:56
```

Информация
```
brctl show br-246ba0e1e0d0
bridge name     bridge id                   STP enabled interfaces
br-246ba0e1e0d0         8000.024286f7c39f       no      veth55cacfd
                                                        veth8ee4979
                                                        vethe8a9750
```

Смотрим информацию `sudo iptables -nL -t nat`
```
Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
MASQUERADE  all  --  10.0.1.0/24          0.0.0.0/0
MASQUERADE  all  --  10.0.2.0/24          0.0.0.0/0
MASQUERADE  all  --  172.18.0.0/16        0.0.0.0/0
MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0
MASQUERADE  tcp  --  10.0.1.2             10.0.1.2             tcp dpt:9292
```

Выполняем `ps ax | grep docker-proxy`
```
21218 ?        Sl     0:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 9292 -container-ip 10.0.1.2 -container-port 9292
22245 pts/0    S+     0:00 grep --color=auto docker-proxy
```
### Docker-compose

Устанавливаем `docker-compose`
Создаем `docker-compose.yml`
```
version: '3.3'
services:
  post_db:
    image: mongo:3.2
    volumes:
      - post_db:/data/db
    networks:
      - reddit
  ui:
    build: ./ui
    image: ${USERNAME}/ui:1.0
    ports:
      - 9292:9292/tcp
    networks:
      - reddit
  post:
    build: ./post-py
    image: ${USERNAME}/post:1.0
    networks:
      - reddit
  comment:
    build: ./comment
    image: ${USERNAME}/comment:1.0
    networks:
      - reddit
volumes:
  post_db:
networks:
  reddit:
```

Создаем `.env`
```
USERNAME=kumite
```

Выполняем 
```
docker kill $(docker ps -q)
docker-compose up -d
docker-compose ps
    Name                  Command             State           Ports
src_comment_1   puma                          Up
src_post_1      python3 post_app.py           Up
src_post_db_1   docker-entrypoint.sh mongod   Up      27017/tcp
src_ui_1        puma                          Up      0.0.0.0:9292->9292/tcp
```

Изменяем `docker-compose.yml`
```
version: '3.3'
services:
  post_db:
    image: mongo:3.2
    volumes:
      - post_db:/data/db
    networks:
      back_net:
        aliases:
          - comment_db
          - post_db
  ui:
    build: ./ui
    image: ${USERNAME}/ui:${VERSION}
    ports:
      - ${PORT_UI}:${PORT_UI}/tcp
    networks:
      - front_net
  post:
    build: ./post-py
    image: ${USERNAME}/post:${VERSION}
    networks:
      - front_net
      - back_net
  comment:
    build: ./comment
    image: ${USERNAME}/comment:${VERSION}
    networks:
      - front_net
      - back_net
volumes:
  post_db:
networks:
  back_net:
    driver: bridge
    ipam:
      driver: default
      config:
      -
        subnet: 10.0.2.0/24
     front_net: 
    driver: bridge
    ipam:
      driver: default
      config:
      -
        subnet: 10.0.1.0/24
```

Переопределить базовое имя проекта можно задав пременную `export COMPOSE_PROJECT_NAME=GCP_KUMITE` или прописав в файл `.env`

### Docker 4 *

Создаем `docker-compose.override.yml`
На машине где запущен docker демон должна быть папка /app с подпаками с исходным кодом для каждого приложения.
```
version: '3.3'
services:
  ui:
    command: ["puma", "--debug", "-w", "2"]
    volumes:
      - /app/ui:/app
  post:
    volumes:
      - /app/post-py:/app
  comment:
    command: ["puma", "--debug", "-w", "2"]
    volumes:
      - /app/comment:/app
```
