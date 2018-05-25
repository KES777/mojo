use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mojolicious::Lite;

app->renderer->add_handler(dead => sub { die 'Exception in handler' });
app->renderer->add_handler(my   => sub {
	${$_[2]} =  'my: ' .$_[1]->stash->{ exception };
});

get '/handler' => { handler => 'dead' } => sub{};
get '/action'  => { handler => 'my'   } => sub{ die 'Exception in action' };

my $t = Test::Mojo->new;

$t->get_ok( '/action'  )->status_is(500)
	->content_like(qr/^my: Exception in action/);
$t->get_ok( '/handler' )->status_is(500)
	->content_like(qr/^dead: Exception in handler/);

done_testing();

__DATA__
@@ exception.html.ep
dead: <%= stash->{ exception } %>
