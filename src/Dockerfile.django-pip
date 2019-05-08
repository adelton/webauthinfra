FROM registry.fedoraproject.org/fedora:29
RUN dnf install -y python3-virtualenv patch && dnf clean all
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
ENTRYPOINT /usr/sbin/init-django
