Write-Output "Iniciando auditoria de arquivos no file server..."

# Caminho da pasta a ser monitorada
$pastaMonitorada = "X:\arquivos" #ALTERE PARA O CAMINHO DA PASTA ONDE VOCE QUER MONITORAR
$reportFile = "$PSScriptRoot\AuditReport.html"

# Verifica se a pasta existe
if (-not (Test-Path $pastaMonitorada)) {
    Write-Output "A pasta '$pastaMonitorada' não existe. Crie-a antes de continuar."
    exit
}

# Aplica a auditoria (SACL) automaticamente
$usuario = "Todos"
$acl = Get-Acl $pastaMonitorada
$rule = New-Object System.Security.AccessControl.FileSystemAuditRule(
    $usuario,
    "Delete, WriteData, AppendData, ReadData, WriteAttributes",
    "ContainerInherit,ObjectInherit",
    "None",
    "Success"
)
$acl.AddAuditRule($rule)
Set-Acl -Path $pastaMonitorada -AclObject $acl
Write-Output "Permissões de auditoria aplicadas na pasta: $pastaMonitorada"

# Cabeçalho HTML
$htmlHeader = @"
<html>
<head>
    <title>Relatório de Auditoria de Arquivos</title>
    <script>
    function searchTable() {
        var input = document.getElementById('searchInput');
        var filter = input.value.toUpperCase();
        var table = document.getElementById('auditTable');
        var tr = table.getElementsByTagName('tr');
        for (var i = 1; i < tr.length; i++) {
            tr[i].style.display = 'none';
            var td = tr[i].getElementsByTagName('td');
            for (var j = 0; j < td.length; j++) {
                if (td[j]) {
                    var txtValue = td[j].textContent || td[j].innerText;
                    if (txtValue.toUpperCase().indexOf(filter) > -1) {
                        tr[i].style.display = '';
                        break;
                    }
                }
            }
        }
    }
    </script>
</head>
<body>
<h1>Relatório de Auditoria de Arquivos</h1>
<input type="text" id="searchInput" onkeyup="searchTable()" placeholder="Pesquisar..."><br><br>
<table id="auditTable" border="1">
<tr><th>Usuário (AD)</th><th>Caminho do Arquivo</th><th>Ação</th><th>Data e Hora</th></tr>
"@

$htmlHeader | Out-File -FilePath $reportFile -Encoding utf8

# Finaliza HTML ao sair
function Finalizar-Relatorio {
    Add-Content -Path $reportFile -Value "</table></body></html>" -Encoding utf8
    Write-Output "Relatório finalizado: $reportFile"
    exit
}
$null = Register-EngineEvent PowerShell.Exiting -Action { Finalizar-Relatorio }

# Função segura para extrair dados do XML
function Get-EventFieldValue {
    param($record, $fieldName)
    return ($record.Event.EventData.Data | Where-Object { $_.Name -eq $fieldName }).'#text'
}

$ultimoRecordId = 0
Write-Output "Monitorando eventos em $pastaMonitorada... Pressione Ctrl+C para encerrar."

while ($true) {
    try {
        $events = Get-WinEvent -LogName Security -FilterXPath "*[System[(EventID=4663 or EventID=4660)]]" -MaxEvents 20 -ErrorAction Stop |
                  Where-Object { $_.RecordId -gt $ultimoRecordId }

        foreach ($event in $events) {
            $record = [xml]$event.ToXml()

            $userName   = Get-EventFieldValue $record "SubjectUserName"
            $userDomain = Get-EventFieldValue $record "SubjectDomainName"
            $filePath   = Get-EventFieldValue $record "ObjectName"
            $accessMask = Get-EventFieldValue $record "AccessMask"

            if (-not $userName -or -not $userDomain -or -not $filePath -or -not $accessMask) { continue }
            if (-not $filePath.StartsWith($pastaMonitorada)) { continue }

            $fullUser = "$userDomain\$userName"
            $action = $null

            switch ($event.Id) {
                4660 {
                    $action = "Exclusão de arquivo"
                }
                4663 {
                    switch ($accessMask) {
                        "0x2"      { $action = "Modificação de arquivo" }
                        "0x4"      { $action = "Criação de arquivo" }
                        "0x10000"  { $action = "Exclusão de arquivo" }
                        "0x10"     { $action = "Movimentação ou Renomeação" }
                        "0x80"     { $action = "Movimentação ou Renomeação" }
                        "0x100"    { $action = "Movimentação ou Renomeação" }
                        default    { $action = $null }
                    }
                }
            }

            if ($action) {
                # Adiciona ao HTML
                $htmlRow = "<tr><td>$fullUser</td><td>$filePath</td><td>$action</td><td>$($event.TimeCreated)</td></tr>"
                Add-Content -Path $reportFile -Value $htmlRow -Encoding utf8

                # Exportação rotativa para CSV
                $dataEvento = Get-Date -Format "yyyy-MM-dd"
                $relatorioDir = "$PSScriptRoot\\Relatorios"
                if (-not (Test-Path $relatorioDir)) {
                    New-Item -Path $relatorioDir -ItemType Directory | Out-Null
                   }
                $csvFile = Join-Path $relatorioDir "Audit_$dataEvento.csv"
                $csvData = [PSCustomObject]@{
                    Usuario     = $fullUser
                    Caminho     = $filePath
                    Acao        = $action
                    DataHora    = $event.TimeCreated
                }

                $csvExists = Test-Path $csvFile
                if (-not $csvExists) {
                    $csvData | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
                } else {
                    $csvData | Export-Csv -Path $csvFile -Append -NoTypeInformation -Encoding UTF8
                }

                Write-Output "[Evento $($event.Id)] $action - $fullUser - $filePath - $($event.TimeCreated)"
            }
        }

        if ($events.Count -gt 0) {
            $ultimoRecordId = ($events | Measure-Object -Property RecordId -Maximum).Maximum
        }

        Start-Sleep -Seconds 10
    }
    catch {
        Write-Output "Erro: $($_.Exception.Message)"
        Start-Sleep -Seconds 5
    }
}
