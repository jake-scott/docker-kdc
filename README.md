# Simple dockerized Kerberos KDC docker build for **DEVELOPMENT**

I created this docker build as a way to rapidly bootstrap a working
MIT Kerberos server for use in developing Kerberos client software.
While there are lots of guides on installing and configuring a KDC,
the process generally consists of enough steps that a casual developer
may be put off.

> Note: A production KDC should be one of it not **the** most secure
> piece of infrastructure in your environment.  It should run on a
> hardened host at minumum, probably with no other co-services and
> arguably on bare-metal (in prefererce to VMs).  This image does
> not meet any of these criteria.  Please use it for test purposes
> only.

> I have not pushed an image to any Docker repositoraries because
> this tends to lead to people using unpatched, vulnerable and
> unmaintained software and OS base images.  It is trivial to build
> them image so please take the time to read and execute the single
> build command below.


## Build

    $ docker build -t github.com/jake-scott/docker-kdc:dev .


## Bootstrap

The image will create the configuration files and database if they don't
exist.

The REALM is only required the first time this is run.

    $ mkdir /var/tmp/krbdata
    $ docker run --network bridge --rm -it -p 88:8888 -p 749:1749 -p 464:1464  -v /var/tmp/krbdata:/kdc -e REALM=JAKETHESNAKE.DEV  github.com/jake-scott/docker-kdc:dev 


Notice the log line that reports the admin password, eg :

> `NEW DATABASE: password for admin/admin@JAKETHESNAKE.DEV: [AkOdS3vuvIh3pm@NvUn7yq#Ok0f]`


From another terminal, change the admin password :

    $ export KRB5_CONFIG=/var/tmp/krbdata/krb5.conf
    $ kpasswd admin/admin
    Password for admin/admin@JAKETHESNAKE.DEV:   <---  Enter the password from the NEW DATABASE log line
    Enter new password: 
    Enter it again: 
    Password changed.


## Controlling the image

You can CTRL-C in the terminal running the KDC and restart it with :

    $ docker run --network bridge --rm -it -p 88:8888 -p 749:1749 -p 464:1464  -v /var/tmp/krbdata:/kdc github.com/jake-scott/docker-kdc:dev 


## Managing the KDC

At this stage you can use kadmin to manage client and service principals
in the KDC.

Always set KRB5_CONFIG to point the client libraries at the KDC :

    $ export KRB5_CONFIG=/var/tmp/krbdata/krb5.conf


.. and run kadmin using the admin/admin principal and the password you changed above :

    $ kadmin -p admin/admin
    Authenticating as principal admin/admin with password.
    Password for admin/admin@JAKETHESNAKE.DEV: 
    kadmin:  


Add some policies for user and service principals :

    kadmin:  addpol -maxlife 90d -minlife 1h -minlength 8 -minclasses 3 -history 4 human
    kadmin:  addpol  -minlength 256 service


Now add users, eg :

    kadmin:  addprinc  -policy human testuser
    Enter password for principal "testuser@JAKETHESNAKE.DEV": 
    Re-enter password for principal "testuser@JAKETHESNAKE.DEV": 
    Principal "testuser@JAKETHESNAKE.DEV" created.


.. and services, eg :

    kadmin:  addprinc -policy service -randkey postgres/wellard.poptart.org
    Principal "postgres/wellard.poptart.org@JAKETHESNAKE.DEV" created.

    admin:  ktadd -k postgres.kt postgres/wellard.poptart.org
    Entry for principal postgres/wellard.poptart.org with kvno 2, encryption type aes256-cts-hmac-sha1-96 added to keytab WRFILE:postgres.kt.
    Entry for principal postgres/wellard.poptart.org with kvno 2, encryption type aes128-cts-hmac-sha1-96 added to keytab WRFILE:postgres.kt.


.. and test :

     $ kinit testuser
     Password for testuser@JAKETHESNAKE.DEV: 
     Warning: Your password will expire in 6 days on Mon 09 Mar 2020 09:18:53 PM EDT
    
     $ klist
     Ticket cache: FILE:/tmp/krb5cc_1000
     Default principal: testuser@JAKETHESNAKE.DEV
    
     Valid starting       Expires              Service principal
     03/02/2020 20:18:58  03/03/2020 08:18:58  krbtgt/JAKETHESNAKE.DEV@JAKETHESNAKE.DEV
    	renew until 03/03/2020 20:18:58
    
     # Get a service ticket for the postgres service on theis host
     $ kvno postgres/wellard.poptart.org
     postgres/wellard.poptart.org@JAKETHESNAKE.DEV: kvno = 2

     $ klist
     Ticket cache: FILE:/tmp/krb5cc_1000
     Default principal: testuser@JAKETHESNAKE.DEV
    
     Valid starting       Expires              Service principal
     03/02/2020 20:18:58  03/03/2020 08:18:58  krbtgt/JAKETHESNAKE.DEV@JAKETHESNAKE.DEV
    	renew until 03/03/2020 20:18:58
     03/02/2020 20:20:10  03/03/2020 08:18:58  postgres/wellard.poptart.org@JAKETHESNAKE.DEV
    	renew until 03/03/2020 20:18:58
    
    
