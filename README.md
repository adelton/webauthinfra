
# Web application authentication developer setup

Web applications that get deployed in large organizations typically
need to be able to work with user identities provided by external
identity sources like FreeIPA/IdM (IPA), Active Directory domains,
SAML Identity Providers (IdP), or OpenID Providers (OP).

To support additional identity provider in Web application, using
front-end HTTP server for authentication and top-level authorization
with existing HTTP server modules might be preferred over implementing
every new protocol in every application or Web framework. The
applications then consume the authentication result as `REMOTE_USER`
environment variable or other means (for example `X-Remote-User` HTTP
header in case of HTTP proxy setup), as well as additional user
attributes and user group membership information that can be used
to control access within the application. More details about the
approach can be found at

* https://www.freeipa.org/page/Web_App_Authentication
* https://www.freeipa.org/page/Environment_Variables#Proposed_Additional_Variables

Even if consuming external authentication results might seem
straightforward, it is still useful to verify the interaction,
especially when HTTP status 401 for Kerberos or 30x redirects for
SAML or OpenID Connect are involved.

This repository aims to help with that task, providing multi-container
developer setup that can be used for development and testing of
external authentication methods for Web applications. By default,
the setup contains IPA server in container (service) **ipa**, Ipsilon
SAML Identity Provider and OpenID Provider (**idp**), Firefox browser
already configured to use the server for Kerberos authentication
(**client**), Apache HTTP server with modules for GSS-API (Kerberos)
and SAML and OpenID Connect (**www**), as well as an example Django
application that shows the effect of propagating authentication result
and the user information to an application (**app**).

```
                                                 HTTP with auth
  +----------+     HTTP    +------------------+  result      +-------------+
  | Browser  | ----------> | Web server       | -----------> | Application |
  | "client" | <---------- + with authn/authz | <----------  | "app"       |
  +----------+  Negotiate  | setup            |  application +-------------+
        |          or      | "www"            |  content
        |       redirect   +------------------+
        |
        \  Kerberos   +---------+
        | ----------> | FreeIPA |
        |             | "ipa"   |
        |  or SAML    +---------+
        |  or OpenID  +-----------------+
        \    Connect  | SAML IdP or     |
         -----------> | OpenID Provider |
          redirects   | "idp"           |
                      +-----------------+
```

By changing the configuration of the Web server, it is possible to
switch from Kerberos to SAML or OpenID Connect and see the effects
in action. It is also possible to rebuild the setup to run the
application directly in the Web server container -- the example
application would then be deployed there via `mod_wsgi`.

This default setup can serve as demonstration of the concepts all by
itself but its primary goal is to help developers get infrastructure
for external authentication and plug in applications they develop
or test. Instead of the provided example application, developers can
instead put their application to the **app** or **www** containers, or
configure the Web server to proxy the requests to completely different
backend location where the application resides.

Instead of using the provided **client** container for browser testing,
it is possible to access the IPA, IdP/OP, and the authentication HTTP
server from a Web client (browser) outside of the setup. However, DNS
or manual hosts records will likely need to be set up manually, as
well a local Kerberos configuration, so starting with the provided
**client** with Firefox might be easier.

## Prerequisites

The setup uses docker and docker-compose, so they should be available.

When started, the containers will store their configuration and data
in `*-data/` sub-directories, and their ownership will change to root
and their SELinux labels will likely change as well. You might want
to pick location for the local copy/clone of the repository where this
will not cause problems.

On SELinux enabled systems,

```
setsebool -P container_manage_cgroup 1
```

might be needed to enable running systemd in the containers.

##  Building the setup

With the freeipa-server image available, running

```
docker-compose build
```

in the directory of this repo will build create five container images.
Depending on the machine where you run the build, it might take
minutes to dozens of minutes to build.

## Running the setup

The setup can be started with

```
docker-compose up
```

It will provide long output starting with

