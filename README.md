# docker-mariadb-10.3-galera
Multi Master Replication using MariaDB 10.3 and Galera inside Docker.

Requires at least 3 nodes.

Let's say server1, server2, server3. You will have 2 data containers (data+config) and 1 container running MariaDB and Galera on each hosts.

# 1 - Config and data containers
### All Servers

##### Build Image
```
docker build -t mym/mariadb-galera-10.3 https://github.com/MineYourMind/docker-mariadb-10.3-galera.git
```


##### Make a config container that will be accessible from the host and the container.
```
docker run --name mariadb-cluster-config -v /var/configs/mariadb-cluster/conf.d:/etc/mysql/conf.d busybox true
                                            ^^^^^^                      ^^^^^^
                                            Host directory               Container directory
```

##### Make a data container that will be accessible from the host and the container.
```
docker run --name mariadb-cluster-data -v /var/data/mariadb-cluster:/data busybox true
                                            ^^^^^^^                      ^^^^^^
                                            Host directory               Container directory
```

##### 

##### Make a ssh container that will be accessible from the host and the container.
```
docker run --name mariadb-cluster-ssh -v /var/configs/mariadb-cluster/.ssh:/root/.ssh busybox true
                                            ^^^^^^^                      ^^^^^^
                                            Host directory               Container directory
```

#####


# 2 - Config
```
cd /var/configs/mariadb-cluster/conf.d
sudo nano cluster.cnf
```
Change <IP> to IP you want
Change <NODE>'s to other nodes
Do this on all servers

# 3 - Initial startup

Start the first server with (sometimes requires "sudo docker restart mariadb-cluster-srv"):
```
docker run -t -i -d --net=host --privileged=true --volumes-from mariadb-cluster-config --volumes-from mariadb-cluster-data --volumes-from mariadb-cluster-ssh -v /etc/timezone:/etc/timezone:ro -e "TZ=Europe/Berlin" --name mariadb-cluster-srv mym/mariadb-galera-10.3 /bin/start new
```

Start other servers with :
```
# other servers
docker run -t -i -d --net=host --privileged=true --volumes-from mariadb-cluster-config --volumes-from mariadb-cluster-data --volumes-from mariadb-cluster-ssh -v /etc/timezone:/etc/timezone:ro -e "TZ=Europe/Berlin" --name mariadb-cluster-srv mym/mariadb-galera-10.3 /bin/start node
```

# 4 - Restart server1 in "node mode"
It is very important to restart the first node just like the other. Otherwise if you stop and start your container, you will create a new cluster each time.

```
docker stop mariadb-cluster-srv
docker rm mariadb-cluster-srv
docker run -t -i -d --net=host --privileged=true --volumes-from mariadb-cluster-config --volumes-from mariadb-cluster-data --volumes-from mariadb-cluster-ssh -v /etc/timezone:/etc/timezone:ro -e "TZ=Europe/Berlin" --name mariadb-cluster-srv mym/mariadb-galera-10.3 /bin/start node
```

# 5 - Debug
If anything goes wrong, you can always debug via the error.log
```
tail -f /var/data/mariadb/error.log
```


# 6 - Migration from 10.1

```
docker build -t mym/mariadb-galera-10.3 https://github.com/MineYourMind/docker-mariadb-10.3-galera.git && \
docker run --name mariadb-10.3-cluster-config -v /var/configs/mariadb-10.3-cluster/conf.d:/etc/mysql/conf.d busybox true && \
docker run --name mariadb-10.3-cluster-data -v /var/data/mariadb-10.3-cluster:/data busybox true && \
docker run --name mariadb-10.3-cluster-ssh -v /var/configs/mariadb-10.3-cluster/.ssh:/root/.ssh busybox true && \
cp -rv /var/configs/mariadb-cluster/* /var/configs/mariadb-10.3-cluster/ && \
sed -i '65i wsrep_on=ON' /var/configs/mariadb-10.3-cluster/conf.d/cluster.cnf && \
docker stop mariadb-cluster-srv && \
docker run -t -i -d --net=host --privileged=true --volumes-from mariadb-10.3-cluster-config --volumes-from mariadb-10.3-cluster-data --volumes-from mariadb-10.3-cluster-ssh -v /etc/timezone:/etc/timezone:ro -e "TZ=Europe/Berlin" --name mariadb-10.3-cluster-srv mym/mariadb-galera-10.3 /bin/start node
```
