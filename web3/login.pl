#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Cookie;

require 'config.pl';
use vars qw(%var);

package auth;

use DBI;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use CGI::Cookie;


sub new {
    my $class = shift;
    my $klass = shift;
    my $dbh = DBI->connect("DBI:mysql:database=$$klass{'base'};host=$$klass{'host'};port=$$klass{'port'}",$$klass{'user'} ,$$klass{'pass'} )
                 || die "Невозможно подключится к базе\n";
    my $this          = {dbh => $dbh};
    return bless $this, $class;
}

#сама авторизация
sub login {
    my $this = shift;
    my $user = shift;

    #достаём из базы пользователя
    my $sth   = $this->{dbh}->prepare("select * from user where `login` = ?");
       $sth->execute($$user{'login'});
    my $loger = $sth->fetchrow_hashref();

    if(exists $$loger{'login'}){#если такой логин уже есть в базе

        #проверка на совпадение паролей
        if(md5_hex($$user{'pass'}) eq $$loger{'pass'}){
            $this->vhod($$user{'login'});
        }else{

                    open(FH, "<", "html/never.html");
                    binmode(FH);
                    my $header;
                    {
                     local $/;
                     $header = <FH>;
                    }
                    print "Content-type:text/html\n\n";
                    print $header;
        }


    }else{#если такого логина нет в базе то создаем его и авторизируем

        my $pass = md5_hex($$user{'pass'});#шифруем пароль

        $this->{dbh}->do("INSERT INTO user(login, pass) values (\'$$user{'login'}\', '$pass')");#записываем нового пользователя в базу
        $this->vhod($$user{'login'});
    }
}

#вход
sub vhod {

    my $this = shift;
    my $user = shift;
    #достаём сессию
    my %cookies         = fetch CGI::Cookie;
    $cookies{'session'} = $cookies{'session'}->value;
    $cookies{'session'} =~s /[\W]//g;
    $cookies{'session'} = 'empty' unless $cookies{'session'};
    if(exists $cookies{'session'}){
        $this->{dbh}->do("UPDATE session SET `user` = (select id from user where `login` = \'$user\')".
                                                    "where session = \'$cookies{'session'}\'");#обновляем сессию
    }

    print "Location: index.pl\n\n";
}

#сброс сессии
sub logout {

 my $this = shift;

  my %cookies         = fetch CGI::Cookie;
     $cookies{'session'} = $cookies{'session'}->value;
     $cookies{'session'} =~s /[\W]//g;
     $cookies{'session'} = 'empty' unless $cookies{'session'};

     if(exists $cookies{'session'}){

        $this->{dbh}->do("DELETE FROM session WHERE session = \'$cookies{'session'}\' LIMIT 1");#обновляем сессию
     }
     print "Content-type:text/html\n\n";
}

package main;

my $cgi     = CGI->new;
my $login   = $cgi->param('login')  || '';
my $action  = $cgi->param('action') || '';
my $auth    = auth->new({host => $var{'host'},
                         port => $var{'port'},
                         base => $var{'base'},
                         user => $var{'name'},
                         pass => $var{'pass'}});

if ($login ne ''){

    my $pass  = $cgi->param('pass')  || '123';
    $auth->login({login => $login, pass => $pass});
}

if ($action eq 'logout'){
    $auth->logout();
}