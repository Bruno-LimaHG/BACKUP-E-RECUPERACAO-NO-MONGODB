# Roteiro de Atividade Prática — Resolução Completa

**Componente Curricular:** Banco de Dados (NoSQL / MongoDB)  
**Título da Atividade:** Backup e recuperação no MongoDB  
**Documento de Origem:** `[SIS]ANO2C4B4S26A2AP.docx`  
**Semana:** 26  

---

## 👤 Identificação do Aluno e Disciplina
- **Nome do Aluno:** Bruno De Lima
- **Turma:** 3° B
- **Professor:** Pedro Yokada
- **Matéria:** Banco de Dados
- **Data de Resolução:** 17/11/2026

---

## 1. Contextualização e Cenário da Atividade

Uma empresa de e-commerce que processa diariamente milhares de transações e cadastros de clientes precisa instituir uma política corporativa rigorosa de **Continuidade de Negócios e Recuperação de Desastres (Disaster Recovery)**. Perdas de dados decorrentes de falhas de hardware, ataques de ransomware ou erros humanos de exclusão acidental representam prejuízos financeiros diretos e infrações graves à LGPD.

Nesta atividade, atuamos como consultores especializados em infraestrutura de banco de dados para:
1. Configurar as ferramentas nativas **MongoDB Database Tools** (`mongodump` e `mongorestore`);
2. Executar procedimentos de **backup completo** e **backup incremental/seletivo** de coleções críticas;
3. Simular cenários de falha catastrófica (`dropDatabase`) e homologar a restauração com validação de integridade;
4. Criar rotinas de automação no Windows e responder às questões avaliativas do roteiro.

---

## 2. Instalação e Configuração das Ferramentas Nativas

As ferramentas utilitárias foram desacopladas do servidor MongoDB a partir da versão 4.4, passando a integrar o pacote **MongoDB Database Tools**.

### 2.1 Passo a Passo de Download e Inclusão no PATH do Windows
1. Download do pacote oficial em formato `.zip` no portal do MongoDB:  
   `https://www.mongodb.com/try/download/database-tools`
2. Extração dos binários no diretório de destino:  
   `C:\Program Files\MongoDB\Tools\100\bin`
3. Configuração da variável de ambiente `PATH` no Windows:
   - Acesso em: *Configurações Avançadas do Sistema* $\rightarrow$ *Variáveis de Ambiente*;
   - Seleção da variável de sistema `Path` $\rightarrow$ *Editar* $\rightarrow$ *Novo*;
   - Adição do caminho `C:\Program Files\MongoDB\Tools\100\bin` e confirmação.

### 2.2 Teste de Validação no Terminal
Executou-se a validação para confirmar a disponibilidade global dos comandos:

```bash
mongodump --version
mongorestore --version
```

**Saída Obtida:**
```text
mongodump version: 100.10.0
git version: e1cfb9b8281d713c706e2361d764ea6f642670e2
Go version: go1.22.8
os - arch: windows - amd64
```

---

## 3. Execução de Backups no MongoDB

### 3.1 Backup Completo do Servidor
O comando `mongodump` extrai todos os bancos de dados, coleções, metadados e arquivos de índices em formato binário comprimido BSON:

```bash
# Execução do backup completo de todas as bases locais
mongodump --host localhost --port 27017 --out ./backup-completo
```

**Detalhamento dos Parâmetros:**
- `--host localhost`: Define o endereço IP ou domínio do servidor de banco de dados.
- `--port 27017`: Especifica a porta TCP de escuta padrão da instância.
- `--out ./backup-completo`: Diretório de destino onde a estrutura de diretórios e arquivos `.bson` e `.metadata.json` será gravada.

---

### 3.2 Backup Incremental / Seletivo de Coleção Crítica
Em cenários de produção, realizar dumps completos a cada hora é inviável devido ao consumo excessivo de I/O e espaço em disco. Para coleções de alta volatilidade, como a coleção `orders` (pedidos) do banco `ecommerce`, realiza-se o dump seletivo:

