@echo off
:: ====================================================================
:: Script Corporativo de Backup Diário MongoDB - ShopWide / Ecommerce
:: Aluno: Bruno De Lima | 3° B | Prof. Pedro Yokada (Banco de Dados)
:: ====================================================================

set BACKUP_DIR=C:\backups\%date:/=-%
set MONGO_HOST=localhost
set MONGO_PORT=27017

echo [%time%] Iniciando rotina de backup do MongoDB...
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

mongodump --host %MONGO_HOST% --port %MONGO_PORT% --out "%BACKUP_DIR%" --gzip

if %ERRORLEVEL% equ 0 (
    echo [%time%] Backup concluido com sucesso em: %BACKUP_DIR%
) else (
    echo [%time%] ERRO: Falha ao gerar o dump do MongoDB! >&2
)
