FROM rocker/r-ver:4.0.0

## Built from templates created by the Rocker Project
## For more information https://www.rocker-project.org

LABEL org.label-schema.license="GPL-2.0" \
      org.label-schema.vendor="The Data Collective" \
      maintainer="Dan Wilson <dan@thedatacollective.com.au>"

## This allows for direct access to rstudio server without passwords
## Do not use the below environment variables if placing on publicly
## exposed server (e.g. Amazon AWS)
ENV ROOT=TRUE
ENV PASSWORD=password
ENV DISABLE_AUTH=TRUE
ENV TZ=Australia/Brisbane

## Variables for the installation of RStudio
ENV S6_VERSION=v1.21.7.0
ENV RSTUDIO_VERSION=latest
ENV PATH=/usr/lib/rstudio-server/bin:$PATH

RUN apt-get update \
&&  apt-get install -y --no-install-recommends \
  libpq5

RUN /rocker_scripts/install_rstudio.sh
RUN /rocker_scripts/install_pandoc.sh
RUN /rocker_scripts/install_verse.sh

RUN mkdir -p /home/rstudio/.config/rstudio/keybindings/

COPY settings/addins.json /home/rstudio/.config/rstudio/keybindings/
COPY settings/rstudio-prefs.json /home/rstudio/.config/rstudio/

## update permissions to avoid needless warnings
RUN chown -R rstudio:staff /home/rstudio/ \
  && chmod -R 777 /home/rstudio/

## copy fonts to make available for use in rstudio and documents
## Update font cache once copied
COPY fonts /usr/share/fonts
COPY fonts /etc/rstudio/fonts
RUN fc-cache -f -v

## Install tools to support desired packages
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libgit2-dev \
    libxml2-dev \
    libcairo2-dev \
    liblapack-dev \
    liblapack3 \
    libopenblas-base \
    libpq-dev \
    libsqlite3-dev \
    libssh2-1-dev \
    unixodbc-dev \
    openssh-client \
    mdbtools \
    libsnappy-dev \
    autoconf \
    automake \
    libtool \
    python-dev \
    pkg-config \
    p7zip-full \
    libudunits2-dev \
    tzdata \
  && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
  && dpkg-reconfigure -f noninteractive tzdata \
  && rm -rf /var/lib/apt/lists/*

## add regularly used packages
RUN install2.r --error --skipinstalled -r $CRAN \
  devtools \
  rmarkdown \
  RcppEigen \
  lme4 \
  car \
  zoo \
  scales \
  reshape2 \
  RPostgreSQL \
  RSQLite \
  Hmisc \
  scales \
  officer \
  flextable \
  xaringan \
  ggthemes \
  futile.logger \
  dplyr \
  readxl \
  writexl \
  drake \
  extrafont \
  visNetwork \
  clustermq \
  secret \
  XLConnect \
  fst \
  && R -e 'remotes::install_gitlab("thedatacollective/segmentr")' \
  && R -e 'remotes::install_github("wilkelab/gridtext")' \
  && R -e 'remotes::install_github("danwwilson/hrbrthemes", "dollar_axes")' \
  && R -e 'remotes::install_github("thedatacollective/tdcthemes")' \
  && R -e 'remotes::install_gitlab("thedatacollective/templatermd")' \
  && R -e 'remotes::install_github("StevenMMortimer/salesforcer")' \
  && R -e 'remotes::install_github("milesmcbain/fnmate")' \
  && R -e 'remotes::install_github("gaborcsardi/dotenv")' \
  && R -e 'install.packages("data.table", type = "source", repos = "http://Rdatatable.github.io/data.table")' \
  && rm -rf /tmp/downloaded_packages/ \
  && rm -rf /tmp/*.tar.gz

## Add /data volume by default
VOLUME /data
VOLUME /home/rstudio/.ssh

EXPOSE 8787

CMD /init