```bash
mongodump --host localhost --port 27017 --db ecommerce --collection orders --out ./backup-incremental
```

**Estrutura de Arquivos Gerada:**
```text
backup-incremental/
└── ecommerce/
    ├── orders.bson            (Dados brutos compactados em formato binário)
    └── orders.metadata.json   (Definições de índices e regras de validação)
```

---

## 4. Testes de Recuperação e Simulação de Falhas

### 4.1 Simulação de Falha Catastrófica (Desastre Induzido)
Para auditar a eficiência do plano de recuperação, conectou-se ao terminal `mongosh` e simulou-se a destruição total da base do e-commerce:

```javascript
// Conexão e verificação prévia dos dados
use ecommerce;
db.orders.countDocuments(); // Retorno: 1.500 pedidos

// EXCLUSÃO ACIDENTAL / CORRUPÇÃO TOTAL DA BASE
db.dropDatabase();
print("ALERTA: Banco de dados ecommerce excluído!");
```

---

### 4.2 Restauração Completa com `mongorestore`
Para restaurar a integridade total da aplicação:

```bash
mongorestore --host localhost --port 27017 --drop ./backup-completo
```

**Parâmetro Crítico:**
- `--drop`: Remove qualquer documento ou coleção residual remanescente antes de aplicar o snapshot do backup, assegurando que o estado do banco seja restaurado de forma fidedigna e sem duplicidade de chaves.

---

### 4.3 Restauração Específica de Coleção Isolada
Caso apenas a coleção `orders` tenha sofrido corrupção:

```bash
mongorestore --host localhost --port 27017 --db ecommerce --collection orders --drop ./backup-incremental/ecommerce/orders.bson
```

---

### 4.4 Validação e Auditoria da Integridade dos Dados Restaurados
Após o restabelecimento, inspecionaram-se os registros via terminal:

```javascript
use ecommerce;

// 1. Contagem de verificação
const totalRestaurado = db.orders.countDocuments();
print("Total de pedidos recuperados:", totalRestaurado);

// 2. Inspeção visual do schema
db.orders.find().limit(2).pretty();

// 3. Verificação da recuperação dos índices
db.orders.getIndexes();
```

**Relatório de Validação:**
- A contagem de documentos retornou idêntica ao estado anterior ao incidente (`1.500 documentos`).
- Todos os índices associados (incluindo índices secundários compostos) foram reconstruídos automaticamente a partir do arquivo `metadata.json`.

---

## 5. Automação de Rotinas de Backup no Windows

Para eliminar a dependência de intervenções manuais, criou-se o script utilitário `backup.bat`:

### 5.1 Código do Script Automatizado (`backup.bat`)

```batch
@echo off
:: ====================================================================
:: Script Corporativo de Backup Diario MongoDB - ShopWide / Ecommerce
:: Aluno: Bruno De Lima | 3° B | Prof. Pedro Yokada
:: ====================================================================

set BACKUP_DIR=C:\backups\%date:/=-%
set MONGO_HOST=localhost
set MONGO_PORT=27017

echo [%time%] Iniciando backup automatico do MongoDB...
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

mongodump --host %MONGO_HOST% --port %MONGO_PORT% --out "%BACKUP_DIR%" --gzip

if %ERRORLEVEL% equ 0 (
    echo [%time%] Sucesso: Backup gravado em %BACKUP_DIR%
) else (
    echo [%time%] ERRO CRITICO: Falha ao gerar o dump do MongoDB! >&2
)
```

### 5.2 Agendamento no Agendador de Tarefas do Windows (*Task Scheduler*)
1. Abertura do **Agendador de Tarefas** (`taskschd.msc`);
2. Seleção de **Criar Tarefa Básica...** $\rightarrow$ Nome: `Backup-Diario-MongoDB`;
3. **Disparador:** *Diariamente* às `02:00 AM` (horário de menor tráfego de usuários);
4. **Ação:** *Iniciar um programa* $\rightarrow$ Caminho: `C:\Users\BrunoDeLima\Desktop\IA\BD\SEMANA 26\backup.bat`;
5. **Configurações adicionais:** Marcada a opção *"Executar estando o usuário conectado ou não"*.

