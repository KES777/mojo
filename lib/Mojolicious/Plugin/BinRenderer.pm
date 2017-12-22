package Mojolicious::Plugin::BinRenderer;
use Mojo::Base 'Mojolicious::Plugin';


sub register {
  my ($self, $app) = @_;

  $app->renderer->add_handler(
    bin => sub {
      $DB::single =  1;
      my ($renderer, $c, $output, $options) = @_;
      $$output = delete $c->stash->{bin};
  });
}

1;
