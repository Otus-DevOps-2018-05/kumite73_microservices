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

## Gitlub-CI 1

Создаем директорорию `gitlub-ci`
Настриваем динамическйи инвентори для `ansible`

`ansible.cfg`

```
[defaults]
inventory = gce.py
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
host_key_checking = False
retry_files_enabled = False
#roles_path = ./roles
#vault_password_file = vault.key

[diff]
always = True
context = 5
```

`gce.py`

Заполняем `gce.ini`
```
gce_service_account_email_address = 11111111111111-compute@developer.gserviceaccount.com
gce_service_account_pem_file_path = ~/docker-1111111.json
gce_project_id = docker-1111111
gce_zone = europe-west3-b
instance_tags = http-server,https-server

```
Создаем playbook для создания вм в GCE `create-vm-for-gitlub.yml`
```
- name: Create instance(s)
  hosts: localhost
  connection: local
  gather_facts: yes
  vars:
    service_account_email: 11111111-compute@developer.gserviceaccount.com
    credentials_file: ~/docker-11111111111.json
    project_id: docker-212817
    machine_type: n1-standard-1
    image: ubuntu-1604-xenial-v20180814
    zone: europe-west3-b
    tags: http-server,https-server
    persistent_boot_disk: true
    disk_size: 100
  tasks:
   - name: Launch instances gitlab-ci
     gce:
         instance_names: gitlab-ci
         machine_type: "{{ machine_type }}"
         image: "{{ image }}"
         service_account_email: "{{ service_account_email }}"
         credentials_file: "{{ credentials_file }}"
         project_id: "{{ project_id }}"
         zone: "{{ zone }}"
         tags: "{{ tags }}"
         persistent_boot_disk: "{{ persistent_boot_disk }}"
         disk_size: "{{ disk_size }}"
```
Запускаем создание машины  `ansible-playbook create-vm-for-gitlub.yml`

Создаем playbook для настройки машины `prepare-vm.yml`
```
- hosts: all
  tasks:
  - name: Add Docker GPG key
    become: true
    apt_key: url=https://download.docker.com/linux/ubuntu/gpg
  - name: Add Docker APT repository
    become: true
    apt_repository:
      repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ansible_distribution_release}} stable
  - name: Install list of packages
    become: true
    apt:
      name: "{{ item }}"
      state: installed
      update_cache: yes
    with_items:
      - apt-transport-https
      - ca-certificates
      - curl
      - software-properties-common
      - docker-ce
      - docker-compose
  - name: Create directory
    become: true
    file:
      path: "{{ item }}"
      state: directory
    with_items:
      - /srv/gitlab/config
      - /srv/gitlab/data
      - /srv/gitlab/logs
  - name: Create docker-compose.yml
    become: true
    copy:
      src: ~/kumite73_microservices/gitlab-ci/docker-compose.yml
      dest: /srv/gitlab/docker-compose.yml
  - name: Install docker-machine
    become: true
    shell: |
      base=https://github.com/docker/machine/releases/download/v0.14.0 && \
      curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine \
      && sudo install /tmp/docker-machine /usr/local/bin/docker-machine
    args:
      executable: /bin/bash
  - name: Create create-runners.sh
    become: true
    copy:
      src: ~/kumite73_microservices/gitlab-ci/create-runners.sh
      dest: /srv/gitlab/create-runners.sh
      mode: 775
```

Создаем `docker-compose.yml`
```
web:
  image: 'gitlab/gitlab-ce:latest'
  restart: always
  hostname: 'gitlab.example.com'
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      external_url 'http://35.198.110.108'
  ports:
    - '80:80'
    - '443:443'
    - '2222:22'
  volumes:
    - '/srv/gitlab/config:/etc/gitlab'
    - '/srv/gitlab/logs:/var/log/gitlab'
    - '/srv/gitlab/data:/var/opt/gitlab'
```

Для задания со свездочкой создаем `create-runners.sh`
```
docker exec -it gitlab-runner gitlab-runner register --non-interactive \
    --url http://35.198.110.108/ \
    --registration-token bmdgNrSZ4xZCzQqnxaU3 \
    --tag-list linux,xenial,ubuntu,docker \
    --executor "docker" \
    --name "auto-init-runner" \
    --docker-image "alpine:latest" \
    --run-untagged \
    --locked=false
```
Выполянем playbook `ansible-playbook prepare-vm.yml`
На удаленном хосте выполняем 
```
sudo -i 
cd /srv/gitlab
docker-compose up -d
```
Заходим `http://35.198.110.108/`
Меняем пароль
Логинимся
Выключаем регистрацию новых пользователей `Settings - Sign-Up restrictions - Sign-up enabled`
Создаем группу `homework`
Создаем внутри нее проект `example`
Добавляем remote в kumite73_microservices
```
git checkout -b gitlab-ci-1
git remote add gitlab http://35.198.110.108/homework/example.git
git push gitlab gitlab-ci-1
вводим логин и пароль которые регистрировали
```
Создаем `.gitlab-ci.yml`
```
stages:
  - build
  - test
  - deploy
build_job:
  stage: build
  script:
    - echo 'Building'
test_unit_job:
  stage: test
  script:
    - echo 'Testing 1'
test_integration_job:
  stage: test
  script:
    - echo 'Testing 2'
deploy_job:
  stage: deploy
  script:
    - echo 'Deploy'
```

Коммитим изменения

```
git add .gitlab-ci.yml
git commit -m "add pipeline definition"
git push gitlab gitlab-ci-1
```

Пайплайн готов к запуску но находится в статусе pending / stuck так как у нас нет runner
Получаем данные для создания runners `Settings - CI/CD - Runners - Setup a specific Runner manually` 
Меняем значения в файле `create-runners.sh` и выполняем playbook `create-runners.sh`
На удаленной машине выполним `/srv/gitlub/create-runners.sh`
Pipeline отработал

Добавим исходный код reddit в репозиторий
```
git clone https://github.com/express42/reddit.git && rm -rf ./reddit/.git
git add reddit/
git commit -m “Add reddit app”
git push gitlab gitlab-ci-1
```
Изменим описание пайплайна в `.gitlab-ci.yml`
```
image: ruby:2.4.2
stages:
  - build
  - test
  - deploy
variables:
  DATABASE_URL: 'mongodb://mongo/user_posts'
before_script:
  - cd reddit
  - bundle install
build_job:
  stage: build
  script:
    - echo 'Building'
test_unit_job:
  stage: test
  services:
    - mongo:latest
  script:
    - ruby simpletest.rb
test_integration_job:
  stage: test
  script:
    - echo 'Testing 2'
deploy_job:
  stage: deploy
  script:
    - echo 'Deploy'
```

Создадим файл для тестирования `simpletest.rb`
```
require_relative './app'
require 'test/unit'
require 'rack/test'
set :environment, :test
class MyAppTest < Test::Unit::TestCase
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end
  def test_get_request
    get '/'
    assert last_response.ok?
  end
end
```
Добавим в `Gemfile` гем для тестирования `gem 'rack-test'`
Закоммитим изменения
Тесты прошли

### Интеграция со Slack

Ссылка `https://devops-team-otus.slack.com/messages/CB6DFJYM7`

## Gitlub-CI 2

Создаем новый проект
Добавим новый remote
```
git checkout -b gitlab-ci-2
git remote add gitlab2 http://35.198.164.239/homework/example2.git
git push gitlab2 gitlab-ci-2
```
Включаем runner
Переименуем deploy stage в review
deploy_job меняем на deploy_dev_job
Добавляем environment
```
stages:
  - build
  - test
  - review
deploy_dev_job:
  stage: review
  script:
    - echo 'Deploy'
  environment:
    name: dev
    url: http://dev.example.com
```
Добавляем `when: manual` для ручного запуска в `staging` и `production`
Добавляем директиву `only` для `staging` и `production`, чтобы job мог запуститься только с тегом версии. Например `2.4.10`
```
only:
  - /^\d+\.\d+\.\d+/
```
Изменение без указания тэга запустят пайплайн без `job staging и production`
Изменение, помеченное тэгом в git запустит полный пайплайн
```
git commit -a -m ‘#4 add logout button to profile page’
git tag 2.4.10
git push gitlab2 gitlab-ci-2 --tags
```
Создаем динамические окуружения
Этот `job` определяет динамическое окружение для каждой ветки в репозитории, кроме ветки `master`
```
branch review:
  stage: review
  script: echo "Deploy to $CI_ENVIRONMENT_SLUG"
  environment:
    name: branch/$CI_COMMIT_REF_NAME
    url: http://$CI_ENVIRONMENT_SLUG.example.com
  only:
    - branches
  except:
    - master
```

