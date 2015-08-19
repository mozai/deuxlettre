#!/usr/bin/python
" probe all two-letter domain names for websites and save results "
# TODO: http request with 'If-Modified-Since'
# TODO: smash icon down to 16x16 PNG
# TODO: also scrape DNS for SOA, A, MX, TXT, RR records
# TODO: also scrape WHOIS info
# TODO: store scraped stuff into sqlite

import sqlite3
import pprint  # until I can use sqlite3
import whois  # DDarko's python-whois
import dns.resolver  # http://www.dnspython.org/
import datetime
from bs4 import BeautifulSoup
from urllib import urlopen
from base64 import urlsafe_b64encode
from urlparse import urljoin

TOPLEVEL = 'com'  # TODO command-line this
ERR_ICON = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQAgMAAABinRfyAAAACVBMVEX/f3///Pz///8Acl/oAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH3wgSFzoiDHz65wAAACZpVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVAgb24gYSBNYWOV5F9bAAAAGUlEQVQI12MQAgIGDyBgUAIChg4gYKBADABZDhBBf9ExzgAAAABJRU5ErkJggg=='


def _twoletters():
  for i in range(ord('a'), ord('a') + 1):
    for j in range(ord('a'), ord('b') + 1):
      yield chr(i) + chr(j)


def db_get(dbconn, key):
  " null operation; not fetching from db yet "
  record = {'key': key}
  return record


def db_put(dbconn, record):
  " spit to stdout; not updating to db yet "
  pprint.pprint(record)


def _dt_to_unixtime(now):
  " converts datetime.datetime() to integer "
  EPOCH = datetime.datetime.utcfromtimestamp(0)
  then = now - EPOCH
  return int(then.total_seconds())


def get_whois_stuff(key):
  " attempt to get WHOIS record "
  rectypes = (
    'registrar', 'creation_date', 'last_updated',
    'expiration_date', 'name_servers', 'emails'
  )
  record = {'whois.' + i: None for i in rectypes}
  try:
    resp = whois.query(key)
    if resp:
      # I have to use getattr() because DDarko's module is weird
      for rec in rectypes:
        record['whois.' + rec] = ' '.join(sorted(list(getattr(resp, rec, []))))
      if not record['whois.' + rec]:
        record['whois.' + rec] = None
  except Exception:
    pass
  for i in record:
    if isinstance(record[i],datetime.datetime):
      record[i] = _dt_to_unixtime(record[i])
  return record


def get_dns_stuff(key):
  " attempt to get useful DNS records "
  rectypes = ('soa', 'ns', 'a', 'txt')
  record = {'dns.' + i: None for i in rectypes}
  for i in rectypes:
    try:
      resp = dns.resolver.query(key, i)
      record['dns.' + i] = ' '.join(sorted([str(j) for j in resp]))
    except dns.resolver.NoAnswer:
      record['dns.' + i] = None
    except dns.resolver.NXDOMAIN:
      break
    if record['dns.soa']:
      record['dns.sn'] = int(record['dns.soa'].split()[2])
      # this might throw an Index exception, fix it later
  return record


def get_http_stuff(key):
  " attempt to talk http on port 80 at it "
  soup = None
  page_url = 'http://%s/' % key
  record = {
    'http.code': None,
    'http.error': None,
    'http.title': None,
    'http.icon': None
  }
  try:
    # can't use with urlopen() as resp
    resp = urlopen(page_url)
    record['http.code'] = resp.getcode()
    soup = BeautifulSoup(resp.read())
    resp.close()
  except Exception as e:
    record['http.error'] = "page_url: " + e.message
  if soup:
    record['http.title'] = soup.title.text
    icon_url = None
    for link in soup.head.find_all('link'):
      if 'icon' in link['rel']:
        if 'href' in link['rel']:
          icon_url = urljoin(page_url, link['href'])
        else:
          record['http.error'] = 'find_all link: link missing href attribute'
    if not icon_url:
      icon_url = urljoin(page_url, '/favicon.ico')
    try:
      resp = urlopen(icon_url)
      if resp.headers.maintype == 'image':
        record['http.icon'] = resp.read()  # binary data
        #mime_type = resp.headers.maintype + '/' + resp.headers.subtype
        # TODO: smash it down to 16x16 gif (because some are animated)
      resp.close()
    except Exception as e:
      record['http.error'] = "icon_url: " + e.message
  return record


# -- main
TOPLEVEL = TOPLEVEL.lower()
if TOPLEVEL not in whois.TLD_RE:
  raise Exception('TLD "%s" not recognized by whois module; aborting' % TOPLEVEL)
DBCONN = sqlite3.connect('nl_cache.db')
for DOMAINNAME in _twoletters():
  key = '%s.%s' % (DOMAINNAME, TOPLEVEL)
  record = db_get(DBCONN, key)
  whois_pieces = get_whois_stuff(key)
  record.update(whois_pieces)
  dns_pieces = get_dns_stuff(key)
  record.update(dns_pieces)
  http_pieces = get_http_stuff(key)
  record.update(http_pieces)
  db_put(DBCONN, record)
