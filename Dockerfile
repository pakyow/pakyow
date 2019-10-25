ARG ruby
FROM pakyow/ci-ruby-$ruby:latest

RUN mkdir -p /pakyow
WORKDIR /pakyow

COPY . .

RUN rm -f Gemfile.lock
RUN bundle install --jobs=3 && bundle update --jobs=3
