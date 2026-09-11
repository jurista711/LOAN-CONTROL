import 'package:flutter/material.dart';

import 'main.dart';

class ConnectedPaymentPage extends StatefulWidget {
  const ConnectedPaymentPage({super.key, required this.loan});

  final Map<String, dynamic> loan;

  @override
  State<ConnectedPaymentPage> createState() => _ConnectedPaymentPageState();
}

class _ConnectedPaymentPageState extends State<ConnectedPaymentPage> {
  final valueController = TextEditingController();
  final noteController = TextEditingController();

  List<Map<String, dynamic>> installments = [];
  bool loading = true;
  bool saving = false;
  int quantity = 1;
  String method = 'Dinheiro';
  String applyTo = 'Juros e Principal';
  bool share = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadInstallments();
  }

  @override
  void dispose() {
    valueController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _loadInstallments() async {
    try {
      final result = await rpc('cobrapp_app_list_pending_installments');
      final loanId = widget.loan['id']?.toString();
      final rows = (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((row) => row['loan_id']?.toString() == loanId)
          .toList();
      rows.sort((a, b) => toDouble(a['number']).compareTo(toDouble(b['number'])));

      if (!mounted) return;
      setState(() {
        installments = rows;
        loading = false;
        error = rows.isEmpty ? 'Não há parcelas pendentes para este empréstimo.' : null;
        quantity = rows.isEmpty ? 1 : 1;
      });
      if (rows.isNotEmpty) _fillSuggestedAmount();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = _friendlyError(e);
      });
    }
  }

  double _openAmount(Map<String, dynamic> row) {
    final total = toDouble(row['total'] ?? row['amount']);
    final paid = toDouble(row['paid_amount']);
    return (total - paid).clamp(0, double.infinity).toDouble();
  }

  double get _selectedAmount {
    if (installments.isEmpty) return 0;
    final count = quantity.clamp(1, installments.length);
    return installments.take(count).fold<double>(0, (sum, row) => sum + _openAmount(row));
  }

  double get _firstOpen => installments.isEmpty ? 0 : _openAmount(installments.first);

  double get _interestOpen {
    if (installments.isEmpty) return 0;
    final row = installments.first;
    final interest = toDouble(row['interest']);
    final total = toDouble(row['total'] ?? row['amount']);
    final paid = toDouble(row['paid_amount']);
    if (total <= 0) return interest;
    final ratio = ((total - paid) / total).clamp(0.0, 1.0);
    return interest * ratio;
  }

  void _fillSuggestedAmount() {
    valueController.text = _selectedAmount.toStringAsFixed(2).replaceAll('.', ',');
  }

  double _parseMoney(String raw) {
    var value = raw.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (value.contains(',') && value.contains('.')) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else if (value.contains(',')) {
      value = value.replaceAll(',', '.');
    }
    return double.tryParse(value) ?? 0;
  }

  String _paymentType(double amount) {
    if (amount < _firstOpen - 0.009) return 'partial';
    if (amount > _firstOpen + 0.009) return 'advance';
    return 'total';
  }

  Future<void> _save() async {
    if (installments.isEmpty || saving) return;

    final amount = _parseMoney(valueController.text);
    if (amount <= 0) {
      setState(() => error = 'Informe um valor de pagamento válido.');
      return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      final type = _paymentType(amount);
      final result = await rpc(
        'cobrapp_app_register_payment_v3',
        params: {
          'p_installment_id': installments.first['id'],
          'p_amount': amount,
          'p_late_charge': 0,
          'p_method': method,
          'p_note': noteController.text.trim().isEmpty ? null : noteController.text.trim(),
          'p_type': type,
          'p_paid_at': DateTime.now().toIso8601String().substring(0, 10),
        },
      );

      if (!mounted) return;
      final data = result is Map ? Map<String, dynamic>.from(result) : <String, dynamic>{};
      final ok = data['ok'] == true;
      if (!ok) {
        throw Exception(data['message'] ?? 'Não foi possível registrar o pagamento.');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['receipt_number'] == null
                ? 'Pagamento registrado com sucesso.'
                : 'Pagamento registrado. Recibo nº ${data['receipt_number']}.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _friendlyError(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '');
    if (text.contains('Parcela não encontrada')) return 'A parcela não foi encontrada no Supabase. Atualize e tente novamente.';
    if (text.contains('Parcela já está paga')) return 'Essa parcela já foi paga. Atualize a tela.';
    if (text.contains('Pagamento total deve ser igual')) return 'O valor do pagamento total precisa ser exatamente o valor em aberto da parcela.';
    if (text.contains('Pagamento parcial deve ser menor')) return 'Para pagamento parcial, informe um valor menor que a parcela em aberto.';
    if (text.contains('Valor maior que o total atualizado')) return 'O valor informado é maior que o permitido para esta parcela.';
    if (text.contains('Licença inválida')) return 'A ativação deste aparelho não é válida ou expirou.';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final customerName = (widget.loan['customer_name'] ?? 'Cliente').toString();
    final debt = installments.fold<double>(0, (sum, row) => sum + _openAmount(row));

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                CircleAvatar(
                  backgroundColor: mintDark,
                  child: Text(
                    customerName.isEmpty ? '?' : customerName[0].toUpperCase(),
                    style: const TextStyle(color: mint, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(customerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                const Icon(Icons.more_vert),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Adicionar Pagamento', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 18),
                    if (loading) const LinearProgressIndicator(),
                    if (!loading) ...[
                      _amountRow('Valor da Parcela', money(_firstOpen), true),
                      _amountRow('Somente Juros', money(_interestOpen), false, onAdd: () {
                        valueController.text = _interestOpen.toStringAsFixed(2).replaceAll('.', ',');
                      }),
                      _amountRow('Dívida Total', money(debt), false, onAdd: () {
                        valueController.text = debt.toStringAsFixed(2).replaceAll('.', ',');
                      }),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Valor', prefixIcon: Icon(Icons.attach_money)),
                    ),
                    const SizedBox(height: 18),
                    const Text('Resumo do Pagamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Juros: ${money(_interestOpen)}'),
                        Text('Principal: ${money((_firstOpen - _interestOpen).clamp(0, double.infinity).toDouble())}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: applyTo,
                      decoration: const InputDecoration(labelText: 'Aplicar o pagamento a*'),
                      items: const [
                        DropdownMenuItem(value: 'Juros e Principal', child: Text('Juros e Principal')),
                        DropdownMenuItem(value: 'Somente Juros', child: Text('Somente Juros')),
                        DropdownMenuItem(value: 'Somente Principal', child: Text('Somente Principal')),
                      ],
                      onChanged: (value) { if (value != null) setState(() => applyTo = value); },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: method,
                      decoration: const InputDecoration(labelText: 'Método de Pagamento', prefixIcon: Icon(Icons.payments_outlined)),
                      items: const [
                        DropdownMenuItem(value: 'Dinheiro', child: Text('Dinheiro')),
                        DropdownMenuItem(value: 'Pix', child: Text('Pix')),
                        DropdownMenuItem(value: 'Cartão', child: Text('Cartão')),
                        DropdownMenuItem(value: 'Transferência', child: Text('Transferência')),
                      ],
                      onChanged: (value) { if (value != null) setState(() => method = value); },
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Data do Pagamento', suffixIcon: Icon(Icons.calendar_month)),
                      child: Text('${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}'),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: noteController, maxLines: 2, decoration: const InputDecoration(labelText: 'Adicionar Nota')),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: share,
                      onChanged: (value) => setState(() => share = value ?? false),
                      title: const Text('Você deseja imprimir ou compartilhar?'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton.icon(
                        onPressed: loading || installments.isEmpty || saving ? null : _save,
                        icon: saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.monetization_on_outlined),
                        label: Text(saving ? 'SALVANDO...' : 'GUARDE O PAGAMENTO', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: IconButton.filled(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))),
          ],
        ),
      ),
    );
  }

  Widget _amountRow(String label, String amount, bool stepper, {VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: muted)),
                Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          if (stepper)
            Container(
              decoration: BoxDecoration(color: const Color(0xFF173D34), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  IconButton(
                    onPressed: quantity > 1 ? () { setState(() => quantity--); _fillSuggestedAmount(); } : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w900)),
                  IconButton(
                    onPressed: quantity < installments.length ? () { setState(() => quantity++); _fillSuggestedAmount(); } : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            )
          else
            IconButton.filledTonal(onPressed: onAdd, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}
