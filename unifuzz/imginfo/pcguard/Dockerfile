FROM path-fuzzing:latest AS builder

LABEL maintainer="gpriamo"

#RUN apt-get install -qq -y --no-install-recommends shtool zlib1g-dev

RUN mkdir -p /home/app/benches/bench/pcguard

COPY . /home/app/benches/bench/

RUN ["chmod", "+x", "/home/app/benches/bench/build_pcguard.sh"]
RUN ["chmod", "+x", "/home/app/benches/bench/fuzz_cmplog.sh"]
RUN ["chmod", "+x", "/home/app/benches/bench/start_session.sh"]

WORKDIR /home/app/benches/bench/

ENV PLACEHOLDER="-f @@"

ENV BIND_CPU=0
CMD ./start_session.sh
