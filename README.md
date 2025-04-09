# Auditoria de Arquivos com Envio Automático de Relatórios

Este projeto em PowerShell realiza a **auditoria de arquivos em tempo real** em uma unidade específica do sistema, gera relatórios nos formatos HTML e CSV e os envia automaticamente por e-mail. Inclui funcionalidades para instalação como **serviço do Windows** ou via **agendador de tarefas**, tornando-o ideal para ambientes corporativos.

## Funcionalidades

- Monitoramento em tempo real de criação, alteração e exclusão de arquivos.
- Geração de relatórios HTML e CSV com dados organizados e visuais.
- Envio automático de relatórios por e-mail diariamente às 20h.
- Instalação como serviço do Windows ou via Agendador de Tarefas.
- Customização do destinatário de e-mail e da unidade monitorada.

## Estrutura do Projeto

| Arquivo | Descrição |
|--------|-----------|
| `auditoria.ps1` | Script principal de auditoria de arquivos e geração dos relatórios. |
| `enviar_relatorio.ps1` | Responsável por enviar os relatórios gerados por e-mail. |
| `instalar_servico.ps1` | Instala o script como um serviço do Windows (usando NSSM). |
| `Adicionar_agendador_envio_relatorio.ps1` | Cria uma tarefa agendada no Windows para envio diário dos relatórios. |

## Pré-requisitos

- PowerShell 5.1 ou superior
- Sistema Operacional Windows
- Cliente SMTP configurado (ex: KingHost, Gmail, etc.)
- [NSSM](https://nssm.cc/download) (caso use o serviço do Windows)

## Instalação

### 1. Configurar Variáveis

Antes de executar os scripts, edite as variáveis nos arquivos `auditoria.ps1` e `enviar_relatorio.ps1`, como:

$diretorioMonitorado = "G:\"
$emailDestino = "EMAIL_DESTINO"
$usuarioSMTP = "USUARIO_DESTINO"
$senhaSMTP = "SUA_SENHA"

### 2. Executar como Serviço (opcional)
Instale o script como serviço do Windows:

.\instalar_servico.ps1

## Requer NSSM instalado e disponível no PATH.

### 3. Executar via Tarefa Agendada (opcional)
Adiciona uma tarefa agendada para envio diário de relatórios:

.\Adicionar_agendador_envio_relatorio.ps1

# Execução Manual
Você pode executar manualmente os scripts com:

.\auditoria.ps1
.\enviar_relatorio.ps1 -Destinatario "outroemail@dominio.com"

# Exemplo de Relatório
Os relatórios são salvos em:

C:\RelatoriosAuditoria\

# Com os arquivos:
relatorio_auditoria.html
relatorio_auditoria.csv

# Licença
Este projeto está licenciado sob a MIT License.

# Autor
[Cleibson Martins de Oliveira da Silva] - [cleibson_10@hotmail.com]

