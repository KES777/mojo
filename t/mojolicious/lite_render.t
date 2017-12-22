use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

app->plugin( 'BinRenderer' );

get '/render' =>  sub{ shift->render( bin => 'кирилик', handler => 'bin' ) };
get '/data' =>  sub{ shift->render( data => 'кирилик' ) };

my $t = Test::Mojo->new;
$t->get_ok('/render')->content_is( 'кирилик' );
$t->get_ok('/data')->content_is( 'кирилик' );

done_testing;
