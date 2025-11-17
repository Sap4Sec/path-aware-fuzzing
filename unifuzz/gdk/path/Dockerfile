FROM path-fuzzing:latest AS builder

LABEL maintainer="gpriamo"

RUN apt-get install -qq -y --no-install-recommends libglib2.0-dev gtk-doc-tools libtiff-dev libpng-dev autopoint

RUN mkdir -p /home/app/benches/bench/path

COPY . /home/app/benches/bench/

RUN ["chmod", "+x", "/home/app/benches/bench/build_path.sh"]
RUN ["chmod", "+x", "/home/app/benches/bench/fuzz_cmplog.sh"]
RUN ["chmod", "+x", "/home/app/benches/bench/start_session.sh"]

WORKDIR /home/app/benches/bench/

ENV PLACEHOLDER="@@ /dev/null"

ENV BIND_CPU=0
CMD ./start_session.sh
