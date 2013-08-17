#!/usr/bin/perl -w
use strict;
use DBI;
use CGI;

package comingbook;

use constant HOST => "localhost";
use constant PORT => 3306;
use constant DATABASE => "comingbook";
use constant USER => "root";
use constant PASS => "";

  sub new{
    my $class = shift;
    my $dsn   = "DBI:mysql:database=".DATABASE.";host=".HOST.";port=".PORT;
    my $dbh   = DBI->connect($dsn, USER, PASS,
    {
        RaiseError => 0,
        PrintError => 0,
    }
    ) || die "невозможно подключиться\n";

    my $amountOnPages = 30;
    my $message       = "";
    my $login         = "";
    my $ip            = 0 ;
    my $this          = {dbh => $dbh, $message => $message, login => $login, ip => $ip, amountOnPages => $amountOnPages};
    return bless $this, $class;
  }

#выборка последних 30 сообщений из базы
  sub getMessage {
    my $this = shift;
      my @res;
      my $i = 0;
      my $result = $this->{dbh}->prepare("SELECT * FROM `messages` ORDER BY `add_date` desc LIMIT ".$this->{amountOnPages});
         $result->execute();
      while (my $row = $result->fetchrow_hashref) {
          $res[$i] = $row;
          $i++;
      }
      $result->finish;
      return @res;
  }

#запись сообщений в базу
  sub write {
      my $this  = shift;
      my @arr   = @_;
      my $sth   = $this->{dbh}->prepare("INSERT INTO `messages`(`login_sender`, `message`, `ip`) VALUES (?, ?, ?) ");
      $sth->execute($arr[0]{login}, $arr[0]{message}, $arr[0]{ip});
      return 1;
  }

#вывод на страницу для аякса
  sub say {
    my $this  = shift;
    my @array = @_;
    my $str;
    print "Content-type:text/html\n\n";
    $str = "[";
    foreach(@array){
    $str .= "{";
    my %ar = %$_;
        foreach my $k(sort keys %ar){
        $str .=  "\"$k\":\"".$ar{$k}."\",";
        }
    $str .=  "},";
    };
    $str .=  "]";
    $str =~ s/,}/}/g;
    $str =~ s/,]/]/g;
    print $str;
  }

package main;

#инициализируем пакеты и определяем переменные
my $cgi     = CGI->new;
my $action  = $cgi->param('action') || '';
my $mesager = comingbook->new();

#нечто похожее на MVC
if($action eq "getlastmessage"){

    my @result = $mesager->getMessage();
    $mesager->say(@result);

}elsif($action eq "sendMessage"){

    my $ip      = getRealIpAddr();
    my $login   = $cgi->param('login') || '';
    my $message = $cgi->param('message') || '';
    $mesager->write({ip=>$ip, login=>$login, message=>$message});
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
