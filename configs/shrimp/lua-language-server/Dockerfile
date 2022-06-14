FROM alpine

RUN apk add --no-cache bash git samurai build-base

WORKDIR /etc/app
RUN git clone https://github.com/sumneko/lua-language-server /etc/app/lua-language-server
WORKDIR /etc/app/lua-language-server
RUN git submodule update --init --recursive

WORKDIR /etc/app/lua-language-server/3rd/luamake
RUN ./compile/install.sh

WORKDIR /etc/app/lua-language-server
RUN ./3rd/luamake/luamake

ENTRYPOINT ["/etc/app/lua-language-server/bin/lua-language-server"]
