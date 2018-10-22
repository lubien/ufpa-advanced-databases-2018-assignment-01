#!/bin/sh
[[ -z "${DB}" ]] && DB='priv/people.db' || DB="${DB}"

mix compile

echo "Running queries against ${DB}"

for i in 1 2 3 4 5 6 7 8 9 10
do
  echo "Running query ${i}"

	for j in 1 2 3
	do
		echo "mix query --db ${DB} --query ${i}"
		time mix query --db "${DB}" --query "${j}" > /dev/null
	done
done

echo "Running queries against PostgreSQL"

for i in 1 2 3 4 5 6 7 8 9 10
do
  echo "Running query ${i}"

	for j in 1 2 3
	do
		echo "make query-${i}"
		time make "query-${i}" > /dev/null
	done
done
