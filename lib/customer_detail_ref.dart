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
              CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFF647C76),
                child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(fontSize: 33, color: mint, fontWeight: FontWeight.w800)),
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
                onTap: () { Navigator.pop(context); _notImplemented('Desativar cliente'); },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Remover'),
                onTap: () { Navigator.pop(context); _notImplemented('Remover cliente'); },
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
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 70, child: _CustomerWave()),
              Transform.translate(
                offset: const Offset(0, -17),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D1D20),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Color(0x6648D8B1), blurRadius: 18, offset: Offset(0, 7))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 42,
                            height: 42,
                            child: IconButton.filledTonal(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w500)),
                                  if (document.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      const Icon(Icons.badge_outlined, color: mint, size: 17),
                                      const SizedBox(width: 5),
                                      Text(document, style: const TextStyle(fontSize: 14.5)),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: const Color(0xFF607A73),
                            child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(fontSize: 29, color: mint, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF2D9070), Color(0xFF96E5CF)]),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [BoxShadow(color: Color(0x443DD0A5), blurRadius: 10)],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.route_outlined, size: 15),
                              SizedBox(width: 5),
                              Text('Não alocado', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              SizedBox(width: 7),
                              Icon(Icons.edit_rounded, size: 14),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _CustomerAction(icon: Icons.person_outline, label: 'Em formaç...', onTap: _showCustomerInfo)),
                          Expanded(child: _CustomerAction(icon: Icons.edit_outlined, label: 'Editar', onTap: () => _notImplemented('Editar cliente'))),
                          Expanded(child: _CustomerAction(icon: Icons.more_vert_rounded, label: 'Mais opções', muted: true, onTap: _showMoreOptions)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(7, 0, 7, 102),
                  child: Column(
                    children: [
                      if (loading) const LinearProgressIndicator(minHeight: 2),
                      _sectionHeader('Empréstimos Ativos', active.length, const Color(0xFF2BA5F7), Icons.trending_up_rounded),
                      const SizedBox(height: 8),
                      if (!loading && active.isEmpty)
                        const Padding(padding: EdgeInsets.all(16), child: Text('Sem crédito ativo', style: TextStyle(color: muted))),
                      for (final loan in active) _loanCard(name, loan, paidLoan: false),
                      if (paid.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _sectionHeader('Empréstimos Pagos', paid.length, const Color(0xFF4DDE65), Icons.check_circle_outline_rounded),
                        const SizedBox(height: 8),
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
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: const Color(0xFF58CDAE),
        foregroundColor: Colors.white,
        onPressed: () => _notImplemented('Etiquetas'),
        child: const Icon(Icons.sell_outlined),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(95, 6, 95, 9),
          child: SizedBox(
            height: 42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF17614D), Color(0xFF81DFC4)]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Color(0x663DD0A5), blurRadius: 15)],
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                onPressed: () => openPage(
                  context,
                  'Adicionar crédito',
                  CreateLoanPage(initialCustomerId: widget.customer['id']?.toString()),
                ),
                icon: const Icon(Icons.request_quote_outlined, size: 17),
                label: const Text('Adicionar crédito', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
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
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(5),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Text('$label ($count)', style: TextStyle(color: color, fontSize: 15.5, fontWeight: FontWeight.w800)),
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
    final note = (loan['note'] ?? '').toString().trim();
    final rawId = (loan['loan_number'] ?? loan['code'] ?? loan['reference'] ?? loan['id'] ?? '').toString().replaceAll('-', '').toUpperCase();
    final shortId = rawId.length >= 9 ? '${rawId.substring(0, 6)}-${rawId.substring(6, 9)}' : rawId;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: paidLoan ? const Color(0xFF545454) : const Color(0xFF304F46)),
        boxShadow: [BoxShadow(color: paidLoan ? const Color(0x22111111) : const Color(0x5535C99C), blurRadius: 13)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 33,
                    height: 33,
                    decoration: BoxDecoration(color: const Color(0xFF324640), borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.trending_up_rounded, color: Colors.amberAccent, size: 22),
                  ),
                  const SizedBox(width: 7),
                  Expanded(child: Text(money(amount), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900))),
                  if (shortId.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF4A766A)), borderRadius: BorderRadius.circular(6)),
                      child: Text(shortId, style: const TextStyle(color: mint, fontSize: 9.5, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Container(height: 2, color: paidLoan ? orange : Colors.white70),
              const SizedBox(height: 5),
              Align(alignment: Alignment.centerLeft, child: Text('Pago: ${money(paid)} / ${money(total)}', style: const TextStyle(fontSize: 10.5))),
              if (!paidLoan) ...[
                const SizedBox(height: 2),
                Align(alignment: Alignment.centerLeft, child: Text('Saldo pendente: ${money(open)}', style: const TextStyle(color: mint, fontSize: 11.5, fontWeight: FontWeight.w800))),
              ],
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(child: _metric('Valor do pagamento', money(paymentValue), Icons.monetization_on_outlined)),
                  Expanded(child: _metric('Cotas', '$qty', Icons.tag)),
                  Expanded(child: _metric('Interesse', '${rate.toStringAsFixed(1)}', Icons.percent)),
                  const Icon(Icons.chevron_right_rounded, color: mint, size: 25),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _metric('Frequência de Pagamentos', _frequency(loan['payment_frequency']), Icons.calendar_month_outlined)),
                  const Icon(Icons.calendar_month_outlined, color: mint, size: 13),
                  const SizedBox(width: 4),
                  Text(_date(loan['start_date']), style: const TextStyle(fontSize: 9.8)),
                ],
              ),
              if (note.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFF38524A)),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sticky_note_2_outlined, color: mint, size: 13),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nota', style: TextStyle(color: muted, fontSize: 9.8)),
                          const SizedBox(height: 2),
                          Text(note, style: const TextStyle(fontSize: 10.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 9.2)),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(icon, size: 12, color: mint),
              const SizedBox(width: 3),
              Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800))),
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
  const _CustomerAction({required this.icon, required this.label, required this.onTap, this.muted = false});
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
              Icon(icon, size: 15, color: muted ? Colors.white70 : mint),
              const SizedBox(width: 5),
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: muted ? Colors.white70 : Colors.white, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      );
}
