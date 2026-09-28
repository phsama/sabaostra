# Spec Técnica: Sabaostra (fatia vertical)

28/09/2026 · @Ph

> Transcrição em Markdown do PDF "Spec Técnica Sabaostra (fatia vertical)" para o agente ler no repo. Decisões aprovadas depois da versão original ficam registradas no fim, em "Registro de decisões", e o texto acima delas já reflete cada uma.

## Objetivo

A fatia vertical são 15 a 20 minutos jogáveis do começo ao fim sem tocar no código: apartamento, praia, arredores da vila, a mãe e o pescador, um confronto de palavras, uma transição de mapa e save. Ela existe para validar o pipeline inteiro (Godot, diálogo, marcadores, resposta da ilha, arte gerada, áudio) antes de qualquer conteúdo do ato 2. A bíblia do projeto é a fonte de toda decisão de design; esta spec só diz como construir.

Entrega da fatia:

- **Apartamento:** três ou quatro escolhas banais em diálogo com a mãe que ajustam níveis iniciais do pescador e da princesa sem aviso. A mãe chama o protagonista, uma vez, pelo nome da ilha. Ele dorme no sofá.
- **Praia:** acorda; o pescador; diálogo com escolhas; a caixa de diálogo tinge pelo estado dele; um confronto de palavras com o pescador; a paleta da praia responde ao medo dele.
- **Arredores da vila:** transição com fade, autosave, a vila ao longe, fim da fatia.
- **Menu:** novo jogo, continuar, três slots, idioma PT-BR ou EN.

Fica de fora: vilas, taverna, casas, rival, princesa em cena, flashbacks, puzzles, temas musicais finais, Steam. Cada um desses entra como marco próprio depois do portão.

**Portão da fatia** (o da bíblia mais o técnico): o Ph joga do início ao fim sem tocar no código e a arte tem a cara que ele quer; todos os testes verdes; smoke headless de todos os mapas passa; build exporta para Windows e Linux.

## Princípios de engenharia (obrigatórios)

Menos é mais. O agente escreve o mínimo de código que resolve a tarefa, com os padrões que o Godot já oferece, e prova que funciona com teste antes de seguir. Estes dez pontos não são sugestão; tarefa que viola um deles volta.

1. **Patterns reais de mercado, não invenções.** Composição por cena e nós; sinais para desacoplar; Resources para dados; autoloads só para estado global de verdade, no máximo três. Nada de framework próprio, event bus genérico, service locator, ECS ou "manager" de tudo.
2. **Menos é mais.** Sem abstração antes do terceiro uso. Sem camada, interface ou classe base preventiva. Se um nó do Godot faz, não se escreve script. Apagar código vale tanto quanto escrever.
3. **Sem verborragia.** Funções curtas com nome que diz o que fazem. Sem comentário que repete o código, sem docstring decorativa, sem print de debug esquecido, sem README por pasta.
4. **Sem empilhar conceitos.** Um conceito novo por tarefa. Addon, padrão ou dependência só entram quando a tarefa pede, e entram como decisão registrada nesta spec, nunca como commit silencioso.
5. **Testar sempre.** Toda lógica sem nó (estado, marcadores, save, humor do mapa) nasce com teste unitário. Toda cena tem smoke test headless. Tarefa sem teste verde não está pronta.
6. **GDScript tipado em tudo, com warnings tratados como erro.** Nomes de código em inglês; conteúdo em PT-BR nos arquivos de diálogo e de localização.
7. **Pequeno e reversível.** Um commit por tarefa do backlog, mensagem que diz o porquê. Nada de refactor de passagem; se algo pede refactor, vira tarefa.
8. **Perguntar antes de assumir.** Ambiguidade na spec vira pergunta ao Ph, não decisão do agente. Se a spec contradiz a bíblia, a bíblia vence e o agente avisa.
9. **Performance não é prioridade.** 320x180 com poucos nós; otimização só com medição que prove o problema.
10. **Conteúdo fora do código.** Diálogos, perfis de NPC e textos vivem em arquivos de dados. O código não conhece nome de personagem.

## Stack e versões

