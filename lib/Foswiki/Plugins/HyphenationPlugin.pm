# Plugin for Foswiki - The Free and Open Source Wiki, https://foswiki.org/
#
# HyphenationPlugin is Copyright (C) 2020-2025 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::HyphenationPlugin;

use strict;
use warnings;

use Foswiki::Func ();

our $VERSION = '1.11';
our $RELEASE = '%$RELEASE%';
our $SHORTDESCRIPTION = 'Server-side hyphenation service';
our $LICENSECODE = '%$LICENSECODE%';
our $NO_PREFS_IN_TOPIC = 1;
our $core;

sub initPlugin {

  Foswiki::Func::registerTagHandler('HYPHENATE', sub { return getCore()->handleHYPHENATE(@_); });

  return 1;
}

sub getCore {
  unless (defined $core) {
    require Foswiki::Plugins::HyphenationPlugin::Core;
    $core = Foswiki::Plugins::HyphenationPlugin::Core->new();
  }
  return $core;
}

sub finishPlugin {
  $core->finish() if defined $core;
  undef $core;
}

sub completePageHandler {
  getCore()->completePageHandler(@_);
}

1;
