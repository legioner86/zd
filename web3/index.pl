#!/usr/bin/perl

# Подключаем основные модули
use strict;
use warnings;
use CGI::Cookie;
use DBI;

require 'config.pl';
use vars qw(%var);

# Отсылаем заголовок браузеру
print "Content-type: text/html;charset=utf-8\" http-equiv=\"Content-Type\"\n\n";
#загружаем HTML хедыры т.к. они у нас одни на все страницы
open(FH, "<", "html/header.html");
binmode(FH);
my $header;
{
 local $/;
 $header = <FH>;
}
print $header;

# Получаем Cookies пользователя
my %cookies     = fetch CGI::Cookie;
my $ip          = getRealIpAddr();
my $remote_host = $ENV{'REMOTE_HOST'} || 'empty';
my %user_vars   = {};
my $dbh;

# Подключаемся к базе данных
eval{
    $dbh = DBI->connect('DBI:mysql:database='.$var{'base'}.';host='.$var{'host'}.';port='.$var{'port'}, $var{'name'}, $var{'pass'})
             || die "Невозможно подключится к базе\n";
};

# Проверяем параметр session в Cookies
if (exists $cookies{'session'}){

# Выбираем значение параметра session
    $cookies{'session'} = $cookies{'session'}->value;
    $cookies{'session'} =~s /[\W]//g;
    $cookies{'session'} = 'empty' unless $cookies{'session'};
# Проверяем наличие сессии
    my $sth = $dbh->prepare("SELECT user, ".
                                    "host, ".
                                    "ip ".
                             "FROM session ".
                             "WHERE session = '$cookies{'session'}' ".
                             "LIMIT 1");
    $sth->execute();

    my $session = $sth->fetchrow_hashref();
    $sth->finish();
    # Если сессия есть и она не гостевая
    if ($$session{'user'} != 0) {

    #-- Проверяем сессию по IP, хосту и прокси серверу пользователя
            if ($$session{'ip'} ne $ip ||
                $$session{'host'} ne $remote_host) {
                &create_session;
                &show_authorize_form;
            }
#-- Обновляем время сессии
        &update_session($cookies{'session'});
#-- Выводим форму приветсвия

        &show_welcome_form($session);
# Если сессия есть и она гостевая
    } elsif ($$session{'user'} == 0) {

#-- Обновляем время сессии
        &update_session($cookies{'session'});
#-- Выводим форму авторизации
        &show_authorize_form;
# Если сессии нет
    } else {
#-- Обращаемся к процедуре создания сессии

        create_session(0, $cookies{'session'});
#-- Выводим форму авторизации
        &show_authorize_form;
    }
} else {
#-- Обращаемся к процедуре создания сессии
    &create_session;
#-- Выводим форму авторизации
    &show_authorize_form;
}
exit;

sub create_session {
# Объявляем переменную новой сессии
    my $adm = 0;
    my $session;

# Массив символов для ключа
    my @rnd_txt = ('0','1','2','3','4','5','6','7','8','9',
                 'A','a','B','b','C','c','D','d','E','e',
                 'F','f','G','g','H','h','I','i','J','j',
                 'K','k','L','l','M','m','N','n','O','o',
                 'P','p','R','r','S','s','T','t','U','u',
                 'V','v','W','w','X','x','Y','y','Z','z');
    srand;
# Генерим ключ
    for (0..31) {
        my $s = rand(@rnd_txt);
        $session .= $rnd_txt[$s]
    }
# Добавляем запись в таблицу сессий
    $dbh->do("INSERT INTO session SET session = '".$session."', user = $adm, time = now(), host = '".$remote_host."', ip = '".$ip."'");

# Определяем код для установки Cookies
# В связи с тем, что скрипт внедряется через SSI, то передача Cookies в заголовке никакого
# еффекта не произведет, т.к. на странице уже заголовки отправлены и приняты, поэтому Cookies
# устанавливаются с помощью JavaScript, иначе же мы просто бы добавили в заголовок строку:

    $user_vars{"cookies"} = "<SCRIPT LANGUAGE=\"JavaScript\">this.document.cookie=\"session=".$session.";path=/;\";</SCRIPT>";
# Создаем дапм хеша с одним элементом name
    open(FT, ">", "./data/".$session);
    print(FT "name => <Guest>\n");
    close(FT);

    return 1;
};

# Процедура обновления сессии
sub update_session {
    my $session = shift;
        $dbh->do("UPDATE session SET time = now() WHERE session = '$session' LIMIT 1");
    return 1;
}

# Процедура вывода формы авторизации
sub show_authorize_form {
# Выводим (или не выводим) код установки Cookies
    print $user_vars{"cookies"} if(exists $user_vars{"cookies"});
# Выводим форму авторизации

    open(FH, "<", "html/auth.html");
    binmode(FH);
    my $fileContent;
    {
     local $/;
     $fileContent = <FH>;
    }
    print $fileContent;
    exit;
}

# Процедура вывода формы приветсвия
sub show_welcome_form {
    my $user = shift;
     open(FH, "<", "html/pars.html");
        binmode(FH);
        my $fileContent;
        {
         local $/;
         $fileContent = <FH>;
        }
        print $fileContent;
        exit;
}

#находим ип
sub getRealIpAddr {
   my $ip = "0";
   if($ENV{"HTTP_CLIENT_IP"}){
     $ip = $ENV{"HTTP_CLIENT_IP"};
   }elsif ($ENV{"HTTP_X_FORWARDED_FOR"}){
     $ip = $ENV{"HTTP_X_FORWARDED_FOR"};
   }else{
     $ip = $ENV{"REMOTE_ADDR"};
   };
   return $ip;
}
1;