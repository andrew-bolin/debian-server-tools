-- Source: http://georgepavlides.info/?p=628
-- Usage: mysql -N DATABASE-NAME < alter-table.sql|mysql


-- To InnoDB
-- Table compression algorithm (lz4) support from MariaDB 10.1.0
-- https://mariadb.com/kb/en/mariadb/innodb-xtradb-page-compression/
SET @engine_string = 'InnoDB';

-- To Aria
-- https://mariadb.com/kb/en/mariadb/aria-storage-engine/
--SET @engine_string = 'Aria, TRANSACTIONAL = 0, PAGE_CHECKSUM = 0';

-- To TokuDB w/LZMA
-- https://www.percona.com/doc/percona-server/5.6/tokudb/tokudb_compression.html
--SET @engine_string = 'TokuDB, ROW_FORMAT=TOKUDB_LZMA';

-- To TokuDB w/Quick LZ
--SET @engine_string = 'TokuDB, ROW_FORMAT=TOKUDB_QUICKLZ';

SET @db_name = ( SELECT DATABASE() );

SELECT CONCAT(
    'ALTER TABLE `',
    `tbl`.`TABLE_SCHEMA`,
    '`.`',
    `tbl`.`TABLE_NAME`,
    '` ENGINE = ',
    @engine_string,
    ';'
) AS `alters`
FROM `information_schema`.`TABLES` `tbl`
WHERE `tbl`.`TABLE_SCHEMA` = @db_name
LIMIT 0,1000;
