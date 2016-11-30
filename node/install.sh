#!/bin/bash
#Built for Ubuntu 16.10 Server
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Author's node: Most of this is from the backend install.sh
# Although the install / compilation parts are the same, different packages are used.

apt-get -y install unzip make gcc git libreadline-dev libssl-dev ffmpeg 


mkdir /tmp/lua
cd /tmp/lua

#youtube-dl package is old
wget https://github.com/rg3/youtube-dl/releases/download/2016.11.27/youtube-dl
chmod +x /tmp/lua/youtube-dl
mv /tmp/lua/youtube-dl /usr/local/bin

#Check if command exists [From http://stackoverflow.com/a/677212/1687505]
type lua >/dev/null 2>&1 || { \
	wget http://www.lua.org/ftp/lua-5.3.3.tar.gz; \
	tar -xzf lua-5.3.3.tar.gz; \
	cd lua-5.3.3; \
	make linux; \
	make linux test; \
	make linux install; \
}

cd /tmp/lua
type luarocks >/dev/null 2>&1 || { \
	wget http://keplerproject.github.io/luarocks/releases/luarocks-2.4.1.tar.gz; \
	tar -xzf luarocks-2.4.1.tar.gz; \
	cd luarocks-2.4.1; \
	/tmp/lua/luarocks-2.4.1/configure; \
	make build; \
	make install; \
}

cd ~
rm -rf /tmp/lua

luarocks install luajson
luarocks install luasec
#luarocks install lbase64 