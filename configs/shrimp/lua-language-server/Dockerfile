FROM alpine

RUN apk add --no-cache bash git samurai build-base

WORKDIR /etc/app
RUN git clone --branch 3.5.6 --depth 1 --shallow-submodules --recurse-submodules https://github.com/sumneko/lua-language-server /etc/app/lua-language-server

WORKDIR /etc/app/lua-language-server/3rd/luamake
RUN ./compile/install.sh

WORKDIR /etc/app/lua-language-server
RUN ./3rd/luamake/luamake rebuild

ENTRYPOINT ["/etc/app/lua-language-server/bin/lua-language-server"]
