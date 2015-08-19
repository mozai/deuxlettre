deuxletter
==========
monitoring/reporting precious unreal estate

Still building.  People (even humans!) keep asking me for my domain name
because it's so short.  So shorter internet domain names must be hella
precious.  Should be easy to get an automated report of all 2808 of them.

Orginal idea is to output a static HTML report.  Maybe I should also
have it accept command-line params for critera, query the local cache,
and and carp to stdout.

* TODO: HTTP part: use HEAD or GET w/ If-Modified-Since: header
  for records already in cache.  Does every server support that header?
* TODO: DNS part: there's three methods for querying DNS, I forget which
  is the one that doesn't suck.
* TODO: WHOIS part: the protocol is such a mess, just for legal
  disclaimers nobody reads. Tempting to resort to /usr/bin/whois immediately.


install
-------
Requires DDarko's 'whois' module.  `pip install --user whois` or `apt-get
install python-whois`.

