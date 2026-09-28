# Sabaostra — regras para o agente

Antes de qualquer tarefa, leia [docs/biblia.md](docs/biblia.md) (design) e [docs/spec.md](docs/spec.md) (construção) e trabalhe dentro delas. A bíblia é a fonte de toda decisão de design; a spec só diz como construir.

1. Uma tarefa do backlog por vez, na ordem. Começa com um plano de até cinco linhas (o que muda, onde, como testa) e só então escreve código.
2. Menos é mais, sempre. Se a solução pede uma classe nova, um autoload novo ou um padrão novo, o agente para e pergunta. Se pede apagar código, apaga.
3. Testa antes de dizer que terminou: runner do gdUnit4 headless verde, cena da tarefa rodada e output lido. Sem isso a tarefa não está pronta, e o agente diz isso em vez de fingir.
4. Não adiciona addon, dependência, autoload ou configuração de projeto sem pedir. Quando aprovado, registra na spec na mesma tarefa.
5. Não escreve conteúdo narrativo. Fala de personagem, nome de lugar e texto de interface são do Ph. Onde faltar texto, o agente deixa `TODO_PH` visível e segue.
6. Não gera arte nem áudio. Usa placeholder na paleta, com tamanho e caminho finais, e avisa quais arquivos esperam asset.
7. Commit pequeno, mensagem com o porquê, sem refactor de passagem e sem "melhorias" fora da tarefa. Se viu algo errado fora do escopo, anota como tarefa nova e não mexe.
8. Código em GDScript tipado, inglês, curto. Sem comentário que repete o código, sem print esquecido, sem função com mais de uma responsabilidade.
9. Ambiguidade vira pergunta ao Ph, com as opções e o preço de cada uma, nunca decisão silenciosa. Conflito entre spec e bíblia: a bíblia vence e o agente avisa.
10. Com o godot-mcp ligado: auto-reload de scripts desligado durante a sessão; roda a cena, lê erros do output, corrige, repete. Sem o MCP: roda headless pela linha de comando e lê o log.
11. Ao terminar cada tarefa, responde em até dez linhas: o que mudou, o que testou à mão, o que ficou de fora e por quê.

## Comandos

Godot 4.7.2 stable. Na máquina do Ph, o binário está em `C:\Users\Philipe\tools\godot\Godot_v4.7.2-stable_win64_console.exe` (use o `_console` para ler a saída no terminal).

```bash
# importar o projeto: primeira vez, depois de adicionar assets e sempre antes de commitar
# (gera os .uid e .import dos arquivos novos, que vão no mesmo commit)
"$GODOT" --headless --path . --import

# rodar todos os testes headless (0 = verde, 100 = falha, 101 = warning)
"$GODOT" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -a res://tests

# rodar uma suíte
"$GODOT" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests/unit/project_settings_test.gd

# checar um script sem rodar
"$GODOT" --headless --path . --check-only -s res://caminho/do/script.gd

# abrir o editor
"$GODOT" --path . -e
```

Não passe `-d` para o runner: com erro de parse, o Godot entra no debugger interativo e fica em loop, em vez de sair com código 105.

`--ignoreHeadlessMode` é necessário porque o gdUnit4 recusa rodar headless por padrão. Em headless, `InputEvent` não chega ao jogo: teste de cena que precisa de input deve simular pela ação (`Input.action_press`) ou chamar o método direto. Isso ainda precisa ser confirmado na tarefa 5.

CI: `.github/workflows/ci.yml` roda `res://tests` em Godot 4.7.2 a cada push e pull request, com o gdUnit4 do repo (`version: installed`) e warning tratado como erro.