## Monitoring-1

Создадим правило фаервола для Prometheus и Puma
```
gcloud compute firewall-rules create prometheus-default --allow tcp:9090
gcloud compute firewall-rules create puma-default --allow tcp:9292
```
Создадим Docker хост в GCE и настроим локальное окружение на работу с ним
```
export GOOGLE_PROJECT=docker-212817
docker-machine create --driver google \
  --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
  --google-machine-type n1-standard-1 \
  --google-zone europe-west1-b \
  docker-host
eval $(docker-machine env docker-host)  
```
Запуск `Prometheus`
```
docker run --rm -p 9090:9090 -d --name prometheus prom/prometheus:v2.1.0
```
Узнаем IP машины `docker-machine ip docker-host`
Переходим в web интерфейс `http://35.241.253.244:9090/graph`
Выполним метрику `prometheus_build_info`
```
prometheus_build_info{branch="HEAD",goversion="go1.9.2",instance="localhost:9090",job="prometheus",revision="85f23d82a045d103ea7f3c89a91fba4a93e6367a",version="2.1.0"}
```
`Название метрики` - идентификатор собранной информации.
`Лейбл` - добавляет метаданных метрике, уточняет ее. Использование лейблов дает нам возможность не ограничиваться лишь одним названием метрик для идентификации получаемой информации. Лейблы содержаться в {} скобках и представлены наборами "ключ=значение".
`Значение метрики` - численное значение метрики, либо NaN, если значение недоступно

`Targets (цели)` - представляют собой системы или процессы, за которыми следит Prometheus.

Информация, которую собирает Prometheus `http://35.241.253.244:9090/metrics`
Остановим контейнер  `docker stop prometheus`
Создаем директорию `monitoring/prometheus`
Создаем `Dockerfile`
```
FROM prom/prometheus:v2.1.0
ADD prometheus.yml /etc/prometheus/
```
Создаем `prometheus.yml`
```
global:
  scrape_interval: '5s'
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets:
        - 'localhost:9090'
  - job_name: 'ui'
    static_configs:
      - targets:
        - 'ui:9292'
  - job_name: 'comment'
    static_configs:
      - targets:
        - 'comment:9292'
```
Создаем образ
```
export USER_NAME=kumite
docker build -t $USER_NAME/prometheus .
```
Собираем `images`
```
/src/ui $ bash docker_build.sh
/src/post-py $ bash docker_build.sh
/src/comment $ bash docker_build.sh
```
Или из корня
```
for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done
```
Меняем `docker/docker-compose.yml`
```
  prometheus:
    image: ${USERNAME}/prometheus
    ports:
      - '9090:9090'
    volumes:
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention=1d'
volumes:
  prometheus_data:
```
Добавляем `networks` для `prometheus`
```
networks:
  - front_net
  - back_net
```
Поднимаем инфраструктуру `docker-compose up -d`
Проверяем состояние сервисов `http://35.241.253.244:9090/targets`
Состояние сервиса UI - всегда выдавалось с ошибкой. После выяснения прчин, было выяснено, что в коде Dockerfile для сервиса комментариев стояла `comment_db` 
Создаем базу для комментов
```
  comment_db:
    image: mongo:3.2
    volumes:
      - comment_db:/data/db
    networks:
      - back_net
```
Заново поднимаем инфраструктуру. Теперь `ui_health` возвращает `1`
Остановим post сервис `docker-compose stop post`
Метрика изменила свое значение на 0, что означает, что UI сервис стал нездоров
`ui_health_post_availability` стал возвращать `0`
Запустим `docker-compose start post`
Post сервис поправился
UI сервис тоже

### Сбор метрик
Добавляем в `docker-compose.yml`
```
  node-exporter:
    image: prom/node-exporter:v0.15.2
    user: root
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($$|/)"'
```
Меняем `prometheus.yml`
```
- job_name: 'node'
  static_configs:
    - targets:
      - 'node-exporter:9100'
```
Собираем контейнер `docker build -t $USER_NAME/prometheus .`
Пересоздадим сервисы
```
docker-compose down
docker-compose up -d
```
Данные с node не собираются, так-как контейнер не видит prometheus. Добавляем сети
```
networks:
  - front_net
  - back_net
```
Сейчас все работает
Получим информацию об использовании CPU `node_load1`
Проверим мониторинг
Зайдем на хост: `docker-machine ssh docker-host`
Добавим нагрузки: `yes > /dev/null`
нагрузка выросла
Запушим собранные образы на DockerHub
```
docker login
docker push $USER_NAME/ui
docker push $USER_NAME/comment
docker push $USER_NAME/post
docker push $USER_NAME/prometheus
```

Ссылка на DockerHub: `https://hub.docker.com/r/kumite/`

## monitoring-2

Создадим Docker хост в GCE и настроим локальное окружение на работу с ним
```
export GOOGLE_PROJECT=docker-1111111
# Создать докер хост
docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-zone europe-west1-b \
    docker-host
# Настроить докер клиент на удаленный докер демон
eval $(docker-machine env docker-host)
docker-machine ip docker-host
```
IP: 35.240.24.254

Вернуть на локальную машину после ДЗ
```
# Переключение на локальный докер
eval $(docker-machine env --unset)
docker-machine rm docker-host
```

Разделим файлы `Docker compose`
Для запуска приложений будем использовать `docker-compose up -d`
Для мониторинга `docker-compose -f docker-compose-monitoring.yml up -d`

### cAdvisor

Добавляем запуск контейнера в `docker-compose-monitoring.yml`
```
cadvisor:
  image: google/cadvisor:v0.29.0
  volumes:
    - '/:/rootfs:ro'
    - '/var/run:/var/run:rw'
    - '/sys:/sys:ro'
    - '/var/lib/docker/:/var/lib/docker:ro'
  ports:
    - '8080:8080'
  networks:
    - front-ner
```

Добавялем информацию о новом сервисе в Prometheus
```
scrape_configs:

  - job_name: 'cadvisor'
    static_configs:
      - targets:
        - 'cadvisor:8080'
```
Пересоберем образ Prometheus с обновленной конфигурацией
```
export USER_NAME=kumite
docker build -t $USER_NAME/prometheus .
docker push kumite/prometheus
```

Запускаем сервисы
```
docker-compose up -d
docker-compose -f docker-compose-monitoring.yml up -d
```
Создаем правило фаервола для 8080 порта `cadvisor` и добавляем тег в машину.
Открываем страницу Web UI по адресу `http://http://35.240.24.254:8080`

### Grafana
Добавляем в `docker-compose-monitoring.yml`
```
  grafana:
    image: grafana/grafana:5.0.0
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=secret
    depends_on:
      - prometheus
    ports:
      - 3000:3000
    networks:
      - front_net

volumes:
  grafana_data:
```
Запустим сервис `docker-compose -f docker-compose-monitoring.yml up -d grafana`
Создаем правило фаервола для 3000 порта `grafana` и добавляем тег в машину.
Открываем Web UI `http://http://35.240.24.254:3000`

### Мониторинг работы приложения

Добавим информацию о post сервисе в конфигурацию Prometheus
```
- job_name: 'post'
  static_configs:
    - targets:
      - 'post:5000'
```
Пересоберем образ Prometheus с обновленной конфигурацией
```
docker build -t $USER_NAME/prometheus .
docker push kumite/prometheus
```

### Alertmanager

Создадим Dockerfile
```
FROM prom/alertmanager:v0.14.0
ADD config.yml /etc/alertmanager/
```
Создаем `cinfig.yml`
```
global:
  slack_api_url: 'https://hooks.slack.com/services/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'

route:
  receiver: 'slack-notifications'

receivers:
- name: 'slack-notifications'
  slack_configs:
  - channel: '#aleksei_kiselev'
```
Собираем образ `docker build -t $USER_NAME/alertmanager .`
Заливаем на хаб `docker push $USER_NAME/alertmanager`
Добавляем новый сервис в мониторинг
```
alertmanager:
  image: ${USER_NAME}/alertmanager:latest
  command:
    - '--config.file=/etc/alertmanager/config.yml'
  ports:
    - 9093:9093
  networks:
    - front_net
```
### Alert rules

