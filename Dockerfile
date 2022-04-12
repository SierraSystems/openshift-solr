FROM solr:8.11.1
LABEL maintainer="jason.dudash@gmail.com"
LABEL maintainer="emiliano.sune@gmail.com"

USER root
ENV STI_SCRIPTS_PATH=/usr/libexec/s2i

RUN apt-get update && \
    apt-get install zip

# ===============================================================================================

LABEL io.k8s.description="Run SOLR search in OpenShift" \
      io.k8s.display-name="SOLR 8.11.1" \
      io.openshift.expose-services="8983:http" \
      io.openshift.tags="builder,solr,solr8.11.1" \
      io.openshift.s2i.scripts-url="image:///${STI_SCRIPTS_PATH}"

COPY ./s2i/bin/. ${STI_SCRIPTS_PATH}
RUN chmod -R a+rx ${STI_SCRIPTS_PATH}

# "Fixing" log4j 2.16
RUN rm -f \
    /opt/solr-8.11.1/server/lib/ext/log4j-core-2.16.0.jar \
    /opt/solr-8.11.1/server/lib/ext/log4j-slf4j-impl-2.16.0.jar \
    /opt/solr-8.11.1/server/lib/ext/log4j-layout-template-json-2.16.0.jar \
    /opt/solr-8.11.1/server/lib/ext/log4j-1.2-api-2.16.0.jar \
    /opt/solr-8.11.1/server/lib/ext/log4j-api-2.16.0.jar \
    /opt/solr-8.11.1/server/lib/ext/log4j-web-2.16.0.jar \
    /opt/solr-8.11.1/contrib/prometheus-exporter/lib/log4j-core-2.16.0.jar \
    /opt/solr-8.11.1/contrib/prometheus-exporter/lib/log4j-slf4j-impl-2.16.0.jar \
    /opt/solr-8.11.1/contrib/prometheus-exporter/lib/log4j-api-2.16.0.jar \
    /opt/solr-8.11.1/licenses/log4j-layout-template-json-2.16.0.jar.sha1 \
    /opt/solr-8.11.1/licenses/log4j-web-2.16.0.jar.sha1 \
    /opt/solr-8.11.1/licenses/log4j-slf4j-impl-2.16.0.jar.sha1 \
    /opt/solr-8.11.1/licenses/log4j-core-2.16.0.jar.sha1 \
    /opt/solr-8.11.1/licenses/log4j-api-2.16.0.jar.sha1 \
    /opt/solr-8.11.1/licenses/log4j-1.2-api-2.16.0.jar.sha1

COPY solr/log4j/*.jar /opt/solr-8.11.1/server/lib/ext/
COPY solr/log4j/log4j-core-2.17.2.jar /opt/solr-8.11.1/contrib/prometheus-exporter/lib
COPY solr/log4j/log4j-slf4j-impl-2.17.2.jar /opt/solr-8.11.1/contrib/prometheus-exporter/lib
COPY solr/log4j/log4j-api-2.17.2.jar /opt/solr-8.11.1/contrib/prometheus-exporter/lib
COPY solr/log4j/log4j-layout-template-json-2.17.2.jar.sha1 /opt/solr-8.11.1/licenses
COPY solr/log4j/log4j-web-2.17.2.jar.sha1 /opt/solr-8.11.1/licenses
COPY solr/log4j/log4j-slf4j-impl-2.17.2.jar.sha1 /opt/solr-8.11.1/licenses
COPY solr/log4j/log4j-core-2.17.2.jar.sha1 /opt/solr-8.11.1/licenses
COPY solr/log4j/log4j-api-2.17.2.jar.sha1 /opt/solr-8.11.1/licenses
COPY solr/log4j/log4j-1.2-api-2.17.2.jar.sha1 /opt/solr-8.11.1/licenses

# end of log4j 2.16 "fix"

# If we need to add files as part of every SOLR conf, they'd go here
# COPY ./solr-config/ /tmp/solr-config

# Give the SOLR directory to root group (not root user)
# https://docs.openshift.org/latest/creating_images/guidelines.html#openshift-origin-specific-guidelines
RUN chgrp -R 0 /opt/solr \
  && chmod -R g+rwX /opt/solr \
  && chown -LR solr:root /opt/solr

RUN chgrp -R 0 /opt/docker-solr \
  && chmod -R g+rwX /opt/docker-solr \
  && chown -LR solr:root /opt/docker-solr

# - In order to drop the root user, we have to make some directories writable
#   to the root group as OpenShift default security model is to run the container
#   under random UID.
RUN usermod -a -G 0 solr

USER 8983
