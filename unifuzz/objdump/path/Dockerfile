FROM path-fuzzing:latest AS builder

LABEL maintainer="gpriamo"

RUN apt-get install -qq -y --no-install-recommends texinfo

RUN mkdir -p /home/app/benches/bench/path

COPY . /home/app/benches/bench/

RUN ["chmod", "+x", "/home/app/benches/bench/build_path.sh"]
RUN ["chmod", "+x", "/home/app/benches/bench/fuzz_cmplog.sh"]
RUN ["chmod", "+x", "/home/app/benches/bench/start_session.sh"]

ENV PLACEHOLDER="-S @@"

WORKDIR /home/app/benches/bench/

ENV BIND_CPU=0
CMD ./start_session.sh
