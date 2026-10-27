# Instruções obrigatórias para agentes de IA — Color Tintas

## Antes de começar
1. Leia `README.md`, `docs/MEMORIA_MESTRA.md`, `docs/ESTADO_ATUAL.md`, `docs/ARQUITETURA.md` e as decisões relevantes em `docs/DECISOES.md`.
2. Inspecione o código e os arquivos reais antes de afirmar como algo funciona. A documentação é um mapa, não substitui o código.
3. Identifique a tarefa e os critérios de aceitação. Se faltar requisito essencial, faça uma pergunta curta antes de mudanças arriscadas.

## Regras de segurança e colaboração
- Não faça commit direto em `main`; trabalhe em branch específica.
- Não sobrescreva, remova ou reformate arquivos não relacionados à tarefa.
- Não remova assets, cenas, scripts, dados de mapa ou configurações sem justificativa explícita e aprovação humana.
- Não invente resultados de testes. Informe comandos executados e resultados observados.
- Não inclua tokens, senhas, keystores, chaves privadas ou dados pessoais no repositório.
- Não altere opções de exportação/assinatura sem explicar o impacto e pedir aprovação quando envolver publicação ou credenciais.
- Prefira mudanças pequenas, reversíveis e isoladas. Verifique `git diff` antes de finalizar.
- Se encontrar mudanças feitas por outro agente, não as descarte; pare, avalie o diff e coordene.

## Regras técnicas
- Godot 4.4+, renderizador Mobile, foco em dispositivos móveis.
- Preserve compatibilidade; não migre de versão principal sem autorização.
- Use caminhos `res://` para recursos internos.
- Respeite padrões de GDScript e nomes existentes.
- Trate mapa e dados OpenStreetMap conforme licença/atribuição aplicável.
- Verifique dependências antes de modificar cenas/scripts.

## Ao terminar
1. Execute testes possíveis; tente `godot --headless --editor --path . --quit` se Godot estiver disponível.
2. Inspecione `git diff --check` e `git diff`.
3. Atualize `docs/ESTADO_ATUAL.md` com mudanças reais e itens não verificados.
4. Acrescente entrada datada em `docs/CHANGELOG.md`; atualize `docs/DECISOES.md` se necessário.
5. No PR, informe objetivo, arquivos alterados, testes, riscos, pendências e reversão.
6. Não declare uma funcionalidade pronta só porque o código foi escrito.

## Relatório
- Objetivo:
- Alterações:
- Testes executados/resultados:
- Não testado/limitações:
- Riscos/conflitos:
- Documentação atualizada:
