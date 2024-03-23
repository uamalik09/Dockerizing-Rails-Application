# Dockerizing-Rails-Application: Streamlining Development with Containers

## Table of Contents
- [CONTAINERIZING THE APPLICATION](#task-1-containerizing-the-application)

- [CONNECTING THE APP WITH DATABASE](#task-2-connecting-the-app-with-database)
- [CONFIGURE NGINX AS REVERSE PROXY](#task-3-configure-nginx-as-reverse-proxy)
- [NGINX AS LOAD BALANCER](#task-4-nginx-as-load-balancer)
- [Enabling  Persistence](#task-5-enabling-persistence)
- [NGINX as Rate lmiter](#task-6-nginx-as-rate-lmiter)
## Task-1 [CONTAINERIZING THE APPLICATION]
### Making changes to the application files
- After examining the `Gemfile` and `Gemfile.lock`, it appears that Ruby version 2.6.1 is necessary, paired with Bundler version 2.4.7.
- Modified the versions of certain gems in the Gemfile to ensure compatibility with Ruby 2.6.1.

### Creating Dockerfile for Rails Application

```
FROM ruby:2.6.1
RUN gem update --system 3.2.3
RUN gem install bundler -v 2.4.7 
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
EXPOSE 3000
CMD ["./bin/rails","server","-b","0.0.0.0"]
```
1. FROM ruby:2.6.1: This sets the base image to use for building the container. In  this case, it's Ruby version 2.6.1.

2. RUN gem update --system 3.2.3: This updates RubyGems to version 3.2.3. RubyGems is the package manager for Ruby, used for installing and managing Ruby libraries (gems).

3. RUN gem install bundler -v 2.4.7: This installs Bundler version 2.4.7. Bundler is a Ruby gem manager used for managing gem dependencies for a Ruby project.

4. WORKDIR /app: This sets the working directory inside the container to /app. This is where the application code will be copied.

5. COPY Gemfile Gemfile.lock ./: This copies the Gemfile and Gemfile.lock from the host machine to the /app directory inside the container. These files are used by Bundler to install the required gems for the Ruby application.


- Copying the Gemfile and Gemfile.lock separately and running bundle install before copying the rest of the application code allows Docker to cache the dependencies layer separately. This can significantly speed up the build process when the application code changes but the dependencies remain the same.



6. RUN bundle install: This installs the gems specified in the Gemfile into the container.

7. COPY . .: This copies the entire application code from the host machine to the /app directory inside the container.

8. EXPOSE 3000: This is the port on which the Rails application will be running.
9. CMD ["./bin/rails","server","- b","0.0.0.0"]: This sets the default command to run when the container starts. It starts the Rails server, binding it to all interfaces (0.0.0.0), allowing external access.

## Runnign Docker file
```
 sudo docker build -t app .
```
- app was built successfully

![App Screenshot](screenshot/ContainerizingApp/build.png?text=App+Screenshot+Here)

```
sudo docker run --rm -p 3000:3000 app
```
-  the app image was successfully build 

![App Screenshot](screenshot/ContainerizingApp/run.png?text=App+Screenshot+Here)
- app was running successfully
![App Screenshot](screenshot/ContainerizingApp/browser.png?text=App+Screenshot+Here)



## Task-2 [CONNECTING THE APP WITH DATABASE]

### Using DOcker Compose
```
version: '3.4'
services:
    db: 
        image: mysql:5.7
        restart: always
        environment:
            MYSQL_ROOT_PASSWORD: password
            MYSQL_DATABASE: app
            MYSQL_USER: root
            MYSQL_PASSWORD: password
    app: 
        build:
            dockerfile: dockerfile
        ports:
            - 8800:3000
        depends_on:
            - db
        environment:
            DB_USER: root
            DB_NAME: app
            DB_PASSWORD: password
            DB_HOST: db                 

```

### Configuring database.yml
```
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: 200
  database: app
  username: root
  password: password
  host: db
  port: 3306

development:
  <<: *default
test:
  <<: *default
production:
  <<: *default

```
![App Screenshot](screenshot/ConnectingDatabase/composeup.png?text=App+Screenshot+Here)
![App Screenshot](screenshot/ContainerizingApp/build.png?text=App+Screenshot+Here)



## Task-3 [CONFIGURE NGINX AS REVERSE PROXY]
### Setting up NGINX
Configuring `nginx.conf` for reverse proxy
'''
http{
    server{

      listen 80;
      server_name localhost;


      location /{
      proxy_pass http://app:3000;
      proxy_set_header Host $host:8800;
      
      }
    }

}
'''
### Adding NGINX in docker compose file
'''
 proxy:
    image: nginx
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    ports:
     - "8080:80"
    depends_on:
      - app
'''
- `listen 80`:This directive tells Nginx to listen the incoming HTT request on port 80
- `server_name localhost`:This specifies that this server should respond to request for the hostname 
- `location /`:This block defines how the NGINX should handle requests that matches the specified location
- `proxy_pass http://app:3000`; : This directive tells Nginx to proxy requests to the
upstream server located at "http://app:3000".This means that any requests coming to
Nginx will be forwarded to the server running on port 3000 on the host named "app".

```
version: '3.4'
services:
    db: 
        image: mysql:5.7
        restart: always
        environment:
            MYSQL_ROOT_PASSWORD: password
            MYSQL_DATABASE: app
            MYSQL_USER: root
            MYSQL_PASSWORD: password
    app: 
        build:
            dockerfile: dockerfile
        depends_on:
            - db
        environment:
            DB_USER: root
            DB_NAME: app
            DB_PASSWORD: password
            DB_HOST: db      
    proxy:
        image: nginx:latest
        volumes:
            - ./nginx.conf:/etc/nginx/conf.d/default.conf
        ports:
            - "8800:80"    
        depends_on:
            - app
```
![App Screenshot](screenshot/Reverse_Proxy/run1.png?text=App+Screenshot+Here)
![App Screenshot](screenshot/Reverse_Proxy/run2.png?text=App+Screenshot+Here)
![App Screenshot](screenshot/Reverse_Proxy/run3.png?text=App+Screenshot+Here)

## Task-4 [NGINX AS LOAD BALANCER]
### Modifying the compose file
```
version: '3.1'
services:
  db: 
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: app
      MYSQL_USER: root
      MYSQL_PASSWORD: password
  app1:
    build: 
      dockerfile: dockerfile
    environment:
      DB_USER: root
      DB_NAME: app
      DB_PASSWORD: password
      DB_HOST: db
    depends_on:
      - db
    volumes:
      - ./storage:/app/storage

  app2:
    build: 
      dockerfile: dockerfile
    environment:
      DB_USER: root
      DB_NAME: app
      DB_PASSWORD: password
      DB_HOST: db
    depends_on:
      - db
    volumes:
      - ./storage:/app/storage
  app3:
    build: 
      dockerfile: dockerfile
    environment:
      DB_USER: root
      DB_NAME: app
      DB_PASSWORD: password
      DB_HOST: db
    depends_on:
      - db   
    volumes:
      -  ./storage:/app/storage

  proxy:
    image: nginx
    ports:
     - "8080:8080"
    depends_on:
      - app1
      - app2
      - app3
    
```
### -Now three app containers will spin up, connected to the same DB

### Modifying nginx.conf
```
http{
    upstream rails {
        server app1:3000;
        server app2:3000;
        server app3:3000;
    }

    server{

      listen 8080;
      server_name localhost;


      location /{
      proxy_pass http://rails;
      proxy_set_header Host $host:8800;
      }
    }

}
```
- Here, an upstream block named rails is defined with three backend servers (app1, app2, and app3), each running a Rails application on port 3000. This block defines the pool of servers to which Nginx will distribute incoming requests.
- `Load Balancing Mechanism:`
When a client makes a request to this Nginx server, Nginx will distribute the requests among the backend Rails servers (app1, app2, app3) defined in the upstream block. The load balancing algorithm used by default is round-robin, meaning each new request is forwarded to the next server in the list.
- With this configuration, Nginx acts as a basic load balancer, distributing incoming HTTP requests across multiple Rails application servers to achieve better performance, scalability, and fault tolerance.

### With this configuration, Nginx acts as a basic load balancer, distributing incoming HTTP requests across multiple Rails application servers to achieve better performance, scalability, and fault tolerance.
`sudo docker compose up`
![App Screenshot](screenshot/Load_Balancing/run1.png?text=App+Screenshot+Here)


![App Screenshot](screenshot/Load_Balancing/run2.png?text=App+Screenshot+Here)


![App Screenshot](screenshot/Load_Balancing/run3.png?text=App+Screenshot+Here)


![App Screenshot](screenshot/Load_Balancing/run5.png?text=App+Screenshot+Here)

## Task-5 [Enabling  Persistence]
### Adding Persistent Storage Option for DB and NGINX

```
version: '3.1'
services:
  db: 
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: app
      MYSQL_USER: root
      MYSQL_PASSWORD: password
    volumes:
      - ./db_storage:/var/lib/mysql
  app1:
    build: 
      dockerfile: dockerfile
    environment:
      DB_USER: root
      DB_NAME: app
      DB_PASSWORD: password
      DB_HOST: db
    depends_on:
      - db
    volumes:
      - ./storage:/app/storage

  app2:
    build: 
      dockerfile: dockerfile
    environment:
      DB_USER: root
      DB_NAME: app
      DB_PASSWORD: password
      DB_HOST: db
    depends_on:
      - db
    volumes:
      - ./storage:/app/storage
  app3:
    build: 
      dockerfile: dockerfile
    environment:
      DB_USER: root
      DB_NAME: app
      DB_PASSWORD: password
      DB_HOST: db
    depends_on:
      - db   
    volumes:
      -  ./storage:/app/storage

  proxy:
    image: nginx
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    ports:
     - "8080:8080"
    depends_on:
      - app1
      - app2
      - app3
    
```
- Persistence is done by using bind mounts, so each file will be there no matter what happens to the containers.
![App Screenshot](screenshot/Persistent/1.png?text=App+Screenshot+Here)

## Task-6 [NGINX as Rate lmiter]

### Adding Rate Limiting in NGINX
```
http{
    upstream rails {
        server app1:3000;
        server app2:3000;
        server app3:3000;
    }


    # Define a limit zone
    limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;


    server{

      listen 8080;
      server_name localhost;


      location /{

        # Apply rate limiting
      limit_req zone=one burst=5;

      proxy_pass http://rails;
      proxy_set_header Host $host:8800;
      }
    }

}
```
- `limit_req_zone:` Defines a shared memory zone used to store the states of the limiting actions.
- `$binary_remote_addr:` This variable holds the client's IP address in binary form, which is used as a key for rate limiting.
- `zone=one:10m:` Defines a shared memory zone named "one" with a size of 10 MB to store the states.
- `rate=10r/s:` Sets the rate limit to 10 request per second
- `limit_req:` Directives within the location block apply the rate limiting.
- `zone=one:` Refers to the defined limit zone.
- `burst=5:` Allows a burst of up to 5 requests above the defined rate before further requests are delayed.
- With this configuration, requests to the / location will be limited to one request per second per IP address