FROM alpine AS builder

WORKDIR /etc/app
RUN apk update
RUN apk add git
RUN git clone https://github.com/neomutt/neomutt neomutt
RUN apk add build-base openssl libressl-dev libxslt ncurses-dev ncurses-libs libxml2-dev libxml2-utils gettext-dev libidn-dev lua-dev notmuch-dev gpgme-dev cyrus-sasl-dev lmdb-dev krb5-dev pcre2-dev lz4-dev
WORKDIR /etc/app/neomutt
RUN ./configure --ssl --notmuch --gpgme --with-ui=ncurses --sasl --gss --lmdb --pcre2 --lz4 --disable-doc
RUN make install

FROM alpine
WORKDIR /root
RUN apk update
RUN apk add openssl ncurses-libs libidn notmuch gpgme libsasl lmdb krb5 pcre2 lz4-libs python2
RUN mkdir Mail
RUN mkdir /var/mail/root
COPY --from=builder /usr/bin/neomutt /usr/bin/neomutt
CMD neomutt
