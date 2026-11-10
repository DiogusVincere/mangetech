# MangeTech

Sistema de chamados de manutenção e gestão de ativos para o chão de fábrica: abre e acompanha chamados, cadastra equipamentos com QR code e mostra indicadores para a gestão. Tem API em Django, front web em Vue e app Android em Flutter.

Projeto Integrador do grupo MangeTech. Este repositório substituiu o `Integrador4_Final`, criado por causa de problemas de merge no repositório anterior; o fork antigo guarda os protótipos de tela, copiados em [`docs/prototipos`](docs/prototipos).

## Funcionalidades

O que existe de verdade no código (`chamados/models.py`, `chamados/views.py`, as views do Vue e as telas do Flutter):

- **Chamados** — abertura com título, descrição, ativo, ambiente, urgência (Crítico, Alta, Média, Baixa), prazo sugerido e responsáveis. Status `ABERTO` → `AGUARDANDO RESP` → `EM ANDAMENTO` → `REALIZADO` → `CONCLUÍDO`, ou `CANCELADO`. Cada mudança de status pede uma descrição, aceita fotos e vira uma linha do histórico (mudar o status pela edição também registra). Edição, exclusão (só quem abriu ou staff; chamado em andamento não pode ser excluído), comentários com fotos, anexos de arquivo (até 20 MB), filtros (status, urgência, ativo, ambiente, solicitante, responsável, período, "meus chamados", críticos em aberto, sem responsável, atrasados), busca por texto ou nº, ordenação, paginação, marcação de atrasado, exportação em CSV (abre direto no Excel) e exclusão em lote.
- **Ativos** — cadastro de equipamentos (código/tag, nome, modelo, fabricante, número de série, fornecedor, ambiente, status Ativo/Inativo/Manutenção, data de aquisição, valor, garantia em meses e observações), com cálculo de "em garantia até". Chamado e ativo ficam ligados de verdade (chave estrangeira `ativo_ref`; chamados antigos de texto livre são ligados pelo código na migração). Histórico automático (cadastro, chamado aberto, mudança de status, troca de local) e manual (preventiva, corretiva, inspeção, calibração…). QR code em PNG com etiqueta para imprimir, leitura do QR pelo app, "abrir chamado" a partir do ativo e contagem de chamados em aberto. Ativo com chamado em aberto não pode ser excluído.
- **Usuários e papéis** — cadastro e login por e-mail com token (`TokenAuthentication` do DRF). Usuário comum vê os chamados em que é solicitante ou responsável e pode editar ativos; *staff* vê todos, acessa o dashboard, cadastra/exclui ativos e gerencia usuários. Só superusuário promove superusuário, e ninguém tira o próprio acesso de staff. Perfil com edição de dados, troca de senha (a sessão continua) e estatísticas e atividades reais.
- **Recuperação de senha** — código numérico de 6 dígitos enviado por e-mail, válido por 15 minutos, uso único e com limite de 5 tentativas. A resposta é a mesma para e-mail cadastrado ou não (não revela quem tem conta) e há limite de requisições por IP nos endpoints públicos.
- **Dashboard gerencial** — por período (7, 30, 90 dias, 12 meses ou tudo): totais por status e urgência, em aberto, atrasados, taxa de resolução, tempo médio até resolver e faixas de tempo (calculados pelo histórico), % resolvidos no prazo, críticos em aberto e situação dos ativos (em operação, manutenção, inativos e os que mais geram chamados). Exporta PDF e CSV.
- **Admin do Django** para todos os modelos.

## Arquitetura

```mermaid
flowchart LR
    Web["Front web<br/>Vue 3 + TypeScript + Vite<br/>Tailwind, Pinia, Chart.js"]
    App["App Android<br/>Flutter<br/>Provider, mobile_scanner, fl_chart"]
    API["API REST<br/>Django 5 + Django REST Framework<br/>token, django-filter, CORS"]
    DB[("SQLite")]
    Media["media/<br/>fotos e anexos"]
    Web -- "/api" --> API
    App -- "/api" --> API
    API --> DB
    API --> Media
```

A API é a única fonte de dados; web e app só falam com ela. O endereço da API é configurável nos dois clientes (ver "Como rodar").

## Estrutura de pastas

