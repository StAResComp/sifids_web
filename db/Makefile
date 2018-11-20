# -*- make -*-

#SQL = schema.sql triggers.sql functions.sql
SQL = schema.sql schema_peru.sql functions.sql functions_peru.sql
TOUCH = $(SQL:%.sql=%.touch)
DEPS = $(SQL:%.sql=%.d)

DBHOST = localhost
DBPORT = 5435
PGPASSFILE = /home/sifids/.pgpass
DB_CONN = PGPASSFILE=$(PGPASSFILE) psql -U sifids_w -h $(DBHOST) -p $(DBPORT) -d sifids_observations

all : $(TOUCH)

# include after all recipe
-include $(DEPS)

# pipe SQL to DB and record this with a touch file
$(TOUCH) : %.touch : %.sql
	cat $< | $(DB_CONN)
	touch $@

clean :
	$(RM) $(TOUCH) $(DEPS)

# how to make dependency Makefiles
$(DEPS) : %.d : %.sql
	echo -n $*.touch " " $*.d ": " > $@
	sed -ne "s/\\\include \(.*\)/\1/p" $*.sql | xargs >> $@
	echo >> $@
