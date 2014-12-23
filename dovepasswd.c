/* dovepasswd.c
 * This is a simple C wrapper to allow the dovepw.pl script run as root
 * so that ordinary users may change their Dovecot passwords.
 *
 */

#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>

//#define UID 65534

#define USER	"dovecot"
#define GROUP	"dovecot"
#define CMD	"/usr/local/bin/dovepasswd.pl"

int main(int argc, char *argv[]) {
	struct passwd pwd;
	struct passwd *result;
	char *buf;
	size_t bufsize;
	int s;
	long uid;
	long gid;

	bufsize = sysconf(_SC_GETPW_R_SIZE_MAX);
	if (bufsize == -1)	/* Value was indeterminate */
	bufsize = 16384;	/* Should be more than enough */

	buf = malloc(bufsize);
	if (buf == NULL) {
		perror("malloc");
		exit(EXIT_FAILURE);
	}

	s = getpwnam_r(USER, &pwd, buf, bufsize, &result);
	uid = pwd.pw_uid;
	gid = pwd.pw_gid;

	if (!setgid(gid) == 0) {
		printf("Unable to switch groups. Am I SUID root?\n");
		return 1;
	}

	if (!setuid(uid) == 0) {
		printf("Unable to switch users. Am I SUID root?\n");
		return 1;
	}

	if( access( CMD, F_OK | X_OK ) != -1 ) {
		execv(CMD, argv);
		return 0;
	}
	printf("Unable to execute %s\n", CMD);
	return 2;
}