---

## 6. Perguntas para Avaliação (Respostas Técnicas Aprofundadas)

### Questão 1: Qual é a diferença entre os tipos de backup realizados?
> **Resposta:**
> - **Backup Completo (*Full Backup*):** Copia a totalidade de todos os bancos, coleções, índices e metadados gerenciados pela instância. Apresenta como vantagem a simplicidade na recuperação (basta um único restore para voltar a operação). Por outro lado, demanda maior tempo de execução, gera maior consumo de banda e espaço de disco.
> - **Backup Incremental / Seletivo:** Registra apenas coleções específicas ou partições de dados que sofreram alterações recentes (como a coleção `orders`). É rápido de executar e consome pouco espaço, permitindo janelas curtas de backup (ex: a cada 1 hora). Em caso de recuperação de desastres, é comumente aplicado sobre um backup completo anterior como base.

---

### Questão 2: Por que é importante simular falhas durante os testes de recuperação?
> **Resposta:**
> Um plano de backup só é tão confiável quanto a sua capacidade comprovada de restauração. A prática de simular desastres controlados (exclusão intencional de banco ou corrupção de arquivos) é indispensável porque:
> 1. **Garante a integridade do arquivo:** Evita a falsa ilusão de segurança em que backups diários são gerados, mas estão corrompidos ou incompletos;
> 2. **Valida o RTO e o RPO:** Permite medir o tempo real que a equipe leva para reestabelecer o sistema (*Recovery Time Objective*) e o volume de dados tolerável de perda (*Recovery Point Objective*);
> 3. **Treina a equipe operacional:** Garante que em um incidente real em produção a equipe aja com precisão, rapidez e sem hesitação sob pressão.

---

### Questão 3: Que benefícios a automação de backups pode trazer para uma empresa?
> **Resposta:**
> 1. **Eliminação de Erro Humano:** Evita que esquecimentos de operadores deixem o sistema vulnerável por dias sem proteção;
> 2. **Previsibilidade e Regularidade:** Garante que snapshots consistentes sejam criados estritamente nos horários de menor impacto de performance;
> 3. **Conformidade Regulatória (Compliance e Auditoria):** Assegura aderência às exigências da LGPD, PCI-DSS e ISO 27001 para retenção e recuperação de registros transacionais;
> 4. **Redução de Custos de Downtime:** Diminui radicalmente o tempo de indisponibilidade da empresa caso ocorra qualquer imprevisto.

---

### Questão 4: Como vocês verificariam a integridade de backups realizados periodicamente?
> **Resposta:**
> A verificação técnica deve ser executada através de três camadas de auditoria:
> 1. **Verificação Criptográfica de Checksums (Hashing MD5 / SHA-256):** Gerar o hash do arquivo compactado imediatamente após o dump e comparar com o hash no momento do armazenamento para detectar qualquer corrupção em trânsito;
> 2. **Restauração Automatizada em Ambiente de Homologação / Staging:** Criar um job agendado que restaura o dump mais recente em um contêiner Docker isolado de teste;
> 3. **Bateria de Queries de Sanidade (*Smoke Tests*):** Rodar scripts que checam a contagem de documentos (`countDocuments`), comparam somatórios de valores financeiros (`$sum` em pedidos) e validam a presença de índices antes de aprovar o backup como saudável.

---

## 7. Conclusão

A implementação do plano de backup e recuperação garantiu à empresa de e-commerce resiliência operacional total. Aliando a utilização das ferramentas nativas `mongodump`/`mongorestore`, testes destrutivos controlados de restauração e rotinas automatizadas no sistema operacional, os dados corporativos encontram-se plenamente salvaguardados.
