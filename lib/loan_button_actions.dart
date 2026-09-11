import 'package:flutter/material.dart';

import 'main.dart';

class LoanButtonActions {
  static Future<void> handleMenu(
    BuildContext context,
    String action, {
    required Map<String, dynamic> loan,
    required String customerName,
    required String? customerId,
    required Future<void> Function() onReload,
  }) async {
    switch (action) {
      case 'Renovar':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoanRenewPage(
              loan: loan,
              customerName: customerName,
              customerId: customerId,
            ),
          ),
        );
        break;
      case 'Marcar como Pago':
        await markAsPaid(context, loan: loan, onReload: onReload);
        break;
      case 'Editar datas de vencimento':
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => LoanDueDatesPage(loan: loan)),
        );
        if (changed == true) await onReload();
        break;
      case 'Imprimir Plano de Pagamento':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoanPreviewPage(loan: loan, mode: 'plan')),
        );
        break;
      case 'Imprimir Histórico de Pagamentos':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoanPreviewPage(loan: loan, mode: 'history')),
        );
        break;
      case 'Documentos':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoanDocumentsPage(loan: loan, customerName: customerName)),
        );
        break;
    }
  }

  static Future<void> editCredit(
    BuildContext context, {
    required Map<String, dynamic> loan,
    required Future<void> Function() onReload,
  }) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LoanEditActionPage(loan: loan)),
    );
    if (changed == true) await onReload();
  }

  static Future<void> removeLoan(
    BuildContext context, {
    required Map<String, dynamic> loan,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover empréstimo'),
        content: const Text('Tem certeza de que deseja remover este empréstimo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await rpc('cobrapp_app_delete_loan', params: {'p_loan_id': loan['id']});
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível remover: $e')));
      }
    }
  }

  static Future<void> markAsPaid(
    BuildContext context, {
    required Map<String, dynamic> loan,
    required Future<void> Function() onReload,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Marcar como Pago'),
        content: const Text('Tem certeza de que deseja marcar este empréstimo como pago?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await rpc('cobrapp_app_mark_loan_paid', params: {'p_loan_id': loan['id']});
      await onReload();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empréstimo marcado como pago com sucesso')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao marcar o empréstimo como pago: $e')));
      }
    }
  }
}

class LoanDueDatesPage extends StatefulWidget {
  const LoanDueDatesPage({super.key, required this.loan});
  final Map<String, dynamic> loan;
  @override
  State<LoanDueDatesPage> createState() => _LoanDueDatesPageState();
}

class _LoanDueDatesPageState extends State<LoanDueDatesPage> {
  late List<Map<String, dynamic>> installments;
  String? selectedId;
  DateTime? selectedDate;
  bool updateFollowing = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.loan['installments'];
    installments = raw is List ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList() : [];
    if (installments.isNotEmpty) {
      selectedId = installments.first['id']?.toString();
      selectedDate = DateTime.tryParse((installments.first['due_date'] ?? '').toString());
    }
  }

  Map<String, dynamic>? get selected {
    for (final row in installments) {
      if (row['id']?.toString() == selectedId) return row;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final initial = selectedDate ?? DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null) setState(() => selectedDate = value);
  }

  Future<void> _save() async {
    if (selectedId == null || selectedDate == null) return;
    setState(() => saving = true);
    try {
      final d = selectedDate!;
      await rpc('cobrapp_app_update_due_dates', params: {
        'p_loan_id': widget.loan['id'],
        'p_installment_id': selectedId,
        'p_new_date': '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        'p_update_following': updateFollowing,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível atualizar a data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('Editar Datas de Vencimento'), backgroundColor: bg),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Altere a data de vencimento de uma parcela e opcionalmente todas as seguintes.'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedId,
            decoration: const InputDecoration(labelText: 'Selecionar parcela'),
            items: installments.map((row) => DropdownMenuItem(
              value: row['id']?.toString(),
              child: Text('Parcela ${row['number']} • ${row['due_date']}'),
            )).toList(),
            onChanged: (value) {
              setState(() {
                selectedId = value;
                selectedDate = DateTime.tryParse((selected?['due_date'] ?? '').toString());
              });
            },
          ),
          const SizedBox(height: 14),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF2B4E43))),
            title: const Text('Nova data'),
            subtitle: Text(selectedDate == null ? 'Selecionar nova data' : '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'),
            trailing: const Icon(Icons.calendar_month_outlined),
            onTap: _pickDate,
          ),
          SwitchListTile(
            value: updateFollowing,
            onChanged: (v) => setState(() => updateFollowing = v),
            title: const Text('Atualizar também as parcelas seguintes'),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: saving ? null : _save, child: Text(saving ? 'SALVANDO...' : 'Salvar')),
        ],
      ),
    );
  }
}

class LoanEditActionPage extends StatefulWidget {
  const LoanEditActionPage({super.key, required this.loan});
  final Map<String, dynamic> loan;
  @override
  State<LoanEditActionPage> createState() => _LoanEditActionPageState();
}

