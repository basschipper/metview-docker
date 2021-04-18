FROM ubuntu:20.04 as build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND noninteractive
# hadolint ignore=DL3008
RUN set -eux \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
  bison \
  ca-certificates \
  cmake \
  curl \
  flex \
  g++ \
  gfortran \
  libcurl4-openssl-dev \
  libexpat1-dev \
  libgdbm-dev \
  libpango1.0-dev \
  libnetcdf-dev \
  libsqlite3-dev \
  libtiff5-dev \
  make \
  sqlite3 \
  wget \
  && rm -rf /var/lib/apt/lists/*

# Install ecbuild
ENV ECBUILD_VERSION=3.4.1
# hadolint ignore=DL3003
RUN set -eux \
  && mkdir -p /src \
  && cd /src \
  && wget -O - https://github.com/ecmwf/ecbuild/archive/${ECBUILD_VERSION}.tar.gz | tar xvzf - \
  && mkdir -p /build/ecbuild \
  && cd /build/ecbuild \
  && cmake /src/ecbuild-${ECBUILD_VERSION} -DCMAKE_BUILD_TYPE=Release \
  && make "-j$(nproc)" \
  && make install

# Install eccodes
ENV ECCODES_VERSION=2.19.1
# hadolint ignore=DL3003
RUN set -eux \
  && mkdir -p /src \
  && cd /src \
  && wget -O - -q https://confluence.ecmwf.int/download/attachments/45757960/eccodes-${ECCODES_VERSION}-Source.tar.gz?api=v2 | tar xvzf - \
  && mkdir -p /build/eccodes \
  && cd /build/eccodes \
  && /usr/local/bin/ecbuild /src/eccodes-${ECCODES_VERSION}-Source -DCMAKE_BUILD_TYPE=Release \
  && make "-j$(nproc)" \
  && make install

# Install Proj
ENV PROJ_VERSION=7.2.0
# hadolint ignore=DL3003
RUN set -eux \
  && mkdir -p /src \
  && cd /src \
  && wget -O - https://github.com/OSGeo/PROJ/archive/${PROJ_VERSION}.tar.gz | tar xvzf - \
  && mkdir -p /build/proj \
  && cd /build/proj \
  && /usr/local/bin/ecbuild /src/PROJ-${PROJ_VERSION} -DCMAKE_BUILD_TYPE=Release -DPROJ_TESTS=OFF \
  && make "-j$(nproc)" \
  && make install

# Install Magics++.
ENV MAGICS_BUNDLE_VERSION=4.5.2
# hadolint ignore=DL3003
RUN set -eux \
  && mkdir -p /src \
  && cd /src \
  && wget -O - https://github.com/ecmwf/magics/archive/${MAGICS_BUNDLE_VERSION}.tar.gz | tar xvzf - \
  && mkdir -p /build/magics-bundle \
  && cd /build/magics-bundle \
  && /usr/local/bin/ecbuild /src/magics-${MAGICS_BUNDLE_VERSION} -DCMAKE_BUILD_TYPE=Release -DENABLE_METVIEW_NO_QT=ON \
  && make "-j$(nproc)" \
  && make install

# Install Metview
ENV METVIEW_VERSION=5.10.1
# hadolint ignore=DL3003
RUN set -eux \
  && mkdir -p /src \
  && cd /src \
  && wget -q -O - https://confluence.ecmwf.int/download/attachments/3964985/Metview-${METVIEW_VERSION}-Source.tar.gz?api=v2 | tar xvzf - \
  && mkdir -p /build/metview \
  && cd /build/metview \
  && /usr/local/bin/ecbuild /src/Metview-${METVIEW_VERSION}-Source -DCMAKE_BUILD_TYPE=Release -DENABLE_UI=OFF \
  && make "-j$(nproc)" \
  && make install

FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive
# hadolint ignore=DL3008
RUN set -eux \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
  ghostscript \
  libcurl4 \
  libpango1.0-dev \
  && rm -rf /var/lib/apt/lists/*

# Copy build artifacts
COPY --from=build /usr/local/share/eccodes/ /usr/local/share/eccodes/
COPY --from=build /usr/local/share/magics/ /usr/local/share/magics/
COPY --from=build /usr/local/bin/ /usr/local/bin/
COPY --from=build /usr/local/lib/ /usr/local/lib/

CMD ["echo", "Please override the default Docker command."]
