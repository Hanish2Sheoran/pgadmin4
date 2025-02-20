SELECT rel.oid, rel.relname AS name, rel.reltablespace AS spcoid,rel.relacl AS relacl_str,
  (CASE WHEN length(spc.spcname::text) > 0 THEN spc.spcname ELSE
    (SELECT sp.spcname FROM pg_catalog.pg_database dtb
    JOIN pg_catalog.pg_tablespace sp ON dtb.dattablespace=sp.oid
    WHERE dtb.oid = {{ did }}::oid)
  END) as spcname,
  (select nspname FROM pg_catalog.pg_namespace WHERE oid = {{scid}}::oid ) as schema,
  pg_catalog.pg_get_userbyid(rel.relowner) AS relowner, rel.relhasoids,
  rel.relhassubclass, rel.reltuples::bigint, des.description, con.conname, con.conkey,
	EXISTS(select 1 FROM pg_catalog.pg_trigger
			JOIN pg_catalog.pg_proc pt ON pt.oid=tgfoid AND pt.proname='logtrigger'
			JOIN pg_catalog.pg_proc pc ON pc.pronamespace=pt.pronamespace AND pc.proname='slonyversion'
			WHERE tgrelid=rel.oid) AS isrepl,
	(SELECT count(*) FROM pg_catalog.pg_trigger WHERE tgrelid=rel.oid AND tgisinternal = FALSE) AS triggercount,
	(SELECT ARRAY(SELECT CASE WHEN (nspname NOT LIKE 'pg\_%') THEN
            pg_catalog.quote_ident(nspname)||'.'||pg_catalog.quote_ident(c.relname)
            ELSE pg_catalog.quote_ident(c.relname) END AS inherited_tables
    FROM pg_catalog.pg_inherits i
    JOIN pg_catalog.pg_class c ON c.oid = i.inhparent
    JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
    WHERE i.inhrelid = rel.oid ORDER BY inhseqno)) AS coll_inherits,
  (SELECT count(*)
		FROM pg_catalog.pg_inherits i
      JOIN pg_catalog.pg_class c ON c.oid = i.inhparent
      JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
		WHERE i.inhrelid = rel.oid) AS inherited_tables_cnt,
	(CASE WHEN rel.relpersistence = 'u' THEN true ELSE false END) AS relpersistence,
	substring(pg_catalog.array_to_string(rel.reloptions, ',') FROM 'fillfactor=([0-9]*)') AS fillfactor,
	substring(pg_catalog.array_to_string(rel.reloptions, ',') FROM 'parallel_workers=([0-9]*)') AS parallel_workers,
	(substring(pg_catalog.array_to_string(rel.reloptions, ',') FROM 'autovacuum_enabled=([a-z|0-9]*)'))::BOOL AS autovacuum_enabled,
	substring(pg_catalog.array_to_string(rel.reloptions, ',') FROM 'autovacuum_vacuum_threshold=([0-9]*)') AS autovacuum_vacuum_threshold,
	substring(pg_catalog.array_to_string(rel.reloptions, ',') FROM 'autovacuum_vacuum_scale_factor=([0-9]*[.]?[0-9]*)') AS autovacuum_vacuum_scale_factor,
	substring(pg_catalog.array_to_string(rel.reloptions, ',') FROM 'autovacuum_analyze_threshold=([0-9]*)') AS autovacuum_analyze_threshold,
	substring(pg_catalog.array_to_string(rel.reloptions, ',') FROM 'autovacuum_analyze_scale_factor=([0-9]*[.]?[0-9]*)') AS autovacuum_analyze_scale_factor,
	substring(pg_catalog.array_to_string(rel.reloptions, ',') FROM 'autovacuum_vacuum_cost_delay=([0-9]*)') AS autovacuum_vacuum_cost_delay,
	substring(pg_catalog.array_to_string(rel.reloptions, ',') FROM 'autovacuum_vacuum_cost_limit=([0-9]*)') AS autovacuum_vacuum_cost_limit,
	substring(pg_catalog.array_to_string(rel.reloptions, ',') FROM 'autovacuum_freeze_min_age=([0-9]*)') AS autovacuum_freeze_min_age,
	substring(pg_catalog.array_to_string(rel.reloptions, ',') FROM 'autovacuum_freeze_max_age=([0-9]*)') AS autovacuum_freeze_max_age,
	substring(pg_catalog.array_to_string(rel.reloptions, ',') FROM 'autovacuum_freeze_table_age=([0-9]*)') AS autovacuum_freeze_table_age,
	(substring(pg_catalog.array_to_string(tst.reloptions, ',') FROM 'autovacuum_enabled=([a-z|0-9]*)'))::BOOL AS toast_autovacuum_enabled,
	substring(pg_catalog.array_to_string(tst.reloptions, ',') FROM 'autovacuum_vacuum_threshold=([0-9]*)') AS toast_autovacuum_vacuum_threshold,
	substring(pg_catalog.array_to_string(tst.reloptions, ',') FROM 'autovacuum_vacuum_scale_factor=([0-9]*[.]?[0-9]*)') AS toast_autovacuum_vacuum_scale_factor,
	substring(pg_catalog.array_to_string(tst.reloptions, ',') FROM 'autovacuum_analyze_threshold=([0-9]*)') AS toast_autovacuum_analyze_threshold,
	substring(pg_catalog.array_to_string(tst.reloptions, ',') FROM 'autovacuum_analyze_scale_factor=([0-9]*[.]?[0-9]*)') AS toast_autovacuum_analyze_scale_factor,
	substring(pg_catalog.array_to_string(tst.reloptions, ',') FROM 'autovacuum_vacuum_cost_delay=([0-9]*)') AS toast_autovacuum_vacuum_cost_delay,
	substring(pg_catalog.array_to_string(tst.reloptions, ',') FROM 'autovacuum_vacuum_cost_limit=([0-9]*)') AS toast_autovacuum_vacuum_cost_limit,
	substring(pg_catalog.array_to_string(tst.reloptions, ',') FROM 'autovacuum_freeze_min_age=([0-9]*)') AS toast_autovacuum_freeze_min_age,
	substring(pg_catalog.array_to_string(tst.reloptions, ',') FROM 'autovacuum_freeze_max_age=([0-9]*)') AS toast_autovacuum_freeze_max_age,
	substring(pg_catalog.array_to_string(tst.reloptions, ',') FROM 'autovacuum_freeze_table_age=([0-9]*)') AS toast_autovacuum_freeze_table_age,
	rel.reloptions AS reloptions, tst.reloptions AS toast_reloptions, rel.reloftype,
	CASE WHEN typ.typname IS NOT NULL THEN (select pg_catalog.quote_ident(nspname) FROM pg_catalog.pg_namespace WHERE oid = {{scid}}::oid )||'.'||pg_catalog.quote_ident(typ.typname) ELSE typ.typname END AS typname,
	typ.typrelid AS typoid,rel.relrowsecurity as rlspolicy, rel.relforcerowsecurity as forcerlspolicy,
	(CASE WHEN rel.reltoastrelid = 0 THEN false ELSE true END) AS hastoasttable,
	(SELECT array_agg(provider || '=' || label) FROM pg_catalog.pg_seclabels sl1 WHERE sl1.objoid=rel.oid AND sl1.objsubid=0) AS seclabels,
	(CASE WHEN rel.oid <= {{ datlastsysoid}}::oid THEN true ElSE false END) AS is_sys_table
FROM pg_catalog.pg_class rel
  LEFT OUTER JOIN pg_catalog.pg_tablespace spc on spc.oid=rel.reltablespace
  LEFT OUTER JOIN pg_catalog.pg_description des ON (des.objoid=rel.oid AND des.objsubid=0 AND des.classoid='pg_class'::regclass)
  LEFT OUTER JOIN pg_catalog.pg_constraint con ON con.conrelid=rel.oid AND con.contype='p'
  LEFT OUTER JOIN pg_catalog.pg_class tst ON tst.oid = rel.reltoastrelid
  LEFT JOIN pg_catalog.pg_type typ ON rel.reloftype=typ.oid
WHERE rel.relkind IN ('r','s','t') AND rel.relnamespace = {{ scid }}::oid
{% if tid %}  AND rel.oid = {{ tid }}::oid {% endif %}
ORDER BY rel.relname;
