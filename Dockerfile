FROM fedora:31

RUN dnf install -y krb5-libs krb5-server krb5-workstation libpwquality cracklib-dicts

ADD startup.sh /opt/kdc/startup.sh
ADD krb5.conf /opt/kdc/templates/krb5.conf
ADD kdc.conf /opt/kdc/templates/kdc.conf
ADD kadm5.acl /opt/kdc/templates/kadm5.acl

ENV KRB5_CONFIG /kdc/krb5.conf
ENV KRB5_KDC_PROFILE /kdc/kdc.conf

ENV HOME /kdc
RUN useradd  -m -s /bin/bash -d /kdc kdc
USER kdc
WORKDIR /kdc

ENTRYPOINT ["/opt/kdc/startup.sh"]



