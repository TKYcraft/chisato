# Chisato

This is TKYcraft BackEnd API for Minecraft Notification bot.



## Getting started (for development)

on your Docker host.

```bash
docker compose up -d --build   # up containers with build process.
docker compose ps   # check running containers.
docker compose down   # down containers.
```



### options

* Ruby version : 3.4.2 (configure on Dockerfile, Gemfile)

* Database creation / initialization
  
  * This API is not using RDB.
  
* How to run the test suite

  ```bash
  docker exec -it chisato-server bundle exec rspec
  # or exec bash
  ```

* Services

  - You should reference compose.yaml

* Deployment instructions

  * Run [tkycraft/chisato:latest](https://hub.docker.com/r/tkycraft/chisato) (Docker Image).

  * example of compose.yaml for Production Deployment.

    ```yaml
    services:
      chisato-server:
        image: tkycraft/chisato:latest
        container_name: chisato-server
        ports:
          - 3000:3000
        environment:
          - SECRET_KEY_BASE={{  }}
          - RAILS_MASTER_KEY={{  }}
    ```


