# Extension for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# HyphenationPlugin is Copyright (C) 2022-2025 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

package Foswiki::Configure::Checkers::Plugins::HyphenationPlugin::Enabled;

use strict;
use warnings;

use Foswiki::Configure::Checker ();
our @ISA = ('Foswiki::Configure::Checker');

my @modules = (
  {
    name => 'TeX::Hyphen',
    usage => "",
    minimumVersion => 0,
  },
);

sub check_current_value {
  my ($this, $reporter) = @_;

  return unless $this->{item}->getRawValue();

  Foswiki::Configure::Dependency::checkPerlModules(@modules);

  foreach my $mod (@modules) {
    if ($mod->{ok}) {
      $reporter->NOTE('   * ' . $mod->{check_result});
    } else {
      $reporter->ERROR('   * ' . $mod->{check_result});
    }
  }
}

1;


