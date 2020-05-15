FROM ponylang/ponyc:release-alpine AS build

WORKDIR /src/rfc-tool

COPY Makefile LICENSE VERSION corral.json lock.json /src/rfc-tool/

WORKDIR /src/rfc-tool/rfc-tool

COPY rfc-tool /src/rfc-tool/rfc-tool/

WORKDIR /src/rfc-tool

RUN make arch=x86-64 static=true linker=bfd \
 && make install

FROM alpine:3.11

COPY --from=build /usr/local/bin/rfc-tool /usr/local/bin/rfc-tool

CMD rfc-tool