Создадим файл `alerts.yml` в директории prometheus
```
groups:
  - name: alert.rules
    rules:
    - alert: InstanceDown
      expr: up == 0
      for: 1m
      labels:
        severity: page
      annotations:
        description: '{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute'
        summary: 'Instance {{ $labels.instance }} down'
```
Добавим операцию копирования данного файла в `monitoring/prometheus/Dockerfile`
```
FROM prom/prometheus:v2.1.0
ADD prometheus.yml /etc/prometheus/
ADD alerts.yml /etc/prometheus/
```

Добавим информацию о правилах, в конфиг `Prometheus`
```
rule_files:
  - "alerts.yml"

alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - "alertmanager:9093"
```

Пересоберем 
```
docker build -t $USER_NAME/prometheus .
docker push kumite/prometheus
```
Пересоздадим нашу Docker инфраструктуру мониторинга
```
docker-compose -f docker-compose-monitoring.yml down
docker-compose -f docker-compose-monitoring.yml up -d
```
Остановим сервис `docker-compose stop post`
```
AlertManager APP [11:29 AM]
[FIRING:1] InstanceDown (post:5000 post page)
```

Ссылка на Docker HUB `https://hub.docker.com/u/kumite/`

## logging-1

Выполняем  сборку образов при помощи скриптов docker_build.sh в директории каждого сервиса:
```
/src/ui $ bash docker_build.sh && docker push $USER_NAME/ui
/src/post-py $ bash docker_build.sh && docker push $USER_NAME/post
/src/comment $ bash docker_build.sh && docker push $USER_NAME/comment
```
Или сразу все из корня репозитория:
```
for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done
```
Подготовка окружения
```
docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-open-port 5601/tcp \
    --google-open-port 9292/tcp \
    --google-open-port 9411/tcp \
    logging
# configure local env
eval $(docker-machine env logging)
# узнаем IP адрес
docker-machine ip logging
```

Создаем `docker/docker-compose-logging.yml`
```
version: '3'
services:
  fluentd:
    image: ${USERNAME}/fluentd
    ports:
      - "24224:24224"
      - "24224:24224/udp"

  elasticsearch:
    image: elasticsearch:6.4.2
    environment:
      - discovery.type=single-node
    expose:
      - 9200
    ports:
      - "9200:9200"
      - "9300:9300"

  kibana:
    image: kibana:6.4.2
    ports:
      - "5601:5601"
```
### Fluentd

Создаем в проекте `microservices` директорию `logging/fluentd`
Создаем `Dockerfile`
```
FROM fluent/fluentd:v0.12
RUN gem install fluent-plugin-elasticsearch --no-rdoc --no-ri --version 1.9.5
RUN gem install fluent-plugin-grok-parser --no-rdoc --no-ri --version 1.0.0
ADD fluent.conf /fluentd/etc
```
Создаем `ogging/fluentd/fluent.conf`
```
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<match *.**>
  @type copy
  <store>
    @type elasticsearch
    host elasticsearch
    port 9200
    logstash_format true
    logstash_prefix fluentd
    logstash_dateformat %Y%m%d
    include_tag_key true
    type_name access_log
    tag_key @log_name
    flush_interval 1s
  </store>
  <store>
    @type stdout
  </store>
</match>
```
Собираем образ `docker build -t $USER_NAME/fluentd .`
Правим `.env` файл и меняем теги нашего приложения на `logging`
Запускаем сервисы приложения `docker/ $ docker-compose up -d`
Смотрим логи post сервиса: `docker/ $ docker-compose logs -f post`

### Отправка логов во Fluentd

Меняем `docker/docker-compose.yml`
```
  post:
    image: ${USER_NAME}/post:${VERSION}
    environment:
      - POST_DATABASE_HOST=post_db
      - POST_DATABASE=posts
    depends_on:
      - post_db
    ports:
      - "5000:5000"
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: service.post
```
Поднимем инфраструктуру централизованной системы логирования и перезапустим сервисы приложения Из каталога `docker`
Необходимо проставить версию  `6.4.2` для кибана и эластик
```
docker-compose -f docker-compose-logging.yml up -d
docker-compose down
docker-compose up -d
```
Добавим фильтр парсинга `logging/fluentd/fluent.conf`
```
<filter service.post>
  @type parser
  format json
  key_name log
</filter>
```
Перерсоберм `docker build -t $USER_NAME/fluentd`
Перезапустим `docker-compose -f docker-compose-logging.yml up -d fluentd`

### Неструктурированные логи

Логируем UI сервис
```
logging:
  driver: "fluentd"
  options:
    fluentd-address: localhost:24224
    tag: service.ui
```
Добавляем разбор неструкурированных логов `/docker/fluentd/fluent.conf`
```
<filter service.ui>
  @type parser
  format /\[(?<time>[^\]]*)\]  (?<level>\S+) (?<user>\S+)[\W]*service=(?<service>\S+)[\W]*event=(?<event>\S+)[\W]*(?:path=(?<path>\S+)[\W]*)?request_id=(?<request_id>\S+)[\W]*(?:remote_addr=(?<remote_addr>\S+)[\W]*)?(?:method= (?<method>\S+)[\W]*)?(?:response_status=(?<response_status>\S+)[\W]*)?(?:message='(?<message>[^\']*)[\W]*)?/
  key_name log
</filter>
```

Меняем парсинг на встроенный
```
<filter service.ui>
  @type parser
  key_name log
  format grok
  grok_pattern %{RUBY_LOGGER}
</filter>
<filter service.ui>
  @type parser
  format grok
  grok_pattern service=%{WORD:service} \| event=%{WORD:event} \| request_id=%{GREEDYDATA:request_id} \| message='%{GREEDYDATA:message}'
  key_name message
  reserve_data true
</filter>
```

### Заждание со *

Добавляем `/docker/fluentd/fluent.conf`
```
<filter service.ui>
  @type parser
  format grok
  grok_pattern service=%{WORD:service} \| event=%{WORD:event} \| path=%{GREEDYDATA:path} \| request_id=%{GREEDYDATA:request_id} \| remote_addr=%{GREEDYDATA:remote_addr} \| method=%{GREEDYDATA:method} \| response_status=%{WORD:response_status}
  key_name message
  reserve_data true
</filter>
```

## kubernetes-1

### Installing the Client Tools
Install CFSSL
```
wget -q --show-progress --https-only --timestamping \
  https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
  https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
```
Install kubectl
```
wget https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```
Virtual Private Cloud Network
```
gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom
gcloud compute networks subnets create kubernetes \
  --network kubernetes-the-hard-way \
  --range 10.240.0.0/24
```
Firewall Rules
Create a firewall rule that allows internal communication across all protocols:
```
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
  --allow tcp,udp,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 10.240.0.0/24,10.200.0.0/16
```
Create a firewall rule that allows external SSH, ICMP, and HTTPS:
```
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 0.0.0.0/0
```
List the firewall rules in the kubernetes-the-hard-way VPC network:
```
gcloud compute firewall-rules list --filter="network:kubernetes-the-hard-way"
```
### Kubernetes Public IP Address
```
gcloud compute addresses create kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region)
```
Проверяем какой адрес
```
gcloud compute addresses list --filter="name=('kubernetes-the-hard-way')"
NAME                     REGION        ADDRESS         STATUS
kubernetes-the-hard-way  europe-west4  35.204.176.124  RESERVED
```
Создаем Kubernetes Controllers
```
for i in 0 1 2; do
  gcloud compute instances create controller-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,controller
done
```
Создаем Kubernetes Workers
```
for i in 0 1 2; do
  gcloud compute instances create worker-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --metadata pod-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,worker
done
```
Проверяем
```
gcloud compute instances list
```

### Configuring SSH Access
```
gcloud compute ssh controller-0
```

### Provisioning a CA and Generating TLS Certificates
Certificate Authority
```
{

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

}
```
### Client and Server Certificates
The Admin Client Certificate
```
{

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin

}
```
The Kubelet Client Certificates
```
for instance in worker-0 worker-1 worker-2; do
cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

EXTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

INTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].networkIP)')

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
  -profile=kubernetes \
  ${instance}-csr.json | cfssljson -bare ${instance}
done
```
The Controller Manager Client Certificate
```
{

cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

}
```
The Kube Proxy Client Certificate
```
{

cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

}
```
The Scheduler Client Certificate
```
{

cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

}
```
The Kubernetes API Server Certificate
```
{

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

}
```
The Service Account Key Pair
```
{

cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

}
```

### Distribute the Client and Server Certificates

Copy the appropriate certificates and private keys to each worker instance:
```
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/
done
```

Copy the appropriate certificates and private keys to each controller instance:
```
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem ${instance}:~/
done
```

### Generating Kubernetes Configuration Files for Authentication