Godot 4.7.2 stable, GDScript tipado, Dialogue Manager 4 para diálogo, gdUnit4 para testes, GitHub Actions para CI. Nada além disso entra na fatia.

| Componente | Escolha | Versão e nota |
|---|---|---|
| Engine | Godot 4.7.2 stable | última stable em set/2026 (o 4.7 saiu em 18/06/2026; ver Registro de decisões). Não usar a 4.8 dev. Renderer Compatibility (OpenGL): 2D leve e build pequeno |
| Linguagem | GDScript com tipagem estática | sem C#, sem GDExtension |
| Diálogo | Dialogue Manager 4 | arquivos `.dialogue` em texto; escolhas, condições e mutações nativas; localização por exportação de CSV; exige Godot 4.6+ |
| Testes | gdUnit4 6.2.1 | unitário e de cena, roda headless; CI com a gdUnit4-action; addon vendorizado em `addons/gdUnit4` |
| Versionamento | Git + GitHub | `.gitignore` padrão Godot; sem LFS por enquanto (pixel art é pequena) |
| Arte | Aseprite (exporta PNG e sprite sheets); PixelLab ou Retro Diffusion a montante | ver Direção de arte na bíblia |
| Áudio | Suno para loops e temas; ElevenLabs ou bibliotecas livres para efeitos | música em OGG Vorbis com loop; efeitos em WAV mono |
| Fonte | m5x7 ou similar de licença livre | conferir cobertura de acentos do PT-BR antes de adotar |
| Agente no editor | godot-mcp (aberto) | opcional; serve para o Claude Code rodar o projeto e ler o output. Desligar auto-reload de scripts durante a sessão |
| Steam | GodotSteam | só na fase beta; fora da fatia |

## Arquitetura

Três autoloads (`StoryState`, `SceneRouter`, `SaveService`), um mapa por cena, NPCs por composição e o Dialogue Manager como único sistema de conversa, inclusive para o confronto. Nada se fala por referência direta entre cenas; o que precisa atravessar cena passa por sinal do `StoryState` ou por chamada ao `SceneRouter`.

O menu só fala com o `SceneRouter` e o `SaveService`. Dentro do mapa, o `Player` interage com o NPC, o NPC abre o balão, o balão ajusta o `StoryState`, e o `StoryState` avisa o `MapMood` por sinal. O `MapExit` pede a troca ao `SceneRouter`, que salva pelo `SaveService`.

```
Menu ──► SceneRouter ◄── MapExit
  │          │
  └──► SaveService ◄─┘ (autosave na troca)

Player ─► NPC (Interactable) ─► balão (Dialogue Manager) ─► StoryState.adjust()
                                                              │ marker_changed
                                                              ▼
                                                           MapMood
```

Estrutura de pastas (código em `src`, conteúdo em `content`, arte e som em `assets`, testes em `tests`):

```
res://
  addons/            dialogue_manager, gdUnit4 (sem modificações locais)
  src/
    autoload/        story_state.gd, scene_router.gd, save_service.gd
    player/          player.tscn, player.gd
    npc/             npc.tscn, npc.gd, npc_profile.gd (Resource), interactable.gd
    dialogue/        balloon.tscn, balloon.gd
    map/             map_mood.gd, map_exit.gd, spawn_point.gd
    ui/              main_menu.tscn, save_slots.tscn, options.tscn
  content/
    dialogue/        apartment.dialogue, beach.dialogue, outskirts.dialogue
    profiles/        mae.tres, pescador.tres, princesa.tres
    maps/            apartment.tscn, beach.tscn, outskirts.tscn
    locale/          dialogue_pt_BR.csv, ui.csv
  assets/
    palette/         sabaostra.gpl (32 cores, fonte da verdade)
    sprites/  tilesets/  portraits/  ui/  fonts/  audio/music  audio/sfx
  tests/
    unit/            story_state_test.gd, save_service_test.gd, map_mood_test.gd
    scene/           maps_smoke_test.gd, dialogue_compile_test.gd
  .github/workflows/ci.yml
```

