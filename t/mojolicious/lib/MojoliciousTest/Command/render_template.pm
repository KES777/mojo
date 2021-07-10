package MojoliciousTest::Command::render_template;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';

sub run {
  my ($self, @args) = @_;
  getopt \@args, 'stash' => \my $stash;

  my $c =  $self->app->build_controller;
  if( $stash ) {
	$c->stash(template => 'invoice');
  	return $c->render_to_string().$c->render_to_string();
  }
  else {
  	return $c->render_to_string('invoice').$c->render_to_string('invoice');
  }
}

1;
