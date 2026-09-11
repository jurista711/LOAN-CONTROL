import 'package:flutter/material.dart';

import 'main.dart';
import 'receipt_detail.dart';

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
  DateTime paymentDate = DateTime.now();

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
        quantity = 1;
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
    final scheduled = toDouble(row['interest']);
    final alreadyPaid = toDouble(row['interest_paid']);
    if (scheduled > 0) return (scheduled - alreadyPaid).clamp(0, double.infinity).toDouble();
    final total = toDouble(row['total'] ?? row['amount']);
    final paid = toDouble(row['paid_amount']);
    if (total <= 0) return 0;
    final ratio = ((total - paid) / total).clamp(0.0, 1.0);
    return scheduled * ratio;
  }

  double get _principalOpen => (_firstOpen - _interestOpen).clamp(0, double.infinity).toDouble();

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

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _brDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickPaymentDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked != null) setState(() => paymentDate = picked);
  }

  Future<bool> _askExtendInterestTerm() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Estender prazo de pagamento?'),
            content: const Text('Este pagamento cobre apenas os juros, por isso não reduz o saldo do principal. Você deseja estender o prazo de pagamento?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sim')),
            ],
          ),
        ) ??
        false;
  }

  String _applyCode() {
    switch (applyTo) {
      case 'Somente Juros':
        return 'interest';
      case 'Juros de mora':
        return 'late_interest';
      case 'Apenas Capital':
        return 'principal';
      default:
        return 'regular';
    }
  }

  Future<void> _save() async {
    if (installments.isEmpty || saving) return;

    final amount = _parseMoney(valueController.text);
    if (amount <= 0) {
      setState(() => error = 'Informe um valor de pagamento válido.');
      return;
    }

    if (applyTo == 'Somente Juros' && amount > _interestOpen + 0.009) {
      setState(() => error = 'O valor do pagamento não pode exceder o valor dos juros da parcela atual.');
      return;
    }
    if (applyTo == 'Apenas Capital' && amount > _principalOpen + 0.009) {
      setState(() => error = 'O valor do pagamento não pode exceder o capital pendente da parcela atual.');
      return;
    }

    var extendInterestTerm = false;
    if (applyTo == 'Somente Juros') {
      extendInterestTerm = await _askExtendInterestTerm();
      if (!mounted) return;
    }

    setState(() {
      saving = true;
      error = null;
    });

    try {
      dynamic result;
      if (applyTo == 'Juros e Principal' && amount > _firstOpen + 0.009) {
        result = await rpc(
          'cobrapp_app_register_payment_v3',
          params: {
            'p_installment_id': installments.first['id'],
            'p_amount': amount,
            'p_late_charge': 0,
            'p_method': method,
            'p_note': noteController.text.trim().isEmpty ? null : noteController.text.trim(),
            'p_type': 'advance',
            'p_paid_at': _isoDate(paymentDate),
          },
        );
      } else {
        result = await rpc(
          'cobrapp_app_register_payment_v4',
          params: {
            'p_installment_id': installments.first['id'],
            'p_amount': amount,
            'p_method': method,
            'p_note': noteController.text.trim().isEmpty ? null : noteController.text.trim(),
            'p_apply_to': _applyCode(),
            'p_paid_at': _isoDate(paymentDate),
            'p_extend_interest_term': extendInterestTerm,
          },
        );
      }

      if (!mounted) return;
      final data = result is Map ? Map<String, dynamic>.from(result) : <String, dynamic>{};
      if (data['ok'] != true) {
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

      if (share && data['receipt_number'] != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptDetailPage(
              receiptNumber: data['receipt_number'],
              customerName: (widget.loan['customer_name'] ?? 'Cliente').toString(),
              amount: amount,
              paymentDate: paymentDate,
              method: method,
              note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
            ),
          ),
        );
        if (!mounted) return;
      }

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
    if (text.contains('não pode exceder o valor dos juros')) return 'O valor do pagamento não pode exceder o valor dos juros da parcela atual.';
    if (text.contains('não pode exceder o capital')) return 'O valor do pagamento não pode exceder o capital pendente da parcela atual.';
    if (text.contains('A data do pagamento não pode estar no futuro')) return 'A data do pagamento não pode estar no futuro.';
    if (text.contains('crédito está fechado')) return 'Este crédito está fechado e não aceita novos pagamentos.';
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
                        setState(() {
                          quantity = 1;
                          applyTo = 'Somente Juros';
                        });
                        valueController.text = _interestOpen.toStringAsFixed(2).replaceAll('.', ',');
                      }),
                      _amountRow('Dívida Total', money(debt), false, onAdd: () {
                        setState(() => applyTo = 'Juros e Principal');
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
                        Text('Principal: ${money(_principalOpen)}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: applyTo,
                      decoration: const InputDecoration(labelText: 'Aplicar o pagamento a*'),
                      items: const [
                        DropdownMenuItem(value: 'Juros e Principal', child: Text('Juros e Principal')),
                        DropdownMenuItem(value: 'Somente Juros', child: Text('Somente Juros')),
                        DropdownMenuItem(value: 'Juros de mora', child: Text('Juros de mora')),
                        DropdownMenuItem(value: 'Apenas Capital', child: Text('Apenas Capital')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          applyTo = value;
                          if (value != 'Juros e Principal') quantity = 1;
                        });
                        if (value == 'Somente Juros') {
                          valueController.text = _interestOpen.toStringAsFixed(2).replaceAll('.', ',');
                        } else if (value == 'Apenas Capital') {
                          valueController.text = _principalOpen.toStringAsFixed(2).replaceAll('.', ',');
                        }
                      },
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
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickPaymentDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Data do Pagamento', suffixIcon: Icon(Icons.calendar_month)),
                        child: Text(_brDate(paymentDate)),
                      ),
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
                    onPressed: applyTo == 'Juros e Principal' && quantity > 1 ? () { setState(() => quantity--); _fillSuggestedAmount(); } : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w900)),
                  IconButton(
                    onPressed: applyTo == 'Juros e Principal' && quantity < installments.length ? () { setState(() => quantity++); _fillSuggestedAmount(); } : null,
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
