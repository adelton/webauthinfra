
# Copyright 2016 Jan Pazdziora
#
# Licensed under the Apache License, Version 2.0 (the "License").

from django.contrib.auth import load_backend, BACKEND_SESSION_KEY
from django.contrib.auth.models import Group
from django.contrib.auth.backends import RemoteUserBackend
from django.contrib.auth.middleware import RemoteUserMiddleware

class RemoteUserAttrMiddleware(RemoteUserMiddleware):
    group_prefix = 'ext:'
    staff_group = 'ext:admins'

    def update_user_groups(self, request):
        user = request.user

        ext_groups = []
        ext_group_count = request.META.get(self.header + "_GROUP_N", None)
        ext_groups_singlestring = request.META.get(self.header + "_GROUPS", None)
        if ext_group_count is not None:
            for i in range(1, int(ext_group_count) + 1):
                g = request.META.get(self.header + "_GROUP_" + str(i), None)
                if g is not None:
                    ext_groups.append(g)
        elif ext_groups_singlestring is not None:
            ext_groups = ext_groups_singlestring.split(':')
        else:
            return

        current_groups = {}
        for g in user.groups.filter(name__startswith=self.group_prefix):
            current_groups[g.name] = g

        for g in ext_groups:
            g = self.group_prefix + g
            if current_groups.has_key(g):
                del current_groups[g]
            else:
                g_obj = Group.objects.filter(name=g)
                if g_obj:
                    user.groups.add(g_obj[0])
            if g == self.staff_group:
                user.is_staff = True

        for g in current_groups.values():
            user.groups.remove(g.id)

    def process_request(self, request):
        self.header = request.META.get("REMOTE_USER_VAR", "REMOTE_USER")

        if hasattr(request, 'user') and request.user.is_authenticated() and \
          request.META.get(self.header, None) and \
          request.user.get_username() == self.clean_username(request.META[self.header], request):
            stored_backend = load_backend(request.session.get(BACKEND_SESSION_KEY, ''))
            if isinstance(stored_backend, RemoteUserBackend):
                user = request.user
                need_save = False
                email = request.META.get(self.header + "_EMAIL", None)
                if email is not None:
                    user.email = email
                    need_save = True
                firstname = request.META.get(self.header + "_FIRSTNAME", None)
                if firstname is not None:
                    user.first_name = firstname
                    need_save = True
                lastname = request.META.get(self.header + "_LASTNAME", None)
                if lastname is not None:
                    user.last_name = lastname
                    need_save = True
                if need_save or request.META.get(self.header + "_GROUP_N", None) or request.META.get(self.header + "_GROUPS", None):
                    self.update_user_groups(request)
                    user.save()
