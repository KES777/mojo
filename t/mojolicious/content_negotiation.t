use Mojolicious::Lite;
use Test::Mojo;
use Test::More;

done_testing();
__END__
app->routes->root->cache->max_keys(0);
get '/app' => 'test';

get '/route' => { template => 'test', format => 'xxx' };

get '/detect_custom' => { template => 'test' } => sub{
	shift->respond_to({
		json => {},
		zzz  => {},
	});
};

get '/detect' => { template => 'test' } => sub{
	shift->respond_to({
		html => {},
		json => {},
		zzz  => {},
	});
};

get '/detect_any' => { template => 'test' } => sub{
	shift->respond_to({
		html => {},
		json => {},
		zzz  => {},
		any  => sub{ shift->render( text => 'any' ) },
	});
};

get '/detect_custom_any' => { template => 'test' } => sub{
	shift->respond_to({
		json => {},
		zzz  => {},
		any  => sub{ shift->render( text => 'any' ) },
	});
};

my $t = Test::Mojo->new;

# Test detection of client requirements
$t->get_ok('/app' => {Accept => 'application/json'} )->status_is(200)
  ->content_type_is('application/json;charset=UTF-8')->content_is( "json\n" );
$t->get_ok('/app.json'       )->status_is(200)
  ->content_type_is('application/json;charset=UTF-8')->content_is( "json\n" );
$t->get_ok('/app?format=json')->status_is(200)
  ->content_type_is('application/json;charset=UTF-8')->content_is( "json\n" );


# Test application default format
$t->get_ok('/app'            )->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')       ->content_is( "html\n" );
$t->get_ok('/app.zzz'        )->status_is(200)
  ->content_type_is('text/plain')                    ->content_is( "zzz\n" );
$t->get_ok('/app.not_exists' )->status_is(404);

app->defaults( format => 'zzz' );
$t->get_ok('/app'     )->status_is(200)
  ->content_type_is('text/plain')                    ->content_is( "zzz\n" );
$t->get_ok('/app.zzz' )->status_is(200)
  ->content_type_is('text/plain')                    ->content_is( "zzz\n" );
# Discuss: How to fallback when page not found?
# $t->get_ok('/app.not_exists' )->status_is(404);


#
$t->get_ok('/route'     )->status_is(200)
  ->content_type_is('text/plain')->content_is( "xxx\n" );
$t->get_ok('/route.xxx' )->status_is(200)
  ->content_type_is('text/plain')->content_is( "xxx\n" );
# Discuss: How to fallback when page not found?
# $t->get_ok('/route.json')->status_is(404)
# $t->get_ok('/route.zzz' )->status_is(404)


$t->get_ok('/detect_custom'     )->status_is(204)    ->content_is( '' );
$t->get_ok('/detect_custom.xml' )->status_is(204)    ->content_is( '' );
$t->get_ok('/detect_custom.zzz' )->status_is(200)
  ->content_type_is('text/plain')                    ->content_is( "zzz\n" );
$t->get_ok('/detect_custom.json')->status_is(200)
  ->content_type_is('application/json;charset=UTF-8')->content_is( "json\n" );


$t->get_ok('/detect'     )->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')       ->content_is( "html\n" );
$t->get_ok('/detect.xml' )->status_is(204)           ->content_is( '' );
$t->get_ok('/detect.zzz' )->status_is(200)
  ->content_type_is('text/plain')                    ->content_is( "zzz\n" );
$t->get_ok('/detect.json')->status_is(200)
  ->content_type_is('application/json;charset=UTF-8')->content_is( "json\n" );


$t->get_ok('/detect_any'     )->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')       ->content_is( "html\n" );
$t->get_ok('/detect_any.xml' )->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')       ->content_is( 'any' );
$t->get_ok('/detect_any.zzz' )->status_is(200)
  ->content_type_is('text/plain')                    ->content_is( "zzz\n" );
$t->get_ok('/detect_any.json')->status_is(200)
  ->content_type_is('application/json;charset=UTF-8')->content_is( "json\n" );


$t->get_ok('/detect_custom_any'     )->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')       ->content_is( 'any' );
$t->get_ok('/detect_custom_any.xml' )->status_is(200)
  ->content_type_is('text/html;charset=UTF-8')       ->content_is( 'any' );
$t->get_ok('/detect_custom_any.zzz' )->status_is(200)
  ->content_type_is('text/plain')                    ->content_is( "zzz\n" );
$t->get_ok('/detect_custom_any.json')->status_is(200)
  ->content_type_is('application/json;charset=UTF-8')->content_is( "json\n" );


done_testing();

__DATA__
@@ test.html.ep
html

@@ test.zzz.ep
zzz

@@ test.xxx.ep
xxx

@@ test.json.ep
json
