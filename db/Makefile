# -*- make -*-

#SQL = schema.sql triggers.sql functions.sql
SQL = schema.sql schema_peru.sql functions.sql functions_peru.sql
SQL_SCHEMA_FILES = $(wildcard schema*.sql)
TOUCH = $(SQL:%.sql=%.touch)
DEPS = $(SQL:%.sql=%.d)

DBHOST = localhost
DBPORT = 5435
PGPASSFILE = /home/sifids/.pgpass
DB_CONN = PGPASSFILE=$(PGPASSFILE) psql -U sifids_w -h $(DBHOST) -p $(DBPORT) -d sifids_observations

SCHEMA_DIR = schema
SCHEMA = $(SCHEMA_DIR)/index.html
SCHEMASPY = java -jar /home/cs2/schemaspy-6.0.1-SNAPSHOT.jar -dp /home/cs2/postgresql-42.2.5.jar > /dev/null

all : $(TOUCH) $(SCHEMA)

# include after all recipe
-include $(DEPS)

# pipe SQL to DB and record this with a touch file
$(TOUCH) : %.touch : %.sql
	cat $< | $(DB_CONN)
	touch $@

$(SCHEMA) : $(SQL_SCHEMA_FILES)
	$(SCHEMASPY)

clean :
	$(RM) $(TOUCH) $(DEPS)
	$(RM) -r $(SCHEMA_DIR)

# how to make dependency Makefiles
$(DEPS) : %.d : %.sql
	echo -n $*.touch " " $*.d ": " > $@
	sed -ne "s/\\\include \(.*\)/\1/p" $*.sql | xargs >> $@
	echo >> $@