class _LoanEditActionPageState extends State<LoanEditActionPage> {
  late final TextEditingController principal;
  late final TextEditingController interest;
  late final TextEditingController note;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    principal = TextEditingController(text: '${widget.loan['amount'] ?? widget.loan['principal'] ?? ''}');
    interest = TextEditingController(text: '${widget.loan['interest_rate'] ?? ''}');
    note = TextEditingController(text: '${widget.loan['note'] ?? ''}');
  }

  @override
  void dispose() {
    principal.dispose(); interest.dispose(); note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final installments = widget.loan['installments'] is List ? widget.loan['installments'] as List : const [];
    final p = double.tryParse(principal.text.replaceAll(',', '.')) ?? 0;
    final r = double.tryParse(interest.text.replaceAll(',', '.')) ?? 0;
    final count = int.tryParse('${widget.loan['payments_number'] ?? installments.length}') ?? installments.length;
    final totalDebt = toDouble(widget.loan['total_debt']);
    final totalInterest = toDouble(widget.loan['total_interest']);
    setState(() => saving = true);
    try {
      await rpc('cobrapp_app_update_loan', params: {
        'p_loan_id': widget.loan['id'],
        'p_customer_id': widget.loan['customer_id'],
        'p_principal': p,
        'p_interest_rate': r,
        'p_interest_type': widget.loan['interest_type'] ?? 'initial_capital',
        'p_payments_number': count,
        'p_payment_frequency': widget.loan['payment_frequency'] ?? 'monthly',
        'p_start_date': widget.loan['start_date'],
        'p_end_date': widget.loan['end_date'],
        'p_total_interest': totalInterest,
        'p_total_debt': totalDebt,
        'p_note': note.text.trim().isEmpty ? null : note.text.trim(),
        'p_installments': installments,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    appBar: AppBar(title: const Text('Editar crédito'), backgroundColor: bg),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(controller: principal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor')),
        const SizedBox(height: 12),
        TextField(controller: interest, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Juros do crédito')),
        const SizedBox(height: 12),
        TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Notas')),
        const SizedBox(height: 18),
        FilledButton(onPressed: saving ? null : _save, child: Text(saving ? 'SALVANDO...' : 'Salvar')),
      ],
    ),
  );
}

class LoanRenewPage extends StatelessWidget {
  const LoanRenewPage({super.key, required this.loan, required this.customerName, required this.customerId});
  final Map<String, dynamic> loan;
  final String customerName;
  final String? customerId;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    appBar: AppBar(title: const Text('Renovar crédito'), backgroundColor: bg),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(customerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Card(child: ListTile(title: const Text('Saldo total a renovar'), trailing: Text(money(toDouble(loan['total_debt']))))),
        const SizedBox(height: 8),
        const Text('A renovação encerra o crédito atual e cria um novo crédito com os novos termos.'),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => openPage(context, 'Novo Empréstimo', CreateLoanPage(initialCustomerId: customerId)),
          icon: const Icon(Icons.autorenew),
          label: const Text('Continuar renovação'),
        ),
      ],
    ),
  );
}

class LoanPreviewPage extends StatelessWidget {
  const LoanPreviewPage({super.key, required this.loan, required this.mode});
  final Map<String, dynamic> loan;
  final String mode;
  @override
  Widget build(BuildContext context) {
    final rows = mode == 'history' ? (loan['payments'] as List? ?? const []) : (loan['installments'] as List? ?? const []);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: Text(mode == 'history' ? 'Histórico de Pagamentos' : 'Plano de Pagamento'), backgroundColor: bg),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        itemBuilder: (_, i) {
          final row = Map<String, dynamic>.from(rows[i] as Map);
          return Card(
            child: ListTile(
              title: Text(mode == 'history' ? 'Pagamento ${i + 1}' : 'Parcela ${row['number'] ?? i + 1}'),
              subtitle: Text(mode == 'history' ? '${row['payment_date'] ?? row['paid_at'] ?? ''}' : '${row['due_date'] ?? ''}'),
              trailing: Text(money(toDouble(row['amount'] ?? row['total']))),
            ),
          );
        },
      ),
    );
  }
}

class LoanDocumentsPage extends StatelessWidget {
  const LoanDocumentsPage({super.key, required this.loan, required this.customerName});
  final Map<String, dynamic> loan;
  final String customerName;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    appBar: AppBar(title: const Text('Documentos'), backgroundColor: bg),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(customerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Crédito: ${money(toDouble(loan['amount']))}', style: const TextStyle(color: muted)),
        const SizedBox(height: 16),
        const Card(child: ListTile(leading: Icon(Icons.description_outlined), title: Text('Documentos Disponíveis'), subtitle: Text('Abra um modelo para gerar documentos deste crédito.'))),
      ],
    ),
  );
}
