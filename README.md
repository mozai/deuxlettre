DeuxLettre
==========
The idea is a report (chart?) of all the two-letter internet domain names.
A-Z in columns, A-Z in rows.  Icon for each, with maybe a clickthrough
to info or a tooltip.

Author: Mozai.


Howto
-----
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

grid of icons, mouseover tooltip for more detailed data, click to go to
their webpage (if exists)


Todo
----
* skip if A record points to 127.0.0.1
* detect if I should link to https or http, dont just guess https
* better "icon not available" icon
* tooltip sometimes renders out of the viewable window
* tabbed UI for com. net. and org. not just com.
* summary table of interesting facts like:
  * %age of unknowned
  * %age of owned but no http server
  * top X owners of multiple domain names
  * top X common SOA/NS/A/AAAA/MX records
* some domain-names are owned by have zero DNS records;
  but cant do WHOIS lookups because my ISP is throttled
* try to detect squatters, indicate them in the icons
* detect mangled SOA records (ie. ask for SOA ??.com I get response for
  SOA lnbj.co.cn ?)

