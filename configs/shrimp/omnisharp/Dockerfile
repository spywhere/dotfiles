FROM alpine

RUN apk add --no-cache unzip curl
RUN apk add --repository="https://dl-cdn.alpinelinux.org/alpine/edge/testing" --no-cache mono

WORKDIR /etc/app
RUN mkdir -p /tmp
RUN mkdir -p /etc/app
RUN curl -fLo /tmp/omnisharp-mono.zip --create-dirs https://github.com/OmniSharp/omnisharp-roslyn/releases/latest/download/omnisharp-mono.zip
RUN unzip /tmp/omnisharp-mono.zip -d /etc/app/omnisharp-mono
RUN chmod +x /etc/app/omnisharp-mono/OmniSharp.exe

ENTRYPOINT ["mono", "/etc/app/omnisharp-mono/OmniSharp.exe"]
