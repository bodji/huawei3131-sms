huawei3131-sms
==============

Perl interface to Huawei E3131 3G HSPA+ USB Modem to send and receive sms. (code is messy and in alpha ;=))


Functions of perl module :
	- telephonySmsList
	- telephonySmsDelete
	- telephonySmsSend 
  	- telephonySmsClean


Example of script to send a sms :

```perl
use SMS;

my $fnret = SMS::telephonySmsSend({ to => '06123456789' , message => 'This is a test' });
if($fnret)
{
	print 'Sms sent !';
}

```

Feel free to modify the code and fork the repo ;)
