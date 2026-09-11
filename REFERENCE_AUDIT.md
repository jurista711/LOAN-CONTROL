# LOAN-CONTROL — MAPA OBRIGATÓRIO DA REFERÊNCIA ORIGINAL

Este arquivo complementa `REGRAS_LOAN_CONTROL_A_PARTIR_DE_AGORA.docx` e registra somente comportamentos/telas comprovados pelos materiais originais enviados pelo usuário.

## Fontes usadas
- `main.dart.js` do CobrApp original.
- Vídeo original `1000244637.mp4`.
- Vídeo de fluxo do cliente `screen-20260910-181721.mp4` e quadros extraídos.

## Regra operacional
Antes de alterar uma tela, conferir este mapa + `main.dart.js` + quadro/vídeo correspondente. Se algo não estiver comprovado, não inventar função nem rota.

## Dashboard / Home — comprovado
- Cabeçalho ondulado verde/menta, compacto.
- Título `Dashboard`.
- Ícones superiores: rota, notificações, suporte/headset, atualizar.
- Filtro de datas: Hoje, Ontem, Últimos 7 dias, Mês corrente e período.
- `Ações Rápidas` com 4 cards compactos: Despesas, Criar Cliente, Criar Empréstimo, Criar Despesa.
- Card `Progresso de Cobranças`.
- Card `Visão Geral`.
- Barra inferior: Dashboard, Clientes, Config, Menu.
- Botão flutuante de calculadora é compacto; não usar `FloatingActionButton.large`.

## Lista de clientes — comprovado
- Cabeçalho ondulado menta.
- `Clientes (n)`.
- Ícones: busca, rota, etiquetas, ordenar/filtro, menu.
- Filtros: Todos, Pago hoje, Pagam hoje, Com crédito.
- Cards escuros compactos com avatar, nome, identificação, `Não alocado`, quantidade de créditos e seta.
- Botão `Adicionar cliente` centralizado e proporcionalmente estreito.
- FAB de calculadora no canto inferior.

## Detalhe do cliente — comprovado
- Cabeçalho ondulado menta no topo.
- Botão voltar à esquerda e avatar grande à direita.
- Nome e documento/identificação.
- Chip `Não alocado` com editar.
- Ações `Em formação`, `Editar`, `Mais opções`.
- Seção azul `Empréstimos Ativos (n)`.
- Seção verde `Empréstimos Pagos (n)` quando houver pagos.
- Card de crédito mostra valor, ID curto, pago/total, saldo pendente quando ativo, valor do pagamento, cotas, interesse, frequência e data.
- Botão inferior `Adicionar crédito`.

## Detalhe do crédito — comprovado
- Topo: voltar, avatar pequeno, nome e menu de três pontos.
- Card superior com: Valor, Juros do crédito, Tipo de juros, Frequência de Pagamento, status `Em formação`, `Editar crédito`, `Remover`, e ícone de gráfico/dinheiro.
- Abas distintas: `Plano de pagamento`, `Registro`, `Gestões`.
- Plano de pagamento: chips `Encostas`, `Pago`, `Atrasado`, `Anulada` e cards de parcela.
- Card da parcela: Balança principal, Saldo de juros, Total pago, Balanço total, Expira e menu de três pontos.
- Botão inferior `Adicionar` abre o fluxo de pagamento.
- FABs laterais: expandir e imprimir.
- Menu superior comprovado: Renovar, Marcar como Pago, Editar datas de vencimento, Imprimir Plano de Pagamento, Imprimir Histórico de Pagamentos, Documentos.

## Registro — comprovado
- Não é atalho para pagamento.
- Exibe resumo/histórico de pagamentos.
- Campos comprovados pelo original: Pagamentos, Pagamento de Capital, Pagamento de Juros, Juros em Atraso, Total de Pagamentos.

## Pagamento — comprovado
- Tela original usa o título visível `Adicionar Empréstimo`.
- Valor da Parcela com seletor - 1 +.
- Somente Juros com botão +.
- Dívida Total com botão +.
- Campo Valor.
- Resumo do Pagamento: Juros e Principal.
- `Aplicar o pagamento a*`.
- Método de Pagamento.
- Data do Pagamento.
- Adicionar Nota.
- Opção de imprimir/compartilhar.
- Botão `GUARDE O PAGAMENTO` compacto e centralizado.
- Botão fechar X no rodapé.

## Adicionar crédito — comprovado em `main.dart.js` e vídeo
- Tipo de juros.
- Valor do crédito.
- Cotas.
- Juros do crédito.
- Opção de calcular juros a partir da parcela.
- Parcela desejada.
- Frequência/Pagamento.
- Data do Crédito/Empréstimo.
- Adicionar Nota.
- Ativar Juros de Mora.
- Dias de Carência.
- Taxa de Juros de Mora (%).
- Valor da Multa por Atraso.
- Exemplo de mora.
- `Ver simulação`.
- `Resumo do Crédito`.
- `SALVAR CRÉDITO` / atualização conforme modo.

## Calculadora
O botão e a posição visual estão comprovados no vídeo. O conteúdo interno da calculadora não aparece no vídeo enviado. Portanto, o conteúdo interno não pode ser redesenhado por suposição. Deve ser identificado no bundle original antes de qualquer reconstrução adicional.
