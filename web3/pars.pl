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

#�������� �� ��������
if($i < 1){
    $i = 1;
};

print "Content-type: text/html;charset=utf-8\" http-equiv=\"Content-Type\"\n\n";

# ��������� �������� session � Cookies
if(exists $cookies{'session'}){

    # �������� �������� ��������� session
    $cookies{'session'} = $cookies{'session'}->value;
    $cookies{'session'} =~s /[\W]//g;
    $cookies{'session'} = 'empty' unless $cookies{'session'};
    # ��������� ������� ������
    my $sth = $dbh->prepare("SELECT user, ".
                                    "host, ".
                                    "ip ".
                             "FROM session ".
                             "WHERE session = '$cookies{'session'}' ".
                             "LIMIT 1");
    $sth->execute();

    $session = $sth->fetchrow_hashref();
    $sth->finish();

    # ���� ������ ���� � ��� �� ��������
    if ($$session{'user'} != 0) {

        #-- ��������� ������ �� IP, ����� � ������ ������� ������������
        if(($$session{'ip'} ne $ip) || ($$session{'host'} ne $remote_host)){
            print "Location: index.pl\n\n";
        }else{

            #���� ���� �������� ���������� ����������
            if($action eq 'prevcoment'){

                show_before({user => $$session{'user'}, id => $i});
                return;
            }
            #��������
            &startshow({user => $$session{'user'}, id => $i});
        }
    }else{
        print "Location: index.pl\n\n";
    }
}else{
    print "Location: index.pl\n\n";
}

#������� ������� ��������� �������
sub startshow {

     my $id    = $_[0]{'id'};
     my $user  = $_[0]{'user'};

     #��������� ����� ��������� ������ ������������ ����
     my $sth;
     my $citat;

     $sth   = $dbh->prepare("SELECT id_citat FROM look WHERE id_user = '$user' order by id_citat desc LIMIT 1");
     $sth->execute();
     $citat = $sth->fetchrow_hashref();

     #��������� ���� �� ����� ������ � ����
     if(exists $$citat{'id_citat'}){

     #��������� ����� ������ �� ����� �����
        if($id <= $$citat{'id_citat'} && $action ne "nextcoment"){ #���� �� ������� ���������� ��� ����� ���������� ������ ����������� ������
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

#��������� ����� � �������
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

#������ ������ � ����
sub writecontent {

     my $content = $_[0]{'content'};
     my $id      = $_[0]{'id'};
     my $sth     = $dbh->prepare("INSERT INTO citat(id, message) VALUES ($id, ?)");
     $sth->execute($content);
}

#����� ����� � ����
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

#����� ����������� ����������
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

#����� �� �������� �� �����
sub go_json {

     my $content = $_[0]{'content'};
     my $id      = $_[0]{'id'};
     my $str     = "{\"content\":\"$content\", \"id\":\"$id\"}";

     print $str;
}

#������� ��
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