#### Client Authentication Configs

Kubernetes Public IP Address
```
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')
```

The kubelet Kubernetes Configuration File
```
for instance in worker-0 worker-1 worker-2; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${instance}.pem \
    --client-key=${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done
```

The kube-proxy Kubernetes Configuration File
```
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}
```

The kube-controller-manager Kubernetes Configuration File
```
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}
```

The kube-scheduler Kubernetes Configuration File
```
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}
```

The admin Kubernetes Configuration File
```
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig
}
```

### Distribute the Kubernetes Configuration Files

Copy the appropriate kubelet and kube-proxy kubeconfig files to each worker instance:
```
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
done
```

Copy the appropriate kube-controller-manager and kube-scheduler kubeconfig files to each controller instance:
```
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done
```

### Generating the Data Encryption Config and Key

The Encryption Key
```
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

The Encryption Config File
```
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
```

Copy the encryption-config.yaml encryption config file to each controller instance:
```
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp encryption-config.yaml ${instance}:~/
done
```

### Bootstrapping the etcd Cluster

Prerequisites
The commands in this lab must be run on each controller instance: controller-0, controller-1, and controller-2. Login to each controller instance using the gcloud command. Example:
```
gcloud compute ssh controller-0
```

### Bootstrapping an etcd Cluster Member

Download and Install the etcd Binaries
```
wget -q --show-progress --https-only --timestamping \
  "https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz"
```

Extract and install the etcd server and the etcdctl command line utility:
```
{
  tar -xvf etcd-v3.3.9-linux-amd64.tar.gz
  sudo mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/
}
```

Configure the etcd Server
```
{
  sudo mkdir -p /etc/etcd /var/lib/etcd
  sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
}
```

The instance internal IP address will be used to serve client requests and communicate with etcd cluster peers. Retrieve the internal IP address for the current compute instance:
```
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
```

Each etcd member must have a unique name within an etcd cluster. Set the etcd name to match the hostname of the current compute instance:
```
ETCD_NAME=$(hostname -s)
```

Create the etcd.service systemd unit file:
```
cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-0=https://10.240.0.10:2380,controller-1=https://10.240.0.11:2380,controller-2=https://10.240.0.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Start the etcd Server
```
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd
}
```

Verification
```
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem
```

### Bootstrapping the Kubernetes Control Plane

In this lab you will bootstrap the Kubernetes control plane across three compute instances and configure it for high availability. You will also create an external load balancer that exposes the Kubernetes API Servers to remote clients. The following components will be installed on each node: Kubernetes API Server, Scheduler, and Controller Manager.
Prerequisites
The commands in this lab must be run on each controller instance: controller-0, controller-1, and controller-2
```
gcloud compute ssh controller-0
```

Provision the Kubernetes Control Plane
```
sudo mkdir -p /etc/kubernetes/config
```

Download and Install the Kubernetes Controller Binaries
```
wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl"
```

Install the Kubernetes binaries:
```
{
  chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
  sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
}
```

Configure the Kubernetes API Server
```
{
  sudo mkdir -p /var/lib/kubernetes/

  sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem \
    encryption-config.yaml /var/lib/kubernetes/
}
```

The instance internal IP address will be used to advertise the API Server to members of the cluster. Retrieve the internal IP address for the current compute instance:
```
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
```

Create the kube-apiserver.service systemd unit file:
```
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\
  --event-ttl=1h \\
  --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Configure the Kubernetes Controller Manager

Move the kube-controller-manager kubeconfig into place:
```
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
```

Create the kube-controller-manager.service systemd unit file:
```
cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Configure the Kubernetes Scheduler

Move the kube-scheduler kubeconfig into place:
```
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
```

Create the kube-scheduler.yaml configuration file:
```
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: componentconfig/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
```

Create the kube-scheduler.service systemd unit file:
```
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Start the Controller Services
```
{
  sudo systemctl daemon-reload
  sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
  sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
}
```

Enable HTTP Health Checks

```
sudo apt-get install -y nginx
cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF
{
  sudo mv kubernetes.default.svc.cluster.local \
    /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

  sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/
}
sudo systemctl restart nginx
sudo systemctl enable nginx
```

Verification

```
kubectl get componentstatuses --kubeconfig admin.kubeconfig
```

Test the nginx HTTP health check proxy:
```
curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz
```

### RBAC for Kubelet Authorization

In this section you will configure RBAC permissions to allow the Kubernetes API Server to access the Kubelet API on each worker node. Access to the Kubelet API is required for retrieving metrics, logs, and executing commands in pods.
```
gcloud compute ssh controller-0
```

Create the system:kube-apiserver-to-kubelet ClusterRole with permissions to access the Kubelet API and perform most common tasks associated with managing pods:
```
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
```

The Kubernetes API Server authenticates to the Kubelet as the kubernetes user using the client certificate as defined by the --kubelet-client-certificate flag.

Bind the system:kube-apiserver-to-kubelet ClusterRole to the kubernetes user:
```
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
```

### The Kubernetes Frontend Load Balancer

In this section you will provision an external load balancer to front the Kubernetes API Servers. The kubernetes-the-hard-way static IP address will be attached to the resulting load balancer.

The compute instances created in this tutorial will not have permission to complete this section. Run the following commands from the same machine used to create the compute instances.

Provision a Network Load Balancer
```
{
  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
    --region $(gcloud config get-value compute/region) \
    --format 'value(address)')

  gcloud compute http-health-checks create kubernetes \
    --description "Kubernetes Health Check" \
    --host "kubernetes.default.svc.cluster.local" \
    --request-path "/healthz"

  gcloud compute firewall-rules create kubernetes-the-hard-way-allow-health-check \
    --network kubernetes-the-hard-way \
    --source-ranges 209.85.152.0/22,209.85.204.0/22,35.191.0.0/16 \
    --allow tcp

  gcloud compute target-pools create kubernetes-target-pool \
    --http-health-check kubernetes

  gcloud compute target-pools add-instances kubernetes-target-pool \
   --instances controller-0,controller-1,controller-2

  gcloud compute forwarding-rules create kubernetes-forwarding-rule \
    --address ${KUBERNETES_PUBLIC_ADDRESS} \
    --ports 6443 \
    --region $(gcloud config get-value compute/region) \
    --target-pool kubernetes-target-pool
}
```

Verification

Retrieve the kubernetes-the-hard-way static IP address:
```
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')
```

Make a HTTP request for the Kubernetes version info:
```
curl --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version
```

### Bootstrapping the Kubernetes Worker Nodes

Bootstrapping the Kubernetes Worker Nodes

In this lab you will bootstrap three Kubernetes worker nodes. The following components will be installed on each node: runc, gVisor, container networking plugins, containerd, kubelet, and kube-proxy.

Prerequisites
The commands in this lab must be run on each worker instance: worker-0, worker-1, and worker-2. Login to each worker instance using the gcloud command. Example:
```
gcloud compute ssh worker-0
```

Provisioning a Kubernetes Worker Node

Install the OS dependencies:
```
{
  sudo apt-get update
  sudo apt-get -y install socat conntrack ipset
}
```

Download and Install Worker Binaries
```
wget -q --show-progress --https-only --timestamping \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.12.0/crictl-v1.12.0-linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-the-hard-way/runsc-50c283b9f56bb7200938d9e207355f05f79f0d17 \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc5/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.6.0/cni-plugins-amd64-v0.6.0.tgz \
  https://github.com/containerd/containerd/releases/download/v1.2.0-rc.0/containerd-1.2.0-rc.0.linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubelet
```

Create the installation directories:
```
sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

Install the worker binaries:
```
{
  sudo mv runsc-50c283b9f56bb7200938d9e207355f05f79f0d17 runsc
  sudo mv runc.amd64 runc
  chmod +x kubectl kube-proxy kubelet runc runsc
  sudo mv kubectl kube-proxy kubelet runc runsc /usr/local/bin/
  sudo tar -xvf crictl-v1.12.0-linux-amd64.tar.gz -C /usr/local/bin/
  sudo tar -xvf cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin/
  sudo tar -xvf containerd-1.2.0-rc.0.linux-amd64.tar.gz -C /
}
```

### Configure CNI Networking

Retrieve the Pod CIDR range for the current compute instance:
```
POD_CIDR=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/pod-cidr)
```

Create the bridge network configuration file:
```
cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF
```

Create the loopback network configuration file:
```
cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOF
```

### Configure containerd

