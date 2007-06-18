############################################################
# Copyright: (C) 2007 John Sargent. All rights reserved.
############################################################
# This file is part of poptart.
#
# poptart is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# poptart is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with poptart; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
############################################################

require 5.005;
use strict;
use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
	NAME		=> 'poptart',
	VERSION_FROM	=> 'bin/poptart.pl',
	AUTHOR		=> 'John Sargent <jbg@cpan.org>',
	EXE_FILES	=> [ ('bin/poptart.pl') ],

	dist			=> {
				'COMPRESS'	=> 'gzip -9f',
				'SUFFIX'	=> 'gz',
				'ZIP'		=> '/usr/bin/zip',
				'ZIPFLAGS'	=> '-rl',
			},

	PREREQ_PM		=> {
				'Mail::POP3Client'=> 0,
			},
);

#sub MY::postamble {
#	my $postamble = <<END;
#END
#	return $postamble;
#}


