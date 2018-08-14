# See CKAN docs on installation from Docker Compose on usage
FROM debian:jessie
MAINTAINER earthquakesan@gmail.com

# Install required system packages
RUN apt-get -q -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -q -y upgrade \
    && apt-get -q -y install \
        python-dev \
        python-pip \
        python-virtualenv \
        python-wheel \
        libpq-dev \
        libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
        postgresql-client \
        build-essential \
        git-core \
        vim \
        wget \
    && apt-get -q clean \
    && rm -rf /var/lib/apt/lists/*

# Define environment variables
ENV CKAN_HOME /usr/lib/ckan
ENV CKAN_VENV $CKAN_HOME/venv
ENV CKAN_CONFIG /etc/ckan
ENV CKAN_STORAGE_PATH=/var/lib/ckan

# Build-time variables specified by docker-compose.yml / .env
ARG CKAN_SITE_URL

# Create ckan user
RUN useradd -r -u 900 -m -c "ckan account" -d $CKAN_HOME -s /bin/false ckan

# Setup virtual environment for CKAN
RUN mkdir -p $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH && \
    virtualenv $CKAN_VENV && \
    ln -s $CKAN_VENV/bin/pip /usr/local/bin/ckan-pip &&\
    ln -s $CKAN_VENV/bin/paster /usr/local/bin/ckan-paster

# Setup CKAN
RUN git clone https://github.com/ckan/ckan $CKAN_VENV/src/ckan && \
    cd $CKAN_VENV/src/ckan && \
    git checkout ckan-2.8.1
RUN ckan-pip install -U pip && \
    ckan-pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirement-setuptools.txt && \
    ckan-pip install --upgrade --no-cache-dir -r $CKAN_VENV/src/ckan/requirements.txt && \
    ckan-pip install -e $CKAN_VENV/src/ckan/ && \
    ln -s $CKAN_VENV/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini && \
    chown -R ckan:ckan $CKAN_HOME $CKAN_VENV $CKAN_CONFIG $CKAN_STORAGE_PATH

RUN git clone https://github.com/ckan/ckanext-dcat $CKAN_VENV/src/ckanext-dcat && \
    cd $CKAN_VENV/src/ckanext-dcat && \
    ckan-pip install -e . && \
    ckan-pip install -r requirements.txt

RUN git clone https://github.com/ckan/ckanext-harvest $CKAN_VENV/src/ckanext-harvest && \
    cd ${CKAN_VENV}/src/ckanext-harvest && \
    ckan-pip install -e . && \
    ckan-pip install -r pip-requirements.txt

ENV ADDITIONAL_CKAN_PLUGINS "dcat dcat_rdf_harvester dcat_json_harvester dcat_json_interface structured_data harvest ckan_harvester"

ADD ckan-entrypoint.sh /ckan-entrypoint.sh
RUN chmod +x /ckan-entrypoint.sh

ADD recaptcha.html $CKAN_VENV/src/ckan/ckan/templates/user/snippets/recaptcha.html
ADD captcha.py $CKAN_VENV/src/ckan/ckan/lib/captcha.py

ENTRYPOINT ["/ckan-entrypoint.sh"]

USER ckan
EXPOSE 5000

CMD ["ckan-paster","serve","/etc/ckan/production.ini"]
