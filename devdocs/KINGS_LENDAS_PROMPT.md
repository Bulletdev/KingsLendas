# KingsLendas.com — Prompt de Desenvolvimento

> Domínio: **kingslendas.com**
> Stack: **Ruby on Rails 8 + Turbo + Stimulus** (frontend, sem banco de dados próprio)
> Objetivo: Site oficial de estatísticas e acompanhamento do torneio **IDL Kings Lendas**

---

## O que é o Kings Lendas

O **IDL Kings Lendas** é um torneio de League of Legends organizado pela **Ilha das Lendas** (IDL), criado por **Baiano (Gustavo Gomes)**. Inspirado no formato da Kings League (futebol), mistura jogadores profissionais do CBLOL, streamers e amadores numa competição comunitária com identidade própria e muita personalidade.

**Características únicas:**
- Times com nomes paródia de equipes famosas do LoL mundial (TSM → Team Sobe Muro, SKT → SKTenis, MAD Lions → Mad Mylons, Karmine Corp → Karmine Cospe, Gen.G → Gen GG, etc.)
- Cada time tem um **capitão/presidente** — geralmente um streamer ou ex-pro
- **Fearless Draft** nos playoffs (campeão escolhido não pode ser repetido na série)
- Escolha de lado definida por duelo **1v1** antes da partida
- Streamed no **Kick, Twitch e YouTube** do Baiano (BaianoTV)
- Premiação: **R$ 50.000**

**Histório de temporadas:**
- **Season 1** — Primeira edição
- **Season 2** — Campeão: Karmine Cospe
- **Season 3** — Campeão: Gen GG (10 times)
- **Kings Lendas Cup** ← **foco atual** (off-season, 6 times, 06–15/Mar/2026)

---

## Times e Rosters — Kings Lendas Cup (2026)

> Início: 06/03/2026 | Fim: 15/03/2026 | Premiação: R$ 50.000

### 1. Team Sobe Muro (TSM)
**Capitão:** ManaJJ
| Role | Jogador |
|------|---------|
| Top | Ayel |
| Jungle | Aegis |
| Mid | Grevthar |
| Bot | ManaJJ |
| Support | Zay |
| Coach | Takeshi |

### 2. SKTenis (SKT)
**Capitão:** YeTz
| Role | Jogador |
|------|---------|
| Top | Pijack |
| Jungle | Sarolu |
| Mid | YeTz |
| Bot | Kojima |
| Support | Konseki |
| Coach | Revolta |

### 3. Mad Mylons (MAD)
**Capitão:** Mylon
| Role | Jogador |
|------|---------|
| Top | Mylon |
| Jungle | Scary |
| Mid | Qats |
| Bot | Buerinho |
| Support | Guiggs |
| Coach | Turtle / Portugal |

### 4. Vôs Grandes (VG)
**Capitão:** Absolut
| Role | Jogador |
|------|---------|
| Top | Makes |
| Jungle | Randal |
| Mid | Piloto |
| Bot | Absolut |
| Support | Bulecha |

### 5. Karmine Cospe (KC)
**Capitão:** Shini
| Role | Jogador |
|------|---------|
| Top | Zekas |
| Jungle | Shini |
| Mid | Leleko |
| Bot | MicaO |
| Support | Scamber |
| Coach | Trigo |

### 6. Gen GG (GEN)
**Capitão:** EsA
| Role | Jogador |
|------|---------|
| Top | Yupps |
| Jungle | Dizin |
| Mid | Hauz |
| Bot | Netuno |
| Support | HamburguesA |
| Coach | Brucer |

---

## Formato do Torneio

### Kings Lendas Cup
```
Fase de Grupos (Round Robin — Bo1)
  └─ Top 2 → Playoffs Semifinais
  └─ Demais → Playoffs Quartas de Final

Playoffs (Eliminação Simples)
  ├─ Quartas: Bo3 (Fearless Draft)
  ├─ Semis:   Bo3 (Fearless Draft)
  └─ Final:   Bo5 (Fearless Draft)
```