Regras da estrutura: um mapa é uma cena inteira e autossuficiente (TileMapLayers, Player, NPCs, MapMood, SpawnPoints, MapExits); não existe cena base de mapa com herança, existe composição de nós pequenos. O Player é instanciado dentro de cada mapa, não carregado por cima. Os autoloads não conhecem nós de cena; só emitem sinais e respondem a chamadas.

## Modelo de dados

Um dicionário de flags, um dicionário de marcadores por NPC e um Resource por personagem. O save é esse estado em JSON. Não existe classe de "entidade", ORM, nem cache.

| Objeto | Onde vive | Campos | Regras |
|---|---|---|---|
| StoryState (autoload) | `src/autoload/story_state.gd` | `flags: Dictionary[String, Variant]`; `markers: Dictionary[String, Dictionary]` (npc_id para `{friendship, trust, fear}` inteiros) | `adjust(npc_id, marker, delta)` soma e trava entre 1 e 5; `get_marker(npc_id, marker) -> int`; `set_flag`, `has_flag`; sinal `marker_changed(npc_id, marker, value)`; `to_dict()` e `from_dict()`; `new_game(profiles)` carrega os níveis iniciais dos Resources |
| NpcProfile (Resource) | `content/profiles/*.tres`, script em `src/npc/npc_profile.gd` | `id`, `display_name` (chave de tradução), `friendship`, `trust`, `fear` iniciais, `portrait: Texture2D`, `blip: AudioStream`, `dialogue: DialogueResource`, `start_title` | `id` em snake_case ASCII (`mae`, `pescador`, `princesa`); nenhum número de marcador fica em código |
| Estado do balão | calculado em `balloon.gd` | `tone` de 0 a 1 a partir de `trust` e `fear` do NPC em cena | função estática pura, testável: quente com confiança alta, fria com medo alto |
| Humor do mapa | calculado em `map_mood.gd` | `npc_ids` exportados; `coldness` de 0 a 1 = média do medo dos NPCs do mapa normalizada; `time_of_day` (`day`, `night`) recebido do SceneRouter | função estática pura para a conta; o nó só aplica |
| Save | `user://saves/slot_1.json` a `slot_3.json` e `user://saves/autosave.json` | `version`, `saved_at`, `map_id`, `spawn_id`, `playtime_sec`, `story_state` (o `to_dict()`) | JSON legível, sem criptografia; `version` inteiro; save com versão desconhecida é recusado com mensagem, nunca migrado em silêncio na fatia |

As escolhas do apartamento não têm camada própria de mapeamento: a mutação é feita direto no arquivo de diálogo (`do StoryState.adjust("pescador", "trust", 1)`). Se um dia houver dezenas de sementes, aí se cria a tabela. Antes disso, não.

## Sistemas da fatia

Sete sistemas, cada um com comportamento e critério de aceite. O confronto de palavras não é sistema: é um modo do balão.

