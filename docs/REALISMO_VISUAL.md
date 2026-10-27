# Plano de realismo visual

## O que esta melhoria muda

- **Asfalto e calçadas:** o build baixa materiais PBR CC0 do ambientCG em 2K, com mapas de cor, normal e rugosidade. O jogo usa esses materiais quando disponíveis e mantém as texturas já existentes como fallback.
- **Micro-relevo procedural:** as superfícies e fachadas recebem mapas normais sutis gerados uma vez por sessão, sem arquivos extras para esse efeito.
- **Iluminação e pós-processamento:** tonemapping filmic, exposição de cor mais natural, névoa atmosférica e bloom/glow discreto.
- **Qualidade inicial:** instalações novas começam na opção gráfica Alta; quem estiver num aparelho mais fraco pode reduzir para Média ou Baixa.
- **Build verificável:** o workflow baixa as texturas antes do import do Godot e tenta exportar o executável Windows também em pull requests.

## Fontes e licença

As texturas de asfalto e pavimento vêm de [ambientCG](https://ambientcg.com/), que publica os materiais sob CC0 1.0. O script `tools/download_realism_assets.py` baixa apenas os mapas necessários para o jogo e os mantém fora do histórico Git para evitar inflar o repositório.

## Limites técnicos

O projeto continua usando o renderizador Mobile do Godot para manter compatibilidade com celular. Por isso, não ativamos SSAO/SSR de Forward+ que não funcionam nesse renderizador. O glow, a névoa, os mapas PBR e as sombras são os ganhos compatíveis com a configuração atual.

## Próxima etapa para chegar a um realismo muito maior

Texturas e iluminação melhoram a aparência, mas o salto maior virá de substituir modelos geométricos simples por modelos 3D detalhados de veículos, árvores, postes, mobiliário urbano e fachadas, além de testar as cenas visualmente. A cidade continua baseada nos dados do OpenStreetMap; a geometria e os dados originais não são substituídos por imagens inventadas.