**Draft especial:**
- Escolha de lado por duelo 1v1 antes de cada partida
- Fearless Draft: campeão usado em game anterior da série fica bloqueado

---

## Stack Técnica

```
Ruby on Rails 8.x
  ├── Turbo (Hotwire)  — navegação SPA-like, Turbo Frames lazy
  ├── Stimulus.js      — interatividade declarativa
  ├── Propshaft        — asset pipeline
  ├── TailwindCSS 4    — utility classes
  ├── Redis            — cache de respostas de API
  └── Faraday          — HTTP client para Leaguepedia API
```

**Sem banco de dados próprio.** Toda persistência via cache Redis (TTL por endpoint).
Dados vindos da **Leaguepedia (MediaWiki CargoQuery API)** — mesmo fonte do Leaguepedia.

---

## Fonte de Dados: Leaguepedia CargoQuery API

```
Base: https://lol.fandom.com/api.php
Método: GET
Parâmetros principais:
  action=cargoquery
  format=json
  tables=TABLE
  fields=FIELDS
  where=CONDITION
  limit=N
```

### Endpoints úteis para o Kings Lendas

```
# Torneios da liga IDL Kings Lendas
?action=cargoquery&tables=Tournaments&fields=Name,DateStart,Date,League,Region,Teams,Prizepool
&where=League="IDL Kings Lendas"&format=json

# Standings (classificação)
?action=cargoquery&tables=TournamentResults&fields=Team,Place,Wins,Losses,Ties
&where=Tournament="IDL Kings Lendas Cup"&format=json

# Partidas agendadas
?action=cargoquery&tables=MatchSchedule&fields=Team1,Team2,DateTime_UTC,BestOf,Winner,Team1Score,Team2Score
&where=OverviewPage="IDL Kings Lendas Cup"&format=json

# Resultados de partidas (scoreboard por game)
?action=cargoquery&tables=ScoreboardGames&fields=Tournament,Team1,Team2,Winner,Gamelength,Team1Picks,Team2Picks,Team1Bans,Team2Bans,Team1Gold,Team2Gold,Team1Kills,Team2Kills
&where=Tournament="IDL Kings Lendas Cup"&format=json&limit=500

# Stats individuais por game
?action=cargoquery&tables=ScoreboardPlayers&fields=Link,Champion,Kills,Deaths,Assists,CS,Gold,DamageToChampions,VisionScore,SummonerSpells,Items
&where=Tournament="IDL Kings Lendas Cup"&format=json&limit=500

# Rosters dos times
?action=cargoquery&tables=TournamentPlayers&fields=Player,Team,Role,IsSubstitute
&where=OverviewPage="IDL Kings Lendas Cup"&format=json

# Stats de campeões
?action=cargoquery&tables=ChampionStatsFromScoreboardGames&fields=Champion,Picks,Bans,Wins,Games
&where=OverviewPage="IDL Kings Lendas Cup"&format=json
```

### DDragon (imagens de campeões/itens)
```
Versão: https://ddragon.leagueoflegends.com/api/versions.json
Campeão: https://ddragon.leagueoflegends.com/cdn/{version}/img/champion/{key}.png
Item:    https://ddragon.leagueoflegends.com/cdn/{version}/img/item/{id}.png
```

---

## Design System (baseado em prostaff-analytics-hub)

### Paleta de Cores

```css
/* Dark theme */
--background:    #0A0E1A;   /* hsl(220 27% 10%) */
--card:          #0F1823;   /* hsl(216 23% 11%) */
--foreground:    #FFFFFF;

/* Brand Kings Lendas */
--lol-gold:      #C89B3C;   /* primary — LoL Gold */
--lol-blue:      #0C223F;   /* secondary — LoL Blue */
--teal:          #0596AA;   /* accent */

/* Status partida */
--win:           #00D364;   /* vitória */
--loss:          #FF4444;   /* derrota */
--warning:       #F59E0B;
--border:        hsl(216 13% 20%);
```

### Tipografia
- **Fonte principal**: `Inter` (300–700, via @font-face)
- **Headings**: Bold 700, letter-spacing -0.02em
- **Body**: Medium 500, line-height 1.75

