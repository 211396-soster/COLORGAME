# Estado atual do projeto

Última revisão: 2026-10-27 (inspeção do ZIP fornecido; não equivale a teste de execução).

## Confirmado por inspeção
- Projeto Godot com `project.godot` e cena inicial `scenes/menu.tscn`.
- Configuração declara Godot 4.4 e renderizador Mobile.
- Autoload `Game` configurado para `scripts/game.gd`.
- Existem cenas/scripts de menu, entrega, modo `overcooked` e zumbis.
- Existe mapa serializado em `data/city.tres` e ferramentas de conversão OSM em `tools/`.
- Existem presets Android, Windows Desktop e Web.

## Ainda não verificado
- Importação sem erros na versão instalada da Godot.
- Inicialização e conclusão de cada modo.
- Desempenho em aparelhos Android reais.
- Exportação Android/Windows/Web em ambiente limpo.
- Referências e dependências completas.
- Portabilidade dos presets para outras máquinas.

## Próximas verificações
1. Abrir em Godot 4.4+ e aguardar importação.
2. Executar a cena principal e percorrer o menu.
3. Testar cada modo individualmente.
4. Verificar erros no debugger e logs.
5. Testar em aparelho Android e registrar modelo, sistema e resultado.
6. Confirmar assinatura Android segura antes de qualquer release.

Registre fatos e evidências, não suposições.
