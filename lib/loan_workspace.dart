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
  bool loading = true;
  Map<String, dynamic> detail = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await rpc(
        'cobrapp_app_get_loan_detail',
        params: {'p_loan_id': widget.loan['id']},
      );
      if (!mounted) return;
      setState(() {
        detail = result is Map
            ? Map<String, dynamic>.from(result)
            : Map<String, dynamic>.from(widget.loan);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        detail = Map<String, dynamic>.from(widget.loan);
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get installments {
    final raw = detail['installments'];
    if (raw is! List) return const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  List<Map<String, dynamic>> get payments {
    final raw = detail['payments'];
    if (raw is! List) return const [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  String get customerName {
    final customers = detail['customers'];
    if (customers is Map && customers['full_name'] != null) {
      return customers['full_name'].toString();
    }
    return widget.customerName;
  }

  double get principal => toDouble(detail['amount'] ?? widget.loan['amount']);
  double get totalDebt => toDouble(detail['total_debt'] ?? widget.loan['total_debt']);
  double get rate => toDouble(detail['interest_rate']);

  String _frequency() {
    final value = (detail['payment_frequency'] ?? widget.loan['payment_frequency'] ?? '').toString().toLowerCase();
    switch (value) {
      case 'weekly':
        return 'Semanal';
      case 'biweekly':
        return 'Quinzenal';
      case 'daily':
        return 'Diário';
      case 'monthly':
        return 'Mensal';
      default:
        return value.isEmpty ? 'Mensal' : value;
    }
  }

  String _interestType() {
    final value = (detail['interest_type'] ?? '').toString().toLowerCase();
    if (value == 'initial_capital') return 'Capital inicial';
    if (value == 'each_payment') return 'Por parcela';
    return value.isEmpty ? 'Capital inicial' : value;
  }

  String _date(dynamic raw) {
    if (raw == null) return '-';
    final text = raw.toString();
    final d = DateTime.tryParse(text);
    if (d == null) return text;
    const months = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}. ${d.year.toString().substring(2)}';
  }

  void _notImplemented(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label ainda não foi ligado ao Supabase nesta reconstrução.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: ClipPath(
                clipper: _LoanWaveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1D6650), Color(0xFF8FE4CB)],
                      begin: Alignment.topLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 116),
                  children: [
                    _customerBar(),
                    const SizedBox(height: 8),
                    _loanHeaderCard(),
                    const SizedBox(height: 10),
                    _tabs(),
                    const SizedBox(height: 10),
                    if (loading) const LinearProgressIndicator(),
                    if (!loading && tab == 0) _planTab(),
                    if (!loading && tab == 1) _registerTab(),
                    if (!loading && tab == 2) _managementTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'expand-loan',
            backgroundColor: const Color(0xFF165E4B),
            foregroundColor: Colors.white,
            onPressed: () => _notImplemented('Expandir'),
            child: const Icon(Icons.open_in_full),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.small(
            heroTag: 'print-loan',
            backgroundColor: const Color(0xFF5FCFB0),
            foregroundColor: Colors.white,
            onPressed: () => _notImplemented('Imprimir'),
            child: const Icon(Icons.print),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(115, 8, 115, 12),
          child: SizedBox(
            height: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF17614D), Color(0xFF80DFC3)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x553DD0A5), blurRadius: 14)],
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => ConnectedPaymentPage(loan: {...widget.loan, ...detail})),
                  );
                  if (changed == true) _load();
                },
                icon: const Icon(Icons.monetization_on_outlined, size: 18),
                label: const Text('Adicionar', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _customerBar() {
    return Row(
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: IconButton.filledTonal(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 17,
          backgroundColor: const Color(0xFF365B50),
          child: Text(
            customerName.isEmpty ? '?' : customerName[0].toUpperCase(),
            style: const TextStyle(color: mint, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _notImplemented,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'Renovar', child: Text('Renovar')),
            PopupMenuItem(value: 'Marcar como Pago', child: Text('Marcar como Pago')),
            PopupMenuItem(value: 'Editar datas de vencimento', child: Text('Editar datas de vencimento')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'Imprimir Plano de Pagamento', child: Text('Imprimir Plano de Pagamento')),
            PopupMenuItem(value: 'Imprimir Histórico de Pagamentos', child: Text('Imprimir Histórico de Pagamentos')),
            PopupMenuItem(value: 'Documentos', child: Text('Documentos')),
          ],
        ),
      ],
    );
  }

  Widget _loanHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _headerMetric('Valor', money(principal))),
                Expanded(child: _headerMetric('Juros do crédito', '${rate.toStringAsFixed(1)}%')),
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFF30433E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: Colors.amberAccent, size: 34),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _headerMetric('Tipo de juros', _interestType())),
                Expanded(child: _headerMetric('Frequência de Pagamento', _frequency())),
                const SizedBox(width: 66),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(statusPt(detail['status'] ?? widget.loan['status'])),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _notImplemented('Editar crédito'),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar crédito'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _notImplemented('Remover'),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remover'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 4, height: 38, decoration: BoxDecoration(color: mint, borderRadius: BorderRadius.circular(8))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 12)),
                const SizedBox(height: 3),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    final labels = const [
      ('Plano de pagamento', Icons.monetization_on_outlined),
      ('Registro', Icons.receipt_long_outlined),
      ('Gestões', Icons.headset_mic_outlined),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF345248)),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = tab == i;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => tab = i),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF274C42) : Colors.transparent,
                  border: selected ? Border.all(color: const Color(0xFF5A9C88)) : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(labels[i].$2, size: 16, color: selected ? mint : muted),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        labels[i].$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: selected ? mint : Colors.white70, fontWeight: selected ? FontWeight.w800 : FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _planTab() {
    final rows = installments;
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: _StatusChip('Encostas', Color(0xFFFFE83A), Colors.black)),
            SizedBox(width: 7),
            Expanded(child: _StatusChip('Pago', Color(0xFF83D984), Colors.black)),
            SizedBox(width: 7),
            Expanded(child: _StatusChip('Atrasado', Color(0xFFFF3E42), Colors.black)),
            SizedBox(width: 7),
            Expanded(child: _StatusChip('Anulada', Color(0xFFE6E6E6), Colors.black)),
          ],
        ),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Nenhuma parcela disponível', style: TextStyle(color: muted))),
            ),
          ),
        for (final row in rows) _installmentCard(row),
      ],
    );
  }

  Widget _installmentCard(Map<String, dynamic> row) {
    final total = toDouble(row['total']);
    final paid = toDouble(row['paid_amount']);
    final interest = toDouble(row['interest']);
    final principalOpen = (toDouble(row['principal']) - (paid - interest).clamp(0, double.infinity)).clamp(0, double.infinity).toDouble();
    final interestOpen = (interest - paid.clamp(0, interest)).clamp(0, double.infinity).toDouble();
    final balance = (total - paid).clamp(0, double.infinity).toDouble();
    final number = row['number'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF616D20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 22, child: Text('$number', style: const TextStyle(color: muted))),
            Expanded(child: _installmentMetric('Balança\nprincipal', money(principalOpen))),
            Expanded(child: _installmentMetric('Saldo de juros', money(interestOpen))),
            Expanded(child: _installmentMetric('Total pago', money(paid))),
            Expanded(child: _installmentMetric('Balanço total\nExpira ${_date(row['due_date'])}', money(balance))),
            PopupMenuButton<String>(
              iconSize: 18,
              onSelected: _notImplemented,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'Editar parcela', child: Text('Editar parcela')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _installmentMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _registerTab() {
    final capital = payments.fold<double>(0, (s, p) => s + toDouble(p['principal_amount'] ?? p['amount']));
    final interest = payments.fold<double>(0, (s, p) => s + toDouble(p['interest_amount']));
    final late = payments.fold<double>(0, (s, p) => s + toDouble(p['late_interest_amount']));
    final total = payments.fold<double>(0, (s, p) => s + toDouble(p['amount']));

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF26775E), Color(0xFF83DFC4)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pagamentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 12),
              _paymentSummaryRow('Pagamento de Capital', money(capital)),
              _paymentSummaryRow('Pagamento de Juros', money(interest)),
              _paymentSummaryRow('Juros em Atraso', money(late)),
              const Divider(color: Colors.white30),
              _paymentSummaryRow('Total de Pagamentos', money(total), bold: true),
              const SizedBox(height: 10),
              const Center(child: Text('Mostrar mais', style: TextStyle(color: Colors.white70))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (payments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: Text('Este empréstimo ainda não tem histórico de pagamentos', style: TextStyle(color: muted), textAlign: TextAlign.center)),
            ),
          )
        else
          for (final p in payments)
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: mintDark, child: Icon(Icons.payments_outlined, color: mint)),
                title: Text(money(toDouble(p['amount'])), style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${_date(p['payment_date'])} • ${(p['method'] ?? 'Dinheiro')}'),
              ),
            ),
      ],
    );
  }

  Widget _paymentSummaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.white, fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _managementTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: const [
            Icon(Icons.headset_mic_outlined, size: 34, color: mint),
            SizedBox(height: 10),
            Text('Nenhuma gestão registrada', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text('Toque + para registrar uma gestão de cobrança', style: TextStyle(color: muted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.background, this.foreground);
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18)),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check, size: 13, color: foreground),
          const SizedBox(width: 3),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: foreground, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _LoanWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height * .65)
      ..cubicTo(size.width * .25, size.height * .95, size.width * .58, size.height * .48, size.width, size.height * .73)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
