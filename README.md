# pvpgn
Docker image containing pvpgn-server release 1.99.7.2.1 which includes: pvpgn, d2cs, d2dbs

# Prerequisites
Docker
docker-compose 

# Build 

Clone repository:
```
git clone https://github.com/espenmjos/pvpgn.git
```
Build the docker image:
```
docker build -t pvpgn-pro:1.99.7.2.1 .
```
Copy config files from inside container to docker host:
```
docker run --rm -v $PWD/var:/mnt/var pvpgn-pro:1.99.7.2.1 cp -r /pvpgn/var/pvpgn/ /mnt/var/
docker run --rm -v $PWD/etc:/mnt/etc pvpgn-pro:1.99.7.2.1 cp -r /pvpgn/etc/pvpgn/ /mnt/etc/
```

Edit configuration:
Follow guide here: https://pvpgn.pro/d2gs_installation.html

# Deploy
docker-compose up -d 

# Pvpgn gateway installer :
https://github.com/pvpgn/battle.net-gateway-installer

