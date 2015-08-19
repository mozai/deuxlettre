#!/usr/bin/python
" makes a blank database for use by nl_probe.py "
import sqlite3

# yeah yeah proper db normalizing would make it all one big table
# but I partitioned it by data sources, 
# since the're updated independently
DBCONN = sqlite3.connect('nl_cache.db')
CURSOR = DBCONN.cursor()
CURSOR.execute(' CREATE TABLE domains (name TEXT PRIMARY KEY) ')
CURSOR.execute(''' 
  CREATE TABLE whois (name TEXT PRIMARY KEY, registrar TEXT, 
    creation_date INT, last_updated INT, expiration_date INT,
    name_servers TEXT, emails TEXT)
''')
CURSOR.execute('''
  CREATE TABLE dns (name TEXT PRIMARY KEY, 
    sn INT, soa TEXT, ns TEXT, a TEXT, txt TEXT )
''')
CURSOR.execute('''
  CREATE TABLE http (name TEXT PRIMARY KEY, code INT, error TEXT, 
    title TEXT, icon BLOB )
''')
DBCONN.close()

