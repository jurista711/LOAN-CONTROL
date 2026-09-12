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
      case 'daily':
        return 'Diário';
      case 'weekly':
        return 'Semanal';
      case 'biweekly':
        return 'Quinzenal';
      case 'monthly':
        return 'Mensal';
      default:
        return (raw ?? 'Mensal').toString();
    }
  }

  String _date(dynamic raw) {
    final d = DateTime.tryParse((raw ?? '').toString());
    if (d == null) return '-';
    const months = ['JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}. ${d.year}';
  }

  String _customerValue(String key, [String fallback = '—']) {
    final value = widget.customer[key];
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  void _noop() {}

  @override
  Widget build(BuildContext context) {
    final name = _customerValue('name', 'Cliente');
    final document = _customerValue('document', '');
    final active = loans.where((e) => !_isPaid(e)).toList();
    final paid = loans.where(_isPaid).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF061B15),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 72, child: _CustomerWave()),
              Transform.translate(
                offset: const Offset(0, -42),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1F1F22),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x334FC99B),
                        blurRadius: 24,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: Material(
                              color: const Color(0xFF30403E),
                              borderRadius: BorderRadius.circular(11),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(11),
                                onTap: () => Navigator.pop(context),
                                child: const Center(
                                  child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF78D8C3), size: 26),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5F8179),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              name.isEmpty ? '?' : name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 34,
                                color: Color(0xFF78D8C3),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w400),
                      ),
                      if (document.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, color: Color(0xFF78D8C3), size: 20),
                            const SizedBox(width: 8),
                            Text(document, style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C8F76), Color(0xFF8EDBCC)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(color: Color(0x4046CBA6), blurRadius: 16, offset: Offset(0, 7)),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.route_outlined, size: 17, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Não alocado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            SizedBox(width: 8),
                            Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _CustomerAction(
                              icon: Icons.person_outline,
                              label: 'Em formação',
                              onTap: _noop,
                            ),
                          ),
                          Expanded(
                            child: _CustomerAction(
                              icon: Icons.person_edit_alt_1_outlined,
                              label: 'Editar',
                              onTap: _noop,
                            ),
                          ),
                          Expanded(
                            child: _CustomerAction(
                              icon: Icons.more_vert_rounded,
                              label: 'Mais opções',
                              muted: true,
                              onTap: _noop,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(7, 0, 7, 110),
                  child: Column(
                    children: [
                      if (loading) const LinearProgressIndicator(minHeight: 2),
                      _sectionHeader('Empréstimos Ativos', active.length, const Color(0xFF2CA7FF), Icons.trending_up_rounded),
                      const SizedBox(height: 13),
                      if (!loading && active.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Sem crédito ativo', style: TextStyle(color: Color(0xFF8A888E))),
                        ),
                      for (final loan in active) _loanCard(name, loan, paidLoan: false),
                      if (paid.isNotEmpty) ...[
                        const SizedBox(height: 17),
                        _sectionHeader('Empréstimos Pagos', paid.length, const Color(0xFF4DDE65), Icons.check_circle_outline_rounded),
                        const SizedBox(height: 13),
                        for (final loan in paid) _loanCard(name, loan, paidLoan: true),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 48,
        height: 48,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF5BCDB7),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          onPressed: _noop,
          child: const Icon(Icons.sell_outlined, size: 25),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(107, 6, 107, 22),
          child: SizedBox(
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF176F5D), Color(0xFF8FE0CF)]),
                borderRadius: BorderRadius.circular(17),
                boxShadow: const [BoxShadow(color: Color(0x4749D8B0), blurRadius: 18, offset: Offset(0, 7))],
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
                onPressed: () => openPage(
                  context,
                  'Adicionar crédito',
                  CreateLoanPage(initialCustomerId: widget.customer['id']?.toString()),
                ),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text(
                  'Adicionar crédito',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
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
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: const Color(0xFF0E3138),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label ($count)',
            style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _loanCard(String customerName, Map<String, dynamic> loan, {required bool paidLoan}) {
    final amount = toDouble(loan['amount']);
    final total = toDouble(loan['total_debt']);
    final paidAmount = toDouble(loan['paid_amount']);
    final open = paidLoan ? 0.0 : (total - paidAmount).clamp(0, double.infinity).toDouble();
    final qty = int.tryParse('${loan['payments_number'] ?? 1}') ?? 1;
    final paymentValue = qty <= 0 ? total : total / qty;
    final rate = toDouble(loan['interest_rate']);
    final rawId = (loan['loan_number'] ?? loan['code'] ?? loan['reference'] ?? loan['id'] ?? '')
        .toString()
        .replaceAll('-', '')
        .toUpperCase();
    final shortId = rawId.length >= 9 ? '${rawId.substring(0, 6)}-${rawId.substring(6, 9)}' : rawId;
    final progress = total <= 0 ? 0.0 : (paidAmount / total).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF202023),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A4942)),
        boxShadow: const [BoxShadow(color: Color(0x3844CD9E), blurRadius: 22, offset: Offset(0, 12))],
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
          padding: const EdgeInsets.all(13),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF31443F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: Color(0xFFF5D54C), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      money(amount),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (shortId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF4C716A)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        shortId,
                        style: const TextStyle(color: Color(0xFF78D8C3), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 3,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (progress * 1000).round().clamp(1, 999),
                        child: const ColoredBox(color: Color(0xFFF08A54)),
                      ),
                      Expanded(
                        flex: (1000 - (progress * 1000).round()).clamp(1, 999),
                        child: const ColoredBox(color: Color(0xFFEEEEEE)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Pago: ${money(paidAmount)} / ${money(total)}', style: const TextStyle(fontSize: 12.5)),
              ),
              if (!paidLoan) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Saldo pendente: ${money(open)}',
                    style: const TextStyle(color: Color(0xFF78D8C3), fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFF35534D)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 135, child: _metric('Valor do pagamento', money(paymentValue), Icons.monetization_on_outlined)),
                  Expanded(flex: 80, child: _metric('Cotas', '$qty', Icons.tag)),
                  Expanded(flex: 80, child: _metric('Interesse', '${rate.toStringAsFixed(1)}', Icons.percent)),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF78D8C3), size: 31),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _metric(
                      'Frequência de Pagamentos',
                      _frequency(loan['payment_frequency']),
                      Icons.calendar_month_outlined,
                    ),
                  ),
                  const Icon(Icons.calendar_month_outlined, color: Color(0xFF78D8C3), size: 15),
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

  Widget _metric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF77747A), fontSize: 11)),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF78D8C3)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CustomerWave extends StatelessWidget {
  const _CustomerWave();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CustomerWaveClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF287763), Color(0xFF9DE1D3)]),
        ),
      ),
    );
  }
}

class _CustomerWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height * .71)
      ..cubicTo(size.width * .10, size.height * .78, size.width * .24, size.height * .99, size.width * .41, size.height * .75)
      ..cubicTo(size.width * .58, size.height * .50, size.width * .76, size.height * .96, size.width, size.height * .78)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CustomerAction extends StatelessWidget {
  const _CustomerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? const Color(0xFF9A979D) : const Color(0xFF72D3BF);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
