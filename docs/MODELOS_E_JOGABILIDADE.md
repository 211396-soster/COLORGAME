# Modelos 3D, jogabilidade e builds multiplataforma

## Modelos externos

O workflow baixa modelos glTF de [Poly Haven](https://polyhaven.com/models), sob CC0 1.0, usando a API pública:
- `covered_car`: carro coberto como objeto de cenário junto à loja.
- `tree_small_02`: árvore detalhada usada em alguns setores da cidade.
- `street_lamp_01`: poste de rua detalhado usado em alguns setores da cidade.

Os arquivos binários são baixados durante a compilação, não são versionados no Git. `scripts/real_assets.gd` carrega os modelos por um manifesto. Se o download não estiver presente, o jogo usa os modelos procedurais existentes como fallback. O restante da cidade mantém as pegadas dos edifícios derivadas do OpenStreetMap para preservar a geografia do mapa; as fachadas ganharam janelas, caixilhos, reflexos e variação de material.

## Jogabilidade e física

- A aceleração, a frenagem, a marcha à ré e o arrasto da picape usam limites em metros por segundo.
- A direção usa um modelo de bicicleta simplificado, com menor ângulo efetivo das rodas em alta velocidade.
- O movimento a pé é mais lento ao carregar uma lata/balde.
- A carga só é contabilizada como entregue depois de o jogador levar o item até o cliente; pegar um item não incrementa mais o contador de entrega.
- O jogo verifica se existe um pallet compatível antes de exibir a ação de pegar, evitando acessar um objeto inexistente.

## Compatibilidade e qualidade

- PC Windows: workflow exporta `ColorTintas.exe`.
- Android: workflow exporta `ColorTintas.apk` para dispositivos ARM64.
- A qualidade inicial é Alta no PC e Média em dispositivos com touchscreen; a opção pode ser alterada no menu.
- O renderizador Mobile continua habilitado para compatibilidade e desempenho em celulares.

## Licenças e créditos

- Modelos 3D: Poly Haven, CC0 1.0.
- Materiais PBR de asfalto e pavimento: ambientCG, CC0 1.0.
- Mapa urbano: OpenStreetMap contributors, ODbL.
- A API pública de Poly Haven solicita que a origem seja clara para os usuários; os créditos estão no menu do jogo.

## Limitações conhecidas

Esses modelos externos melhoram objetos de cenário, mas não substituem cada edifício por uma construção única, nem são modelos humanos fotorealistas ou um veículo jogável completo. A picape dirigível, os carros do tráfego e os personagens ainda são modelos procedurais refinados. A compilação automática precisa passar e as cenas devem ser testadas no PC e em um celular real antes de considerar a versão pronta.
