# Color Tintas: Passo Fundo

Projeto de jogo em Godot 4 para dispositivos móveis, com mapa de Passo Fundo baseado em dados do OpenStreetMap e modos de entrega, loja/cozinha (`overcooked`) e zumbis.

## Estado da importação inicial

A estrutura de colaboração e a documentação já estão no repositório. Os arquivos reais do jogo ainda precisam ser importados da pasta do projeto local. O arquivo `project.godot` não deve ser considerado presente até aparecer nesta raiz.

**Pacote de importação:** baixe o ZIP preparado na conversa em que o responsável está trabalhando e execute `PUBLICAR_NO_GITHUB.ps1` no Windows. O script copia os arquivos do jogo para uma branch separada e preserva `README.md`, `AGENTS.md`, `docs/`, `.github/` e `.gitignore` existentes. Ele pede confirmação antes do commit/push e exige Git instalado e autenticação GitHub funcional. Após o push, abra o Pull Request sugerido pelo script.

## Abrir o projeto

1. Instale Godot **4.4 ou superior**.
2. Abra a pasta que contém `project.godot`.
3. Aguarde a importação dos recursos.
4. Execute `scenes/menu.tscn` (cena principal configurada em `project.godot`).

## Fonte oficial da memória do projeto

Antes de alterar o código, leia nesta ordem:

1. [`AGENTS.md`](AGENTS.md) — regras obrigatórias para agentes.
2. [`docs/MEMORIA_MESTRA.md`](docs/MEMORIA_MESTRA.md) — visão e decisões conhecidas.
3. [`docs/ESTADO_ATUAL.md`](docs/ESTADO_ATUAL.md) — estado verificado e limitações.
4. [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md) — estrutura técnica.
5. [`docs/ROADMAP.md`](docs/ROADMAP.md) e [`docs/DECISOES.md`](docs/DECISOES.md) — próximas etapas e decisões.

Ao concluir qualquer tarefa, atualize `docs/ESTADO_ATUAL.md`, `docs/CHANGELOG.md` e a documentação afetada. Não registre como concluído algo que não foi testado.

## Colaboração entre agentes

- Abra uma branch por tarefa/agente; não trabalhe diretamente em `main`.
- Use commits pequenos e descritivos.
- Abra Pull Request para integrar alterações.
- Declare arquivos alterados, testes executados, resultados e pendências no PR.
- Se duas tarefas alterarem os mesmos arquivos, pare e coordene antes de integrar.
- Proteja `main` com revisão e verificações de CI quando disponíveis.

## Verificação local

Se tiver Godot no PATH:

```bash
godot --version
godot --headless --editor --path . --quit
```

O segundo comando inicia a importação/verificação pelo editor em modo headless; não substitui testes de jogabilidade no dispositivo.

## Mapa e atribuição

O mapa usa dados do OpenStreetMap. A atribuição e as obrigações da licença ODbL devem ser mantidas em qualquer distribuição pública. Consulte `LEIA-ME.txt` e a documentação do OpenStreetMap antes de redistribuir dados derivados.

## Segurança

Não comite senhas, tokens, keystores de assinatura, arquivos `.env`, builds/exportações ou dados privados. O preset de exportação do pacote foi sanitizado para remover caminhos específicos de outra máquina e dados de assinatura padrão; configure a assinatura Android somente localmente ou em segredos protegidos de CI.
