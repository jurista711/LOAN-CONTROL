import 'package:flutter/material.dart';

import 'main.dart';

class ReceiptDetailPage extends StatefulWidget {
  const ReceiptDetailPage({super.key, required this.paymentId});

  final String paymentId;

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  bool loading = true;
  String? error;
  Map<String, dynamic> data = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await rpc(
        'cobrapp_app_get_receipt_by_payment',
        params: {'p_payment_id': widget.paymentId},
      );
      if (!mounted) return;
      if (result is! Map || result.isEmpty) {
        setState(() {
          loading = false;
          error = 'Recibo não encontrado.';
        });
        return;
      }
      setState(() {
        data = Map<String, dynamic>.from(result);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  String _date(dynamic raw, {bool time = false}) {
    final d = DateTime.tryParse((raw ?? '').toString())?.toLocal();
    if (d == null) return '-';
    final base = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    if (!time) return base;
    return '$base ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _appliedTo() {
    final type = (data['payment_type'] ?? '').toString().toLowerCase();
    final principal = toDouble(data['principal_amount']);
    final interest = toDouble(data['interest_amount']);
    final late = toDouble(data['late_interest_amount']);
    if (late > 0 && principal == 0 && interest == 0) return 'Juros de Mora';
    if (interest > 0 && principal == 0) return 'Somente Juros';
    if (principal > 0 && interest == 0) return 'Apenas Capital';
    if (type == 'advance') return 'Juros e Principal';
    return 'Juros e Principal';
  }

  @override
  Widget build(BuildContext context) {
    final customer = (data['customer_name'] ?? 'Cliente').toString();
    final receiptNumber = data['receipt_number']?.toString();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(receiptNumber == null ? 'Recibo' : 'Recibo nº $receiptNumber'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(error!, style: const TextStyle(color: Colors.redAccent)),
                ))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('RECIBO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 16),
                            const Text('CLIENTE', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 5),
                            Text(customer, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            if ((data['customer_document'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Identificação: ${data['customer_document']}', style: const TextStyle(color: muted)),
                            ],
                            const SizedBox(height: 18),
                            const Divider(),
                            const SizedBox(height: 12),
                            const Text('INFORMAÇÕES DO EMPRÉSTIMO', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            _row('Data do empréstimo', _date(data['start_date'])),
                            _row('Juros do crédito', '${toDouble(data['interest_rate']).toStringAsFixed(1)}%'),
                            _row('Valor do empréstimo', money(toDouble(data['loan_amount']))),
                            _row('Dívida total', money(toDouble(data['total_debt']))),
                            const SizedBox(height: 18),
                            const Divider(),
                            const SizedBox(height: 12),
                            const Text('DETALHES DO RECIBO', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            _row('Data do Pagamento', _date(data['payment_date'], time: true)),
                            _row('Pagamento aplicado a', _appliedTo()),
                            _row('Total pago', money(toDouble(data['amount']))),
                            _row('Método de Pagamento', (data['method'] ?? 'Dinheiro').toString()),
                            if ((data['note'] ?? '').toString().trim().isNotEmpty)
                              _row('Nota', data['note'].toString()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ASSINATURAS', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 22),
                            const Text('Assinatura do cliente:'),
                            const SizedBox(height: 26),
                            const Divider(),
                            Text(customer, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 24),
                            const Text('Assinatura do credor:'),
                            const SizedBox(height: 26),
                            const Divider(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: muted))),
            const SizedBox(width: 12),
            Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );
}
