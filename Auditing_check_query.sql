-- Auditing check query

select event_time, server_principal_name, statement, target_server_principal_name, object_name
from sys.fn_get_audit_file('E:\Backup\Audit\Audit-privilegedusers_*.sqlAudit',default,default)
where server_principal_name like '%IBG\adm-%' and statement like '%sp_%'
go