# dovepasswd
Allow shell users to change their Dovecot (imap and pop3) passwords

This a Perl script to allow shell users to change their Dovecot (imap 
and pop3) login passwords.  The script isn't run directly, but is 
executed by a helper C program which handles the setuid issues of 
allowing a user to change a file he/she cannot read.

## preparation
Edit `dovepasswd.c` and look for these lines:

    #define UID 65534
    #define CMD "/usr/local/bin/dovepasswd.pl"

Change `UID` to the UID of the dovecot user.  Check `/etc/passwd` for 
that.  Change `CMD` to the actual location of the `dovepasswd.pl` script 
in case you put it somewhere else.

Edit `dovepasswd.pl` and examine the "Configuation Section".  Look at 
the choices for `$crypt`.  If you happen to have Blowfish available, use 
`BLF-CRYPT`.  If not, the next best hash algorithm is `SHA512-CRYPT`, 
which is preselected.

Check `$passwd_file` and make sure contains the path to your Dovecot 
password file.

Check `$auth_user`.  If Dovecot is running under a different user, 
change this accordingly.

## installation

    gcc -o dovepasswd dovepasswd.c
    strip dovepasswd
    sudo cp dovepasswd /usr/local/bin
    sudo chown root.dovecot /usr/local/bin/dovepasswd
    sudo chmod 4750 /usr/local/bin/dovepasswd
    sudo cp dovepasswd.pl /usr/local/bin
    sudo chown root.root /usr/local/bin/dovepasswd.pl
    sudo chmod 0755 /usr/local/bin/dovepasswd.pl

## caveats

While it works, I haven't finished going over the code for security 
problems.  Do not rely on it yet.

## attributions

This program was intended to work identically to the regular passwd(1) 
command commonly found in Unix systems.  Inspiration for the innards 
came chiefly from Charlie Orford's 
[dovecotpfd](https://code.google.com/p/dovecotpfd/), a program for doing 
the same thing with [Roundcube](http://roundcube.net/).  My C wrapper is 
essentially a copy of his.
