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