### Componentes Retro-UI

```css
/* Glass card (igual prostaff) */
.card-glass     { bg-card/80 backdrop-blur-sm border-border/50 }

/* Hover effects */
.hover-lift     { transition 300ms; hover: translate3d(0,-4px,0) + shadow-xl }
.hover-scale    { transition 300ms; hover: scale3d(1.05,1.05,1) }
.hover-glow     { hover: shadow-[0_0_30px_hsl(var(--primary)/0.3)] }

/* Status de partida */
.win-badge      { background: var(--win);  color: #000; }
.loss-badge     { background: var(--loss); color: #fff; }
.live-badge     { background: #FF4444; animation: live-pulse 2s infinite; }

/* Gradientes Kings Lendas */
.gold-gradient  { background: linear-gradient(135deg, #C89B3C 0%, #F0E6D2 50%, #C89B3C 100%) }
.blue-gradient  { background: linear-gradient(135deg, #0C223F 0%, #0596AA 100%) }

/* Background body com overlay (igual prostaff) */
body {
  background-image: url('/backgrounds/kings-lendas-bg.webp');
  background-size: cover;
  background-attachment: fixed;
}
body::before {
  content: '';
  position: fixed; inset: 0;
  background: rgba(8, 14, 26, 0.65);
  z-index: 0;
}
```

**Referência completa de CSS:** `/home/bullet/PROJETOS/prostaff-analytics-hub/src/index.css`

---

## Arquitetura de Rotas (Rails 8)

```ruby
Rails.application.routes.draw do
  root "home#index"

  # Kings Lendas Cup (torneio atual)
  get "/copa",              to: "cup#index",      as: :cup
  get "/copa/classificacao",to: "cup#standings",  as: :cup_standings
  get "/copa/partidas",     to: "cup#matches",    as: :cup_matches
  get "/copa/picks-bans",   to: "cup#draft",      as: :cup_draft
  get "/copa/campeoes",     to: "cup#champions",  as: :cup_champions
  get "/copa/jogadores",    to: "cup#players",    as: :cup_players

  # Times
  get "/times",             to: "teams#index",    as: :teams
  get "/times/:slug",       to: "teams#show",     as: :team

  # Jogadores
  get "/jogadores/:slug",   to: "players#show",   as: :player

  # Seasons anteriores
  get "/temporadas",        to: "seasons#index",  as: :seasons
  get "/temporadas/:slug",  to: "seasons#show",   as: :season  # season-1, season-2, season-3

  # Draft stats
  get "/draft",             to: "draft#index",    as: :draft

  # API interna (JSON para Turbo Frames)
  namespace :api do
    get "standings",        to: "standings#index"
    get "matches",          to: "matches#index"
    get "match/:id",        to: "matches#show"
    get "players",          to: "players#index"
    get "player/:slug",     to: "players#show"
    get "champions",        to: "champions#index"
    get "team/:slug",       to: "teams#show"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

---

## Páginas e Funcionalidades

### Home (`/`)
- Hero com logo Kings Lendas + próxima partida com countdown
- **Fase atual** do torneio (status: Grupos / Quartas / Semis / Final)
- Classificação rápida (top 3 + posições)
- Últimos resultados (3 partidas)
- "Stat do torneio" (jogador com mais kills, melhor KDA, mais assistências)
- Banner "Assista ao vivo" → links Kick/Twitch/YouTube do Baiano

**Stimulus:** `countdown-controller`, `live-banner-controller`

---

### Copa — Visão Geral (`/copa`)
Overview completo da Kings Lendas Cup:
- Infobox do torneio (datas, premiação, formato)
- Tabela de classificação grupos
- Bracket de playoffs
- Últimas partidas
- Navegação para sub-páginas

---

### Classificação (`/copa/classificacao`)

| # | Time (logo + nome) | Capitão | V | D | % Vitória | Forma (últimas 5) |
|---|---|---|---|---|---|---|

- Indicadores visuais: 🟢 zona de semifinal direto, 🟡 quartas de final
- Hover no time: mini-card com capitão + roster resumido
- Forma: badges coloridas **W** (verde) / **L** (vermelho)

**Stimulus:** `standings-hover-controller`

---

### Partidas (`/copa/partidas`)

Tabs: `Todas` | `Grupos` | `Playoffs`

Cards de partida:
```
[Logo TSM] Team Sobe Muro  vs  Gen GG [Logo GEN]
           ManaJJ (cap)       EsA (cap)
           [DATA/HORA BRT]    [FORMATO: Bo1]
           [RESULTADO: 1-0 se concluído]
