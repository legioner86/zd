#!/usr/bin/perl

# ���������� �������� ������
use strict;
use warnings;
use CGI::Cookie;
use DBI;

require 'config.pl';
use vars qw(%var);

# �������� ��������� ��������
print "Content-type: text/html;charset=utf-8\" http-equiv=\"Content-Type\"\n\n";
#��������� HTML ������ �.�. ��� � ��� ���� �� ��� ��������
open(FH, "<", "html/header.html");
binmode(FH);
my $header;
{
 local $/;
 $header = <FH>;
}
print $header;

# �������� Cookies ������������
my %cookies     = fetch CGI::Cookie;
my $ip          = getRealIpAddr();
my $remote_host = $ENV{'REMOTE_HOST'} || 'empty';
my %user_vars   = {};
my $dbh;

# ������������ � ���� ������
eval{
    $dbh = DBI->connect('DBI:mysql:database='.$var{'base'}.';host='.$var{'host'}.';port='.$var{'port'}, $var{'name'}, $var{'pass'})
             || die "���������� ����������� � ����\n";
};

# ��������� �������� session � Cookies
if (exists $cookies{'session'}){

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

    my $session = $sth->fetchrow_hashref();
    $sth->finish();
    # ���� ������ ���� � ��� �� ��������
    if ($$session{'user'} != 0) {

    #-- ��������� ������ �� IP, ����� � ������ ������� ������������
            if ($$session{'ip'} ne $ip ||
                $$session{'host'} ne $remote_host) {
                &create_session;
                &show_authorize_form;
            }
#-- ��������� ����� ������
        &update_session($cookies{'session'});
#-- ������� ����� ����������

        &show_welcome_form($session);
# ���� ������ ���� � ��� ��������
    } elsif ($$session{'user'} == 0) {

#-- ��������� ����� ������
        &update_session($cookies{'session'});
#-- ������� ����� �����������
        &show_authorize_form;
# ���� ������ ���
    } else {
#-- ���������� � ��������� �������� ������

        create_session(0, $cookies{'session'});
#-- ������� ����� �����������
        &show_authorize_form;
    }
} else {
#-- ���������� � ��������� �������� ������
    &create_session;
#-- ������� ����� �����������
    &show_authorize_form;
}
exit;

sub create_session {
# ��������� ���������� ����� ������
    my $adm = 0;
    my $session;

# ������ �������� ��� �����
    my @rnd_txt = ('0','1','2','3','4','5','6','7','8','9',
                 'A','a','B','b','C','c','D','d','E','e',
                 'F','f','G','g','H','h','I','i','J','j',
                 'K','k','L','l','M','m','N','n','O','o',
                 'P','p','R','r','S','s','T','t','U','u',
                 'V','v','W','w','X','x','Y','y','Z','z');
    srand;
# ������� ����
    for (0..31) {
        my $s = rand(@rnd_txt);
        $session .= $rnd_txt[$s]
    }
# ��������� ������ � ������� ������
    $dbh->do("INSERT INTO session SET session = '".$session."', user = $adm, time = now(), host = '".$remote_host."', ip = '".$ip."'");

# ���������� ��� ��� ��������� Cookies
# � ����� � ���, ��� ������ ���������� ����� SSI, �� �������� Cookies � ��������� ��������
# ������� �� ����������, �.�. �� �������� ��� ��������� ���������� � �������, ������� Cookies
# ��������������� � ������� JavaScript, ����� �� �� ������ �� �������� � ��������� ������:

    $user_vars{"cookies"} = "<SCRIPT LANGUAGE=\"JavaScript\">this.document.cookie=\"session=".$session.";path=/;\";</SCRIPT>";
# ������� ���� ���� � ����� ��������� name
    open(FT, ">", "./data/".$session);
    print(FT "name => <Guest>\n");
    close(FT);

    return 1;
};

# ��������� ���������� ������
sub update_session {
    my $session = shift;
        $dbh->do("UPDATE session SET time = now() WHERE session = '$session' LIMIT 1");
    return 1;
}

# ��������� ������ ����� �����������
sub show_authorize_form {
# ������� (��� �� �������) ��� ��������� Cookies
    print $user_vars{"cookies"} if(exists $user_vars{"cookies"});
# ������� ����� �����������

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

# ��������� ������ ����� ����������
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