import 'package:flutter/material.dart';

import 'main.dart';

class ReceiptDetailPage extends StatefulWidget {
  const ReceiptDetailPage({
    super.key,
    this.paymentId,
    this.receiptNumber,
    this.customerName = 'Cliente',
    this.amount = 0,
    this.paymentDate,
    this.method = 'Dinheiro',
    this.note,
  });

  final String? paymentId;
  final dynamic receiptNumber;
  final String customerName;
  final double amount;
  final DateTime? paymentDate;
  final String method;
  final String? note;

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  Map<String, dynamic>? receipt;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      Map<String, dynamic>? found;
      if (widget.paymentId != null && widget.paymentId!.isNotEmpty) {
        final raw = await rpc(
          'cobrapp_app_get_receipt_by_payment',
          params: {'p_payment_id': widget.paymentId},
        );
        if (raw is Map && raw.isNotEmpty) {
          found = Map<String, dynamic>.from(raw);
        }
      } else if (widget.receiptNumber != null) {
        final raw = await rpc('cobrapp_app_list_receipts');
        final list = (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        for (final item in list) {
          if ('${item['receipt_number']}' == '${widget.receiptNumber}') {
            found = item;
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        receipt = found;
        loading = false;
        if (found == null) error = 'Recibo não encontrado.';
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
    DateTime? d;
    if (raw is DateTime) {
      d = raw;
    } else {
      d = DateTime.tryParse((raw ?? '').toString())?.toLocal();
    }
    if (d == null) return '-';
    final base = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return time ? '$base ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}' : base;
  }

  String _appliedTo() {
    final type = (receipt?['payment_type'] ?? '').toString().toLowerCase();
    final principal = toDouble(receipt?['principal_amount']);
    final interest = toDouble(receipt?['interest_amount']);
    final late = toDouble(receipt?['late_interest_amount']);
    if (late > 0 && principal == 0 && interest == 0) return 'Juros de Mora';
    if (interest > 0 && principal == 0) return 'Somente Juros';
    if (principal > 0 && interest == 0) return 'Apenas Capital';
    if (type == 'interest') return 'Somente Juros';
    if (type == 'late_interest') return 'Juros de Mora';
    if (type == 'principal') return 'Apenas Capital';
    return 'Juros e Principal';
  }

  @override
  Widget build(BuildContext context) {
    final name = (receipt?['customer_name'] ?? widget.customerName).toString();
    final amount = receipt == null ? widget.amount : toDouble(receipt!['amount']);
    final number = receipt?['receipt_number'] ?? widget.receiptNumber;
    final paymentDate = receipt?['payment_date'] ?? receipt?['issued_at'] ?? widget.paymentDate;
    final note = (receipt?['note'] ?? receipt?['notes'] ?? widget.note ?? '').toString();
    final method = (receipt?['method'] ?? widget.method).toString();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(number == null ? 'Recibo' : 'Recibo nº $number'),
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.receipt_long_outlined, color: mint),
                                SizedBox(width: 8),
                                Text('RECIBO', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const Divider(height: 28),
                            const Text('CLIENTE', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            if ((receipt?['customer_document'] ?? '').toString().isNotEmpty)
                              Text('Identificação: ${receipt!['customer_document']}', style: const TextStyle(color: muted)),
                            const SizedBox(height: 18),
                            const Text('INFORMAÇÕES DO EMPRÉSTIMO', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            if (receipt != null) ...[
                              _row('Data do empréstimo', _date(receipt!['start_date'])),
                              _row('Juros do crédito', '${toDouble(receipt!['interest_rate']).toStringAsFixed(1)}%'),
                              _row('Valor do empréstimo', money(toDouble(receipt!['loan_amount']))),
                              _row('Dívida total', money(toDouble(receipt!['total_debt']))),
                            ],
                            const Divider(height: 28),
                            const Text('DETALHES DO RECIBO', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            _row('Data do Pagamento', _date(paymentDate, time: true)),
                            _row('Pagamento aplicado a', _appliedTo()),
                            _row('Total pago', money(amount)),
                            _row('Método de Pagamento', method),
                            if (note.trim().isNotEmpty) _row('Nota', note),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ASSINATURAS', style: TextStyle(color: muted, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 24),
                            const Text('Assinatura do cliente:'),
                            const SizedBox(height: 30),
                            const Divider(),
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 24),
                            const Text('Assinatura do credor:'),
                            const SizedBox(height: 30),
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
        padding: const EdgeInsets.symmetric(vertical: 5),
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
