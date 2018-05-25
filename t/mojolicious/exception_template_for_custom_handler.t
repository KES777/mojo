use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mojolicious::Lite;

app->renderer->add_handler(dead    => sub { die 'Exception in handler' });
app->renderer->add_handler(openapi => sub {
	my( $r, $c, $output ) =  @_;

	my $e =  $c->stash->{ exception };
	chomp $e;
	$$output =  qq!{ "error": "$e"}!;
});

get '/handler' => { handler => 'dead' } => sub{};
get '/action'  => { handler => 'openapi', format => 'json' }
	=> sub{ die 'Exception in action' };

my $t = Test::Mojo->new;

$t->get_ok( '/action'  )->status_is(500)
	->json_like( '/error' => qr/^Exception in action/ );
$t->get_ok( '/handler' )->status_is(500)
	->content_like(qr/^dead: Exception in handler/);

done_testing();

__DATA__
@@ exception.html.ep
dead: <%= stash->{ exception } %>