Create the containerd configuration file:
```
sudo mkdir -p /etc/containerd/
cat << EOF | sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
    [plugins.cri.containerd.untrusted_workload_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"
    [plugins.cri.containerd.gvisor]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runsc"
      runtime_root = "/run/containerd/runsc"
EOF
```

Create the containerd.service systemd unit file:
```
cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubelet

```
{
  sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/
  sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
  sudo mv ca.pem /var/lib/kubernetes/
}
```

Create the kubelet-config.yaml configuration file:
```
cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
EOF
```

Create the kubelet.service systemd unit file:
```
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubernetes Proxy

```
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
```

Create the kube-proxy-config.yaml configuration file:
```
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF
```

Create the kube-proxy.service systemd unit file:
```
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Start the Worker Services

```
{
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl start containerd kubelet kube-proxy
}
```

### Verification

The compute instances created in this tutorial will not have permission to complete this section. Run the following commands from the same machine used to create the compute instances.

List the registered Kubernetes nodes:
```
gcloud compute ssh controller-0 \
  --command "kubectl get nodes --kubeconfig admin.kubeconfig"
```

### Configuring kubectl for Remote Access

In this lab you will generate a kubeconfig file for the kubectl command line utility based on the admin user credentials.

Run the commands in this lab from the same directory used to generate the admin client certificates.

#### The Admin Kubernetes Configuration File

Each kubeconfig requires a Kubernetes API Server to connect to. To support high availability the IP address assigned to the external load balancer fronting the Kubernetes API Servers will be used.

Generate a kubeconfig file suitable for authenticating as the admin user:
```
{
  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
    --region $(gcloud config get-value compute/region) \
    --format 'value(address)')

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}
```

#### Verification

```
kubectl get componentstatuses
```

List the nodes in the remote Kubernetes cluster:
```
kubectl get nodes
```

### Provisioning Pod Network Routes

Pods scheduled to a node receive an IP address from the nodes Pod CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing network routes.
In this lab you will create a route for each worker node that maps the nodes Pod CIDR range to the nodes internal IP address.
There are other ways to implement the Kubernetes networking model.

#### The Routing Table

In this section you will gather the information required to create routes in the kubernetes-the-hard-way VPC network.

Print the internal IP address and Pod CIDR range for each worker instance:
```
for instance in worker-0 worker-1 worker-2; do
  gcloud compute instances describe ${instance} \
    --format 'value[separator=" "](networkInterfaces[0].networkIP,metadata.items[0].value)'
done
```

#### Routes

Create network routes for each worker instance:
```
for i in 0 1 2; do
  gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
    --network kubernetes-the-hard-way \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done
```

List the routes in the kubernetes-the-hard-way VPC network:
```
gcloud compute routes list --filter "network: kubernetes-the-hard-way"
```

### Deploying the DNS Cluster Add-on

In this lab you will deploy the DNS add-on which provides DNS based service discovery, backed by CoreDNS, to applications running inside the Kubernetes cluster.

#### The DNS Cluster Add-on

Deploy the coredns cluster add-on:
```
kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml
```

List the pods created by the kube-dns deployment:
```
kubectl get pods -l k8s-app=kube-dns -n kube-system
```

#### Verification

Create a busybox deployment:
```
kubectl run busybox --image=busybox:1.28 --command -- sleep 3600
```

List the pod created by the busybox deployment:
```
kubectl get pods -l run=busybox
```

Retrieve the full name of the busybox pod:
```
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
```

Execute a DNS lookup for the kubernetes service inside the busybox pod:
```
kubectl exec -ti $POD_NAME -- nslookup kubernetes
```

Падали поды cubectl-
```
kubectl -n kube-system get deployment coredns -o yaml | \
  sed 's/allowPrivilegeEscalation: false/allowPrivilegeEscalation: true/g' | \
  kubectl apply -f -
```

### Проверка Reddit

```
NAME                                 READY   STATUS    RESTARTS   AGE
busybox-bd8fb7cbd-k42rh              1/1     Running   1          87m
comment-deployment-f8d4f85fb-qxf4d   1/1     Running   0          28m
mongo-deployment-57cd8664c6-gtcx8    1/1     Running   0          26m
post-deployment-7f8b79b48-tbzvz      1/1     Running   0          28m
ui-deployment-55cbbf797b-t8ps8       1/1     Running   0          28m
```

## kubernetes-2

### Minikube

Установка
```
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.27.0/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

Запускаем Minukube-кластер.
```
minikube start
```

Провяzрем `kubectl get nodes`

### Kubectl

Текущий контекст `kubectl config current-context`

Список всех контекстов `kubectl config get-contexts`

### UI

Меняем файл `kuberntetes/ui-deployment.yml`
```
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: ui
  labels:
    app: reddit
    component: ui
spec:
  replicas: 3
  selector:
    matchLabels:
      app: reddit
      component: ui
  template:
    metadata:
      name: ui-pod
      labels:
        app: reddit
        component: ui
    spec:
      containers:
      - image: kumite/ui
        name: ui
```

Запускаем в Minikube ui-компоненту.
```
kubectl apply -f ui-deployment.yml
```

Проверка `kubectl get deployment`
```
NAME   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
ui     3         3         3            3           41s
```

Найдем, используя selector, POD-ы приложения
```
kubectl get pods --selector component=ui
```

Пробрасываем порты
```
kubectl port-forward <pod-name> 8080:9292
```

Так-как у меня данный порт занят пробрасывал на 8899

### Comment

Меняем файл `kuberntetes/comment-deployment.yml`
```
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: comment
  labels:
    app: reddit
    component: comment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: reddit
      component: comment
  template:
    metadata:
      name: comment
      labels:
        app: reddit
        component: comment
    spec:
      containers:
      - image: kumite/comment
        name: comment
```

Запуск и проверка
```
kubectl apply -f comment-deployment.yml
kubectl get deployment
kubectl get pods --selector component=comment
kubectl port-forward comment-6d9887d946-888hv 8899:9292
http://localhost:8899/healthcheck
```

### Post

Меняем файл `kuberntetes/post-deployment.yml`
```
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: post
  labels:
    app: reddit
    component: post
spec:
  replicas: 3
  selector:
    matchLabels:
      app: reddit
      component: post
  template:
    metadata:
      name: post
      labels:
        app: reddit
        component: post
    spec:
      containers:
      - image: kumite/post
        name: post
```

Запуск и проверка
```
kubectl apply -f post-deployment.yml
kubectl get deployment
kubectl get pods --selector component=post
kubectl port-forward post-bb9958b84-9m8q6 8899:5000
http://localhost:8899/healthcheck
```

### MongoDB
Меняем файл `kuberntetes/mongo-deployment.yml`
```
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: mongo
  labels:
    app: reddit
    component: mongo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reddit
      component: mongo
  template:
    metadata:
      name: mongo
      labels:
        app: reddit
        component: mongo
    spec:
      containers:
      - image: mongo:3.2
        name: mongo
```

примонтируем стандартный Volume для хранения данных вне контейнера
```
        volumeMounts:
        - name: mongo-persistent-storage
          mountPath: /data/db
      volumes:
      - name: mongo-persistent-storage
        emptyDir: {}
```

### Services

Для связи ui с post и comment нужно создать им по объекту Service. 
`comment-service.yml`
```
---
apiVersion: v1
kind: Service
metadata:
  name: comment
  labels:
    app: reddit
    component: comment
spec:
  ports:
  - port: 9292
    protocol: TCP
    targetPort: 9292
  selector:
    app: reddit
    component: comment
```

`post-service.yml`
```
---
apiVersion: v1
kind: Service
metadata:
  name: post
  labels:
    app: reddit
    component: post
spec:
  ports:
  - port: 5000
    protocol: TCP
    targetPort: 5000
  selector:
    app: reddit
    component: post
```

`mongodb-service.yml`
```
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  labels:
    app: reddit
    component: mongo
spec:
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 27017
  selector:
    app: reddit
    component: mongo
```

Сделаем Service для БД comment. `comment-mongodb-service.yml`
```
---
apiVersion: v1
kind: Service
metadata:
  name: comment-db
  labels:
    app: reddit
    component: mongo
    comment-db: "true"
spec:
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 27017
  selector:
    app: reddit
    component: mongo
    comment-db: "true"
```

Добавляем новый тег в `mongo-deployment.yml`
```
comment-db: "true"
```

Задаем pod-ам `comment` переменную окружения для обращения к базе
```
        env:
        - name: COMMENT_DATABASE_HOST
          value: comment-db
```

