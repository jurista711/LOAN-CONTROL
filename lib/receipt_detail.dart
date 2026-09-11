import 'package:flutter/material.dart';

import 'main.dart';

class ReceiptDetailPage extends StatefulWidget {
  const ReceiptDetailPage({
    super.key,
    required this.receiptNumber,
    required this.customerName,
    required this.amount,
    required this.paymentDate,
    required this.method,
    this.note,
  });

  final dynamic receiptNumber;
  final String customerName;
  final double amount;
  final DateTime paymentDate;
  final String method;
  final String? note;

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  Map<String, dynamic>? receipt;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rpc('cobrapp_app_list_receipts');
      final list = (raw as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      Map<String, dynamic>? found;
      for (final item in list) {
        if ('${item['receipt_number']}' == '${widget.receiptNumber}') {
          found = item;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        receipt = found;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final name = (receipt?['customer_name'] ?? widget.customerName).toString();
    final amount = receipt == null ? widget.amount : toDouble(receipt!['amount']);
    final number = receipt?['receipt_number'] ?? widget.receiptNumber;
    final issuedRaw = receipt?['payment_date'] ?? receipt?['created_at'];
    final issued = DateTime.tryParse('${issuedRaw ?? ''}') ?? widget.paymentDate;
    final note = (receipt?['notes'] ?? widget.note ?? '').toString();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: const Text('Recibo de pagamento'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (loading) const LinearProgressIndicator(minHeight: 2),
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
                      Text('RECIBO DE PAGAMENTO', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const Divider(height: 28),
                  _row('Recibo', '#$number'),
                  _row('Cliente', name),
                  _row('Valor', money(amount)),
                  _row('Data', _date(issued)),
                  _row('Método', widget.method),
                  if (note.trim().isNotEmpty) _row('Nota', note),
                  const SizedBox(height: 16),
                  const Text(
                    'Pagamento registrado com sucesso.',
                    style: TextStyle(color: mint, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('CONCLUIR'),
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
            SizedBox(width: 88, child: Text(label, style: const TextStyle(color: muted))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );
}
