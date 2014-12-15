#!/usr/bin/perl -w

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

#my $passwd_file = "/etc/dovecot/dovecot.passwd";
my $passwd_file = "/home/dave/dove-passwd.txt";
my $auth_user = "dovecot";


my @passwd_file_array;
my $username;
my $passwd;
my $pass1;
my $pass2;
my $line;

my $max_extra = 32;
my @junk;
my $junk;
my @extra;

my $line_count = 0;
my $found = 0;

print "dovepasswd: For changing your Dovecot password.\n";

my $myname = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);

#if (getuid() != getpwnam($auth_user)) { 
#	die "This script cannot be run directly.\nUse the compiled dovepw program instead.\n";
#}

if ($ARGV[0]) { 
	$username = $ARGV[0];
} else {
	$username = $myname;
}

print "  $myname is changing $username\'s password.\n";

#if ( ($myname ne "root") && ($myname ne $username) ) {
#	die "Only root can change someone else's password\n";
#}


tie @passwd_file_array, 'Tie::File', $passwd_file or die "  Unable to read $passwd_file!\n";

foreach (@passwd_file_array) {
	if (m/^$username/) {
		$found = 1;
		last;
	}
	$line_count++;
}

if (!$found) { print "  No such user in $passwd_file!\n"; exit;}

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

if ($pass1 ne $pass2) { die "Error: Passwords don't match!\n"; }

# Check a password?
my $pwcheck = Data::Password::Check->check({ 'password' => $pass1 });

# Did we have any errors?
if ($pwcheck->has_errors) {
	# Print the errors
	print(
	  join("\n", @{ $pwcheck->error_list }),
	  "\n"
	  );
	exit;
}

$passwd = `doveadm pw -s $crypt -u $username -p $pass1`;

chomp($passwd);
print "$passwd\n";
exit;

($junk, $junk, $uid, $gid, $gecos, $home, $shell, @extra) = split(/:/, $passwd_file_array[$line_count], $max_extra);

if (@extra) { 
	my $stuff = join(':', @extra);
	$newline = "$username:$passwd:$uid:$gid:$gecos:$home:$shell:$stuff";
} else {
	$newline = "$username:$passwd:$uid:$gid:$gecos:$home:$shell";
}
chomp($newline);

# Now replace our entry.
$passwd_file_array[$line_count] = $newline;
untie @passwd_file_array;

print "dovepasswd: dovecot password updated sucessfully\n";