```
Creating webauthinfra_ipa_1 ... done
Creating webauthinfra_app_1 ... done
Creating webauthinfra_idp_1 ... done
Creating webauthinfra_www_1 ... done
Creating webauthinfra_client_1 ... done
Attaching to webauthinfra_app_1, webauthinfra_ipa_1, webauthinfra_idp_1, webauthinfra_www_1, webauthinfra_client_1
ipa_1     | Configuring ipa.example.test ...
ipa_1     | Mon Dec 10 18:42:42 UTC 2018 /usr/sbin/ipa-server-configure-first
ipa_1     |
ipa_1     | The log file for this installation can be found in /var/log/ipaserver-install.log
ipa_1     | ==============================================================================
ipa_1     | This program will set up the FreeIPA Server.
idp_1     | Waiting for FreeIPA server (HTTP Server) ...
www_1     | Waiting for FreeIPA server (HTTP Server) ...
```

and you can watch IPA server and Ipsilon IdP/OP being configured, and
then the client container with Firefox IPA-enrolled and www container
with the Apache HTTP server IPA-enrolled and configured as SAML Service
Provider and OpenID Provider, as well as the example Django application
configured and started.

After all the containers have initialized, you can use `ssh -X` to log
in to the container where Firefox is configured, and run the browser:

```
ssh -X -i client-data/id_rsa -p 55022 developer@localhost firefox -no-remote
```

(When running ssh as root, `chmod 600 client-data/id_rsa` might be needed.)

It will open four tabs -- the example application, IPA and IdP/OP logon
pages, and a page that allows you to obtain Kerberos Ticket Granting
Ticket (kinit) or change IPA user passwords in the client container.
There will be one admin user in the IPA server -- the password for
that account can be found with

```
cat ipa-data/admin-password
```

You can log in to the IPA server WebUI, either by `kinit`-ing first or
with login and password and create more users and groups. Then you
can to log in into the example application via **www.example.test**
(again, Kerberos or login and password should work). The application
aims at easily presenting authentication-related information, so it
will show the list of last logged-in users, and for authenticated
access, it will display information about the user.

If you want to drive permissions of users in the example application,
log in as **admin** to its Admin interface and create groups there,
with names matching user groups in IPA with **ext:** prefix. For example,
if you created group **webapp-admin** in IPA, the counterpart in the
example application would be **ext:webapp-admin**. You can attach the
application-level permissions to the group. Upon logon, users will
have their user attributes and group membership synced into the
example Django database.

Note that the Admin part of the application is only accessible to
users with a Staff flag which the example application sets to members
of IPA's **admins** group. Due to the Django Admin internals, the Staff
flag cannot be linked to group membership to be populated with more
flexibility.

Explore https://github.com/adelton/django-identity-external
to see the approach used.

To switch the Kerberos-based authentication to SAML-based, copy the
example `src/www-proxy-saml.conf` to **www**'s data directory:

```
cp src/www-proxy-saml.conf www-data/www.conf
```

or

```
docker cp src/www-proxy-saml.conf webauthinfra_www_1:/data/www.conf
```

and restart the Apache HTTP server:

```
docker exec -ti webauthinfra_www_1 systemctl restart httpd
```

When you try to log in to the example application now, instead of
Kerberos authentication used, you should see HTTP redirection to the
IdP at **idp.example.test/idp** where you will authenticate and be
redirected back.

For OpenID Connect, use `src/www-proxy-openidc.conf` in similar manner.

To switch back to Kerberos, use `src/www-proxy-gssapi.conf` which was
the default `/data/www.conf` configuration in the **www** container.

The `tests/test.sh` can be used for testing the basic operation.

## Developing with the setup

There are multiple ways to use the setup with application that you
develop:

* Deploy application in the HTTP server (**www**) container.
* Run application in the existing **app** container instead of the
  default example application, using the **www** container as
  authentication HTTP proxy.
