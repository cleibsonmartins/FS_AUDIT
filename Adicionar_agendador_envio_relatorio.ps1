$taskName = "EnviarRelatorioAuditoria"
$scriptPath = "C:\NSSM\enviar_relatorio.ps1"
$hora = "17:30"

# Verifica se o script existe
if (-not (Test-Path $scriptPath)) {
    Write-Host "O script $scriptPath não foi encontrado. Verifique o caminho." -ForegroundColor Red
    exit 1
}

# Remove tarefa anterior se existir
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Start-Sleep -Milliseconds 500
    Write-Host "Tarefa anterior '$taskName' removida." -ForegroundColor Yellow
}

# Cria ação
$acao = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""

# Define horário (20:00 todo dia)
$gatilho = New-ScheduledTaskTrigger -Daily -At ([datetime]::ParseExact($hora, "HH:mm", $null))

# Define que roda como SYSTEM com mais privilégios
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

# Registra a tarefa
Register-ScheduledTask -TaskName $taskName -Action $acao -Trigger $gatilho -Principal $principal -Description "Envia relatório de auditoria de arquivos por e-mail todos os dias às 20:00"

Write-Host "`n Tarefa '$taskName' criada com sucesso para rodar todos os dias às $hora." -ForegroundColor Green