| Sistema | Comportamento | Aceite |
|---|---|---|
| Jogador | grade de 16 px, 4 direções, um tween por passo, correr segurando `run`; input map: `move_up/down/left/right`, `interact`, `cancel`, `run`, `menu`; trava durante diálogo e transição; sprite 16x32 com 4 frames por direção | anda e para alinhado à grade; não atravessa colisão; não se move com balão aberto |
| Interação | `Interactable` (Area2D) com sinal `interacted`; o jogador tem uma Area2D na direção em que olha e, ao apertar `interact`, chama o mais próximo | um NPC responde ao apertar `interact` de frente; nada responde de lado ou de costas |
| NPC | cena `npc.tscn` = Sprite2D + Interactable + `NpcProfile` exportado; ao interagir chama `DialogueManager.show_dialogue_balloon(profile.dialogue, profile.start_title, [profile])` | trocar o `.tres` troca personagem, retrato, blip e diálogo sem tocar em código |
| Diálogo | Dialogue Manager com balão próprio (`balloon.tscn`, estilo SNES em 320x180): texto letra a letra, retrato opcional, escolhas de 2 a 3; mutações `StoryState.adjust(...)`; condições `if StoryState.get_marker(...) >= n`; a cor da borda e do fundo vem de `tone`; blip por perfil | um `.dialogue` com escolha muda um marcador e a mudança aparece no save; a cor do balão muda entre um NPC que confia e um que teme |
| Confronto de palavras | um título no `.dialogue` marcado com a tag `#confront`; o balão troca a moldura e o ritmo do texto, sem HP, sem menu novo; 3 a 5 rodadas de escolhas, cada uma com mutação; o título de saída é escolhido por condição sobre os marcadores; perder é cair no título de variação, nunca game over | zero scripts novos além do toggle de estilo no balão; o mesmo confronto termina em dois títulos diferentes conforme as escolhas |
| Ilha responde (MapMood) | nó em cada mapa com `npc_ids` exportados; escuta `StoryState.marker_changed`, recalcula `coldness` e aplica: na fatia, CanvasModulate interpolando entre tinta quente e fria (do `time_of_day` vem a base); loops de áudio base, quente e frio com volume interpolado | subir o medo do pescador esfria a praia em até 1 s; o shader de paleta fica para depois da fatia |
| Transição e save | `MapExit` (Area2D com `target_map` e `target_spawn`) chama `SceneRouter.change_map()`: fade out, troca de cena, posiciona o jogador no `SpawnPoint`, fade in, `SaveService.autosave()`; `SaveService.save(slot)` e `load(slot)`; menu com novo jogo, continuar e três slots | sair do apartamento cria `autosave.json`; carregar o slot devolve o jogador no mesmo mapa e spawn, com os mesmos marcadores |

O que não existe na fatia, de propósito: inventário, sistema de tempo, flashback, puzzle, shader de paleta, sinestesia sonora. Cada um vira marco depois do portão e entra com o mesmo padrão: nó pequeno, dado em Resource, teste antes.

## Testes e CI

Três camadas de teste, todas headless, todas no CI a cada push. Teste vermelho bloqueia merge; lógica nova sem teste também.

| Camada | O que cobre | Como |
|---|---|---|
| Unitário (gdUnit4) | `StoryState`: `adjust` soma e trava entre 1 e 5, `to_dict` e `from_dict` fazem ida e volta idêntica, `new_game` carrega níveis dos perfis; `SaveService`: grava e lê um slot, recusa versão desconhecida; `MapMood`: a função pura de `coldness` com 0, 1 e 3 NPCs; balão: a função pura de `tone` | `tests/unit/*_test.gd`; sem cena, sem `await`, rápido |
| Cena (gdUnit4 scene runner) | cada mapa em `content/maps` instancia sem erro, tem um `Player`, um `MapMood` e ao menos um `SpawnPoint`; o balão abre e fecha com um diálogo de teste | `tests/scene/maps_smoke_test.gd`; itera a pasta, não lista mapas à mão |
| Conteúdo | todo `.dialogue` em `content/dialogue` compila sem erro; todo `.tres` de perfil tem `id`, `dialogue` e `start_title` preenchidos e o título existe no arquivo | `tests/scene/dialogue_compile_test.gd`; falha cedo quando o Ph erra um título |

**CI:** `.github/workflows/ci.yml` com a gdUnit4-action rodando as três camadas em Godot 4.7.2 headless a cada push e pull request. Um segundo job, só em tag, exporta Windows e Linux com os export templates e anexa os binários ao release.

**Local:** o agente roda os testes pelo runner de linha de comando do gdUnit4 antes de todo commit, e nunca marca uma tarefa como pronta com o runner vermelho. Quando o godot-mcp estiver ligado, o agente também roda a cena da tarefa e lê o output do editor antes de encerrar.

## Resolução, importação e assets

Viewport de 320x180 com escala inteira, filtro Nearest no projeto inteiro e uma paleta de 32 cores que é a fonte da verdade. Placeholder é permitido na fatia; fora da paleta, não.

| Configuração | Valor |
|---|---|
| `display/window/size/viewport_width` e `height` | 320 e 180 |
| `display/window/size/window_width_override` e `height_override` | 1920 e 1080 para testar |
| `display/window/stretch/mode` | `canvas_items` |
| `display/window/stretch/aspect` | `keep` |
| `display/window/stretch/scale_mode` | `integer` |
| `rendering/textures/canvas_textures/default_texture_filter` | Nearest |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | ligado |
| `rendering/renderer/rendering_method` | `gl_compatibility` |
| Importação de PNG | sem mipmaps, sem filtro, sem compressão com perda |