```
MANGETECH/
  Back/                 API Django (projeto Back, app chamados)
    Back/               settings, urls, wsgi
    chamados/           models, serializers, views, filters, urls, admin,
                        qr_generator, email_service, exceptions, pagination,
                        templates/email/ (e-mails da recuperação de senha),
                        tests.py, management/commands/seed_demo.py
    .env.example        variáveis de ambiente da API
    requirements.txt
  front-end/            front web Vue 3 + TypeScript (Vite, Tailwind, Pinia)
    src/api/            cliente axios (token, erros) e chamadas à API
    src/views/          telas   src/stores/ sessão e avisos   src/components/ layout, formulário de ativo e modais
    .env.example        VITE_API_URL
    vercel.json         rewrite de SPA para o Vercel
  app_integrador/       app Flutter
    lib/data/           api_service e providers
    lib/ui/             telas (screens), widgets e tema
docs/prototipos/        telas do Figma da primeira versão (HTML)
render.yaml             publicação da API no Render
LICENSE                 MIT
```

## Como rodar

### API (Django)

```bash
cd MANGETECH/Back
python -m venv .venv
.venv\Scripts\activate          # Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt
copy .env.example .env          # Linux/macOS: cp .env.example .env
python manage.py migrate
python manage.py seed_demo      # dados de demonstração (opcional)
python manage.py runserver
```

A API responde em `http://localhost:8000/api/` e o admin em `http://localhost:8000/admin/`. `GET /api/health/` responde sem login (usado pelo Render e pelo app para testar a conexão).

Testes da API (31 casos: autenticação e recuperação de senha, permissões, chamados, anexos, filtros, CSV, ativos, QR e dashboard):

```bash
python manage.py test chamados
```

Variáveis de ambiente (lidas do `.env` ao lado do `manage.py` ou do ambiente):

| Variável | Padrão | Para que serve |
|---|---|---|
| `SECRET_KEY` | chave aleatória a cada início | Em produção precisa ser fixa. |
| `DEBUG` | `False` | `True` só em desenvolvimento. |
| `ALLOWED_HOSTS` | `localhost,127.0.0.1` | Hosts aceitos, separados por vírgula. Para o emulador Android, inclua `10.0.2.2` (o `.env.example` já inclui). |
| `CORS_ALLOWED_ORIGINS` | portas locais do Vite e do Flutter web | Origens do front. Com `DEBUG=True`, qualquer origem é aceita. |
| `CSRF_TRUSTED_ORIGINS` | as mesmas do CORS | Precisa do esquema (`https://...`). |
| `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD` | vazios | Com os dois, a recuperação de senha envia por SMTP; sem eles, o e-mail sai no console. |
| `FRONTEND_URL` | `http://localhost:5173` | Link do front nos e-mails. |
| `AUTH_THROTTLE_RATE` | `30/min` | Limite por IP em login, cadastro e recuperação de senha. |
| `SERVE_MEDIA` | `True` | O Django serve os uploads em `/media/`. Desligue se houver Nginx/CDN na frente. |

### Front web (Vue)

```bash
cd MANGETECH/front-end
npm install
copy .env.example .env          # VITE_API_URL=http://localhost:8000/api
npm run dev
```

Abre em `http://localhost:5173`. `npm run typecheck` confere os tipos; `npm run build` confere os tipos e gera a pasta `dist/`; no Vercel, o `vercel.json` já redireciona todas as rotas para o `index.html`. Sem `VITE_API_URL`, o front usa a API publicada no Render (`https://mangetech-api.onrender.com/api`).

### App (Flutter)

```bash
cd MANGETECH/app_integrador
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:8000/api
```

`10.0.2.2` é o endereço da máquina visto de dentro do emulador Android (já está no `ALLOWED_HOSTS` do `.env.example`). Em aparelho físico, rode a API com `python manage.py runserver 0.0.0.0:8000`, use o IP da máquina na rede (`--dart-define=API_URL=http://192.168.x.x:8000/api`) e inclua esse IP em `ALLOWED_HOSTS`. Sem `--dart-define`, o padrão é o do emulador.

### Usuário de demonstração

`python manage.py seed_demo` cria dois usuários, quatro ativos e seis chamados. O login é pelo e-mail:

| E-mail | Senha | Papel |
|---|---|---|
| `demo@mangetech.local` | `demo1234` | staff (vê tudo, dashboard, usuários) |
| `tecnico@mangetech.local` | `demo1234` | usuário comum (responsável por chamados) |

