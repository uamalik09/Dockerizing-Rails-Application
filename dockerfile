FROM ruby:2.6.1
RUN gem update --system 3.2.3
RUN gem install bundler -v 2.4.7 
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
EXPOSE 3000
CMD ["./bin/rails","server","-b","0.0.0.0"]