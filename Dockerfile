From ruby
ADD . /usr/app/
workdir /usr/app/
EXPOSE 80
CMD ["ruby","HttpServer.rb"]