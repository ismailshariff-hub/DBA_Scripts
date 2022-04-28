--For Stripe backup use the below script


Backup database XmlServiceRuntime20 to URL='https://mtmproductionftp.blob.core.windows.net/sqlbackups/SQLstaging/XmlServiceRuntime20_04032020_1.bak',
URL='https://mtmproductionftp.blob.core.windows.net/sqlbackups/SQLstaging/XmlServiceRuntime20_04032020_2.bak',
URL='https://mtmproductionftp.blob.core.windows.net/sqlbackups/SQLstaging/XmlServiceRuntime20_04032020_3.bak',
URL='https://mtmproductionftp.blob.core.windows.net/sqlbackups/SQLstaging/XmlServiceRuntime20_04032020_4.bak',
URL='https://mtmproductionftp.blob.core.windows.net/sqlbackups/SQLstaging/XmlServiceRuntime20_04032020_5.bak',
URL='https://mtmproductionftp.blob.core.windows.net/sqlbackups/SQLstaging/XmlServiceRuntime20_04032020_6.bak',
URL='https://mtmproductionftp.blob.core.windows.net/sqlbackups/SQLstaging/XmlServiceRuntime20_04032020_7.bak',
URL='https://mtmproductionftp.blob.core.windows.net/sqlbackups/SQLstaging/XmlServiceRuntime20_04032020_8.bak'
with MAXTRANSFERSIZE = 4194304, BLOCKSIZE = 65536,compression,stats=5,
NOFORMAT, NOINIT
go