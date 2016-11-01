#!/bin/bash
#Built for Ubuntu 16.10 Server
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

#Assumes that the current directory was git cloned from the repo.
#Todo: Chown the directories and stuff to the user. 
mkdir /opt/rt-downloader/
cp ./backend/rt.lua /opt/rt-downloader/

apt-get -y install unzip make gcc git libreadline-dev sqlite3 libsqlite3-dev libssl-dev #youtube-dl ffmpeg handbrake-cli

mkdir /tmp/lua
cd /tmp/lua
wget http://www.lua.org/ftp/lua-5.3.3.tar.gz
tar -xzf lua-5.3.3.tar.gz
cd lua-5.3.3
make linux
make linux test
make linux install

cd /tmp/lua
wget http://keplerproject.github.io/luarocks/releases/luarocks-2.4.1.tar.gz
tar -xzf luarocks-2.4.1.tar.gz
cd luarocks-2.4.1

/tmp/lua/luarocks-2.4.1/configure
make build
make install

cd ~
rm -rf /tmp/lua

luarocks install luajson #Not sure if needed in final build, as json is really only used for development purposes.
luarocks install lsqlite3
luarocks install luasec #Includes LuaSocket
luarocks install sha2
