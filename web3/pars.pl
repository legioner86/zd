#!/usr/bin/env perl
use Mojo::Base -strict;
use Mojo::UserAgent;
use Data::Dumper;
use DBI;
use CGI::Cookie;
use CGI;

require 'config.pl';
use vars qw(%var);

my $cgi         = CGI->new;
my $action      = $cgi->param('action') || '';
my $i           = $cgi->param('id')     || "1";
my %cookies     = fetch CGI::Cookie;
my $ip          = getRealIpAddr();
my $remote_host = $ENV{'REMOTE_HOST'} || 'empty';
my $dbh         = DBI->connect('DBI:mysql:database='.$var{'base'}.';host='.$var{'host'}.';port='.$var{'port'},
                                                     $var{'name'}, $var{'pass'}) || die "Bad connect\n";

my $session;

#проверка на вшивость
if($i < 1){
    $i = 1;
};

print "Content-type: text/html;charset=utf-8\" http-equiv=\"Content-Type\"\n\n";

# ѕровер€ем параметр session в Cookies
if(exists $cookies{'session'}){

    # ¬ыбираем значение параметра session
    $cookies{'session'} = $cookies{'session'}->value;
    $cookies{'session'} =~s /[\W]//g;
    $cookies{'session'} = 'empty' unless $cookies{'session'};
    # ѕровер€ем наличие сессии
    my $sth = $dbh->prepare("SELECT user, ".
                                    "host, ".
                                    "ip ".
                             "FROM session ".
                             "WHERE session = '$cookies{'session'}' ".
                             "LIMIT 1");
    $sth->execute();

    $session = $sth->fetchrow_hashref();
    $sth->finish();

    # ≈сли сесси€ есть и она не гостева€
    if ($$session{'user'} != 0) {

        #-- ѕровер€ем сессию по IP, хосту и прокси серверу пользовател€
        if(($$session{'ip'} ne $ip) || ($$session{'host'} ne $remote_host)){
            print "Location: index.pl\n\n";
        }else{

            #если надо показать предыдущий коментарий
            if($action eq 'prevcoment'){

                show_before({user => $$session{'user'}, id => $i});
                return;
            }
            #стартуем
            &startshow({user => $$session{'user'}, id => $i});
        }
    }else{
        print "Location: index.pl\n\n";
    }
}else{
    print "Location: index.pl\n\n";
}

#функци€ запуска основного скрипта
sub startshow {

     my $id    = $_[0]{'id'};
     my $user  = $_[0]{'user'};

     #провер€ем какую последнюю цитату просматривал юзер
     my $sth;
     my $citat;

     $sth   = $dbh->prepare("SELECT id_citat FROM look WHERE id_user = '$user' order by id_citat desc LIMIT 1");
     $sth->execute();
     $citat = $sth->fetchrow_hashref();

     #провер€ем есть ли такие цитаты в базе
     if(exists $$citat{'id_citat'}){

     #провер€ем какую цитату мы имеем введу
        if($id <= $$citat{'id_citat'} && $action ne "nextcoment"){ #если мы заходим изначально или хотим посмотреть какуто определЄнную цитату
            $id = $$citat{'id_citat'};
        };
     };

     $sth = $dbh->prepare("SELECT * FROM citat WHERE id = ? LIMIT 1");
     $sth->execute($id);

     my $showcitat = $sth->fetchrow_hashref();
     $sth->finish();

     if(exists $$showcitat{'id'}){

        &showcitat({content => $$showcitat{'message'}, id => $$showcitat{'id'}});
     }else{

        getanovercontent($id);
     }
}

#получение цитат с башорга
sub getanovercontent {

    my $i = @_[0];
    my $contenet;

    while(1){
      my $uri   = 'http://bash.im/quote/'.$i;
      my $ua    = Mojo::UserAgent->new();
      my $text  = $ua->get($uri);
      $contenet = $$text{'res'}->{'content'}->{'asset'}->{'content'};

      if($contenet =~ m/#(\d)/gi){
        $contenet =~ m/(<div class="text">)/g;
        $contenet= $';
        $contenet =~ m/(<\/div>)/g;
        $contenet= $`;
        Encode::from_to($contenet, "cp1251", "utf8");
        last;
      }else{
        $i++;
        redo;
      };
    }
    writecontent({content => $contenet, id => $i});
    showcitat({content => $contenet, id => $i});
}

#запись цитаты в базу
sub writecontent {

     my $content = $_[0]{'content'};
     my $id      = $_[0]{'id'};
     my $sth     = $dbh->prepare("INSERT INTO citat(id, message) VALUES ($id, ?)");
     $sth->execute($content);
}

#поиск цитат в базе
sub showcitat {

     my $content = $_[0]{'content'};
     my $id      = $_[0]{'id'};
     my $sth     = $dbh->prepare("SELECT * FROM look WHERE id_user = $$session{'user'} AND id_citat = $id LIMIT 1");
     $sth->execute();

     my $look = $sth->fetchrow_hashref();
     $sth->finish();

     if(!exists $$look{'id_citat'}){

        $sth = $dbh->prepare("INSERT INTO look(id_user, id_citat) VALUES ($$session{'user'}, $id)");
        $sth->execute();
        $sth->finish();
     }

     go_json({content => $content, id => $id})
}

#показ предыдущего коментари€
sub show_before {

    my $id   = $_[0]{'id'};
    my $user = $_[0]{'user'};
    my $showcitat;
    my $sth;

    while(1){
        $sth = $dbh->prepare("SELECT * FROM citat WHERE id = ? LIMIT 1");
             $sth->execute($id);
        $showcitat = $sth->fetchrow_hashref();

        if(exists $$showcitat{'id'}){

             &go_json({content => $$showcitat{'message'}, id => $$showcitat{'id'}});
             last;
        }else{
            $id--;
             redo;
        }
    }
    $sth->finish();
}

#вывод на страницу по а€ксу
sub go_json {

     my $content = $_[0]{'content'};
     my $id      = $_[0]{'id'};
     my $str     = "{\"content\":\"$content\", \"id\":\"$id\"}";

     print $str;
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