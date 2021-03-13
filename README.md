# pvpgn
# Prerequisites
Docker 
docker-compose 

# Build 
'''
git clone https://github.com/espenmjos/pvpgn.git

docker build -t pvpgn-pro:1.99.7.2.1 .

docker run --rm -v $PWD/var:/mnt/var pvpgn-pro:1.99.7.2.1 cp -r /pvpgn/var/pvpgn/ /mnt/var/
docker run --rm -v $PWD/etc:/mnt/etc pvpgn-pro:1.99.7.2.1 cp -r /pvpgn/etc/pvpgn/ /mnt/etc/
'''

# Edit configuration
see https://pvpgn.pro/d2gs_installation.html

# Deploy
docker-compose up -d 

# Pvpgn gateway installer :
https://github.com/pvpgn/battle.net-gateway-installer

