ARG ERIC_ENM_SLES_BASE_IMAGE_NAME=eric-enm-sles-base
ARG ERIC_ENM_SLES_BASE_IMAGE_REPO=armdocker.rnd.ericsson.se/proj-enm
ARG ERIC_ENM_SLES_BASE_IMAGE_TAG=1.64.0-33

FROM ${ERIC_ENM_SLES_BASE_IMAGE_REPO}/${ERIC_ENM_SLES_BASE_IMAGE_NAME}:${ERIC_ENM_SLES_BASE_IMAGE_TAG}

ARG BUILD_DATE=unspecified
ARG IMAGE_BUILD_VERSION=unspecified
ARG GIT_COMMIT=unspecified
ARG ISO_VERSION=unspecified
ARG RSTATE=unspecified
ARG SGUSER=187578

LABEL \
com.ericsson.product-number="CXC Placeholder" \
com.ericsson.product-revision=$RSTATE \
enm_iso_version=$ISO_VERSION \
org.label-schema.name="ENM fmx moduleserver Service Group" \
org.label-schema.build-date=$BUILD_DATE \
org.label-schema.vcs-ref=$GIT_COMMIT \
org.label-schema.vendor="Ericsson" \
org.label-schema.version=$IMAGE_BUILD_VERSION \
org.label-schema.schema-version="1.0.0-rc1"

RUN /usr/sbin/groupadd -g 5004 "fmexportusers" > /dev/null 2>&1 && \
    /usr/sbin/usermod -a -G "fmexportusers" jboss_user > /dev/null 2>&1 && \
    /usr/sbin/groupadd -g 5000 "mm-smrsusers" > /dev/null 2>&1 && \
    /usr/sbin/usermod -a -G "mm-smrsusers" jboss_user > /dev/null 2>&1  && \
    /usr/sbin/groupadd -g 210 "nmx" > /dev/null 2>&1 && \
    /usr/sbin/useradd -m -g nmx  -u 210 nmxadm  > /dev/null 2>&1

RUN zypper install -y ERICfmxmoduleserver_CXP9031790 \
                      ERICvaultloginmodule_CXP9036201  \
                      ERICfmxutilbasic_CXP9031797 \
                      ERICfmxenmutilbasic_CXP9031802 \
                      rsync \
                      openssh && \
    zypper download   ERICfmxtools_CXP9031793 \
                      ERICfmxenmcfg_CXP9032402 \
                      ERICfmxltxrules_CXP9031806 \
                      ERICfmxnsxrules_CXP9031805 \
                      ERICfmxgrxrules_CXP9035783 \
                      ERICfmxecxrules_CXP9033756 \
                      ERICfmxwrxrules_CXP9033987 \
                      ERICfmxranautomationrules_CXP9037197 && \
                      rpm -ivh /var/cache/zypp/packages/enm_iso_repo/*.rpm --nodeps --noscripts && \
                      zypper clean -a

RUN mv /usr/lib/ocf/resource.d/* /var/tmp/
RUN mv /var/tmp/rsyslog-healthcheck.sh /usr/lib/ocf/resource.d/
COPY image_content/check_application_startup_has_completed.sh /usr/lib/ocf/resource.d/
COPY image_content/fmxms_entrypoint.sh /var/run/fmx/scripts/
RUN chmod 775 /var/run/fmx/scripts/fmxms_entrypoint.sh
COPY image_content/rabbitmq-env.conf /etc/rabbitmq/
COPY image_content/postInstall.sh /etc/opt/ericsson/ERICmodeldeployment/data/toBeInstalled/post_install
COPY image_content/fmx_preconfig.sh /var/run/fmx/scripts/
RUN chmod 775 /var/run/fmx/scripts/fmx_preconfig.sh
COPY image_content/enable_jmx_opts.sh /var/run/fmx/scripts/
RUN chmod 775 /var/run/fmx/scripts/enable_jmx_opts.sh
COPY image_content/fmx_cpp_block_config.sh /var/run/fmx/scripts/
RUN chmod 775 /var/run/fmx/scripts/fmx_cpp_block_config.sh
COPY image_content/perl_modules/* /var/tmp/

ENV ENM_JBOSS_SDK_CLUSTER_ID="fmx" \
    ENM_JBOSS_BIND_ADDRESS="0.0.0.0" \
    GLOBAL_CONFIG="/gp/global.properties"

RUN sed -i 's/127.0.0.1/fmx-rabbitmq/g' $(find /etc/opt/ericsson/fmx/moduleserver/fmx_moduleserver.properties )
RUN sed -i 's/localhost:7001,localhost:7002,localhost:7003/eric-data-key-value-database-rd-operand:6379/g' $(find /etc/opt/ericsson/fmx/moduleserver/fmx_moduleserver.properties )
RUN sed -i 's/port="514"/port="5140"/g' /etc/opt/ericsson/fmx/moduleserver/log4j2.xml
RUN sed -i 's/UMASK.*[0-9][0-9][0-9]/UMASK    022/g' /etc/login.defs
RUN sed -i '/\Host \*/a\   StrictHostKeyChecking no\n\   UserKnownHostsFile=/dev/null' /etc/ssh/ssh_config

RUN find /opt/ericsson/fmx /etc/opt/ericsson/fmx -type d -exec chmod 775 {} +

RUN echo "$SGUSER:x:$SGUSER:210:An Identity for fmx-moduleserver:/nonexistent:/bin/false" >> /etc/passwd && \
    echo "$SGUSER:!::0:::::" >> /etc/shadow

USER $SGUSER

ENTRYPOINT ["/bin/sh", "-c" , "/var/run/fmx/scripts/fmxms_entrypoint.sh"]

EXPOSE 3528 4369 4447 8009 8080 9990 9999 12987 54200 56127 56142 56145 56185 56193 56199 56203 56214 56216 56219 56227 56235 5671 5672 15672 25671 7001 7002 7003 7004 7005 7006
