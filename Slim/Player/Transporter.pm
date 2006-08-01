package Slim::Player::Transporter;

# $Id$

# SlimServer Copyright (c) 2001-2005 Sean Adams, Slim Devices Inc.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

use strict;
use base qw(Slim::Player::Squeezebox2);

use File::Spec::Functions qw(:ALL);
use FindBin qw($Bin);
use IO::Socket;
use MIME::Base64;

use Slim::Player::Player;
use Slim::Utils::Misc;
use Slim::Utils::Unicode;


our $defaultPrefs = {
	'clockSource'		=> 0,
	'digitalInput'		=> 0,
};

sub init {
	my $client = shift;
	# make sure any preferences unique to this client may not have set are set to the default
	Slim::Utils::Prefs::initClientPrefs($client,$defaultPrefs);
	$client->SUPER::init();
}

sub reconnect {
	my $client = shift;
	$client->SUPER::reconnect(@_);

	$client->updateClockSource();
}

sub updateClockSource {
    my $client = shift;

	my $data = pack('C', $client->prefGet("clockSource"));
	$client->sendFrame('audc', \$data);	
}

sub updateKnob {
	my $client    = shift;
	my $forceSend = shift || 0;

	my $listIndex = $client->param('listIndex');
	my $listLen   = $client->param('listLen');

	if (!$listLen) {

		my $listRef = $client->param('listRef');

		if ($listRef) {
			$listLen = scalar(@$listRef);
		}			
	}

	my $knobPos = $client->knobPos();

	if (defined $listIndex && defined $knobPos && (($listIndex == $knobPos) || $forceSend)) {

		my $parambytes;

		if (defined $listLen) {
		    	my $flags = 0;
		    	my $width = 0;
		    	my $height = 0;

			$parambytes = pack "NNcnc", $listIndex, $listLen, $flags, $width, $height;
		} else {
			$parambytes = pack "N", $listIndex;
		}

		$::d_ui && msg("sending new knob position: $listIndex with knobpos: $knobPos of $listLen\n");
		$client->sendFrame('knob', \$parambytes);	

	} else {

		$::d_ui && msg("skipping sending redundant knob position\n");
	}
}

sub model {
	return 'transporter';
};

sub hasExternalClock {
	return 1;
}

1;


# Local Variables:
# tab-width:4
# indent-tabs-mode:t
# End:
