param(
    [string]$destinatario = "--EMAIL_DESTINATÁRIO--" # INSIRA O EMAIL DO DESTINATARIO
)

# Configurações
$smtpServer   = "--SERVIDOR_SMTP--"
$smtpPort     = 587  # Porta recomendada para STARTTLS
$usuarioEmail = "--EMAIL_REMETENTE--" # INSIRA O EMAIL DO REMENTENTE
$senhaEmail   = "--SENHA_DO_EMAIL--" # SENHA DO EMAIL
$dataHoje     = Get-Date -Format "yyyy-MM-dd"
$scriptRoot   = $PSScriptRoot
$csvPath      = "$scriptRoot\Relatorios\Audit_$dataHoje.csv"
$htmlPath     = "$scriptRoot\AuditReport.html"

# Verifica se os arquivos existem
if (-not (Test-Path $csvPath)) {
    Write-Output "Relatório CSV não encontrado: $csvPath"
    exit
}

if (-not (Test-Path $htmlPath)) {
    Write-Output "Relatório HTML não encontrado: $htmlPath"
    exit
}

# Conteúdo do e-mail
$assunto = "Relatorio de Auditoria de Arquivos- $dataHoje"
$mensagem = @"
Prezados,

Segue em anexo o relatorio de auditoria de arquivos gerado em $dataHoje.

Atenciosamente,
Monitor de Auditoria TIMT
"@

# Envia e-mail com os dois anexos
Send-MailMessage -To $destinatario `
    -From $usuarioEmail `
    -Subject $assunto `
    -Body $mensagem `
    -SmtpServer $smtpServer `
    -Port $smtpPort `
    -UseSsl `
    -Credential (New-Object PSCredential ($usuarioEmail, (ConvertTo-SecureString $senhaEmail -AsPlainText -Force))) `
    -Attachments @($csvPath, $htmlPath)

Write-Output "Relatório enviado para $destinatario com os arquivos:"
Write-Output "   - $csvPath"
Write-Output "   - $htmlPath"
