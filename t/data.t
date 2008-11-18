# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl data.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 19;
BEGIN { use_ok('Sane') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $test = Sane::Device->open('test');
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'opening test backend');

$options = $test->get_option_descriptor(10);
is ($options->{name}, 'test-picture', 'test-picture');

my $info = $test->set_option(10, 'Color pattern');
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'Color pattern');

$options = $test->get_option_descriptor(2);
cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'Modes');

for my $mode (@{$options->{constraint}}) {
 my $info = $test->set_option(2, $mode);
 cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, $mode);

 $test->start;
 cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'start');

 my $param = $test->get_parameters;
 cmp_ok($Sane::STATUS, '==', SANE_STATUS_GOOD, 'get_parameters');

 if ($param->{lines} >= 0) {
  my $filename = "$mode.pnm";
  open my $fh, '>', $filename;
  binmode $fh;

  my ($data, $len);
  do {
   ($data, $len) = $test->read ($param->{bytes_per_line});
   print $fh substr($data, 0, $len) if ($data);
  }
  while ($Sane::STATUS == SANE_STATUS_GOOD);
  cmp_ok($Sane::STATUS, '==', SANE_STATUS_EOF, 'EOF');
  is ($data, undef, 'EOF data');
  is ($len, 0, 'EOF len');

  $test->cancel;
  close $fh;
  is (-s $filename, $param->{bytes_per_line}*$param->{lines}, 'image size');
 }
}
