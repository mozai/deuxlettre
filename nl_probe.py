#!/usr/bin/python
" probe all two-letter domain names for websites and save results "
# TODO: also scrape WHOIS info
# TODO: also scrape DNS for SOA, A, MX, TXT, RR records
# TODO: store scraped stuff into sqlite
# import sqlite3

import pprint  # until I can use sqlite3
from bs4 import BeautifulSoup
from urllib import urlopen
from base64 import urlsafe_b64encode
from urlparse import urljoin

TOPLEVEL = 'com'


def _twoletters():
  for i in range(ord('a'), ord('b') + 1):
    for j in range(ord('a'), ord('b') + 1):
      yield chr(i) + chr(j)


def db_get(key):
  " null operation; not fetching from db yet "
  record = {
    'key': key,
    'icon_url': None,
    'icon_data': None
  }
  return record


def db_put(record):
  " spit to stdout; not updating to db yet "
  pprint.pprint(record)


def get_http_stuff(key):
  " attempt to talk http on port 80 at it "
  soup = None
  page_url = 'http://%s/' % key
  record = {
    'http_code': None,
    'error': None,
    'title': None,
    'icon_data': None
  }
  try:
    # can't use with urlopen() as resp
    resp = urlopen(page_url)
    record['http_code'] = resp.getcode()
    soup = BeautifulSoup(resp.read())
    resp.close()
  except Exception as e:
    record['error'] = "page_url: " + e.message
  if soup:
    record['title'] = soup.title.text
    for link in soup.head.find_all('link'):
      if 'icon' in link['rel']:
        if 'href' in link['rel']:
          icon_url = urljoin(page_url, link['href'])
        else:
          record['error'] = 'find_all link: link missing href attribute'
    if not icon_url:
      icon_url = urljoin(page_url, '/favicon.ico')
    try:
      resp = urlopen(icon_url)
      mime_type = resp.headers.maintype + '/' + resp.headers.subtype
      record['icon_data'] = 'data:%s;base64,%s' % (mime_type, urlsafe_b64encode(resp.read()))
      resp.close()
    except Exception as e:
      record['error'] = "icon_url: " + e.message
  return record


for DOMAINNAME in _twoletters():
  key = '%s.%s' % (DOMAINNAME, TOPLEVEL)
  record = db_get(key)
  http_pieces = get_http_stuff(key)
  record.update(http_pieces)
  db_put(record)