```

Expandir game → stats do game (Turbo Frame lazy):
- Duração, kills por time, dragões, barões, torres
- Picks & bans com imagens DDragon
- Tabela de jogadores: Campeão | K/D/A | CS | Dano | Visão

**Stimulus:** `match-accordion-controller`

---

### Picks & Bans (`/copa/picks-bans`)

- Top 10 campeões mais picks com imagem + Pick%, Win%, Ban%
- Top 10 mais banidos
- Tabela completa ordenável
- Filtro por time (ver o que cada time prefere picar/banear)
- Composition winrate (combos de 2+ campeões)

**Stimulus:** `draft-filter-controller`, `sort-table-controller`

---

### Campeões (`/copa/campeoes`)

Grid visual com imagens DDragon:
- Ordenar por: Picks, Bans, Aparições, Win%
- Filtro por role (top/jungle/mid/adc/sup)
- Página individual: quem joga, quando foi jogado, resultados

---

### Jogadores (`/copa/jogadores`)

Tabela de stats individuais:
| Jogador | Time | Role | Partidas | KDA | Kills | Deaths | Assists | CS/min | Gold/min | Campeões |
|---|---|---|---|---|---|---|---|---|---|---|

- Ordenação por qualquer coluna
- Clique → perfil do jogador

---

### Perfil de Jogador (`/jogadores/:slug`)

- Avatar + nick + time + role + capitão? (badge especial)
- **Stats agregados:** Partidas, W/L, Win%, KDA, Méd. K/D/A, Méd. CS
- **Por campeão:**

| Campeão (img) | Jogos | Win% | KDA | KP% | Méd. CS |
|---|---|---|---|---|---|

- **Histórico de partidas:** resultado, adversário, campeão, K/D/A, CS, duração

---

### Perfil de Time (`/times/:slug`)

- Header: logo + nome + abreviação (TSM, SKT, etc.) + capitão
- **Roster** com foto/avatar dos jogadores + roles
- **Record:** V/D, Win%, série atual
- **Histórico de partidas**
- **Picks favoritos** (top 5 campeões do time)
- **Bans favoritos** (top 5 bans do time)

---

### Temporadas (`/temporadas`)

Lista das seasons passadas com link para detalhes:
- Season 1, Season 2 (campeão: Karmine Cospe), Season 3 (campeão: Gen GG)
- Cada season com: formato, times, resultados, campeão

---

## Estrutura de Arquivos Rails 8

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── home_controller.rb
│   ├── cup_controller.rb
│   ├── teams_controller.rb
│   ├── players_controller.rb
│   ├── seasons_controller.rb
│   ├── draft_controller.rb
│   └── api/
│       ├── standings_controller.rb
│       ├── matches_controller.rb
│       ├── players_controller.rb
│       ├── champions_controller.rb
│       └── teams_controller.rb
│
├── services/
│   ├── leaguepedia_service.rb        # CargoQuery API client (Faraday)
│   ├── ddragon_service.rb            # DDragon assets (imagens de campeões/itens)
│   └── cache_service.rb              # Redis wrapper com TTLs
│
├── views/
│   ├── layouts/
│   │   └── application.html.erb      # navbar + footer + Turbo
│   ├── shared/
│   │   ├── _navbar.html.erb
│   │   ├── _footer.html.erb
│   │   ├── _match_card.html.erb
│   │   ├── _team_card.html.erb
│   │   ├── _player_row.html.erb
│   │   ├── _champion_icon.html.erb
│   │   └── _win_loss_badge.html.erb
│   ├── home/index.html.erb
│   ├── cup/
│   │   ├── index.html.erb
│   │   ├── standings.html.erb
│   │   ├── matches.html.erb
│   │   ├── draft.html.erb
│   │   ├── champions.html.erb
│   │   └── players.html.erb
│   ├── teams/
│   │   ├── index.html.erb
│   │   └── show.html.erb
│   ├── players/show.html.erb
│   └── seasons/
│       ├── index.html.erb
│       └── show.html.erb
│
└── javascript/controllers/
    ├── countdown_controller.js       # countdown até próxima partida
    ├── match_accordion_controller.js # expandir stats do game
    ├── draft_filter_controller.js    # filtrar picks/bans por time
    ├── sort_table_controller.js      # ordenar tabelas
    ├── standings_hover_controller.js # hover no time → mini-card
    └── theme_controller.js           # toggle tema (futuro)
```