Создаем `comment-mongodb-service.yml`
```
---
apiVersion: v1
kind: Service
metadata:
  name: post-db
  labels:
    app: reddit
    component: mongo
    post-db: "true"
spec:
  ports:
  - port: 27017
    protocol: TCP
    targetPort: 27017
  selector:
    app: reddit
    component: mongo
    post-db: "true"
```

Добавляем новый тег в `mongo-deployment.yml`
```
post-db: "true"
```

Добавляем переменные окружения в `post-deployment.yml`
```
        env:
        - name: POST_DATABASE_HOST
          value: post-db
```

Применяем конфигурацию, форвардим порт и проверяем.

#### NodePort

Создаем `ui-service.yml`
```
---
apiVersion: v1
kind: Service
metadata:
  name: ui
  labels:
    app: reddit
    component: ui
spec:
  type: NodePort
  ports:
  - nodePort: 32092
    port: 9292
    protocol: TCP
    targetPort: 9292
  selector:
    app: reddit
    component: ui
```

Проверяем работоспособность
```
 w3m http://$(minikube ip):32092
```

Смотрим на какие сервисы можно нодить из вне
```
minikube service list
```

### Minikube

Получить список расширений: `minikube addons list`

### Namespaces

Объекты dashboard
```
kubectl get all -n kube-system --selector app=kubernetes-dashboard
```

Создаем Namespace dev `dev-namespace.yml`
```
---
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

Добавляем информацию об окружении внутрь контейнера UI
```
        env:
        - name: ENV
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
```

### Kubernetes

Создаем кластер
Подключаемся
```
gcloud container clusters get-credentials standard-cluster-1 --zone us-central1-a --project docker-212817
```

Создадим dev namespace
```
kubectl apply -f ./kubernetes/reddit/dev-namespace.yml
```
Задеплоим все компоненты приложения в namespace dev:
```
kubectl apply -f ./kubernetes/reddit/ -n dev
```
Создаем правило брнадмауэра, все экземпляры сети сеть 0.0.0.0/0 порты TCP:30000-32767

Внешний IP-адрес любой ноды из кластера ExternalIP
```
kubectl get nodes -o wide
```

Ищем  порт публикации сервиса ui
```
kubectl describe service ui -n dev | grep NodePort
```

Заходим
```
http://35.238.113.177:30543/
```
Результат
```
Microservices Reddit in dev ui-75d98bbf9b-882c7 container
```

## kubernetes-3

### Kube-dns

Отключим kube-dns
```
kubectl scale deployment --replicas 0 -n kube-system kube-dns-autoscaler
kubectl scale deployment --replicas 0 -n kube-system kube-dns
```

Прверяем
```
kubectl exec -ti -n dev post-7d4686657d-vbp2j ping comment
ping: bad address 'comment'
command terminated with exit code 1
```

Возвращаем в рабочее состояние
```
kubectl scale deployment --replicas 1 -n kube-system kube-dns-autoscaler
kubectl scale deployment --replicas 1 -n kube-system kube-dns
```

### LoadBalancer

Меняем `ui-service.yml`
```
---
apiVersion: v1
kind: Service
metadata:
  name: ui
  labels:
    app: reddit
    component: ui
spec:
  type: LoadBalancer
  ports:
  - port: 80
    nodePort: 32092
    protocol: TCP
    targetPort: 9292
  selector:
    app: reddit
    component: ui
```

Применим изменения
```
kubectl apply -f ui-service.yml -n dev
```
Проверим

```
kubectl get service  -n dev --selector component=ui
NAME   TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)        AGE
ui     LoadBalancer   10.7.251.64   35.240.55.13   80:32092/TCP   27m
```

### Ingress

Создадим Ingress для сервиса UI `ui-ingress.yml`
```
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ui
spec:
  backend:
    serviceName: ui
    servicePort: 80
```

Применяем `kubectl apply -f ui-ingress.yml -n dev`

Сотрим на IP
```
kubectl get ingress -n dev
NAME   HOSTS   ADDRESS         PORTS   AGE
ui     *       35.190.95.124   80      2m34s
```

Один балансировщик можно спокойно убрать. Обновим сервис для UI `ui-service.yml`
```
---
apiVersion: v1
kind: Service
metadata:
  name: ui
  labels:
    app: reddit
    component: ui
spec:
  type: NodePort
  ports:
  - port: 9292
    protocol: TCP
    targetPort: 9292
  selector:
    app: reddit
    component: ui
