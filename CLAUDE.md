# SISCOM — branch `refactor/remaster`

Reescrita do siscom (Secretaria de Estado da Educação do Amapá) em **Rails 8.1 + Ruby 3.4.5**, monolito
modular com Hotwire, Tailwind e RSpec. O plano completo fica fora do repositório:

**`/Users/josue/projetos/seed/docs/refactor-remaster/`** — ler `00-LEIA-ME.md` → `01` … `04` e
`PROGRESSO.md` (fase atual, decisões e pendências) antes de alterar qualquer coisa.

## Regras

- Trabalhar só na branch `refactor/remaster`. Nunca commit no `master`, nunca `push --force`,
  nunca conectar no banco de produção.
- O seed (`/Users/josue/projetos/seed/sis/seed`) e o `master` do siscom são **somente leitura**
  (`git show master:<caminho>` para consultar o código antigo).
- Passos pequenos, com testes, um commit por passo, mensagens em português.
- Decisão fora dos documentos (nome de tabela, regra de negócio, gem nova) → perguntar ao Josue.
- Ao fim de cada sessão, atualizar `PROGRESSO.md` no pacote do plano.

## Arquitetura (resumo de `02-arquitetura-e-convencoes.md`)

- Módulos por namespace, nomes em português: `Core` (`core_*`), `Rh` (`rh_*`), `Ti` (`ti_*`),
  `Transporte` (`transporte_*`), `Equipamentos` (`equipamentos_*`), `Legado` (lê tabelas antigas).
  `users` é a tabela antiga, dona = Core.
- Um módulo só fala com outro pelo `<Modulo>::Api`. Sem join/model de outro módulo
  (exceções: `belongs_to :user` e FKs estáveis como `rh_unidade_id`, com snapshot de nome).
- Controllers finos; regras em services `call` que retornam `Core::Resultado`.
- Permissões declaradas em `config/modulos/<modulo>.yml` (permissões, papéis, concessão, menu);
  `Core::Autorizacao`, `pode?`/`pode!`, `Core::PoliticaBase` (Pundit).
- Banco: migrations só **adicionam** (rodam sobre o banco de produção). Importações por tasks
  idempotentes em `lib/tasks/remaster/*.rake` com `legacy_id`.

## Convenções técnicas

- Fuso **Brasília** com `active_record.default_timezone = :local` (dados antigos em horário local).
  Não mudar para UTC.
- Banco único: Solid Cache/Queue/Cable em tabelas do banco principal (inclusive em desenvolvimento).
- Front: importmap + Turbo + Stimulus + `tailwindcss-rails` (sem Node). Tema em
  `app/assets/tailwind/application.css` (variáveis do seed; `dark:` = `html[data-theme="dark"]`,
  `menu-recolhido:` = menu lateral recolhido).
- Layout: `layouts/application` (shell) e `layouts/publico` (login). Partials em
  `app/views/layouts/compartilhado/` e `app/views/compartilhado/` (`_cabecalho_pagina`, `_flash`,
  `_alternar_tema`). Ícones CoreUI: `icone(:nome)` (arquivos `app/assets/images/icones/cil-*.svg`).
- **Celular:** toda tela segue o comportamento do seed em tela pequena e é conferida em ~390 px (sem
  rolagem horizontal; menu em gaveta; ação principal só com ícone; formulário em painel de altura
  inteira). O app será instalável (PWA). Regras no plano, `02` §6.1 e §6.2.
- Stimulus com nomes em português (`tema`, `menu-lateral`, `dropdown`, `flash`, `mostrar-senha`).
- Paginação: `pagy`. Excel: `caxlsx` + `caxlsx_rails`.
- **Datas sempre em formato brasileiro (dd/mm/aaaa)** na tela e nos formulários: no model `datas_br :campo`,
  no formulário `render "compartilhado/campo_data"` (nunca `date_field`), em filtros `DataBr.interpretar(params[...])`
  e para exibir `DataBr.formatar(valor)` ou `l(data)`. Máscaras (data, CPF, telefone): Stimulus `mascara`.
- Painéis (`compartilhado/_painel_formulario`) e confirmações fecham só pelos botões (Cancelar/Fechar/×).
- Auditoria: toda ação que altera dados chama `Core::Api.auditar` (ou `Core::Auditoria::Registrar` dentro do Core);
  notificações por `Core::Api.notificar`; fontes de referência por `Core::Api.opcoes_da_fonte`. Um módulo publica
  entidades para fontes definindo `entidades_publicaveis` e `registros_da_entidade` na sua `Api`.
- Respostas para Turbo: 422 em erro de formulário, 303 em redirecionamento.

## Comandos

```bash
bin/dev                 # web + tailwind watch + jobs (Solid Queue)
bundle exec rspec       # testes (system specs :js usam Chrome headless)
bin/ci                  # rubocop, bundler-audit, importmap audit, brakeman, rspec
```

Deploy: Dokku por **buildpack** (sem Dockerfile na raiz — não adicionar), `Procfile` com `web` e `release`;
Josue faz push no GitHub e `dokku git:sync --build` no servidor.

Usuários padrão (um por perfil, login e senha no plano em `USUARIOS-PADRAO.md`): `bin/rails remaster:dev:usuarios_padrao`.
Ao criar módulo, papel ou permissão, acrescente o usuário em `lib/tasks/remaster/dev.rake`, rode a task e
atualize o documento.

Banco local: `siscom_development` é uma cópia (dump) de produção — não criar dados de teste nele
(além dos usuários padrão `@siscom.dev`);
use os specs (banco `siscom_test`).
