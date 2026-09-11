import 'package:flutter/material.dart';

import 'main.dart';
import 'loan_workspace.dart';

class ReferenceCustomerDetailPage extends StatefulWidget {
  const ReferenceCustomerDetailPage({
    super.key,
    required this.customer,
    required this.allLoans,
  });

  final Map<String, dynamic> customer;
  final List<Map<String, dynamic>> allLoans;

  @override
  State<ReferenceCustomerDetailPage> createState() => _ReferenceCustomerDetailPageState();
}

class _ReferenceCustomerDetailPageState extends State<ReferenceCustomerDetailPage> {
  bool loading = true;
  List<Map<String, dynamic>> loans = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final customerId = widget.customer['id']?.toString();
    try {
      final list = await rpc('cobrapp_app_list_loans');
      final base = (list as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((loan) => loan['customer_id']?.toString() == customerId)
          .toList();

      final enriched = await Future.wait(base.map((loan) async {
        try {
          final detail = await rpc('cobrapp_app_get_loan_detail', params: {'p_loan_id': loan['id']});
          if (detail is Map) return {...loan, ...Map<String, dynamic>.from(detail)};
        } catch (_) {}
        return loan;
      }));

      if (!mounted) return;
      setState(() {
        loans = enriched;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loans = widget.allLoans
            .where((loan) => loan['customer_id']?.toString() == customerId)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        loading = false;
      });
    }
  }

  String _frequency(dynamic raw) {
    final value = (raw ?? '').toString().toLowerCase();
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

  String _date(dynamic raw) {
    if (raw == null) return '-';
    final d = DateTime.tryParse(raw.toString());
    if (d == null) return raw.toString();
    const months = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}. ${d.year}';
  }

  void _notImplemented(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label ainda não foi ligado ao Supabase nesta reconstrução.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.customer['name'] ?? 'Cliente').toString();
    final document = (widget.customer['document'] ?? '').toString();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                    ),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFF567D72),
                    child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(fontSize: 26, color: mint)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
              if (document.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: mint, size: 22),
                    const SizedBox(width: 8),
                    Text(document, style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2A8D6E), Color(0xFF8DDFC7)]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.route_outlined, size: 17, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Não alocado', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(width: 7),
                      Icon(Icons.edit, size: 15, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_outline, size: 18),
                      label: const Text('Em formação'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _notImplemented('Editar cliente'),
                      icon: const Icon(Icons.edit_note, size: 19),
                      label: const Text('Editar'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _notImplemented('Mais opções'),
                      style: TextButton.styleFrom(foregroundColor: Colors.white70),
                      icon: const Icon(Icons.more_vert, size: 19),
                      label: const Text('Mais opções'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3440),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(left: BorderSide(color: Colors.lightBlueAccent, width: 5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.lightBlueAccent),
                    const SizedBox(width: 8),
                    Text('Empréstimos Ativos (${loans.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.lightBlueAccent)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (loading) const LinearProgressIndicator(),
              if (!loading && loans.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Center(child: Text('Nenhum empréstimo ativo', style: TextStyle(color: muted))),
                  ),
                ),
              for (final loan in loans) _loanCard(name, loan),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: const Color(0xFF5FCFB0),
        foregroundColor: Colors.white,
        onPressed: () => _notImplemented('Etiquetas'),
        child: const Icon(Icons.sell_outlined),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(88, 8, 88, 12),
          child: SizedBox(
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF17614D), Color(0xFF81DFC4)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x553DD0A5), blurRadius: 14)],
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                onPressed: () => openPage(
                  context,
                  'Adicionar crédito',
                  CreateLoanPage(initialCustomerId: widget.customer['id']?.toString()),
                ),
                icon: const Icon(Icons.request_quote_outlined, size: 19),
                label: const Text('Adicionar crédito', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loanCard(String customerName, Map<String, dynamic> loan) {
    final amount = toDouble(loan['amount']);
    final total = toDouble(loan['total_debt']);
    final paid = toDouble(loan['paid_amount']);
    final pending = (total - paid).clamp(0, double.infinity).toDouble();
    final installmentCount = int.tryParse('${loan['payments_number'] ?? 1}') ?? 1;
    final paymentValue = installmentCount <= 0 ? total : total / installmentCount;
    final rate = toDouble(loan['interest_rate']);
    final id = (loan['id'] ?? '').toString();
    final shortId = id.length > 9 ? id.substring(0, 9).toUpperCase() : id.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF305348)),
        boxShadow: const [BoxShadow(color: Color(0x4436C99D), blurRadius: 15)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoanWorkspacePage(
              loan: loan,
              customerName: customerName,
              customerId: widget.customer['id']?.toString(),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 14, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: const Color(0xFF30443E), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.trending_up_rounded, color: Colors.amberAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(money(amount), style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900))),
                  if (shortId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF4E766A)), borderRadius: BorderRadius.circular(8)),
                      child: Text(shortId, style: const TextStyle(color: mint, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.white70),
              const SizedBox(height: 7),
              Text('Pago: ${money(paid)} / ${money(total)}', style: const TextStyle(fontSize: 12.5)),
              const SizedBox(height: 3),
              Text('Saldo pendente: ${money(pending)}', style: const TextStyle(color: mint, fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFF365248)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _metric('Valor do pagamento', money(paymentValue), Icons.monetization_on_outlined)),
                  Expanded(child: _metric('Cotas', '$installmentCount', Icons.tag)),
                  Expanded(child: _metric('Interesse', '${rate.toStringAsFixed(1)}', Icons.percent)),
                  const Icon(Icons.chevron_right, color: mint, size: 30),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _metric('Frequência de Pagamentos', _frequency(loan['payment_frequency']), Icons.calendar_month_outlined)),
                  Text(_date(loan['start_date']), style: const TextStyle(fontSize: 12.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 11.5)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: mint),
            const SizedBox(width: 4),
            Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
          ],
        ),
      ],
    );
  }
}
