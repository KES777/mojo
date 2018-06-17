use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;
use Mojo::File qw(path tempdir);
use Mojolicious::Command;

# Application
my $command = Mojolicious::Command->new;
isa_ok $command->app, 'Mojolicious', 'right application';

# Creating directories
my $cwd = path;
my $dir = tempdir;
chdir $dir;
my $buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $command->create_rel_dir('foo/bar');
}
like $buffer, qr/[mkdir]/, 'right output';
ok -d path('foo', 'bar'), 'directory exists';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $command->create_rel_dir('foo/bar');
}
like $buffer, qr/\[exist\]/, 'right output';
chdir $cwd;

# Generating files
is $command->rel_file('foo/bar.txt')->basename, 'bar.txt', 'right result';
my $template = "@@ foo_bar\njust <%= 'works' %>!\n";
$template .= "@@ pass_by_value\nvariable value <%= \$_[0] %>\n";
$template .= "@@ pass_many\nmany values: <%= \@_ %>\n";
$template .= "@@ pass_by_name\nvariable value <%= \$foo %>\n";
open my $data, '<', \$template;
no strict 'refs';
*{"Mojolicious::Command::DATA"} = $data;
chdir $dir;
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $command->render_to_rel_file('foo_bar', 'bar/baz.txt');
}
like $buffer, qr/\[mkdir\].*\[write\]/s, 'right output';
open my $txt, '<', $command->rel_file('bar/baz.txt');
is join('', <$txt>), "just works!\n", 'right result';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $command->chmod_rel_file('bar/baz.txt', 0700);
}
like $buffer, qr/\[chmod\]/, 'right output';
ok -e $command->rel_file('bar/baz.txt'), 'file is executable';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $command->write_rel_file('123.xml', "seems\nto\nwork");
}
like $buffer, qr/\[exist\].*\[write\]/s, 'right output';
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $command->write_rel_file('123.xml', 'fail');
}
like $buffer, qr/\[exist\]/, 'right output';
open my $xml, '<', $command->rel_file('123.xml');
is join('', <$xml>), "seems\nto\nwork", 'right result';
chdir $cwd;

# Pass variables into template
$buffer =  $command->render_data( 'pass_by_value', 'yada' );
is $buffer, "variable value yada\n", 'pass variable by value';

$buffer =  $command->render_data( 'pass_by_value', 'foo', 'bar' );
is $buffer, "many values: foo bar\n", 'pass many variables by value';

$buffer =  $command->render_data( 'pass_by_name', { foo => 'bar' } );
is $buffer, "variable value bar\n", 'pass variable by name';

# Quiet
chdir $dir;
$buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $command->quiet(1)->write_rel_file('123.xml', 'fail');
}
is $buffer, '', 'no output';
chdir $cwd;

# Abstract methods
eval { Mojolicious::Command->run };
like $@, qr/Method "run" not implemented by subclass/, 'right error';

done_testing();
