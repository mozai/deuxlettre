DeuxLettre
==========
The idea is a report (chart?) of all the two-letter internet domain names.
A-Z in columns, A-Z in rows.  Icon for each, with maybe a clickthrough
to info or a tooltip.

last update 2021-10-04


Howto
-----
    mkdir -p ico; rm ico/*
    ./gather_records.sh >gathered.tsv
    ./gather_icons.sh gathered.tsv
    ./make_html.sh gathered.tsv >index.html  


Vision
------
Considered python or golang, but really I could do it in bash since
this is a once-a-day thing at its most frequent.  Use `xargs` for parallel
processing.

Fetch A, AAAA, CNAME, MX, NS and SOA records.

Probe for a webserver (https:443 first, then http:80).  Fetch first page,
pull out {title} text and {link rel="icon"} if there, /favicon.ico if not,
cook the icon into 32x32 png (or webp?) for display at 16x16

grid of icons, mouseover tooltip for more detailed data, click to go to their webpage (if exists)


Todo
----
* detect if I should link to https or http, dont just guess https
* better "icon not available" icon
* tooltip sometimes renders out of the viewable window
* some domain-names are owned by have zero DNS records; 
  but WHOIS lookups are throttled to asphyxiation
* try to detect squatters, indicate them in the icons
* detect mangled SOA records (ie. ask for SOA ??.com I get response for SOA lnbj.co.cn ?)

