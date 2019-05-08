FROM registry.fedoraproject.org/fedora:29
RUN dnf install -y /usr/sbin/ipa-client-install /usr/bin/ipsilon-client-install ipsilon-saml2 httpd mod_ssl mod_auth_gssapi mod_intercept_form_submit mod_lookup_identity sssd-dbus /usr/bin/xargs && dnf clean all
COPY init-data ipa-client-enroll ipsilon-client-configure populate-data-volume www-setup-apache /usr/sbin/
COPY ipa-client-enroll.service ipsilon-client-configure.service populate-data-volume.service www-setup-apache.service /usr/lib/systemd/system/
RUN ln -s /usr/lib/systemd/system/ipa-client-enroll.service /usr/lib/systemd/system/default.target.wants/
RUN ln -s /usr/lib/systemd/system/ipsilon-client-configure.service /usr/lib/systemd/system/default.target.wants/
RUN ln -s /usr/lib/systemd/system/populate-data-volume.service /usr/lib/systemd/system/default.target.wants/
RUN ln -s /usr/lib/systemd/system/www-setup-apache.service /usr/lib/systemd/system/default.target.wants/
COPY app.pam-service /etc/pam.d/webapp
COPY volume-data-list /etc/
COPY www-proxy-gssapi.conf /etc/httpd/conf.d/www-proxy-gssapi.conf.sample
COPY www-proxy-saml.conf /etc/httpd/conf.d/www-proxy-saml.conf.sample
RUN ln -s www-proxy-gssapi.conf.sample /etc/httpd/conf.d/www-default.conf.sample
RUN ln -s /data/www.conf /etc/httpd/conf.d/www.conf
ENV container docker
VOLUME [ "/tmp", "/run", "/data" ]
ENTRYPOINT /usr/sbin/init-data

RUN dnf install -y python3-virtualenv python3-mod_wsgi patch && dnf clean all
RUN mkdir -p /var/www/django
RUN cd /var/www/django \
	&& virtualenv . \
	&& source bin/activate \
	&& pip install 'Django == 2.2.*' django-identity-external
RUN cd /var/www/django \
	&& source bin/activate \
	&& django-admin startproject project \
	&& cd project \
	&& python manage.py migrate \
	&& echo "from django.contrib.auth.models import Group; Group.objects.get_or_create(name='ext:admins');" | python manage.py shell
COPY django/ /var/www/django/project/
RUN cd /var/www/django/project/ && patch -p0 < project.patch
COPY init-django /usr/sbin/init-django
COPY init-django.service /usr/lib/systemd/system/
RUN ln -s /usr/lib/systemd/system/init-django.service /usr/lib/systemd/system/default.target.wants/
COPY www-mod_wsgi-gssapi.conf /etc/httpd/conf.d/www-mod_wsgi-gssapi.conf.sample
COPY www-mod_wsgi-saml.conf /etc/httpd/conf.d/www-mod_wsgi-saml.conf.sample
RUN rm -f /etc/httpd/conf.d/www-default.conf.sample && ln -s www-mod_wsgi-gssapi.conf.sample /etc/httpd/conf.d/www-default.conf.sample