```
Применяем `kubectl apply -f ui-service.yml -n dev`

Заставим работать Ingress Controller как классический веб `ui-ingress.yml`
```
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ui
spec:
  rules:
  - http:
      paths:
      - path: /*
        backend:
          serviceName: ui
          servicePort: 9292
```

Поучааем Ingress IP
```
kubectl get ingress -n dev
NAME   HOSTS   ADDRESS         PORTS   AGE
ui     *       35.190.95.124   80      20m
```

Подготовим сертификат используя IP как CN
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=35.190.95.124"
```

Загрузим сертификат в кластер kubernetes
```
kubectl create secret tls ui-ingress --key tls.key --cert tls.crt -n dev
```

Проверяем
```
kubectl describe secret ui-ingress -n dev
```

### TLS Termination

Настроим Ingress на прием только HTTPS траффика `ui-ingress.yml`
```
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ui
  annotations:
    kubernetes.io/ingress.allow-http: "false"
spec:
  tls:
  - secretName: ui-ingress
  backend:
    serviceName: ui
    servicePort: 9292
```

Применим `kubectl apply -f ui-ingress.yml -n dev`

Не удалился HTTP пересоздали конфигурацию
```
kubectl delete ingress ui -n dev
kubectl apply -f ui-ingress.yml -n dev
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=35.190.95.124"
kubectl delete secret ui-ingress -n dev
kubectl create secret tls ui-ingress --key tls.key --cert tls.crt -n dev
```

### Network Policy
Ищем имя и зону кластера
```
gcloud beta container clusters list
NAME                LOCATION        MASTER_VERSION  MASTER_IP      MACHINE_TYPE  NODE_VERSION  NUM_NODES  STATUS
standard-cluster-1  europe-west1-b  1.9.7-gke.6     104.199.69.39  g1-small      1.9.7-gke.6   3          RUNNING
```

Включаем политику и ждем обновления (операция долгая)
```
gcloud beta container clusters update standard-cluster-1 --zone=europe-west1-b --update-addons=NetworkPolicy=ENABLED
gcloud beta container clusters update standard-cluster-1 --zone=europe-west1-b --enable-network-policy
```

Создаем объект политики для mongo `mongo-network-policy.yml`
Чтобы разрешить `post` добавлем тег `component: post`
```
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-db-traffic
  labels:
    app: reddit
spec:
  podSelector:
    matchLabels:
      app: reddit
      component: mongo
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: reddit
          component: comment
          component: post
```

### Хранилище для базы

Изменяем `mongo-deployment.yml`
```
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: mongo
  labels:
    app: reddit
    component: mongo
    post-db: "true"
    comment-db: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reddit
      component: mongo
  template:
    metadata:
      name: mongo
      labels:
        app: reddit
        component: mongo
        post-db: "true"
        comment-db: "true"
    spec:
      containers:
      - image: mongo:3.2
        name: mongo
        volumeMounts:
        - name: mongo-persistent-storage
          mountPath: /data/db
      volumes:
      - name: mongo-persistent-storage
        emptyDir: {}
```

Создадим диск в Google Cloud
```
gcloud compute disks create --size=25GB --zone=europe-west1-b reddit-mongo-disk
```

Меняем в `mongo-deployment.yml`

```
    spec:
      containers:
      - image: mongo:3.2
        name: mongo
        volumeMounts:
        - name: mongo-gce-pd-storage
          mountPath: /data/db
      volumes:
      - name: mongo-persistent-storage
        emptyDir: {}
        volumes:
      - name: mongo-gce-pd-storage
        gcePersistentDisk:
          pdName: reddit-mongo-disk
          fsType: ext4
```

Монтируем выделенный диск к POD’у mongo
```
kubectl apply -f mongo-deployment.yml -n dev
```

Удалим deployment `kubectl delete deploy mongo -n dev`
Создадим `kubectl apply -f mongo-deployment.yml -n dev` даннык на месте

### PersistentVolume

Создадим описание PersistentVolume `mongo-volume.yml`
```
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: reddit-mongo-disk
spec:
  capacity:
    storage: 25Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  gcePersistentDisk:
    fsType: "ext4" 
    pdName: "reddit-mongo-disk"
```

Добавим PersistentVolume в кластер `kubectl apply -f mongo-volume.yml -n dev`

### PersistentVolumeClaim

Создадим описание PersistentVolumeClaim (PVC) `mongo-claim.yml`
```
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: mongo-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 15Gi
```

Добавим PersistentVolumeClaim в кластер  `kubectl apply -f mongo-claim.yml -n dev`

Подключим PVC к нашим Pod ам `mongo-deployment.yml`
```
    spec:
      containers:
      - image: mongo:3.2
        name: mongo
        volumeMounts:
        - name: mongo-gce-pd-storage
          mountPath: /data/db
      volumes:
      - name: mongo-gce-pd-storage
        persistentVolumeClaim:
          claimName: mongo-pvc
```

Обновим описание нашего Deployment `kubectl apply -f mongo-deployment.yml -n dev`

### Динамическое выделение Volumes

Создадим описание StorageClass `storage-fast.yml`
```
---
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
  name: fast
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
```

Добавим StorageClass в кластер `kubectl apply -f storage-fast.yml -n dev`

Создадим описание PersistentVolumeClaim `mongo-claim-dynamic.yml`
```
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: mongo-pvc-dynamic
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fast
  resources:
    requests:
      storage: 10Gi
```

Добавим StorageClass в кластер `kubectl apply -f mongo-claim-dynamic.yml -n dev`

Подключим PVC к нашим Pods `mongo-deployment.yml`
```
    spec:
      containers:
      - image: mongo:3.2
        name: mongo
        volumeMounts:
        - name: mongo-gce-pd-storage
          mountPath: /data/db
      volumes:
      - name: mongo-gce-pd-storage
        persistentVolumeClaim:
          claimName: mongo-pvc-dynamic
```

Обновим описание нашего Deployment `kubectl apply -f mongo-deployment.yml -n dev`

Созданнеы Volumes
```
kubectl get persistentvolume -n dev
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                   STORAGECLASS   REASON   AGE
pvc-4a3d0407-d608-11e8-ba91-42010a84025a   10Gi       RWO            Delete           Bound       dev/mongo-pvc-dynamic   fast                    4m46s
pvc-4fae2473-d606-11e8-ba91-42010a84025a   15Gi       RWO            Delete           Bound       dev/mongo-pvc           standard                18m
reddit-mongo-disk                          25Gi       RWO            Retain           Available                                                   20m
```

## kubernetes-4

Helm - установка

Скачиваем, распаковываем в нцжное место `https://github.com/helm/helm/releases`

Создаем `tiller.yml`
```
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
```

Применимм манифест
Запустим tiller-сервер `helm init --service-account tiller`
Создаем структуру Chart
Создадим `ui/Chart.yaml`
Установим Chart `helm install --name test-ui-1 ui/`
Проверим `helm ls`

Теперь сделаем так, чтобы можно было использовать 1 Chart для запуска нескольких экземпляров (релизов).
```
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  labels:
    app: reddit
    component: ui
    release: {{ .Release.Name }}
spec:
  type: NodePort
  ports:
  - port: 9292
    protocol: TCP
    targetPort: 9292
  selector:
    app: reddit
    component: ui
    release: {{ .Release.Name }}
```

### Templates

name: {{ .Release.Name }}-{{ .Chart.Name }}
Здесь мы используем встроенные переменные
.Release - группа переменных с информацией о релизе
(конкретном запуске Chart’а в k8s)
.Chart - группа переменных с информацией о Chart’е (содержимое
файла Chart.yaml)
Также еще есть группы переменных:
.Template - информация о текущем шаблоне ( .Name и .BasePath)
.Capabilities - информация о Kubernetes (версия, версии API)
.Files.Get - получить содержимое файла

Модифицируем `ui/templates/deployment.yaml`
```
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  labels:
    app: reddit
    component: ui
    release: {{ .Release.Name }}
spec:
  replicas: 3
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: reddit
      component: ui
      release: {{ .Release.Name }}
  template:
    metadata:
      name: ui-pod
      labels:
        app: reddit
        component: ui
        release: {{ .Release.Name }}
    spec:
      containers:
      - image: kumite/ui
        name: ui
        ports:
        - containerPort: 9292
          name: ui
          protocol: TCP
        env:
        - name: ENV
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
```

Меняем `ui/templates/ingress.yaml`

```
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  annotations:
    kubernetes.io/ingress.class: "gce"
spec:
  rules:
  - http:
      paths:
      - path: /*
        backend:
          serviceName: {{ .Release.Name }}-{{ .Chart.Name }}
          servicePort: 9292
```

Установим несколько релизов ui
```
helm install ui --name ui-1
helm install ui --name ui-2
helm install ui --name ui-3
```

Кастомизируем установку своими переменными (образ и порт). `ui/templates/deployment.yaml`
```
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  labels:
    app: reddit
    component: ui
    release: {{ .Release.Name }}
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: reddit
      component: ui
      release: {{ .Release.Name }}
  template:
    metadata:
      name: ui
      labels:
        app: reddit
        component: ui
        release: {{ .Release.Name }}
    spec:
      containers:
      - image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        name: ui
        ports:
        - containerPort: {{ .Values.service.internalPort }}
          name: ui
          protocol: TCP
        env:
        - name: ENV
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
```

Изменим `ui/templates/service.yaml`
```
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  labels:
    app: reddit
    component: ui
    release: {{ .Release.Name }}
spec:
  type: NodePort
  ports:
  - port: {{ .Values.service.externalPort }}
    protocol: TCP
    targetPort: {{ .Values.service.internalPort }}
  selector:
    app: reddit
    component: ui
    release: {{ .Release.Name }}
```

Изменим `ui/templates/ingress.yaml`
```
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  annotations:
    kubernetes.io/ingress.class: "gce"
spec:
  rules:
  - http:
      paths:
      - path: /
        backend:
          serviceName: {{ .Release.Name }}-{{ .Chart.Name }}
          servicePort: {{ .Values.service.externalPort }}
```

Определим значения собственных переменных `ui/values.yaml`
```
---
service:
  internalPort: 9292
  externalPort: 9292

image:
  repository: kumite/ui
  tag: latest
```

Обновим UI
```
helm upgrade ui-1 ui/
helm upgrade ui-2 ui/
helm upgrade ui-3 ui/
```

### Post

Создадим структуру и обновим файлы

`post/templates/service.yaml`
```
---
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  labels:
    app: reddit
    component: post
    release: {{ .Release.Name }}
spec:
  type: ClusterIP
  ports:
  - port: {{ .Values.service.externalPort }}
    protocol: TCP
    targetPort: {{ .Values.service.internalPort }}
  selector:
    app: reddit
    component: post
    release: {{ .Release.Name }}
```

`post/templates/deployment.yaml`
```
---
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  labels:
    app: reddit
    component: post
    release: {{ .Release.Name }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: reddit
      component: post
      release: {{ .Release.Name }}
  template:
    metadata:
      name: post
      labels:
        app: reddit
        component: post
        release: {{ .Release.Name }}
    spec:
      containers:
      - image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        name: post
        ports:
        - containerPort: {{ .Values.service.internalPort }}
          name: post
          protocol: TCP
        env:
        - name: POST_DATABASE_HOST
          value: postdb
```

Cоздадим удобный шаблон для задания адреса БД.
```
env:
  - name: POST_DATABASE_HOST
    value: {{ .Values.databaseHost | default (printf "%s-mongodb" .Release.Name) }}
```

Создадим `post/values.yaml`
```
---
service:
  internalPort: 5000
  externalPort: 5000

image:
  repository: kumite/post
  tag: latest

databaseHost:
```

Шаблонизируем сервис comment:
Здесь все очень похоже на сервис post
comment/templates/deployment.yaml (`https://gist.githubusercontent.com/chromko/6f852aae9408d6e7206415202b25da6d/raw/10ce16d24431c0991b75aaf003fdac1b62e45f96/gistfile1.txt`)
comment/templates/service.yaml (`https://gist.githubusercontent.com/chromko/334a499f2988d3eebec0278ec01e601a/raw/f6fe9f3d819e75bfb75204fcc21d79082034eea3/gistfile1.txt`)
comment/values.yaml (`https://gist.githubusercontent.com/chromko/e33f7000194715f31800a713a1ee108b/raw/fcb26d927e4bccaaa762570c3830b99982fd9f59/gistfile1.txt`)


Создае функцию `comment.fullname` : `charts/comment/templates/_helpers.tpl`

Заменим
`name: {{ template "comment.fullname" . }}`

### Управление зависимостями

Создаем `reddit/Chart.yaml`
```
---
name: reddit
version: 0.1.0
description: OTUS sample reddit application
maintainers:
  - name: Aleksei Kiselev
    email: kumite73@gmail.com
```
Создаем пустой `reddit/values.yaml`

В директории `Chart/reddit` создадим файл `reddit/requirements.yaml`
```
dependencies:
  - name: ui
    version: "1.0.0"
    repository: "file://../ui"
  - name: post
    version: 1.0.0
    repository: file://../post
  - name: comment
    version: 1.0.0
    repository: file://../comment
```

Нужно загрузить зависимости (когда Chart не упакован в tgz архив)  `helm dep update`

Найдем Chart в общедоступном репозитории
```
helm search mongo
```

Добавим в `eddit/requirements.yml`
```
  - name: mongodb
    version: 4.0.3
    repository: https://kubernetes-charts.storage.googleapis.com
```

Выгрузим зависимости `helm dep update`

Запсукакм проект 
```
helm install reddit --name reddit-test
```

Выясняем внешний IP `kubectl get ingress`

Меняем секцию `env` для `ui/deployments.yaml`
```
        env:
        - name: POST_SERVICE_HOST
          value: {{  .Values.postHost | default (printf "%s-post" .Release.Name) }}
        - name: POST_SERVICE_PORT
          value: {{  .Values.postPort | default "5000" | quote }}
        - name: COMMENT_SERVICE_HOST
          value: {{  .Values.commentHost | default (printf "%s-comment" .Release.Name) }}
        - name: COMMENT_SERVICE_PORT
          value: {{  .Values.commentPort | default "9292" | quote }}
        - name: ENV
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
```

Добавялем переменые в `ui/values.yaml`
```
postHost:
postPort:
commentHost:
commentPort:
```

Можно задавать переменные для зависимостей в `values.yaml` самого Chart reddit.
Они перезаписывают значения переменных из зависимых чартов.
```
comment:
  image:
    repository: kumite/comment
    tag: latest
  service:
    externalPort: 9292

post:
  image:
    repository: kumite/post
    tag: latest
    service:
      externalPort: 5000

ui:
  image:
    repository: kumite/ui
    tag: latest
    service:
      externalPort: 9292
```

Обновляем 
```
helm dep update ./reddit
helm upgrade reddit-test ./reddit
```

### GitLab + Kubernetes

Добавляем новый пул узлов:
• bigpool
• 1 узел типа n1-standard-2 (7,5 Гб, 2 виртуальных ЦП)
• Размер диска 40 Гб

Установим Gitlab
Включим устревшие права доступа
Добавим репозиторий Gitlab
```
helm repo add gitlab https://charts.gitlab.io
```
Скачиваем и распаковываем
```
helm fetch gitlab/gitlab-omnibus --version 0.1.37 --untar
```

Создаем `Gitlab_ci`
Переносим исходные коды проектов, пушим в полготовленные проекты на gitlab

#### Настроим CI

Создайте файл `Gitlab_ci/ui/.gitlab-ci.yml`
```
image: alpine:latest

stages:
  - build
  - test
  - release
  - cleanup
 
build:
  stage: build
  image: docker:git
  services:
    - docker:dind
  script:
    - setup_docker
    - build
  variables:
    DOCKER_DRIVER: overlay2
  only:
    - branches

test:
  stage: test
  script:
    - exit 0
  only:
    - branches

release:
  stage: release
  image: docker
  services:
    - docker:dind
  script:
    - setup_docker
    - release
  only:
    - master

.auto_devops: &auto_devops |
  [[ "$TRACE" ]] && set -x
  export CI_REGISTRY="index.docker.io"
  export CI_APPLICATION_REPOSITORY=$CI_REGISTRY/$CI_PROJECT_PATH
  export CI_APPLICATION_TAG=$CI_COMMIT_REF_SLUG
  export CI_CONTAINER_NAME=ci_job_build_${CI_JOB_ID}
  export TILLER_NAMESPACE="kube-system"

  function setup_docker() {
    if ! docker info &>/dev/null; then
      if [ -z "$DOCKER_HOST" -a "$KUBERNETES_PORT" ]; then
        export DOCKER_HOST='tcp://localhost:2375'
      fi
    fi
  }

  function release() {

    echo "Updating docker images ..."

    if [[ -n "$CI_REGISTRY_USER" ]]; then
      echo "Logging to GitLab Container Registry with CI credentials..."
      docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD"
      echo ""
    fi

    docker pull "$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG"
    docker tag "$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG" "$CI_APPLICATION_REPOSITORY:$(cat VERSION)"
    docker push "$CI_APPLICATION_REPOSITORY:$(cat VERSION)"
    echo ""
  }

  function build() {

    echo "Building Dockerfile-based application..."
    echo `git show --format="%h" HEAD | head -1` > build_info.txt
    echo `git rev-parse --abbrev-ref HEAD` >> build_info.txt
    docker build -t "$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG" .

    if [[ -n "$CI_REGISTRY_USER" ]]; then
      echo "Logging to GitLab Container Registry with CI credentials..."
      docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD"
      echo ""
    fi

    echo "Pushing to GitLab Container Registry..."
    docker push "$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG"
    echo ""
  }

before_script:
  - *auto_devops
```

#### Настроим CI

Обновим конфиг ингресса для сервиса UI: `reddit-deploy/ui/templates/ingress.yml`
```
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: {{ template "ui.fullname" . }}
  annotations:
    kubernetes.io/ingress.class: {{ .Values.ingress.class }}
spec:
  rules:
  - host: {{ .Values.ingress.host | default .Release.Name }}
    http:
      paths:
      - path: /
        backend:
          serviceName: {{ template "ui.fullname" . }}
          servicePort: {{ .Values.service.externalPort }}
```

Обновим конфиг ингресса для сервиса UI `reddit-deploy/ui/values.yml` Будем использовать nginx-ingress, который был поставлен вместе с gitlab-ом (так быстрее и правила более гибкие, чем у GCP)
```
ingress:
  class: nginx
```

Дадим возможность разработчику запускать отдельное окружение в Kubernetes по коммиту в feature-бранч.

Создайте новый бранч в репозитории ui `git checkout -b feature/3`
Обновите `ui/.gitlab-ci.yml`
Закоммитьте и запушьте изменения
```
git commit -am "Add review feature"
git push origin feature/3
```

CI не завершился из-за ошибки обновления helm
```
Error: error when upgrading: current Tiller version is newer, use --force-upgrade to downgrade
```

Обновил опциию на `--force-upgrade`

```
helm ls
NAME                    REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
gitlab                  1               Tue Oct 30 13:56:39 2018        DEPLOYED        gitlab-omnibus-0.1.37                   default
review-kumite-ui-de3zeg 1               Tue Oct 30 15:43:35 2018        DEPLOYED        reddit-0.1.0                            review
```

#### Настроим CI

Созданные для таких целей окружения временны, их требуется “убивать”, когда они больше не нужны. Изменяем `.gitlab-ci.yml`

```
stop_review:
  stage: cleanup
  variables:
    GIT_STRATEGY: none
  script:
    - install_dependencies
    - delete
  environment:
    name: review/$CI_PROJECT_PATH/$CI_COMMIT_REF_NAME
    action: stop
  when: manual
  allow_failure: true
  only:
    refs:
      - branches
    kubernetes: active
  except:
    - master
```

```
stages:
  ...
  - cleanup
```

```
review:
  stage: review
  …
  environment:
    name: review/$CI_PROJECT_PATH/$CI_COMMIT_REF_NAME
    url: http://$CI_PROJECT_PATH_SLUG-$CI_COMMIT_REF_SLUG
    on_stop: stop_review
```

```
  function delete() {
    track="${1-stable}"
    name="$CI_ENVIRONMENT_SLUG"
    helm delete "$name" --purge || true
  }
```

Скопировать полученный файл `.gitlab-ci.yml` для `ui` в репозитории для `post` и `comment`.

#### Деплой

Создадим `staging` и `production` среды для работы приложения
Создаем файл `reddit-deploy/.gitlab-ci.yml`

Проверяем
```
helm ls
NAME            REVISION        UPDATED                         STATUS          CHART                   APP VERSION     NAMESPACE
gitlab          1               Tue Oct 30 13:56:39 2018        DEPLOYED        gitlab-omnibus-0.1.37                   default
production      1               Tue Oct 30 16:10:30 2018        DEPLOYED        reddit-0.1.0                            production
staging         1               Tue Oct 30 16:08:24 2018        DEPLOYED        reddit-0.1.0                            staging
```

