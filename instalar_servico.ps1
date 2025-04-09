$nssmExe = "C:\NSSM\nssm-2.24\win64\nssm.exe"
$scriptAuditoria = "C:\NSSM\auditoria.ps1"
$servico = "MonitoramentoAuditoria"

# Verifica se NSSM existe
if (-not (Test-Path $nssmExe)) {
    Write-Error "nssm.exe não encontrado em $nssmExe"
    exit
}

# Remove serviço anterior se existir
if (Get-Service -Name $servico -ErrorAction SilentlyContinue) {
    & $nssmExe stop $servico
    Start-Sleep 1
    & $nssmExe remove $servico confirm
    Start-Sleep 1
    Write-Output "Serviço antigo removido."
}

# Reinstala com configuração correta
& $nssmExe install $servico "powershell.exe" `
    "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptAuditoria`""

# Define diretório de inicialização e logs
& $nssmExe set $servico AppDirectory "C:\NSSM"
& $nssmExe set $servico AppStdout "C:\NSSM\saida.log"
& $nssmExe set $servico AppStderr "C:\NSSM\erro.log"
& $nssmExe set $servico AppRotateFiles 1
& $nssmExe set $servico AppRotateOnline 1
& $nssmExe set $servico AppRotateBytes 1048576

# Inicia serviço
& $nssmExe start $servico
Start-Sleep 3

# Mostra status
Get-Service -Name $servico

# Exibe logs
if (Test-Path "C:\NSSM\erro.log") {
    Write-Output "---- ERRO.LOG ----"
    Get-Content "C:\NSSM\erro.log" | Out-String
}

if (Test-Path "C:\NSSM\saida.log") {
    Write-Output "---- SAIDA.LOG ----"
    Get-Content "C:\NSSM\saida.log" | Out-String
}