Regras de asset:

- `assets/palette/sabaostra.gpl` guarda as 32 cores (16 quentes, 16 frias, 4 neutros). Todo PNG do projeto usa só essas cores. Um script em `tools/check_palette.gd` confere e roda no CI a partir do marco de arte; na fatia, conferência manual no Aseprite.
- Sprites de personagem: 16x32, sheet com 4 direções x 4 frames, ordem fixa (baixo, esquerda, direita, cima) para todos, protagonista incluído. Tiles: 16x16 em atlas por tileset. Retratos: 48x48.
- Placeholder na fatia: retângulos de uma cor da paleta e sprites de um frame são aceitos, desde que tenham o tamanho final e o caminho final. A arte gerada e limpa no Aseprite substitui o arquivo, e nada no código muda.
- Nomes: `snake_case`, sem acento, com o id do personagem na frente (`pescador_walk.png`, `pescador_portrait.png`).
- Áudio: música em OGG Vorbis com loop marcado na importação; efeitos em WAV 44.1 kHz mono; volumes por bus (`Master`, `Music`, `SFX`, `Voice`), nunca no nó.

## Localização

PT-BR é a língua de escrita e EN entra desde o primeiro texto, pelo mecanismo nativo do Godot e do Dialogue Manager. Nenhuma string de interface nasce solta no código ou na cena.

- **Interface:** toda string passa por `tr()` com chave em `content/locale/ui.csv` (colunas `key`, `pt_BR`, `en`). Botões, menus e mensagens de save incluídos.
- **Diálogo:** escrito em PT-BR nos `.dialogue`; o Dialogue Manager exporta as linhas para CSV com id estável por linha, e o EN entra nesse CSV (`content/locale/dialogue.csv`). O texto no `.dialogue` nunca é traduzido no próprio arquivo.
- **Idioma padrão** `pt_BR`; troca em Opções aplica na hora com `TranslationServer.set_locale()` e persiste em `user://settings.cfg`.
- **Fonte:** a fonte pixel precisa cobrir acentos e cedilha do PT-BR; conferir antes de adotar, com a frase de teste "A mãe pôs açúcar no café às três" renderizada em 320x180.
- **Tradução EN** é trabalho do Ph com revisão; o agente pode preencher um rascunho marcado `DRAFT` no CSV, nunca um texto final em silêncio.
- **Teste:** o smoke de cena falha se um `Label` ou `Button` de `src/ui` tiver `text` literal em vez de chave.

## Backlog da fatia vertical

Treze tarefas em ordem, uma por commit, cada uma com definição de pronto. O agente não pula nem junta tarefas; se uma se mostrar grande demais, ele a divide e avisa.

