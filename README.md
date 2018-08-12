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
