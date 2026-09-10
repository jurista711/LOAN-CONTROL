import 'package:flutter/material.dart';

import 'main.dart';

class OriginalCustomerFlow extends StatefulWidget {
  const OriginalCustomerFlow({super.key});

  @override
  State<OriginalCustomerFlow> createState() => _OriginalCustomerFlowState();
}

class _OriginalCustomerFlowState extends State<OriginalCustomerFlow> {
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> loans = [];
  bool loading = true;
  bool searching = false;
  String query = '';
  String selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    try {
      final result = await Future.wait([
        rpc('cobrapp_app_list_customers'),
        rpc('cobrapp_app_list_loans'),
      ]);
      if (!mounted) return;
      setState(() {
        customers = (result[0] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        loans = (result[1] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  int _loanCount(Map<String, dynamic> customer) {
    final id = customer['id']?.toString();
    return loans.where((loan) => loan['customer_id']?.toString() == id).length;
  }

  @override
  Widget build(BuildContext context) {
    final visible = customers.where((customer) {
      final text = '${customer['name'] ?? ''} ${customer['document'] ?? ''} ${customer['phone'] ?? ''}'.toLowerCase();
      return text.contains(query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            WaveHeader(
              title: 'Clientes (${customers.length})',
              actions: [
                IconButton(
                  onPressed: () => setState(() => searching = !searching),
                  icon: const Icon(Icons.search, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.route_outlined, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.sell_outlined, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.sort_rounded, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
              child: Column(
                children: [
                  if (searching) ...[
                    TextField(
                      autofocus: true,
                      onChanged: (value) => setState(() => query = value),
                      decoration: const InputDecoration(
                        hintText: 'Buscar cliente',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Todos', 'Pago hoje', 'Pagam hoje', 'Com crédito']
                          .map(
                            (filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: selectedFilter == filter,
                                onSelected: (_) => setState(() => selectedFilter = filter),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (loading) const LinearProgressIndicator(),
                  for (final customer in visible) _customerCard(customer),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 265,
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D8E6F), Color(0xFF9BE7D0)],
                        ),
                        borderRadius: BorderRadius.circular(29),
                        boxShadow: const [
                          BoxShadow(color: Color(0x5539C49D), blurRadius: 18),
                        ],
                      ),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: () => openPage(
                          context,
                          'Adicionar cliente',
                          const CreateCustomerPage(),
                        ),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text(
                          'Adicionar cliente',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF193D34),
        foregroundColor: mint,
        onPressed: () => openPage(context, 'Calculadora', const CalculatorPage()),
        child: const Icon(Icons.calculate_outlined),
      ),
    );
  }

  Widget _customerCard(Map<String, dynamic> customer) {
    final name = (customer['name'] ?? 'Cliente').toString();
    final document = (customer['document'] ?? 'Sem identificação').toString();
    final count = _loanCount(customer);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFF355A4E)),
        boxShadow: const [
          BoxShadow(color: Color(0x332FC89A), blurRadius: 13),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: mintDark,
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: const TextStyle(
              color: mint,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 15, color: muted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    document,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2B3532),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Não alocado',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF173D54),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.credit_card, size: 14, color: Colors.lightBlueAccent),
                  const SizedBox(width: 4),
                  Text('$count', style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OriginalCustomerDetail(
              customer: customer,
              allLoans: loans,
            ),
          ),
        ),
      ),
    );
  }
}

class OriginalCustomerDetail extends StatefulWidget {
  const OriginalCustomerDetail({
    super.key,
    required this.customer,
    required this.allLoans,
  });

  final Map<String, dynamic> customer;
  final List<Map<String, dynamic>> allLoans;

  @override
  State<OriginalCustomerDetail> createState() => _OriginalCustomerDetailState();
}

class _OriginalCustomerDetailState extends State<OriginalCustomerDetail> {
  late List<Map<String, dynamic>> loans;

  @override
  void initState() {
    super.initState();
    _syncLoans(widget.allLoans);
  }

  void _syncLoans(List<Map<String, dynamic>> allLoans) {
    final customerId = widget.customer['id']?.toString();
    loans = allLoans
        .where((loan) => loan['customer_id']?.toString() == customerId)
        .toList();
  }

  Future<void> _refresh() async {
    final result = await rpc('cobrapp_app_list_loans');
    if (!mounted) return;
    setState(() {
      _syncLoans(
        (result as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.customer['name'] ?? 'Cliente').toString();
    final document = (widget.customer['document'] ?? '').toString();

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            WaveHeader(
              title: name,
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: mintDark,
                        child: Text(
                          name.isEmpty ? '?' : name[0].toUpperCase(),
                          style: const TextStyle(
                            color: mint,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (document.isNotEmpty)
                              Text(document, style: const TextStyle(color: muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => openPage(
                        context,
                        'Novo Empréstimo',
                        CreateLoanPage(
                          initialCustomerId: widget.customer['id']?.toString(),
                        ),
                      ),
                      icon: const Icon(Icons.add_card),
                      label: const Text(
                        'Novo Empréstimo',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Empréstimos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  if (loans.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Center(
                          child: Text(
                            'Nenhum empréstimo para este cliente',
                            style: TextStyle(color: muted),
                          ),
                        ),
                      ),
                    ),
                  for (final loan in loans) _loanCard(name, loan),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loanCard(String customerName, Map<String, dynamic> loan) {
    final amount = toDouble(loan['amount'] ?? loan['principal']);
    final frequency = (loan['payment_frequency'] ?? 'Mensal').toString();
    final status = statusPt(loan['status']);

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: mintDark,
                child: Icon(Icons.account_balance_wallet_outlined, color: mint),
              ),
              title: Text(
                money(amount),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              subtitle: Text('$frequency • $status'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openPage(
                context,
                customerName,
                LoanDetail(loanId: loan['id'].toString()),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openPage(
                      context,
                      customerName,
                      LoanDetail(loanId: loan['id'].toString()),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Ver crédito'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OriginalPaymentPage(loan: loan),
                      ),
                    ),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Pagar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OriginalPaymentPage extends StatefulWidget {
  const OriginalPaymentPage({super.key, required this.loan});

  final Map<String, dynamic> loan;

  @override
  State<OriginalPaymentPage> createState() => _OriginalPaymentPageState();
}

class _OriginalPaymentPageState extends State<OriginalPaymentPage> {
  final valueController = TextEditingController();
  final noteController = TextEditingController();
  int quantity = 1;
  String applyTo = 'Juros e Principal';
  String method = 'Dinheiro';
  bool share = true;

  @override
  void dispose() {
    valueController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final installment = toDouble(
      widget.loan['installment_amount'] ??
          widget.loan['installment_value'] ??
          widget.loan['amount'],
    );
    final interest = toDouble(
      widget.loan['interest_amount'] ?? widget.loan['interest_value'],
    );
    final debt = toDouble(widget.loan['total_debt'] ?? widget.loan['amount']);
    final customerName = (widget.loan['customer_name'] ?? 'Cliente').toString();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                CircleAvatar(
                  backgroundColor: mintDark,
                  child: Text(
                    customerName.isEmpty ? '?' : customerName[0].toUpperCase(),
                    style: const TextStyle(color: mint, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                const Icon(Icons.more_vert),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adicionar Empréstimo',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 18),
                    _amountRow('Valor da Parcela', money(installment), true),
                    _amountRow('Somente Juros', money(interest), false),
                    _amountRow('Dívida Total', money(debt), false),
                    const SizedBox(height: 12),
                    TextField(
                      controller: valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Resumo do Pagamento',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Juros: R$ 0,00'),
                        Text('Principal: R$ 0,00'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: applyTo,
                      decoration: const InputDecoration(labelText: 'Aplicar o pagamento a*'),
                      items: const [
                        DropdownMenuItem(value: 'Juros e Principal', child: Text('Juros e Principal')),
                        DropdownMenuItem(value: 'Somente Juros', child: Text('Somente Juros')),
                        DropdownMenuItem(value: 'Somente Principal', child: Text('Somente Principal')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => applyTo = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: method,
                      decoration: const InputDecoration(
                        labelText: 'Método de Pagamento',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Dinheiro', child: Text('Dinheiro')),
                        DropdownMenuItem(value: 'Pix', child: Text('Pix')),
                        DropdownMenuItem(value: 'Cartão', child: Text('Cartão')),
                        DropdownMenuItem(value: 'Transferência', child: Text('Transferência')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => method = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    const InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Data do Pagamento',
                        suffixIcon: Icon(Icons.calendar_month),
                      ),
                      child: Text('Hoje'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Adicionar Nota'),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: share,
                      onChanged: (value) => setState(() => share = value ?? false),
                      title: const Text('Você deseja imprimir ou compartilhar?'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.monetization_on_outlined),
                        label: const Text(
                          'GUARDE O PAGAMENTO',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: IconButton.filled(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountRow(String label, String amount, bool stepper) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: muted)),
                Text(
                  amount,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          if (stepper)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF173D34),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: quantity > 1
                        ? () => setState(() => quantity--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w900)),
                  IconButton(
                    onPressed: () => setState(() => quantity++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            )
          else
            IconButton.filledTonal(
              onPressed: () {
                valueController.text = amount.replaceAll(RegExp(r'[^0-9,]'), '');
              },
              icon: const Icon(Icons.add),
            ),
        ],
      ),
    );
  }
}
