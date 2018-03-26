package Mojolicious::Plugin::Format;
use Mojo::Base 'Mojolicious::Plugin';


sub register {
  my( $self, $app, $conf ) =  @_;

  $app->helper( format => \&format );

  $app->hook( around_action =>  \&_content_negotiation );

  my $hook_all =  $app->routes->under( \&_apply_defaults );
  my @children =  @{ $app->routes->children };
  for my $child ( @children ) {
    next   if $child == $hook_all;
    $hook_all->add_child( $child );
  }
}


sub format {
  my( $c, @cap ) =  @_;

  my $stash =  $c->stash;
  return $stash->{format}  if defined $stash->{format};

  # Server capabilities
  my $stack =  $c->match  &&  $c->match->stack;
  my $fmt =  @$stack && $stack->[-1]{ _sformat }  ||  undef;
  @cap =  ref $fmt eq 'ARRAY' ? @$fmt : $fmt // ()   unless @cap;

  # Client requirements
  my $req =  $c->req;
  $fmt =  $req->param('format')
    || @$stack && $stack->[-1]{ _cformat }
    || undef;
  my @req =  $fmt ? ($fmt) : ();
  push @req, @{$c->app->types->detect($req->headers->accept)};

  # Find best representation
  for my $ext (@req) { $ext eq $_ and return $stash->{format}= $ext for @cap }

  # Fallbacks
  return $stash->{format} =  @req ?
    (@cap ? ''      : $req[0] ):
    (@cap ? $cap[0] : $c->app->renderer->default_format );
}


sub _apply_defaults {
  my( $c ) =  @_;

  return   unless my @stack =  @{ $c->match->stack };

  my $captures =  pop @stack;
  delete @$_{qw/ _cformat _sformat /} for @stack;
  delete @$captures{qw/ _cformat _sformat /}
    if $captures->{format} && !defined $captures->{format};

  $captures->{ _sformat } //=  $c->app->defaults->{ format };

  return 1;
}


sub _content_negotiation {
  my( $next, $c, $action, $last ) =  @_;
  return   unless $next;

  my $stash =  $c->stash;

  # This required because of next:
  # https://github.com/KES777/mojo/blob/content_negotiation/lib/Mojolicious/Routes/Match.pm#L80
  # Our content negotiation will reffer to _cformat/_sformat
  unless( $stash->{ 'format.cleared' } ) {
    delete $stash->{format};
    $stash->{ 'format.cleared' } =  1;
  }

  &format( $c );

  $next->();
}


sub Mojolicious::Controller::respond_to {
  my ($self, $args) = (shift, ref $_[0] ? $_[0] : {@_});

  # Detect format
  my $renderer = $self->app->renderer;
  my $format = $self->format( $renderer->default_format, keys %$args );
  $self->stash->{format} = $format;

  # Find target
  my $target;
  unless ($target = $args->{$format}) {
    return $self->rendered(204) unless $target = $args->{any};
  }

  # Dispatch
  ref $target eq 'CODE' ? $target->($self) : $self->render(%$target);

  return $self;
}

my $old;
BEGIN{ $old =  \&Mojolicious::Renderer::accepts }
sub Mojolicious::Renderer::accepts {
  my ($self, $c) = (shift, shift);

  $c->stash->{format} =  &format( $c );
  $old->( $self, $c, @_ );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Format - Content negotiation module

=head1 SYNOPSIS

  # Restrict all controllers to given format:
  # /hello                      -> "html"
  # /hello (Accept: text/html)  -> "html"
  # /hello (Accept: text/xml)   -> "xml"
  # /hello (Accept: text/plain) -> undef
  # /hello.html                 -> "html"
  # /hello.xml                  -> "xml"
  # /hello.txt                  -> undef
  # /hello?format=html          -> "html"
  # /hello?format=xml           -> "xml"
  # /hello?format=txt           -> undef
  $app->plugin('Format');
  $app>defaults( format => [qw( html xml )] );

  # Or only current route:
  # /custom                      -> "json"
  # /custom.html                 -> undef
  # /custom.xml                  -> "xml"
  # /custom.txt                  -> undef
  $r->get( '/custom', { format => [qw( json, xml )] );

  # Same but in controller's action (fallback is disabled):
  # /action                      -> undef
  # /action.html                 -> "html"
  # /action.xml                  -> "xml"
  # /action.txt                  -> undef
  my $format = $c->format(undef, 'html', 'xml');


=head1 DESCRIPTION

L<Mojolicious::Plugin::Format> is a content negotiation plugin.

When request has come and before we render response to a client we should do
content negotiation. This process depends on client requirements and server
capabilities. By design content negotiation is done only once.


The code of this plugin is a good example for learning to build new plugins,
you're welcome to fork it.

See L<Mojolicious::Plugins/"PLUGINS"> for a list of plugins that are available
by default.

=head1 METHODS

L<Mojolicious::Plugin::Format> inherits all methods from L<Mojolicious::Plugin>
and implements the following new ones.

=head2 format

  my $format = $c->format('html', 'json', 'txt');

  # Check if JSON is acceptable
  $c->render(json => {hello => 'world'}) if $c->format('json');

  # Check if JSON was specifically requested
  $c->render(json => {hello => 'world'}) if $c->format('', 'json');

  # Unsupported representation
  $c->render(data => '', status => 204)
    unless my $format = $c->format('html', 'json');

Select best possible representation for L<Mojolicious::Controller> object from
C<format> C<GET>/C<POST> parameter, C<format> stash value, C<Accept> request
header, supported C<format> for route or application and sets up C<format>
stash value. If no preference could be detected it will return one of next
results:

If C<format> is requested and route or application defines supported C<format>
then empty string is returned

If C<format> is requested and route or application does not define
suported C<format>s then fallback to first requested C<format>

If C<format> is not requested and route or application defines supported
C<format> then fallback to first supported C<format>

If C<format> is not requested and route or application does not define
suported C<format>s fallback to renderer's default C<format>

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin and C<format> helper, hooks to C<around_action>,
in L<Mojolicious> application. Also redefines
L<Mojolicious::Controller/"respond_to"> and override
L<Mojolicious::Renderer/"accepts">

Notice you MUST load this plugin as last step on your application startup

=head1 AUTHOR

Eugen Konkov

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Eugen Konkov

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
