#!/usr/bin/perl -w

use strict;
use POSIX;
use Tie::File;			# debian libio-all-perl
use IO::Stty;			# debian libio-stty-perl
use Data::Password::Check;	# must use CPAN

# Configuration Section
#

#my $crypt = "BLF-CRYPT";
my $crypt = "SHA512-CRYPT";
#my $crypt = "SHA256-CRYPT";
#my $crypt = "MD5-CRYPT";

my $passwd_file = "/etc/dovecot/dovecot.passwd";
my $auth_user = "dovecot";
my $doveadm_cmd = "/usr/bin/doveadm";

# To avoid potential confusion, remove one if you only offer one service.
my @services = ("IMAP", "POP3");


################################
## End of configuration section

my @passwd_file_array;
my $username;
my $passwd;
my $pass1;
my $pass2;
my $line;

my $progname = "dovepasswd";

my $max_extra = 32;
my @junk;
my ($junk, $uid, $gid, $gecos, $home, $shell, $stuff);
my @extra;
my $newentry;

my $line_count = 0;
my $found = 0;

if (!defined $services[0]) {
	die "Must define at least one service!\n";
}

print "$progname: For changing your $services[0] ";
if (defined $services[1]) {
	print "/ $services[1] ";
}
print "password.\n";

my $myname = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);

if (geteuid() != getpwnam($auth_user)) { 
	die "  This script cannot be run directly.\n  Use the compiled $progname program instead.\n";
}

if ($ARGV[0]) { 
	$username = $ARGV[0];
} else {
	$username = $myname;
}

if ( ($myname ne "root") && ($myname ne $username) ) {
	die "Only root can change someone else's password\n";
}

if (!(-r $passwd_file)) { die "Unable to read $passwd_file!\n"; }

if (!(-w $passwd_file)) { die "Unable to write to $passwd_file!\n"; }

tie @passwd_file_array, 'Tie::File', $passwd_file or die "  Unable to tie $passwd_file!\n";

foreach (@passwd_file_array) {
	if (m/^$username/) {
		$found = 1;
		last;
	}
	$line_count++;
}

print "Changing $services[0] ";
if (defined $services[1]) {
	print "/ $services[1] ";
}
print "password for $username.\n";


if (!$found) {
	if ($myname ne "root") {
		print "  Sorry, but you're not allowed to use IMAP or POP3.\n"; 
		exit;
	}
	$line_count++;
	print "  Sorry, you'll have to manually add an entry to $passwd_file.\n";
}

REDO:

print "Enter new password: ";

IO::Stty::stty(\*STDIN,'-echo');
$pass1 = <STDIN>;
IO::Stty::stty(\*STDIN,'echo');
chomp $pass1;

print "\nRetype new password: ";

IO::Stty::stty(\*STDIN,'-echo');
$pass2 = <STDIN>;
IO::Stty::stty(\*STDIN,'echo');
chomp $pass2;

print "\n";

if ($pass1 ne $pass2) {
	print "Error: Passwords don't match!\n";
	goto REDO;
}

# Check the password?
my $pwcheck = Data::Password::Check->check({ 'password' => $pass1 });

# Did we have any errors?
if ($pwcheck->has_errors) {
	# Print the errors
	print(
	  join("\n", @{ $pwcheck->error_list }),
	  "\n"
	  );
	goto REDO;
}

$passwd = `$doveadm_cmd pw -s $crypt -u $username -p $pass1`;

chomp($passwd);

($junk, $junk, $uid, $gid, $gecos, $home, $shell, @extra) = split(/:/, $passwd_file_array[$line_count], $max_extra);

if (@extra) { 
	my $stuff = join(':', @extra);
	$newentry = "$username:$passwd:$uid:$gid:$gecos:$home:$shell:$stuff";
} else {
	$newentry = "$username:$passwd:$uid:$gid:$gecos:$home:$shell";
}
chomp($newentry);

# Now replace our entry.
$passwd_file_array[$line_count] = $newentry;
untie @passwd_file_array;

print "$progname: $services[0] ";
if (defined $services[1]) {
	print "/ $services[1] ";
}
print "password updated sucessfully\n";
