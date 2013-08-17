#!/usr/bin/perl
use strict;
use warnings;
use CGI;

package mailer;

#SMTP адрес
use constant SMTP => 'smtp.te.net.ua';

use CGI qw/:standard/;
use CGI::Cookie;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Mail::Sendmail;

sub  new {
    my $class = shift;
    my $this  = {};
    return bless $this, $class;
}
 #создаем нечто похожее на сессию
sub setsession {
    my $this = shift;
    my $random_number = int(rand(2));
    my $session       = int(rand(999999999999));
    my @ip            = @_;
    $session          = md5_hex(@ip.$session);
    open(FT, ">", "session/".$session) || print "$session";
    print(FT $random_number);
    close(FT);
    my $cookie = CGI::Cookie->new(-name=>'uid',-value=>$session);
    print header(-cookie=>[$cookie]);
    print $random_number;
}

#отсылаем сообщение
sub sendmailer {
    my $this = shift;
    my @arr  = shift;
    print "Content-type:text/html\n\n";
    if($arr[0]{captcha} == $this->checkcapcha()){#если капче введена верно то идем дальше
       my %mail = (To => $arr[0]{email},
              From    => 'kazak@tenet.ua',
              Subject => $arr[0]{login},
              Message => $arr[0]{message},
              SMTP    => SMTP
              );

       sendmail(%mail) or print "error";
       print "OK";
    }else{
        print "error";
    }
    $this->closesession();
}

#проверяем капчу
sub checkcapcha {
    my $this = shift;
    my $hash = $this->getcookie('uid');
    open( FH, "<", "session/".$hash);
    my $str = <FH>;
    close(FH);
    return $str;
}

#достаём куки
sub getcookie {
    my $this = shift;
    my $stri = shift;
    my %cookies = fetch CGI::Cookie;# Получаем Cookies пользователя
    return $cookies{$stri}->value;
}

#убираем сессию
sub closesession {
    my $this = shift;
    unlink ("session/".getcookie('uid'));
}

package main;

#инициализируем пакеты и определяем переменные
my $cgi     = CGI->new;
my $action  = $cgi->param('action') || '';
my $mesager = mailer->new();
my $ip      = getRealIpAddr();

#нечто похожее на MVC
if($action eq "startsession"){
    $mesager->setsession($ip);
}elsif($action eq "sendMessage"){
    my $login   = $cgi->param('login')   || '';
    my $message = $cgi->param('message') || '';
    my $email   = $cgi->param('email')   || '';
    my $capcha  = $cgi->param('capcha')  || '';
    $mesager->sendmailer({ip=>$ip, login=>$login, message=>$message, email=>$email, captcha=>$capcha});

}

#находим ип
sub getRealIpAddr {
   my $ip = "0";
   if($ENV{'HTTP_CLIENT_IP'}){
     $ip = $ENV{'HTTP_CLIENT_IP'};
   }elsif ($ENV{'HTTP_X_FORWARDED_FOR'}){
     $ip = $ENV{'HTTP_X_FORWARDED_FOR'};
   }else{
     $ip = $ENV{'REMOTE_ADDR'};
   };
   return $ip;
}