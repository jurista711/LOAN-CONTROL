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
          final detail = await rpc(
            'cobrapp_app_get_loan_detail',
            params: {'p_loan_id': loan['id']},
          );
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

  void _notImplemented(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label ainda não foi ligado nesta reconstrução.')),
    );
  }

  Future<void> _showCustomerInfo() async {
    final name = _customerValue('name', 'Cliente');
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isEmpty ? name : parts.first;
    final last = parts.length <= 1 ? '—' : parts.skip(1).join(' ');
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .74),
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        backgroundColor: const Color(0xFF29292C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF647C76),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 33, color: mint, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 14),
              Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(width: 56, height: 2, color: mint),
              const SizedBox(height: 14),
              _infoRow('ID', _customerValue('document')),
              _infoRow('Nome', first),
              _infoRow('Sobrenome', last),
              _infoRow('Endereço', _customerValue('address')),
              _infoRow('Email', _customerValue('email')),
              _infoRow('Telemóvel', _customerValue('phone')),
              _infoRow('Linha fixa', _customerValue('landline')),
              _infoRow('Nota', _customerValue('notes')),
              const SizedBox(height: 6),
              IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 92, child: Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.white70))),
            Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, color: Colors.white))),
          ],
        ),
      );

  Future<void> _showMoreOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF202024),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.person_off_outlined, color: orange),
                title: const Text('Desativar'),
                onTap: () {
                  Navigator.pop(context);
                  _notImplemented('Desativar cliente');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Remover'),
                onTap: () {
                  Navigator.pop(context);
                  _notImplemented('Remover cliente');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              SizedBox(
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: const [
                    _OriginalWave(),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -42),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1F1F22),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
                    boxShadow: [BoxShadow(color: Color(0x3330C99B), blurRadius: 24, offset: Offset(0, 14))],
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                                side: const BorderSide(color: Color(0xFF3D615A)),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(11),
                                onTap: () => Navigator.pop(context),
                                child: const Icon(Icons.arrow_back_ios_new_rounded, color: mint, size: 30),
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
                              style: const TextStyle(fontSize: 34, color: mint, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(name, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w400)),
                      if (document.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, color: mint, size: 20),
                            const SizedBox(width: 8),
                            Text(document, style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF2C8F76), Color(0xFF8EDBCC)]),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [BoxShadow(color: Color(0x4046CBA6), blurRadius: 16, offset: Offset(0, 7))],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.route_outlined, color: Colors.white, size: 17),
                            SizedBox(width: 8),
                            Text('Não alocado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            SizedBox(width: 8),
                            Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: _OriginalAction(icon: Icons.person_outline, label: 'Em formação', onTap: _showCustomerInfo)),
                          Expanded(child: _OriginalAction(icon: Icons.edit_outlined, label: 'Editar', onTap: () => _notImplemented('Editar cliente'))),
                          Expanded(child: _OriginalAction(icon: Icons.more_vert_rounded, label: 'Mais opções', muted: true, onTap: _showMoreOptions)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -25),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(7, 0, 7, 110),
                  child: Column(
                    children: [
                      if (loading) const LinearProgressIndicator(minHeight: 2),
                      _sectionHeader('Empréstimos Ativos', active.length, const Color(0xFF2CA7FF), Icons.trending_up_rounded),
                      const SizedBox(height: 13),
                      if (!loading && active.isEmpty)
                        const Padding(padding: EdgeInsets.all(16), child: Text('Sem crédito ativo', style: TextStyle(color: muted))),
                      for (final loan in active) _loanCard(name, loan, paidLoan: false),
                      if (paid.isNotEmpty) ...[
                        const SizedBox(height: 16),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: SizedBox(
          width: 48,
          height: 48,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF5BCDB7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            onPressed: () => _notImplemented('Etiquetas'),
            child: const Icon(Icons.local_offer_outlined, size: 25),
          ),
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
                icon: const Icon(Icons.request_quote_outlined, size: 18),
                label: const Text('Adicionar crédito', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
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
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF0E3138),
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text('$label ($count)', style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w800)),
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
    final rawId = (loan['loan_number'] ?? loan['code'] ?? loan['reference'] ?? loan['id'] ?? '')
        .toString()
        .replaceAll('-', '')
        .toUpperCase();
    final shortId = rawId.length >= 9 ? '${rawId.substring(0, 6)}-${rawId.substring(6, 9)}' : rawId;
    final progress = total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF202023),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A4942)),
        boxShadow: const [BoxShadow(color: Color(0x3830CD9E), blurRadius: 22, offset: Offset(0, 12))],
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
                    decoration: BoxDecoration(color: const Color(0xFF31443F), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.trending_up_rounded, color: Color(0xFFF5D54C), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(money(amount), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
                  if (shortId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF4C716A)), borderRadius: BorderRadius.circular(8)),
                      child: Text(shortId, style: const TextStyle(color: mint, fontSize: 11, fontWeight: FontWeight.w700)),
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
                      Expanded(flex: (progress * 1000).round().clamp(0, 1000), child: Container(color: const Color(0xFFF08A54))),
                      Expanded(flex: ((1 - progress) * 1000).round().clamp(0, 1000), child: Container(color: const Color(0xFFEEEEEE))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerLeft, child: Text('Pago: ${money(paid)} / ${money(total)}', style: const TextStyle(fontSize: 12.5))),
              if (!paidLoan) ...[
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerLeft, child: Text('Saldo pendente: ${money(open)}', style: const TextStyle(color: mint, fontSize: 13, fontWeight: FontWeight.w800))),
              ],
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFF35534D)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 135, child: _metric('Valor do pagamento', money(paymentValue), Icons.monetization_on_outlined)),
                  const SizedBox(width: 8),
                  Expanded(flex: 80, child: _metric('Cotas', '$qty', Icons.tag)),
                  const SizedBox(width: 8),
                  Expanded(flex: 80, child: _metric('Interesse', rate.toStringAsFixed(1), Icons.percent)),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: mint, size: 31),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _metric('Frequência de Pagamentos', _frequency(loan['payment_frequency']), Icons.calendar_month_outlined)),
                  const SizedBox(width: 10),
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
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF77747A), fontSize: 11)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 15, color: mint),
              const SizedBox(width: 4),
              Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
            ],
          ),
        ],
      );
}

class _OriginalWave extends StatelessWidget {
  const _OriginalWave();

  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: _OriginalWaveClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF287763), Color(0xFF9DE1D3)]),
          ),
        ),
      );
}

class _OriginalWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height * .72)
    ..cubicTo(size.width * .09, size.height * .79, size.width * .27, size.height * .84, size.width * .41, size.height * .75)
    ..cubicTo(size.width * .62, size.height * .62, size.width * .76, size.height * .92, size.width, size.height * .78)
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _OriginalAction extends StatelessWidget {
  const _OriginalAction({
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
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: muted ? const Color(0xFF9A979D) : const Color(0xFF72D3BF)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: 16,
                    color: muted ? const Color(0xFF9A979D) : const Color(0xFF72D3BF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