As senhas são públicas de propósito. O comando pode rodar mais de uma vez: não duplica nada.

## Instância pessoal (dados permanentes)

A demonstração (`mangetech-api`) recomeça a cada deploy de propósito. Para uso de verdade existe um segundo serviço no [`render.yaml`](render.yaml), o `mangetech-pessoal`, que guarda o banco no **Neon** (Postgres gratuito) e as fotos/anexos num bucket privado do **Cloudflare R2**. Ele não carrega os dados de demonstração e cria o seu administrador a partir de variáveis de ambiente.

A API decide pelo ambiente: com `DATABASE_URL` usa Postgres (sem ela, SQLite); com `R2_BUCKET` e as chaves do R2 guarda os arquivos no bucket e devolve links assinados que valem 1 hora (sem elas, usa a pasta `media/`).

**1. Banco no Neon**
1. Crie um projeto em <https://neon.tech> (plano gratuito). Escolha a região **AWS US West (Oregon)**, a mesma do Render, para a API responder mais rápido.
2. Em *Connection Details*, copie a *connection string* **sem pooling** (a que não tem `-pooler` no host). Ela tem a forma `postgresql://usuario:senha@ep-....neon.tech/neondb?sslmode=require`. Esse é o `DATABASE_URL`.

**2. Arquivos no Cloudflare R2**
1. No painel da Cloudflare: *R2 Object Storage* → *Create bucket* (ex.: `mangetech-pessoal`). Deixe o bucket **privado** (o padrão).
2. *Manage R2 API Tokens* → *Create API token* com permissão **Object Read & Write** só nesse bucket. Guarde o *Access Key ID* e o *Secret Access Key* (o segredo aparece uma vez só).
3. Anote o *Account ID* da conta (aparece na página do R2). Ficam: `R2_BUCKET`, `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`.