1. **Bootstrap.** Projeto Godot 4.7.2 com as configurações de resolução, `.gitignore`, gdUnit4 instalado, um teste trivial e o CI verde. Pronto: badge verde no GitHub.
2. **StoryState.** Autoload com flags, marcadores, `adjust` travado em 1 a 5, `to_dict` e `from_dict`, sinal `marker_changed`. Pronto: testes unitários cobrindo limites e ida e volta.
3. **NpcProfile.** Resource com os campos do modelo de dados e os três `.tres` (mãe, pescador, princesa) com níveis iniciais vazios para o Ph preencher. Pronto: `new_game` carrega os perfis e o teste confere.
4. **SaveService.** Três slots mais autosave em JSON, versão, recusa de versão desconhecida. Pronto: teste grava, lê e compara; teste recusa versão 999.
5. **Player.** Grade de 16 px, 4 direções, correr, input map, sprite placeholder 16x32. Pronto: smoke de um mapa vazio com o jogador andando por script de teste sem atravessar parede.
6. **Interactable e NPC.** Cena de NPC por composição com perfil exportado. Pronto: smoke em que o jogador de frente para o NPC dispara `interacted`; de lado, não.
7. **Diálogo.** Dialogue Manager, balão próprio em 320x180, `tone` por marcador, blip por perfil, um `.dialogue` de exemplo com escolha e mutação. Pronto: teste de compilação e smoke do balão abrindo, escolhendo e fechando; a mutação aparece no `StoryState`.
8. **Confronto.** Tag `#confront` no título, moldura e ritmo diferentes no balão, saída por condição. Pronto: um confronto de exemplo termina em dois títulos diferentes conforme as escolhas, sem script novo.
9. **SceneRouter, MapExit e SpawnPoint.** Fade, troca de mapa, posicionamento, autosave. Pronto: smoke sai de um mapa e chega no outro no spawn certo; `autosave.json` existe.
10. **MapMood.** `coldness` por média de medo, `CanvasModulate` interpolado, três loops de áudio com volume. Pronto: teste da função pura; smoke em que subir o medo muda a tinta.
11. **Os três mapas.** Apartamento, praia e arredores com tiles placeholder na paleta, NPCs posicionados, saídas ligadas, diálogos com o texto do Ph (ou `TODO_PH` onde faltar). Pronto: jogar do apartamento aos arredores sem tocar no código.
12. **Menu e opções.** Novo jogo, continuar, slots, idioma. Pronto: carregar um slot devolve mapa, spawn e marcadores; trocar idioma muda a interface na hora.
13. **Arte, áudio e export.** Substituir placeholders pela arte gerada e limpa, loops do Suno, export Windows e Linux por tag. Pronto: portão da fatia fechado (Objetivo).

**Definição de pronto, para toda tarefa:** testes da tarefa escritos e verdes; CI verde; nenhum warning novo; nenhuma dependência nova sem registro nesta spec; commit único com mensagem que diz o porquê; o agente descreve em três linhas o que testou à mão.

## Regras para o agente

Esta seção vira o `CLAUDE.md` do repositório, com os comandos de rodar e testar acrescentados. O agente lê a bíblia e esta spec antes de qualquer tarefa e trabalha dentro delas. O texto das onze regras está no [CLAUDE.md](../CLAUDE.md).

## Registro de decisões

| Data | Tarefa | Decisão | Por quê |
|---|---|---|---|
| 28/09/2026 | 1 | Godot 4.7.2 stable no lugar de 4.6.3 | A spec partia de "4.6.3 é a última stable, 4.7 está em beta", o que já não era verdade: 4.7 stable em 18/06/2026, 4.7.2 em 18/08/2026. Os releases 4.x do Dialogue Manager saem marcados para Godot 4.7, e o gdUnit4 6.2.1 suporta o 4.7. Aprovado pelo Ph. |
| 28/09/2026 | 1 | gdUnit4 6.2.1 vendorizado em `addons/gdUnit4`; o CI usa essa cópia (`version: installed`) | Mesma versão no editor, no runner local e no CI. |
| 28/09/2026 | 1 | Warnings de tipagem GDScript (`untyped_declaration`, `unsafe_property_access`, `unsafe_method_access`, `unsafe_cast`, `unsafe_call_argument`) no nível erro; addons excluídos | Cumpre o princípio 6 no parser, sem depender de revisão. |
| 28/09/2026 | 1 | O runner local roda com `--ignoreHeadlessMode` | O gdUnit4 recusa rodar headless por padrão; a spec exige headless. Consequência: `InputEvent` não chega ao jogo em headless, então teste de cena simula pela ação ou chama o método direto. |

### Pendências de decisão (avisadas ao Ph na tarefa 1)

1. Nome do CSV de diálogo: a árvore de pastas diz `dialogue_pt_BR.csv` e a seção Localização diz `dialogue.csv`. Proposta: `dialogue.csv`. Decidir até a tarefa 7.
2. A fase 1 da bíblia fala em "um mapa, dois personagens"; esta spec tem três mapas. Proposta: manter os três e ajustar a bíblia.
3. Teto de três autoloads: o Dialogue Manager registra o autoload `DialogueManager`. Proposta: autoload de addon não conta. Decidir na tarefa 7.
4. Controles: na bíblia, B é cancelar e correr; aqui, `run` é uma ação separada. Proposta: ações separadas, as duas na mesma tecla. Decidir na tarefa 5.
