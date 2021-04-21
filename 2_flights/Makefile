# Описание командной утилиты по работе с базой данных:
# https://github.com/launchbadge/sqlx/tree/master/sqlx-cli

.SILENT:
.PHONY:

START_POSTGRES:
	docker-compose up

INSTALL_DEMO_DB:
	# Демо база данных для 2го примера
	# https://postgrespro.ru/education/demodb  
	psql -h localhost -U pg -a -f /Users/devnul/Downloads/demo-medium-20170815.sql

START_PG_CLI:
	pgcli -U pg -d demo -h 127.0.0.1