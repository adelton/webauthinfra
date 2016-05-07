
# Copyright 2016 Jan Pazdziora
#
# Licensed under the Apache License, Version 2.0 (the "License").

from django.contrib.auth.middleware import PersistentRemoteUserMiddleware

class PersistentRemoteUserMiddleware(PersistentRemoteUserMiddleware):
	def process_request(self, request):
		self.header = request.META.get("REMOTE_USER_VAR", "REMOTE_USER")
		return super(PersistentRemoteUserMiddleware, self).process_request(request)
