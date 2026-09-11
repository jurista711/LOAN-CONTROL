import 'package:flutter/material.dart';

import 'main.dart';
import 'payment_flow.dart';

class LoanWorkspacePage extends StatefulWidget {
  const LoanWorkspacePage({
    super.key,
    required this.loan,
    required this.customerName,
    required this.customerId,
  });

  final Map<String, dynamic> loan;
  final String customerName;
  final String? customerId;

  @override
  State<LoanWorkspacePage> createState() => _LoanWorkspacePageState();
}

class _LoanWorkspacePageState extends State<LoanWorkspacePage> {
  int tab = 0;
  List<Map<String, dynamic>> receipts = [];
  bool loadingReceipts = false;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => loadingReceipts = true);
    try {
      final result = await rpc('cobrapp_app_list_receipts');
      final rows = (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((r) => (r['customer_name'] ?? '').toString().trim().toLowerCase() == widget.customerName.trim().toLowerCase())
          .toList();
      if (!mounted) return;
      setState(() {
        receipts = rows;
        loadingReceipts = false;
      });
    } catch (_) {
      if (mounted) setState(() => loadingReceipts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final principal = toDouble(widget.loan['principal'] ?? widget.loan['amount']);
    final rate = toDouble(widget.loan['interest_rate']);
    final totalDebt = toDouble(widget.loan['total_debt'] ?? widget.loan['amount']);
    final frequency = (widget.loan['payment_frequency'] ?? 'Mensal').toString();
    final status = statusPt(widget.loan['status']);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF216B4F), Color(0xFF83DDC2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF174B3E),
                    child: Text(widget.customerName.isEmpty ? '?' : widget.customerName[0].toUpperCase()),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.customerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _valueRow('Valor', money(principal)),
                          _valueRow('Juros do crédito', '${rate.toStringAsFixed(1)}%'),
                          _valueRow('Frequência de Pagamento', frequency),
                          _valueRow('Dívida Total', money(totalDebt)),
                          _valueRow('Status', status),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ConnectedPaymentPage(loan: widget.loan)),
                                  ),
                                  icon: const Icon(Icons.payments_outlined),
                                  label: const Text('Pagar'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => openPage(
                                    context,
                                    'Novo Empréstimo',
                                    CreateLoanPage(initialCustomerId: widget.customerId),
                                  ),
                                  icon: const Icon(Icons.add_card),
                                  label: const Text('Adicionar crédito'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Plano de pagamento'), icon: Icon(Icons.list_alt_outlined)),
                      ButtonSegment(value: 1, label: Text('Registro'), icon: Icon(Icons.receipt_long_outlined)),
                      ButtonSegment(value: 2, label: Text('Gestões'), icon: Icon(Icons.tune_outlined)),
                    ],
                    selected: {tab},
                    onSelectionChanged: (value) => setState(() => tab = value.first),
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 14),
                  if (tab == 0) _paymentPlan(totalDebt),
                  if (tab == 1) _receiptList(),
                  if (tab == 2) _management(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(46, 8, 46, 12),
          child: SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () => openPage(
                context,
                'Novo Empréstimo',
                CreateLoanPage(initialCustomerId: widget.customerId),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar crédito', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _valueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _paymentPlan(double totalDebt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Plano de pagamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _valueRow('Balanço total', money(totalDebt)),
            _valueRow('Total pago', money(toDouble(widget.loan['paid_amount']))),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ConnectedPaymentPage(loan: widget.loan)),
                ),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Pagar parcela'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptList() {
    if (loadingReceipts) return const Center(child: CircularProgressIndicator());
    if (receipts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Nenhum recibo para este cliente', style: TextStyle(color: muted))),
        ),
      );
    }
    return Column(
      children: receipts.map((receipt) {
        final number = (receipt['receipt_number'] ?? '').toString();
        final amount = toDouble(receipt['amount']);
        final date = (receipt['payment_date'] ?? receipt['created_at'] ?? '').toString();
        return Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: mintDark, child: Icon(Icons.receipt_long_outlined, color: mint)),
            title: Text(number.isEmpty ? 'Recibo' : 'Recibo #$number', style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(date.isEmpty ? widget.customerName : '${widget.customerName}\n$date'),
            isThreeLine: date.isNotEmpty,
            trailing: Text(money(amount), style: const TextStyle(fontWeight: FontWeight.w900)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReceiptViewPage(receipt: receipt, customerName: widget.customerName)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _management() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.add_card, color: mint),
              title: const Text('Adicionar outro empréstimo'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openPage(
                context,
                'Novo Empréstimo',
                CreateLoanPage(initialCustomerId: widget.customerId),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined, color: mint),
              title: const Text('Ver recibos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => tab = 1),
            ),
          ],
        ),
      ),
    );
  }
}

class ReceiptViewPage extends StatelessWidget {
  const ReceiptViewPage({super.key, required this.receipt, required this.customerName});
  final Map<String, dynamic> receipt;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final number = (receipt['receipt_number'] ?? '').toString();
    final amount = toDouble(receipt['amount']);
    final date = (receipt['payment_date'] ?? receipt['created_at'] ?? '').toString();
    final notes = (receipt['notes'] ?? '').toString();
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, title: Text(number.isEmpty ? 'Recibo' : 'Recibo #$number')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 38, color: mint),
                  const SizedBox(height: 14),
                  Text(customerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 18),
                  _line('Valor recebido', money(amount)),
                  _line('Data', date.isEmpty ? '-' : date),
                  if (notes.isNotEmpty) _line('Observação', notes),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(label, style: const TextStyle(color: muted))),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800))),
        ]),
      );
}
