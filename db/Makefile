# -*- make -*-

#SQL = schema.sql triggers.sql functions.sql
SQL = schema.sql functions.sql
TOUCH = $(SQL:%.sql=%.touch)

DBHOST = localhost
DBPORT = 5435
PGPASSFILE = /home/sifids/.pgpass
DB_CONN = PGPASSFILE=$(PGPASSFILE) psql -U sifids_w -h $(DBHOST) -p $(DBPORT) -d sifids_observations

all : $(TOUCH)

$(TOUCH) : %.touch : %.sql
	cat $^ | $(DB_CONN)
	touch $@

clean :
	$(RM) $(TOUCH)