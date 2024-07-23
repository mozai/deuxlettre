dbfile = ./gathered.tsv

all:
	@echo Create/Update $(dbfile)
	-./gather_records.sh >$(dbfile)
	-./gather_icons.sh $(dbfile)
	./make_html.sh $(dbfile) >index.html