---

## Cache Strategy (Redis)

```ruby
CACHE_TTLS = {
  standings:      10.minutes,
  schedule:       5.minutes,
  match_details:  1.hour,
  player_stats:   30.minutes,
  team_profile:   30.minutes,
  draft_stats:    1.hour,
  champion_stats: 1.hour,
  ddragon_version: 7.days,
  ddragon_assets:  7.days
}.freeze
```

**Graceful degradation:** se a API falhar, mostrar dados do cache (mesmo que expirado) + badge "Dados podem estar desatualizados".

---

## Gemfile

```ruby
gem "rails", "~> 8.0"
gem "propshaft"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "redis", "~> 5.0"
gem "faraday"          # HTTP client
gem "faraday-retry"    # Retry automático com backoff
gem "oj"               # JSON parsing rápido
gem "meta-tags"        # SEO og:title, og:image, etc.

group :development, :test do
  gem "debug"
  gem "brakeman"
  gem "rubocop-rails-omakase"
end
```

---

## Componentes Stimulus Chave

### Countdown para próxima partida

```javascript
// countdown_controller.js
export default class extends Controller {
  static values = { target: String }  // ISO datetime string

  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  tick() {
    const diff = new Date(this.targetValue) - new Date()
    if (diff <= 0) {
      this.element.textContent = "AO VIVO"
      this.element.classList.add("text-red-500", "animate-pulse")
      clearInterval(this.timer)
      return
    }
    const h = Math.floor(diff / 3600000)
    const m = Math.floor((diff % 3600000) / 60000)
    const s = Math.floor((diff % 60000) / 1000)
    this.element.textContent = `${h}h ${m}m ${s}s`
  }

  disconnect() { clearInterval(this.timer) }
}
```

### Accordion de stats do game

```javascript
// match_accordion_controller.js
export default class extends Controller {
  static targets = ["content", "icon"]

  toggle() {
    const frame = this.contentTarget.querySelector("turbo-frame")
    if (this.contentTarget.classList.toggle("hidden")) {
      this.iconTarget.textContent = "▼"
    } else {
      this.iconTarget.textContent = "▲"
      if (!frame.src) frame.src = frame.dataset.lazySrc
    }
  }
}
```

---

## Mapeamento de Times (todas as seasons)

```ruby
# config/kings_lendas_teams.rb
TEAMS = {
  # Kings Lendas Cup 2026
  "Team Sobe Muro"  => { abbr: "TSM", parody_of: "TSM",         color: "#0057B8" },
  "SKTenis"         => { abbr: "SKT", parody_of: "T1/SKT",      color: "#FF0000" },
  "Mad Mylons"      => { abbr: "MAD", parody_of: "MAD Lions",   color: "#00A0DC" },
  "Vôs Grandes"     => { abbr: "VG",  parody_of: "Los Grandes", color: "#FF6600" },
  "Karmine Cospe"   => { abbr: "KC",  parody_of: "Karmine Corp",color: "#00D4FF" },
  "Gen GG"          => { abbr: "GEN", parody_of: "Gen.G",       color: "#B8860B" },

  # Season 3 (times adicionais)
  "100Vices"        => { abbr: "100", parody_of: "100 Thieves", color: "#E63946" },
  "FONatic"         => { abbr: "FNC", parody_of: "Fnatic",      color: "#FF8C00" },
  "G12 Esports"     => { abbr: "G12", parody_of: "G2 Esports",  color: "#00FF87" },
  "Oreiudos Esports"=> { abbr: "ORE", parody_of: "Cloud9",      color: "#1DA1F2" },
  "paiNtriotas"     => { abbr: "PNG", parody_of: "paiN Gaming", color: "#7B2D8B" },
  "Tepei Assassins" => { abbr: "TEP", parody_of: "Team Liquid",  color: "#009FDA" },
  "ÉanDG"           => { abbr: "EDG", parody_of: "EDward Gaming",color: "#FF4500" },
}.freeze
```

