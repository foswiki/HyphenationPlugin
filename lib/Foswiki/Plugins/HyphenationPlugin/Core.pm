# Plugin for Foswiki - The Free and Open Source Wiki, https://foswiki.org/
#
# HyphenationPlugin is Copyright (C) 2020 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::HyphenationPlugin::Core;

use strict;
use warnings;

use Foswiki::Func ();
use TeX::Hyphen ();
use Error qw(:try);

use constant TRACE => 0; # toggle me
our %hyphenatorCache;

our %patternFilesMapping = (
  "de" => "hyph-de-1996.tex",
  "el" => "hyph-el-monoton.tex", # hyph-el-polyton.tex
  "pt-br" => "hyph-pt.tex",
  "en" => "hyph-en-us.tex", # hyph-en-gb.tex
);

sub new {
  my $class = shift;

  my $this = bless({
    defaultLanguage => $Foswiki::cfg{HyphenationPlugin}{DefaultLanguage} || $Foswiki::cfg{MultiLingualPlugin}{DefaultLanguage} || 'en',
    patternsDir => $Foswiki::cfg{HyphenationPlugin}{PatternsDir} || $Foswiki::cfg{PubDir} . '/' . $Foswiki::cfg{SystemWebName} . '/HyphenationPlugin/patterns',
    minLength => $Foswiki::cfg{HyphenationPlugin}{MinLength} || 5,
    memoryCache => $Foswiki::cfg{HyphenationPlugin}{MemoryCache} // 1,
    @_
  }, $class);

  return $this;
}

sub DESTROY {
  my $this = shift;

  unless ($this->{memoryCache}) {
    # with it goes the memory cache
    foreach my $lang (keys %hyphenatorCache) {
      undef $hyphenatorCache{$lang};
    }
  }

  undef $this->{_parser};
}

sub getParser {
  my $this = shift;

  unless (defined $this->{_parser}) {
    require Foswiki::Plugins::HyphenationPlugin::Parser;
    $this->{_parser} = Foswiki::Plugins::HyphenationPlugin::Parser->new();
  }

  return $this->{_parser};
}

sub getPatternFile {
  my ($this, $lang) = @_;

  my $file = $patternFilesMapping{$lang} || 'hyph-'.$lang.'.tex';
  return $this->{patternsDir} . '/' . $file;
}

sub getHyphenator {
  my ($this, $lang) = @_;

  $lang //= $this->{defaultLanguage};
  my $hyp = $hyphenatorCache{$lang};

  unless (defined $hyp) {
    my $path = $this->getPatternFile($lang);
    _writeDebug("pattern file=$path");
    throw Error::Simple("no patterns found for language $lang") unless -e $path;

    $hyp = TeX::Hyphen->new(
      file => $path,
      style => "utf8",
    );

    $hyphenatorCache{$lang} = $hyp;
  }

  return $hyp;
}

sub handleHYPHENATE {
  my ($this, $session, $params, $topic, $web) = @_;

  _writeDebug("called HYPHENATE()");

  my $text = $params->{_DEFAULT} // $params->{text} // '';

  my $error;
  try {
    $text = $this->hyphenateText($text, $params);
  } catch Error with {
    $error = _inlineError(shift);
  };

  return $error if defined $error;
  return $text;
}

sub hyphenateText {
  my ($this, $text, $params) = @_;

  #_writeDebug("called hyphenateText()");

  my $minLength = $params->{minlength} || $this->{minLength};
  $text =~ s/(\w{$minLength,})/$this->hyphenateWord($1, $params)/xsmeg;

  #_writeDebug("... result: $text");
  return $text;
}

sub hyphenateWord {
  my ($this, $word, $params) = @_;

  return '' if $word eq ''; 

  my $hyphen = $params->{hyphen} // '&shy;';
  my $lang = $params->{lang} || $params->{language} || Foswiki::Func::getPreferencesValue("CONTENT_LANGUAGE") || $this->{defaultLanguage};

  my $hyp = $this->getHyphenator($lang);

  my $num = 0;
  foreach my $pos ($hyp->hyphenate($word)) {
    substr($word, $pos + $num, 0, $hyphen);
    $num += length $hyphen;
  }
 
  return $word; 
}

sub hyphenateHtml {
  my ($this, $html, $params) = @_;

  return $this->getParser()->processText($html, $params, sub {
    my ($t, $p) = @_;
    return $this->hyphenateText($t, $p);
  });
}

sub completePageHandler {
#    my($this, $html, $httpHeaders ) = @_;
  my $this = shift;

  return unless defined $_[0];
  return unless $_[0] =~ /<(?:div|span)\s+([^>]*?class=["'][^"']*?hyphenate[^>]*?)\s*>/;
  return unless $_[1] =~ /Content-type: text\/html/;

  _writeDebug("detected hyphenation");

  my $html = $this->hyphenateHtml($_[0], {
    lang => Foswiki::Func::getPreferencesValue("CONTENT_LANGUAGE") || $this->{defaultLanguage},
  });

  #print STDERR "HTML: ".$html;

  $_[0] = $html;
}

sub _inlineError {
  my $msg = shift;

  return "<span class='foswikiAlert'>$msg</span>";
}

sub _writeDebug {
  return unless TRACE;
  print STDERR "HyphenationPlugin::Core - $_[0]\n";
}


1;
