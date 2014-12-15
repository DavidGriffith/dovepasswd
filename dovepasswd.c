/* dovepasswd.c
 * This is a simple C wrapper to allow the dovepw.pl script run as root
 * so that ordinary users may change their Dovecot passwords.
 *
 */

#include <stdio.h>
#include <unistd.h>

//#define UID 65534
#define UID 111
#define CMD "/home/dave/dovepw.pl"


int main(int argc, char *argv[]) {

	if (!(setuid(UID) == 0)) {
		printf("Unable to switch users\n");
		return 1;
	}

	execv(CMD, argv);
	return 0;
}
