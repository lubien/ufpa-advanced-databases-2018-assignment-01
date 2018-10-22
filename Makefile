DB_NAME ?= ufpa-databases-2
DB_USER ?= postgres

prepare:
	make db
	make table

db:
	createdb -U "${DB_USER}" "${DB_NAME}"

table:
	psql -U "${DB_USER}" -d "${DB_NAME}" -a -f priv/create_table.sql

reset-table:
	psql -U "${DB_USER}" -d "${DB_NAME}" -a -c "delete from people"

dump-database:
	mix compile
	time mix export > dump.csv

import-dump:
	time psql -U "${DB_USER}" -d "${DB_NAME}" -a -c "\copy people from dump.csv with csv"

import-to-psql:
	make export-database > make insert-from-stdin

count:
	psql -U "${DB_USER}" -d "${DB_NAME}" -a -c "select count(*) from people"

query-1:
	time psql -U "${DB_USER}" -d "${DB_NAME}" -a -c "select country, gender, count(*) from people group by country, gender;"

query-2:
	time psql -U "${DB_USER}" -d "${DB_NAME}" -a -c "select country, gender, age, count(*) from people group by country, gender, age;"

query-3:
	time psql -U "${DB_USER}" -d "${DB_NAME}" -a -c "select country, gender, avg(income) from people group by country, gender;"

query-4:
	time psql -U "${DB_USER}" -d "${DB_NAME}" -a -c "select country, gender, avg(age) from people group by country, gender;"

query-5:
	time psql -U "${DB_USER}" -d "${DB_NAME}" -a -c "select country, gender, count(*) from people where country = 15 group by country, gender;"

query-6:
	time psql -U "${DB_USER}" -d "${DB_NAME}" -a -c "select country, gender, count(*) from people where country = 15 and gender = 1 group by country, gender;"

query-7:
	time psql -U "${DB_USER}" -d "${DB_NAME}" -a -c "select country, gender, count(*) from people where country >= 0 and country <= 15 group by country, gender;"