---

## Leaguepedia Sub-pages (para referência de dados)

A wiki da Leaguepedia documenta o torneio completo:
- `IDL_Kings_Lendas_Cup/Team_Rosters` — rosters
- `IDL_Kings_Lendas_Cup/Picks_and_Bans` — draft stats
- `IDL_Kings_Lendas_Cup/Scoreboards` — scoreboards por game
- `IDL_Kings_Lendas_Cup/Match_History` — histórico de partidas
- `IDL_Kings_Lendas_Cup/Champion_Statistics` — stats de campeões
- `IDL_Kings_Lendas_Cup/Player_Statistics` — stats individuais

Imagem oficial do torneio:
`https://static.wikia.nocookie.net/lolesports_gamepedia_en/images/a/a3/Kings_Lendas_Cup.png`

---

## Fases de Desenvolvimento

### Fase 1 — Setup & Estrutura
- [ ] `rails new kingslendas --css tailwind --javascript importmap`
- [ ] Configurar Redis para cache
- [ ] `LeaguepediaService` com Faraday + retry
- [ ] `DDragonService` para imagens de campeões
- [ ] `CacheService` wrapper com TTLs
- [ ] Design tokens Tailwind (LoL gold, blue, teal)
- [ ] Layout base: navbar (logo + links) + footer (social links do Baiano)

### Fase 2 — Copa (foco atual)
- [ ] Home com próxima partida + classificação resumida
- [ ] `/copa` overview
- [ ] `/copa/classificacao` — standings completo
- [ ] `/copa/partidas` — schedule + resultados com accordion de stats
- [ ] Deploy inicial → kingslendas.com

### Fase 3 — Profiles & Draft
- [ ] Perfis de times com roster completo
- [ ] Perfis de jogadores com stats por campeão
- [ ] `/copa/picks-bans` com imagens DDragon
- [ ] `/copa/campeoes` grid visual

### Fase 4 — Seasons passadas
- [ ] `/temporadas` com Season 1, 2, 3
- [ ] Reutilizar componentes com parâmetro `tournament`

### Fase 5 — Polish
- [ ] SEO (meta tags, og:image usando logo do Kings Lendas)
- [ ] PWA manifest
- [ ] Performance: turbo prefetch, lazy images
- [ ] Mobile responsivo completo

---

## Notas Importantes

1. **Sem autenticação** — site público, read-only
2. **Cache agressivo** — respeitar rate limits da Leaguepedia API
3. **Horário:** sempre America/Sao_Paulo (UTC-3)
4. **Imagens de jogadores:** não disponíveis na Leaguepedia, usar avatar placeholder com iniciais + cor do time
5. **Fearless Draft:** lógica especial para exibir quais campeões estão bloqueados em cada game de uma série
6. **1v1:** registrar resultado do duelo 1v1 se disponível nos dados
7. **Meme/humor:** o torneio tem personalidade cômica — o site pode ter easter eggs e referências aos nomes paródia dos times
8. **Leaguepedia table names** podem variar — confirmar com `?action=ask&query=[[Category:Cargo tables]]` se necessário

---

## Streams e Redes Sociais (para footer/links)

```
Kick:      http://kick.com/BaianoTV
Twitch:    https://twitch.tv/baiano
YouTube:   https://youtube.com/@BaianoTV1/live
Instagram: https://instagram.com/ilhadaslendas
Twitter/X: https://x.com/ilhadaslendas
```
