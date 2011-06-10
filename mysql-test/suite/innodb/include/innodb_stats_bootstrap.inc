-- disable_warnings
-- disable_query_log

DROP TABLE IF EXISTS mysql.innodb_table_stats;
CREATE TABLE mysql.innodb_table_stats (
	database_name			VARCHAR(64) NOT NULL,
	table_name			VARCHAR(64) NOT NULL,
	stats_timestamp			TIMESTAMP NOT NULL,
	n_rows				BIGINT UNSIGNED NOT NULL,
	clustered_index_size		BIGINT UNSIGNED NOT NULL,
	sum_of_other_index_sizes	BIGINT UNSIGNED NOT NULL,
	PRIMARY KEY (database_name, table_name)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS mysql.innodb_index_stats;
CREATE TABLE mysql.innodb_index_stats (
	database_name			VARCHAR(64) NOT NULL,
	table_name			VARCHAR(64) NOT NULL,
	index_name			VARCHAR(64) NOT NULL,
	stat_timestamp			TIMESTAMP NOT NULL,
	/* there are at least:
	stat_name='size'
	stat_name='n_leaf_pages'
	stat_name='n_diff_pfx%' */
	stat_name			VARCHAR(64) NOT NULL,
	stat_value			BIGINT UNSIGNED NOT NULL,
	sample_size			BIGINT UNSIGNED,
	stat_description		VARCHAR(1024) NOT NULL,
	PRIMARY KEY (database_name, table_name, index_name, stat_name),
	FOREIGN KEY (database_name, table_name)
	  REFERENCES mysql.innodb_table_stats (database_name, table_name)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

-- enable_warnings
-- enable_query_log