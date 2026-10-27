# Arquitetura técnica — inventário inicial

Este documento é um mapa inicial baseado nos nomes e referências observados no projeto. Leia o código antes de modificar responsabilidades ou dependências.

## Configuração global
- `project.godot`: configuração do projeto, renderizador, cena inicial e autoload.
- `scripts/game.gd`: singleton/autoload `Game`.

## Cenas
| Cena | Script |
|---|---|
| `scenes/menu.tscn` | `scripts/menu.gd` |
| `scenes/delivery.tscn` | `scripts/mode_delivery.gd` |
| `scenes/overcooked.tscn` | `scripts/mode_overcooked.gd` |
| `scenes/zombie.tscn` | `scripts/mode_zombie.gd` |

## Scripts identificados
- Mundo/cidade: `city.gd`, `city_data.gd`, `facade.gd`.
- Entrega e veículos: `mode_delivery.gd`, `dl_models.gd`, `truck_model.gd`, `vehicles.gd`, `traffic.gd`.
- Loja/cozinha: `mode_overcooked.gd`, `oc_models.gd`, `oc_hud.gd`.
- Zumbis: `mode_zombie.gd`.
- Interface/apoio: `menu.gd`, `touch_ui.gd`, `minimap.gd`, `ui_kit.gd`, `util.gd`, `props.gd`, `chars.gd`.

## Dados e recursos
- `data/city.tres`: recurso de dados da cidade.
- `tools/osm_to_json.py`, `tools/make_city_tres.py`: pipeline de dados OSM; validar argumentos lendo os scripts.
- `assets/`: modelo 3D e HDRI.
- `tex/`: imagens e texturas.

## Convenções
- Procurar utilitários e padrões existentes antes de adicionar sistemas.
- Evitar acoplamento novo ao singleton global quando dependência explícita for suficiente.
- Separar lógica de jogo, apresentação e controles quando compatível com a arquitetura.
- Atualizar este documento se pastas, cenas ou responsabilidades mudarem.
