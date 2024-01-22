# Plugin for Foswiki - The Free and Open Source Wiki, https://foswiki.org/
#
# HyphenationPlugin is Copyright (C) 2020-2024 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::HyphenationPlugin::Parser;

use strict;
use warnings;

use constant TRACE => 0; # toggle me

use HTML::Parser;
our @ISA = qw( HTML::Parser );

sub new {
  my $class = shift;
  my $callback = shift;

  my $this = $class->SUPER::new(
    api_version => 3,
    text_h => ['_text', 'self, text, offset, length'],
    start_h => ['_start', 'self, tagname, attr'],
    end_h => [ '_end', 'self, tagname'],
  ); 

  $this = bless($this, $class);

  $this->{_hyphenDepth} = 0;
  $this->{_pauseDepth} = 0;
  $this->{_depth} = 0;

  return $this;
};

sub processText {
  my ($this, $html, $params, $callback) = @_;

  _writeDebug("called processText()");

  $this->{_textPosList} = [];
  $this->{_htmlData} = {};

  $this->parse($html);

  foreach my $item (reverse @{$this->{_textPosList}}) {

    my %p = %$params;
    foreach my $key (keys %{$item->{htmlData}}) {
      next if $key =~ /^class$/;
      my $val = $item->{htmlData}{$key};
      $key =~ s/(?:data)?\-//g;
      $p{$key} = $val if defined $val;
    }
    $p{lang} = $item->{lang} if defined $item->{lang};
    $p{minlength} = $item->{minLength} if defined $item->{minLength};

    my $text = substr($html, $item->{offset}, $item->{length});
    next if $text =~ /^\s*$/;

    $text = &$callback($text, \%p);
    substr($html, $item->{offset}, $item->{length}, $text);

    #_writeDebug("lang=$p{lang}, hyphen=$p{hyphen}, offset=$item->{offset}, length=$item->{length}");
    #_writeDebug($text);
  }

  return $html;
}

sub _text {
  my ($this, $text, $offset, $length) = @_;

  return if !$this->{_hyphenDepth} || $this->{_pauseDepth};
  next unless $length;
  return if $text =~ /^\s*$/;

  _writeDebug("found text at $offset,$length in depth $this->{_depth}");

  my %htmlData = %{$this->{_htmlData}};

  push @{$this->{_textPosList}}, {
    offset => $offset,
    length => $length,
    htmlData => \%htmlData,
  };
}

sub _start {
  my ($this, $tagName, $attr) = @_;

  $this->{_depth}++;

  if (defined $attr->{class}) {
    if ($attr->{class} =~ /\bhyphenate\b/) {
      _writeDebug("found hyphenate class in depth $this->{_depth}");
      $this->{_hyphenDepth} = $this->{_depth};
      $this->{_htmlData} = $attr;

    } elsif ($attr->{class} =~ /\bdonthyphenate\b/) {
      $this->{_pauseDepth} = $this->{_depth};
    }
  } elsif ($tagName =~ /^(pre|script|style)$/) {
    $this->{_pauseDepth} = $this->{_depth};
  }

  _writeDebug("<$tagName> depth=$this->{_depth}, hyphenDepth=$this->{_hyphenDepth}, pauseDepth=$this->{_pauseDepth}");
}

sub _end {
  my ($this, $tagName) = @_;

  $this->{_depth}--;
  $this->{_depth} = 0 if $this->{_depth} < 0; # just to make sure

  $this->{_hyphenDepth} = 0 if $this->{_hyphenDepth} > $this->{_depth};
  $this->{_pauseDepth} = 0 if $this->{_pauseDepth} > $this->{_depth};

  _writeDebug("</$tagName> depth=$this->{_depth}, hyphenDepth=$this->{_hyphenDepth}, pauseDepth=$this->{_pauseDepth}");
}

sub _writeDebug {
  return unless TRACE;
  print STDERR "HyphenationPlugin::Parser - $_[0]\n";
}

1;
