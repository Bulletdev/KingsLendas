
```
>  ██╗  ██╗██╗███╗   ██╗ ██████╗ ███████╗    ██╗     ███████╗███╗   ██╗██████╗  █████╗ ███████╗
>  ██║ ██╔╝██║████╗  ██║██╔════╝ ██╔════╝    ██║     ██╔════╝████╗  ██║██╔══██╗██╔══██╗██╔════╝
>  █████╔╝ ██║██╔██╗ ██║██║  ███╗███████╗    ██║     █████╗  ██╔██╗ ██║██║  ██║███████║███████╗
>  ██╔═██╗ ██║██║╚██╗██║██║   ██║╚════██║    ██║     ██╔══╝  ██║╚██╗██║██║  ██║██╔══██║╚════██║
>  ██║  ██╗██║██║ ╚████║╚██████╔╝███████║    ███████╗███████╗██║ ╚████║██████╔╝██║  ██║███████║
>  ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝    ╚══════╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚══════╝
                         Torneio IDL Kings Lendas — kingslendas.com
```

<div align="center">

[![Ruby Version](https://img.shields.io/badge/ruby-3.4.5-CC342D?logo=ruby)](https://www.ruby-lang.org/)
[![Rails Version](https://img.shields.io/badge/rails-8.0.4-CC342D?logo=rubyonrails)](https://rubyonrails.org/)
[![SQLite](https://img.shields.io/badge/SQLite-3-003B57?logo=sqlite)](https://www.sqlite.org/)
[![Redis](https://img.shields.io/badge/Redis-6+-red?logo=redis)](https://redis.io/)
[![TailwindCSS](https://img.shields.io/badge/Tailwind-4-06B6D4?logo=tailwindcss)](https://tailwindcss.com/)
[![Leaguepedia](https://img.shields.io/badge/Dados-Leaguepedia-C89B3C)](https://lol.fandom.com/wiki/League_of_Legends_Esports_Wiki)

</div>

---

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  KINGS LENDAS — Ruby on Rails 8.0.4 (Full-stack + Hotwire)                   ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  Site do torneio comunitário de LoL organizado pela Ilha das Lendas.         ║
║  Dados via Leaguepedia API · SQLite + FTS5 · Turbo Frames · Kamal deploy     ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

<details>
<summary><kbd>▶ Funcionalidades (click para expandir)</kbd></summary>

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  [■] Classificação ao vivo    — Tabela de pontos atualizada da Kings Cup    │
│  [■] Calendário de partidas   — Próximas partidas e resultados              │
│  [■] Perfil de times          — Roster, logo, stats e histórico             │
│  [■] Perfil de jogadores      — KDA, champions, partidas jogadas            │
│  [■] Picks & Bans             — Draft tracker por partida                   │
│  [■] Estatísticas de campeões — Pick rate, win rate, KDA por torneio        │
│  [■] Seasons anteriores       — S1, S2 (Karmine Cospe), S3 (Gen GG)         │
│  [■] Leaguepedia Sync         — Rake task para sync automático de dados     │
│  [■] SQLite + FTS5            — Busca full-text de jogadores                │
│  [■] Cache multi-camada       — MemoryStore dev, Redis prod                 │
│  [■] API interna JSON         — Endpoints para Turbo Frames                 │
│  [■] Design responsivo        — Mobile-first, dark theme gold/teal          │
│  [■] Deploy via Kamal         — Docker + Kamal para produção                │
└─────────────────────────────────────────────────────────────────────────────┘
```

</details>

---

## Indice

```
┌──────────────────────────────────────────────────────┐
│  01 · Quick Start                                    │
│  02 · Stack de Tecnologia                            │
│  03 · Arquitetura                                    │
│  04 · Configuracao                                   │
│  05 · Sync de Dados (Leaguepedia)                    │
│  06 · Rotas                                          │
│  07 · Design System                                  │
│  08 · Deploy                                         │
│  09 · Times do Torneio                               │
└──────────────────────────────────────────────────────┘
```

---

## 01 · Quick Start

<details>
<summary><kbd>▶ Opcao 1: Docker (Recomendado)</kbd></summary>

```bash
# Subir app + Redis
docker-compose up

# Acessar
open http://localhost:3001

# Sincronizar dados da Leaguepedia
docker exec kings-lendas-app-1 bin/rails leaguepedia:sync
```

</details>

<details>
<summary><kbd>▶ Opcao 2: Local</kbd></summary>

```bash
# Instalar dependencias
bundle install

# Criar e migrar banco
bin/rails db:create db:migrate

# Sincronizar dados da API Leaguepedia
bin/rails leaguepedia:sync

# Subir servidor + Tailwind watch
bin/dev
# ou somente o servidor:
rails server -p 3001 -b 0.0.0.0

# Acessar
open http://localhost:3001
```

</details>

---

## 02 · Stack de Tecnologia

```
┌──────────────────────┬─────────────────────────────────────────────────────┐
│  Camada              │  Tecnologia                                         │
├──────────────────────┼─────────────────────────────────────────────────────┤
│  Framework           │  Ruby on Rails 8.0.4                                │
│  Ruby                │  3.4.5                                              │
│  Frontend            │  Hotwire (Turbo + Stimulus) — sem React             │
│  CSS                 │  TailwindCSS 4 com @theme custom tokens             │
│  Banco de dados      │  SQLite 3 (storage/development.sqlite3)             │
│  Busca full-text     │  SQLite FTS5 (lp_players_fts)                       │
│  Cache (dev)         │  MemoryStore                                        │
│  Cache (prod)        │  Redis 6+ (porta 6380, database /2)                 │
│  HTTP Client         │  Faraday + faraday-retry                            │
│  Fonte de dados      │  Leaguepedia CargoQuery API                         │
│  Assets CDN          │  DDragon (ícones de campeões)                       │
│  Deploy              │  Kamal + Docker                                     │
│  Linter              │  RuboCop (rubocop-rails-omakase)                    │
│  N+1 detection       │  Bullet gem                                         │
│  Security scan       │  Brakeman                                           │
└──────────────────────┴─────────────────────────────────────────────────────┘
```

---

## 03 · Arquitetura

```
app/
├── controllers/
│   ├── home_controller.rb          # Pagina inicial
│   ├── cup_controller.rb           # Kings Lendas Cup (copa atual)
│   ├── teams_controller.rb         # Lista e perfil de times
│   ├── players_controller.rb       # Perfil de jogadores
│   ├── seasons_controller.rb       # Seasons anteriores
│   └── api/                        # JSON endpoints para Turbo Frames
│       ├── standings_controller.rb
│       ├── matches_controller.rb
│       ├── players_controller.rb
│       ├── champions_controller.rb
│       ├── teams_controller.rb
│       └── games_controller.rb
├── models/
│   ├── lp_match.rb                 # Partidas sincronizadas
│   ├── lp_game.rb                  # Games individuais
│   ├── lp_player.rb                # Estatísticas de jogadores
│   └── lp_champion_stat.rb         # Estatísticas de campeões
├── services/
│   ├── leaguepedia_service.rb      # CargoQuery + winner resolution
│   ├── leaguepedia_sync_service.rb # Sync Leaguepedia → SQLite
│   ├── ddragon_service.rb          # URLs de ícones de campeões
│   └── cache_service.rb            # CacheService.fetch(key, ttl_key)
├── helpers/application_helper.rb   # team_logo, champion_icon, kda_color...
├── views/
│   ├── layouts/application.html.erb
│   ├── shared/                     # _navbar, _footer, _match_card
│   ├── home/, cup/, teams/, players/, seasons/
│   └── api/games/scoreboard.json.erb
└── javascript/controllers/
    ├── countdown_controller.js
    ├── match_accordion_controller.js
    ├── sort_table_controller.js
    ├── draft_filter_controller.js
    ├── tab_filter_controller.js
    └── mobile_nav_controller.js

config/
├── initializers/kings_lendas_teams.rb  # TEAMS_DATA, SEASONS_DATA, CACHE_TTLS
└── routes.rb                           # Rotas PT-BR
```

---

## 04 · Configuracao

### Variaveis de ambiente

```bash
# .env (desenvolvimento)
RAILS_ENV=development

# .env.production
RAILS_ENV=production
REDIS_URL=redis://localhost:6380/2
SECRET_KEY_BASE=...
```

### Cache

| Ambiente    | Store         | Detalhes                          |
|-------------|---------------|-----------------------------------|
| development | MemoryStore   | Rapido, sem dependencias externas |
| production  | Redis         | porta 6380, database /2           |

---

## 05 · Sync de Dados (Leaguepedia)

Os dados de partidas, games, jogadores e campeões são buscados da **Leaguepedia CargoQuery API** e persistidos no SQLite local.

```bash
# Sync completo (matches + games + players + champions)
bin/rails leaguepedia:sync

# Sync individual
bin/rails leaguepedia:sync_matches
bin/rails leaguepedia:sync_games
bin/rails leaguepedia:sync_players
bin/rails leaguepedia:sync_champions
```

**Observacoes criticas da API:**

```
- Campo DateTime_UTC na query → retorna como "DateTime UTC" (com espaco) → normalizado no service
- Campo Winner = "1" ou "2" (posicao do time, NAO o nome)
  → "1" resolve para Team1, "2" resolve para Team2
- ScoreboardGames com muitos campos retorna MWException → usar apenas campos essenciais
- Tables confirmadas: MatchSchedule, TournamentResults, ScoreboardPlayers,
  ChampionStatsFromScoreboardGames
- TournamentResults usa Tournament= (nao OverviewPage=)
- OverviewPage do torneio: "IDL Kings Lendas Cup"
```

Os controllers leem SQLite primeiro via `db_schedule`, `db_games`, `db_players`, `db_champions` (ApplicationController). Se o banco estiver vazio, chama a API e persiste automaticamente.

---

## 06 · Rotas

```
GET  /                          → Home (proximas partidas + classificacao)
GET  /copa                      → Kings Lendas Cup (overview)
GET  /copa/classificacao        → Tabela de pontos
GET  /copa/partidas             → Calendario de partidas
GET  /copa/picks-bans           → Draft tracker
GET  /copa/campeoes             → Estatísticas de campeões
GET  /copa/jogadores            → Lista de jogadores
GET  /copa/resultados           → Resultados

GET  /times                     → Lista de times
GET  /times/:slug               → Perfil do time

GET  /jogadores/:slug           → Perfil do jogador

GET  /temporadas                → Seasons anteriores
GET  /temporadas/:slug          → Detalhes da season

# API interna (JSON para Turbo Frames)
GET  /api/standings
GET  /api/matches
GET  /api/match/:id
GET  /api/players
GET  /api/player/:slug
GET  /api/champions
GET  /api/team/:slug
GET  /api/game/:id/scoreboard

GET  /up                        → Health check
```

---

## 07 · Design System

```
Cores (TailwindCSS @theme):
  --color-kl-gold:  #C89B3C   (dourado Kings Lendas)
  --color-kl-teal:  #0596AA   (teal accent)
  --color-kl-bg:    #0A0E1A   (fundo escuro)

Classes utilitarias:
  .card-glass          → card com glassmorphism
  .hover-lift          → elevacao no hover
  .text-gradient-gold  → texto com gradiente dourado

Fontes:
  Inter (Google Fonts)

Icones:
  Remix Icons (CDN)

Campeoes:
  DDragon CDN — versao atual: 16.5.1
```

---

## 08 · Deploy

Deploy via **Kamal** com Docker.

```bash
# Build da imagem
docker build -f Dockerfile.production -t kings-lendas .

# Deploy com Kamal
kamal deploy

# Variaveis de producao em .kamal/secrets
```

O `docker-compose.yml` usa `Dockerfile.dev` em desenvolvimento, com volume `sqlite_data` montado em `/rails/storage` para persistencia do banco.

---

## 09 · Times do Torneio

### Kings Lendas Cup 2026

| Time            | Abrev | Capitao   | Slug            |
|-----------------|-------|-----------|-----------------|
| Team Sobe Muro  | TSM   | ManaJJ    | team-sobe-muro  |
| SKTenis         | SKT   | YeTz      | sktenis         |
| Mad Mylons      | MAD   | Mylon     | mad-mylons      |
| Vos Grandes     | VG    | Absolut   | vos-grandes     |
| Karmine Cospe   | KC    | Shini     | karmine-cospe   |
| Gen GG          | GEN   | EsA       | gen-gg          |

### Seasons Anteriores

| Season   | Campeo         | Leaguepedia                   |
|----------|----------------|-------------------------------|
| Season 1 | —              | IDL_Kings_Lendas              |
| Season 2 | Karmine Cospe  | IDL_Kings_Lendas_Season_2     |
| Season 3 | Gen GG         | IDL_Kings_Lendas_Season_3     |

---

### Streams do Baiano

| Plataforma | Canal                              |
|------------|------------------------------------|
| Kick       | kick.com/BaianoTV                  |
| Twitch     | twitch.tv/baiano                   |
| YouTube    | @BaianoTV1                         |

---

<div align="center">

Feito com Ruby on Rails para a comunidade IDL Kings Lendas.

</div>