* Point the setup to an external location (container, host) where the
  application runs, again, using the **www** container as authentication
  HTTP proxy.

Each method is described in more detail below.

### Deploy application in the HTTP server (**www**) container

Amend `src/Dockerfile.www` to install additional Apache modules like
`mod_wsgi`, and either install the application into the image in build
time or make it available in the container via `www-data/` or some
other bind mount location. This way you will test the application
on the same "machine" as the front-end authentication HTTP server.

Check the `src/Dockerfile.www-with-app` for an example of turning
the HTTP proxy based setup into `mod_wsgi`-based one, running the
application in the **www** container directly, instead of in the
**app** container. In fact, if you edit the `docker-compose.yml` file
and use the commented-out `dockerfile:` line instead of the original
one and rebuild the setup, you will get the example application
running locally in the HTTP server (**www**) container. Explore the
diff of `src/Dockerfile.www` and `src/Dockerfile.www-with-app` to get
an inspiration for putting your application into the www container.

### Replace example application with your application in **app** container

Change `src/Dockerfile.app` to include and run your application instead
of the example one in the separate container. Chances are your
application has different layout of the logon URLs, so the Apache
HTTP server configuration in the **www** container will need to be
tweaked a bit as well, either by changing the `src/www*.conf` files or
by putting the configuration to `www-data/www.conf` directly.

This will turn the HTTP server container into authentication HTTP
proxy for your application, instead of the default example one.

It is important that in production, the communication between the
authentication proxy and the application is protected as the
authentication and authorization result is passed via HTTP headers
of the HTTP request. If users are able to connect to the backend
application directly, they'd be able to provide any HTTP header
content they'd like, sidestepping the authentication setup.
Depending on the network and system infrastructure, iptables,
mutual TLS authentication, or other means might be appropriate.

### Use existing application location

Change `www-data/www.conf` to proxy the requests to whatever location
your application runs on, potentially on the host machine directly.
With this setup, you will use the authentication HTTP proxy approach,
without forcing the application to be run in container.

The note from the previous item about securing the communication in
production setups applies here as well.

## The defaults of the setup

### The services

* **ipa** -- IPA server
  * Hostname: ipa.example.test
  * Persistent storage in `ipa-data/`

* **idp** -- Ipsilon IdP server
  * Hostname: idp.example.test
  * Persistent storage in `idp-data/`

* **www** -- Apache HTTP server with authn/authz modules
  * Hostname: www.example.test
  * Configuration stored in `www-data/`; namely Apache HTTP server loads `www-data/www.conf`.
  * IPA-enrolled during the first run.

* **app** Back-end server with example application
  * Hostname: app.example.test
  * Database stored in `app-data/`

* **client** -- SSH server and Firefox
  * Hostname: client.example.test
  * Accessible on host's port 55022.
  * IPA-enrolled during the first run.

### Precreated accounts

* **admin** (IPA)
  * password in `ipa-data/admin-password`

* **admin** (the example application)
  * password in the docker-compose output (but access with IPA's admin password will also work)

### PAM services and host-based access access control (HBAC) rules:

* **webapp**
  * used for HBAC on http://www.example.test
  * HBAC rule: allow_webapp

* **idp**
  * used for HBAC idp.example.test/idp
  * HBAC rule: allow_idp

Both HBAC rules are set up to allow access for any user but the HBAC
rules can be changed in IPA. The allow_all is disabled by default for
HBAC to work.

Set of applications and authentication modules was used to demonstrate
the external authentication concepts. In future versions, different
versions or different applications might be used to achieve the same
goal.

## Automated testing

The **client** container has Selenium with Python bindings installed,
so it can be directly used for automated testing of the setup or
developed application. Examples of simple tests can be found in
`src/test-kerberos.py`, `src/test-saml.py`, and `src/test-openidc.py`
-- they are invoked from `tests/test.sh`.

## Licence

Copyright 2016--2022 Jan Pazdziora

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

