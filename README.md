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