**3. API no Render**
1. Com este código na `main`, abra o Blueprint do repositório no Render (*Blueprints* → o blueprint do MangeTech → *Sync*/*Manual sync*). Se a demonstração não foi criada por Blueprint, use *New* → *Blueprint* e escolha o repositório; o Render mostra os dois serviços e cria o que falta.
2. Preencha as variáveis que o Render pedir para o `mangetech-pessoal`: `DATABASE_URL`, as quatro do R2, `ADMIN_EMAIL`, `ADMIN_PASSWORD` (forte: a API recusa senhas comuns ou só numéricas), `ADMIN_NOME`. `CORS_ALLOWED_ORIGINS` e `FRONTEND_URL` podem ficar para o passo 4.
3. No primeiro início ele cria as tabelas no Neon e o seu usuário administrador. Teste em `https://mangetech-pessoal.onrender.com/api/health/` (o nome exato aparece no painel).

O administrador só é criado se ainda não existir; depois você troca a senha pelo perfil normalmente e ela não é sobrescrita.

**4. Front no Vercel**
1. *Add New* → *Project* → importe este repositório de novo, com **Root Directory** `MANGETECH/front-end`.
2. Em *Environment Variables*, crie `VITE_API_URL` = `https://mangetech-pessoal.onrender.com/api` e faça o deploy.
3. Volte ao Render e preencha no `mangetech-pessoal`: `CORS_ALLOWED_ORIGINS` = a URL do Vercel (ex.: `https://mangetech-pessoal.vercel.app`) e `FRONTEND_URL` = a mesma URL.

**5. App Android**
No GitHub: *Actions* → *APK (Android)* → *Run workflow* → informe `api_url` = `https://mangetech-pessoal.onrender.com/api`. O APK sai como artefato `mangetech-apk-main-pessoal`.

**Opcional: e-mail de recuperação de senha.** Sem SMTP, o código de 6 dígitos só aparece nos logs do Render. Para receber por e-mail, crie no `mangetech-pessoal` as variáveis `EMAIL_HOST_USER` e `EMAIL_HOST_PASSWORD` (no Gmail, uma *senha de app*).

**Bom saber:** os dois serviços gratuitos do Render dormem sem uso (uns 30 s para acordar) e dividem as horas gratuitas do mês, mas dormindo não gastam. O Neon gratuito guarda os dados sem prazo, com limite de espaço pequeno (suficiente para uso pessoal) e restauração de poucas horas para trás; para cópia de segurança, rode de vez em quando `pg_dump "$DATABASE_URL" > backup.sql`. Confira limites e preços atuais nos sites do Neon, da Cloudflare e do Render.

## API: endpoints principais

Todos sob `/api/`, com `Authorization: Token <token>` (exceto `auth/*` e `health/`). Listagens são paginadas (`?page=`, `?page_size=` até 1000) e erros vêm com um campo `message` legível.

| Método e rota | Para quê |
|---|---|
| `POST auth/login/`, `auth/register/`, `auth/logout/` | Sessão (login pelo e-mail). |
| `POST auth/solicitar-recuperacao-senha/` → `auth/verificar-token-recuperacao/` → `auth/resetar-senha/` | Recuperação de senha com código de 6 dígitos. |
| `GET/POST chamados/`, `GET/PATCH/DELETE chamados/{id}/` | Chamados (filtros: `status`, `urgencia` — aceitam vários, separados por vírgula —, `search`, `ativo_ref`, `responsavel`, `meus_chamados`, `atrasados`, `sem_responsavel`, `criticos_abertos`, `data_inicio`, `data_fim`, `ordering`). |
| `POST chamados/{id}/mudar_status/`, `adicionar_comentario/`, `adicionar_anexo/`; `DELETE chamados/{id}/anexos/{anexo}/` | Andamento do chamado (multipart para fotos). |
| `GET chamados/export/`, `POST chamados/bulk-delete/` | CSV com os mesmos filtros; exclusão em lote. |
| `GET/POST ativos/`, `GET/PATCH/DELETE ativos/{id}/` | Ativos (filtros: `status`, `search`, `ambiente`, `com_chamados_abertos`). |
| `GET ativos/{id}/chamados/`, `ativos/{id}/qr-code/` (JSON base64), `ativos/{id}/qr-code/png/`, `ativos/por-codigo/?codigo=`; `POST ativos/{id}/adicionar_historico/` | QR, leitura do QR e histórico do ativo. |
| `GET dashboard/gerencial/?dias=30` | Indicadores. |
| `GET/PATCH usuarios/`, `usuarios/me/`, `usuarios/{id}/estatisticas/`; `perfil/`, `perfil/atualizar/`, `perfil/alterar-senha/`, `perfil/estatisticas/` | Usuários e perfil. |

## Telas

![Login do painel web](docs/prints/web-login.png)

Painel web em https://integrador4-final.vercel.app (entre com `demo@mangetech.local` / `demo1234`). O app Flutter roda em https://diogusvincere.github.io/mangetech/ numa moldura de celular.

## Demonstração

- Front web: <https://integrador4-final.vercel.app>
- API: `https://mangetech-api.onrender.com/api` (Render, plano gratuito: dorme sem uso e leva uns 30 s para acordar no primeiro acesso; o banco é reposto pelo `seed_demo` a cada deploy). A API original do curso, no Azure, saiu do ar; o [`render.yaml`](render.yaml) é o que publica esta.
- App (web): <https://diogusvincere.github.io/mangetech/> — publicada pelo workflow [`web.yml`](.github/workflows/web.yml) a cada push na `main` que mexa em `MANGETECH/app_integrador/`, depois que o GitHub Pages for ligado (Settings > Pages > Source: GitHub Actions). O app aparece numa moldura de celular; `…/mangetech/app/` abre em tela cheia. Aponta para a API no Render.
- App (APK Android): na página de [Releases](https://github.com/DiogusVincere/mangetech/releases) (gerado pelo workflow [`apk.yml`](.github/workflows/apk.yml) a cada tag `v*`; cada execução também deixa o APK como artefato). Assinado com a chave de debug: instala em qualquer aparelho Android, mas não serve para a Play Store.


## Equipe

- Diogo Vieira de Lima — [@DiogusVincere](https://github.com/DiogusVincere)
- Gustavo Mendes — [@Guga-Sistemas](https://github.com/Guga-Sistemas)
- Gabriel Lopes — [@gabriel-adssenai](https://github.com/gabriel-adssenai)
- Guilherme Rosa — [@guilhermebombado](https://github.com/guilhermebombado)

## Licença

[MIT](LICENSE) — Copyright (c) 2025 Diogo Vieira de Lima e equipe MangeTech.
