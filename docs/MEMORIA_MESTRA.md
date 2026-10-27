# Memória Mestra — Color Tintas: Passo Fundo

> Fonte central de contexto do projeto. Atualize este documento quando uma decisão estável for aprovada. Para o estado operacional mais recente, consulte `ESTADO_ATUAL.md`.

## Identidade
- Nome configurado na Godot: **Color Tintas: Passo Fundo**.
- Motor: **Godot 4.4+**.
- Renderizador: **Mobile**.
- Orientação configurada: paisagem.
- Cena inicial: `res://scenes/menu.tscn`.
- Autoload global: `Game` → `res://scripts/game.gd`.
- Identificador Android configurado: `com.colortintas.passofundo`.

## Conceito
Jogo ambientado em Passo Fundo, com mapa urbano derivado de dados OpenStreetMap, uma loja de tintas e diferentes modos de jogo. O foco indicado é mobile/Android; presets para Windows e Web existem, mas precisam ser testados antes de serem considerados suportados.

## Modos/cenas identificados
- Menu: `scenes/menu.tscn` → `scripts/menu.gd`.
- Entrega: `scenes/delivery.tscn` → `scripts/mode_delivery.gd`.
- Loja/cozinha (`overcooked`): `scenes/overcooked.tscn` → `scripts/mode_overcooked.gd`.
- Zumbis: `scenes/zombie.tscn` → `scripts/mode_zombie.gd`.

## Recursos relevantes
- `data/city.tres`: dados serializados do mapa.
- `tools/osm_to_json.py` e `tools/make_city_tres.py`: ferramentas de conversão/regeneração do mapa.
- `assets/models/lata_tinta.glb`: modelo de lata de tinta.
- `assets/sky/sky_day.hdr`: ambiente/céu.
- `tex/`: texturas e imagens de apoio.

## Princípios
1. Preservar a identidade e conteúdo do jogo até decisão explícita.
2. Priorizar desempenho, estabilidade e controles mobile.
3. Preservar atribuição/licença dos dados OpenStreetMap.
4. Não presumir que um modo funciona só por existir cena/script.
5. Separar fatos confirmados, hipóteses e ideias futuras.
6. Registrar decisões importantes com data, contexto, alternativas e consequência.

## Confirmado pelo projeto inspecionado
- Godot 4.4 e renderer Mobile configurados.
- Mapa em `data/city.tres`, ferramentas em `tools/`.
- Presets de exportação para Android, Windows Desktop e Web.

## Em aberto
- Escopo/prioridade final dos modos.
- Metas de desempenho e dispositivos mínimos.
- Builds automatizados e distribuição.
- Repositório público ou privado e agentes com permissão de escrita.

## Política
Acrescente fatos após conferir código, teste ou decisão explícita. Não substitua decisões antigas silenciosamente; registre alterações em `DECISOES.md`. Detalhes de tarefas ficam nos documentos específicos.
