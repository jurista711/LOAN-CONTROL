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

  bool _isPaid(Map<String, dynamic> loan) {
    final status = (loan['status'] ?? '').toString().toLowerCase();
    return status == 'paid' || status == 'completed' || status == 'closed';
  }

  String _frequency(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'daily': return 'Diário';
      case 'weekly': return 'Semanal';
      case 'biweekly': return 'Quinzenal';
      case 'monthly': return 'Mensal';
      default: return (raw ?? 'Mensal').toString();
    }
  }

  String _date(dynamic raw) {
    final d = DateTime.tryParse((raw ?? '').toString());
    if (d == null) return '-';
    const months = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}. ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.customer['name'] ?? 'Cliente').toString();
    final document = (widget.customer['document'] ?? '').toString();
    final active = loans.where((e) => !_isPaid(e)).toList();
    final paid = loans.where(_isPaid).toList();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 74, child: _CustomerWave()),
              Container(
                margin: const EdgeInsets.only(top: -16),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1D1D20),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Color(0x553FD1AD), blurRadius: 16, offset: Offset(0, 7))],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: IconButton.filledTonal(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 24),
                          ),
                        ),
                        const Spacer(),
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: const Color(0xFF5A7E74),
                          child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(fontSize: 30, color: mint, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                    ),
                    if (document.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, color: mint, size: 22),
                          const SizedBox(width: 6),
                          Text(document, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF2D9070), Color(0xFF96E5CF)]),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [BoxShadow(color: Color(0x442DD0A4), blurRadius: 12)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.route_outlined, size: 17),
                            SizedBox(width: 6),
                            Text('Não alocado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            SizedBox(width: 8),
                            Icon(Icons.edit_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Expanded(child: _CustomerAction(icon: Icons.person_outline, label: 'Em formaç...')),
                        Expanded(child: _CustomerAction(icon: Icons.person_edit_alt_1_outlined, label: 'Editar')),
                        Expanded(child: _CustomerAction(icon: Icons.more_vert_rounded, label: 'Mais opções', muted: true)),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 110),
                child: Column(
                  children: [
                    if (loading) const LinearProgressIndicator(minHeight: 2),
                    _sectionHeader('Empréstimos Ativos', active.length, const Color(0xFF2BA5F7), Icons.trending_up_rounded),
                    const SizedBox(height: 8),
                    if (!loading && active.isEmpty)
                      const Padding(padding: EdgeInsets.all(16), child: Text('Sem crédito ativo', style: TextStyle(color: muted))),
                    for (final loan in active) _loanCard(name, loan, paidLoan: false),
                    if (paid.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _sectionHeader('Empréstimos Pagos', paid.length, const Color(0xFF4DDE65), Icons.check_circle_outline_rounded),
                      const SizedBox(height: 8),
                      for (final loan in paid) _loanCard(name, loan, paidLoan: true),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: const Color(0xFF58CDAE),
        foregroundColor: Colors.white,
        onPressed: () {},
        child: const Icon(Icons.sell_outlined),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(84, 7, 84, 10),
          child: SizedBox(
            height: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF17614D), Color(0xFF81DFC4)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x663DD0A5), blurRadius: 15)],
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                onPressed: () => openPage(
                  context,
                  'Adicionar crédito',
                  CreateLoanPage(initialCustomerId: widget.customer['id']?.toString()),
                ),
                icon: const Icon(Icons.request_quote_outlined, size: 18),
                label: const Text('Adicionar crédito', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, int count, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text('$label ($count)', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _loanCard(String customerName, Map<String, dynamic> loan, {required bool paidLoan}) {
    final amount = toDouble(loan['amount']);
    final total = toDouble(loan['total_debt']);
    final paid = toDouble(loan['paid_amount']);
    final open = paidLoan ? 0.0 : (total - paid).clamp(0, double.infinity).toDouble();
    final qty = int.tryParse('${loan['payments_number'] ?? 1}') ?? 1;
    final paymentValue = qty <= 0 ? total : total / qty;
    final rate = toDouble(loan['interest_rate']);
    final rawId = (loan['id'] ?? '').toString().replaceAll('-', '').toUpperCase();
    final shortId = rawId.length >= 9 ? '${rawId.substring(0, 6)}-${rawId.substring(6, 9)}' : rawId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: paidLoan ? const Color(0xFF545454) : const Color(0xFF304F46)),
        boxShadow: [BoxShadow(color: paidLoan ? const Color(0x22111111) : const Color(0x4435C99C), blurRadius: 16)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: const Color(0xFF324640), borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.trending_up_rounded, color: Colors.amberAccent, size: 27),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: Text(money(amount), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                  if (shortId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF4A766A)), borderRadius: BorderRadius.circular(8)),
                      child: Text(shortId, style: const TextStyle(color: mint, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(height: 2, color: paidLoan ? orange : Colors.white70),
              const SizedBox(height: 7),
              Align(alignment: Alignment.centerLeft, child: Text('Pago: ${money(paid)} / ${money(total)}', style: const TextStyle(fontSize: 12.5))),
              if (!paidLoan) ...[
                const SizedBox(height: 3),
                Align(alignment: Alignment.centerLeft, child: Text('Saldo pendente: ${money(open)}', style: const TextStyle(color: mint, fontSize: 13.5, fontWeight: FontWeight.w800))),
              ],
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFF38524A)),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(child: _metric('Valor do pagamento', money(paymentValue), Icons.monetization_on_outlined)),
                  Expanded(child: _metric('Cotas', '$qty', Icons.tag)),
                  Expanded(child: _metric('Interesse', '${rate.toStringAsFixed(1)}', Icons.percent)),
                  const Icon(Icons.chevron_right_rounded, color: mint, size: 30),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(child: _metric('Frequência de Pagamentos', _frequency(loan['payment_frequency']), Icons.calendar_month_outlined)),
                  const Icon(Icons.calendar_month_outlined, color: mint, size: 15),
                  const SizedBox(width: 5),
                  Text(_date(loan['start_date']), style: const TextStyle(fontSize: 11.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 10.5)),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(icon, size: 15, color: mint),
              const SizedBox(width: 4),
              Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800))),
            ],
          ),
        ],
      );
}

class _CustomerWave extends StatelessWidget {
  const _CustomerWave();
  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: _CustomerWaveClipper(),
        child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1D6A50), Color(0xFF9EE8D2)]))),
      );
}

class _CustomerWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height * .62)
    ..cubicTo(size.width * .2, size.height * .95, size.width * .52, size.height * .5, size.width, size.height * .73)
    ..lineTo(size.width, 0)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CustomerAction extends StatelessWidget {
  const _CustomerAction({required this.icon, required this.label, this.muted = false});
  final IconData icon;
  final String label;
  final bool muted;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: muted ? Colors.white54 : mint, size: 19),
            const SizedBox(width: 5),
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted ? Colors.white60 : mint, fontSize: 13.5))),
          ],
        ),
      );
}
