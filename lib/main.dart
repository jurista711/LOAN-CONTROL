import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://jyyioyoaupzuwljzwbyc.supabase.co';
const _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp5eWlveW9hdXB6dXdsanp3YnljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg2MzUxODQsImV4cCI6MjEwNDIxMTE4NH0.-ZaTFjQyHPVaT6dPMyi2apt7z0iF_L91l7J9JOLRzo8';

const bg = Color(0xFF071A15);
const panel = Color(0xFF1D1D20);
const mint = Color(0xFF72D9BA);
const mintDark = Color(0xFF1B6A57);
const orange = Color(0xFFFF8E58);
const muted = Color(0xFF98989F);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseKey);
  runApp(const RootsApp());
}

SupabaseClient get supabase => Supabase.instance.client;

class LicenseService {
  static const _deviceKey = 'loan_control_device_id';

  Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceKey);
    if (existing != null && existing.length > 10) return existing;
    final random = Random.secure();
    final id = 'loan-${DateTime.now().microsecondsSinceEpoch}-${List.generate(4, (_) => random.nextInt(0xffffffff).toRadixString(16)).join()}';
    await prefs.setString(_deviceKey, id);
    return id;
  }

  Future<Map<String, dynamic>> validate() async {
    final result = await supabase.rpc('cobrapp_app_validate_device', params: {'p_device_id': await deviceId()});
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> activate(String code) async {
    final result = await supabase.rpc('cobrapp_app_activate_device', params: {
      'p_activation_code': code.trim(),
      'p_device_id': await deviceId(),
      'p_device_name': 'Roots Cobranças - LOAN CONTROL',
    });
    return Map<String, dynamic>.from(result as Map);
  }
}

Future<dynamic> rpc(String name, {Map<String, dynamic> params = const {}}) async {
  return supabase.rpc(name, params: {'p_device_id': await LicenseService().deviceId(), ...params});
}

class RootsApp extends StatelessWidget {
  const RootsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roots Cobranças',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: mint, secondary: orange, surface: panel),
        cardTheme: CardThemeData(
          color: panel,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: Color(0xFF2B3F38))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF143028),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2B4E43))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: mint, width: 1.5)),
        ),
      ),
      home: const ActivationGate(),
    );
  }
}

class ActivationGate extends StatefulWidget {
  const ActivationGate({super.key});
  @override
  State<ActivationGate> createState() => _ActivationGateState();
}

class _ActivationGateState extends State<ActivationGate> {
  final code = TextEditingController();
  bool loading = true;
  bool active = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    _validate();
  }

  Future<void> _validate() async {
    try {
      final result = await LicenseService().validate();
      if (!mounted) return;
      setState(() {
        active = result['ok'] == true;
        message = (result['message'] ?? '').toString();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        message = 'Este aparelho ainda não foi ativado.';
      });
    }
  }

  Future<void> _activate() async {
    if (code.text.trim().isEmpty) return;
    setState(() => loading = true);
    try {
      final result = await LicenseService().activate(code.text);
      if (!mounted) return;
      setState(() {
        active = result['ok'] == true;
        message = (result['message'] ?? '').toString();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        message = 'Código inválido ou indisponível.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (active) return const HomeShell();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1D6A50), bg], begin: Alignment.topCenter, end: Alignment.center)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircleAvatar(radius: 34, backgroundColor: mintDark, child: Icon(Icons.account_balance_wallet_rounded, size: 34, color: Colors.white)),
                    const SizedBox(height: 16),
                    const Text('Roots Cobranças', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    const Text('Ativação do aparelho', style: TextStyle(color: muted)),
                    const SizedBox(height: 22),
                    TextField(controller: code, decoration: const InputDecoration(labelText: 'Código de ativação', prefixIcon: Icon(Icons.vpn_key_outlined))),
                    if (message.isNotEmpty) ...[const SizedBox(height: 12), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: muted))],
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: FilledButton(onPressed: _activate, child: const Text('ATIVAR'))),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(onOpenClients: () => setState(() => index = 1)),
      const CustomersPage(),
      const SettingsPage(),
      const MenuPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Color(0xFF0D2A22), boxShadow: [BoxShadow(color: Color(0x665AC9A7), blurRadius: 28)]),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 74,
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            backgroundColor: Colors.transparent,
            indicatorColor: const Color(0x555ECBA9),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: 'Dashboard'),
              NavigationDestination(icon: Icon(Icons.people_alt_rounded), label: 'Clientes'),
              NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Config'),
              NavigationDestination(icon: Icon(Icons.menu_rounded), label: 'Menu'),
            ],
          ),
        ),
      ),
      floatingActionButton: index == 0
          ? FloatingActionButton.large(backgroundColor: mint, foregroundColor: Colors.white, onPressed: () => openPage(context, 'Calculadora', const CalculatorPage()), child: const Icon(Icons.calculate_rounded))
          : null,
    );
  }
}

void openPage(BuildContext context, String title, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: bg, appBar: AppBar(title: Text(title), backgroundColor: bg), body: page)));
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.onOpenClients});
  final VoidCallback onOpenClients;
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> data = const {};
  bool loading = true;
  String filter = 'Hoje';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await rpc('cobrapp_app_dashboard_summary');
      if (!mounted) return;
      setState(() {
        data = Map<String, dynamic>.from(result as Map);
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  double value(String key) => toDouble(data[key]);
  int count(String key) => int.tryParse('${data[key] ?? 0}') ?? 0;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          WaveHeader(title: 'Dashboard', actions: [
            headerIcon(Icons.route_outlined),
            headerIcon(Icons.notifications_none_rounded),
            headerIcon(Icons.headset_mic_outlined),
            headerIcon(Icons.refresh_rounded, onTap: load),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Expanded(child: Text('Filtro de Datas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), Text(DateFormat('dd/MM/yyyy').format(DateTime.now()), style: const TextStyle(color: mint))]),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: ['Hoje', 'Ontem', 'Últimos 7 dias', 'Mês corrente', 'Período'].map((label) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(label), selected: filter == label, onSelected: (_) => setState(() => filter = label)),
                  );
                }).toList()),
              ),
              const SizedBox(height: 22),
              const Row(children: [CircleAvatar(backgroundColor: Color(0xFF293419), child: Icon(Icons.bolt_rounded, color: Colors.amber)), SizedBox(width: 10), Text('Ações Rápidas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: QuickCard(icon: Icons.query_stats_rounded, label: 'Despesas', color: Color(0xFF7567E8), onTap: () => openPage(context, 'Despesas', const PlaceholderPage('Despesas')))),
                const SizedBox(width: 8),
                Expanded(child: QuickCard(icon: Icons.person_add_alt_1_rounded, label: 'Criar Cliente', color: Color(0xFF1FC889), onTap: () => openPage(context, 'Criar Cliente', const CreateCustomerPage()))),
                const SizedBox(width: 8),
                Expanded(child: QuickCard(icon: Icons.request_quote_rounded, label: 'Criar Empréstimo', color: Color(0xFFE49A15), onTap: () => openPage(context, 'Criar Empréstimo', const CreateLoanPage()))),
                const SizedBox(width: 8),
                Expanded(child: QuickCard(icon: Icons.receipt_long_rounded, label: 'Criar Despesa', color: Color(0xFFB719D3), onTap: () => openPage(context, 'Criar Despesa', const PlaceholderPage('Criar Despesa')))),
              ]),
              const SizedBox(height: 18),
              CollectionCard(pending: value('pending_amount'), collected: value('received_today')),
              const SizedBox(height: 16),
              OverviewCard(totalLoaned: value('total_loaned'), pending: value('pending_amount'), overdue: count('overdue_installments')),
              const SizedBox(height: 16),
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [CircleAvatar(backgroundColor: Color(0xFF282849), child: Icon(Icons.credit_card, color: Color(0xFF7368FF))), SizedBox(width: 12), Expanded(child: Text('Resumo dos Métodos de Pagamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), Icon(Icons.open_in_full, color: mint)]), SizedBox(height: 34), Center(child: Text('Nenhum dado disponível', style: TextStyle(color: muted))), SizedBox(height: 22)]))),
              const SizedBox(height: 16),
              Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [CircleAvatar(backgroundColor: Color(0xFF1A3824), child: Icon(Icons.attach_money, color: Colors.greenAccent)), SizedBox(width: 12), Expanded(child: Text('Valor do Pagamento por Dia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), Icon(Icons.download_for_offline_outlined, color: Colors.greenAccent)]), const SizedBox(height: 24), Text(money(value('received_today')), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)), const SizedBox(height: 12), LinearProgressIndicator(value: value('received_today') > 0 ? 1 : 0, color: mint, backgroundColor: Colors.white12, minHeight: 7)]))),
              if (loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            ]),
          ),
        ],
      ),
    );
  }

  Widget headerIcon(IconData icon, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(13), child: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: Colors.white))),
    );
  }
}

class WaveHeader extends StatelessWidget {
  const WaveHeader({super.key, required this.title, this.actions = const []});
  final String title;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: 180,
        padding: const EdgeInsets.fromLTRB(24, 48, 16, 42),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF216B4F), Color(0xFF9DE9D2)], begin: Alignment.topLeft, end: Alignment.topRight)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w400, color: Colors.white))), ...actions]),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height * .63)
      ..cubicTo(size.width * .18, size.height * .90, size.width * .42, size.height * .58, size.width * .62, size.height * .69)
      ..cubicTo(size.width * .78, size.height * .81, size.width * .88, size.height * .94, size.width, size.height * .70)
      ..lineTo(size.width, 0)
      ..close();
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class QuickCard extends StatelessWidget {
  const QuickCard({super.key, required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 126,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(.48))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(.16), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)), const Spacer(), Text(label, maxLines: 2, style: TextStyle(color: color, fontWeight: FontWeight.w900))]),
      ),
    );
  }
}

class CollectionCard extends StatelessWidget {
  const CollectionCard({super.key, required this.pending, required this.collected});
  final double pending;
  final double collected;
  @override
  Widget build(BuildContext context) {
    final total = pending + collected;
    final progress = total <= 0 ? 1.0 : (collected / total).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [CircleAvatar(backgroundColor: Color(0xFF4A3027), child: Icon(Icons.trending_up, color: orange)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Progresso de Cobranças', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text('Toque para ver o detalhamento completo', style: TextStyle(color: muted, fontStyle: FontStyle.italic))])), Icon(Icons.info_outline, color: orange)]),
          const SizedBox(height: 22),
          Text('${money(collected)}  De ${money(total)}', style: const TextStyle(fontSize: 29)),
          const SizedBox(height: 15),
          ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress, minHeight: 14, backgroundColor: const Color(0xFF303032), color: orange)),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [legend('Pendente', money(pending), Colors.grey), legend('Cobrado', money(collected), mint)]),
        ]),
      ),
    );
  }
  Widget legend(String label, String amount, Color color) => Row(children: [Container(width: 5, height: 48, color: color), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label), Text(amount, style: const TextStyle(fontSize: 16))])]);
}

class OverviewCard extends StatelessWidget {
  const OverviewCard({super.key, required this.totalLoaned, required this.pending, required this.overdue});
  final double totalLoaned;
  final double pending;
  final int overdue;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [CircleAvatar(backgroundColor: Color(0xFF243A35), child: Icon(Icons.analytics_outlined, color: mint)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Visão Geral', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text('Toque para ver o detalhamento completo', style: TextStyle(color: muted, fontStyle: FontStyle.italic))])), Icon(Icons.download, color: mint), SizedBox(width: 12), Icon(Icons.open_in_full, color: mint)]),
          const SizedBox(height: 18),
          metric('Total Emprestado', money(totalLoaned), totalLoaned > 0 ? 1 : 0),
          metric('Capital pendente', money(pending), totalLoaned > 0 ? (pending / totalLoaned).clamp(0.0, 1.0) : 0),
          metric('Parcelas vencidas', '$overdue', overdue > 0 ? 1 : 0),
        ]),
      ),
    );
  }
  Widget metric(String label, String amount, double progress) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Column(children: [Row(children: [Expanded(child: Text(label)), Text(amount, style: const TextStyle(fontWeight: FontWeight.w800))]), const SizedBox(height: 5), LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: mint)]));
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  String query = '';
  @override
  void initState() {
    super.initState();
    load();
  }
  Future<void> load() async {
    try {
      final result = await rpc('cobrapp_app_list_customers');
      if (!mounted) return;
      setState(() {
        rows = (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final list = rows.where((r) => '${r['name']} ${r['phone']} ${r['document']}'.toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          const SimpleHeader(title: 'Clientes'),
          Padding(padding: const EdgeInsets.all(14), child: TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(hintText: 'Buscar clientes...', prefixIcon: Icon(Icons.search)))),
          if (loading) const LinearProgressIndicator(),
          Expanded(child: RefreshIndicator(onRefresh: load, child: ListView.builder(padding: const EdgeInsets.fromLTRB(14, 0, 14, 100), itemCount: list.length, itemBuilder: (context, index) {
            final r = list[index];
            final name = (r['name'] ?? 'Cliente').toString();
            return Card(child: ListTile(leading: CircleAvatar(backgroundColor: mintDark, child: Text(name.isEmpty ? '?' : name[0].toUpperCase())), title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text([r['phone'], r['document']].where((e) => e != null && e.toString().isNotEmpty).join(' • ')), trailing: const Icon(Icons.chevron_right), onTap: () => openPage(context, name, CustomerDetail(customer: r))));
          })),
        ]),
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: mint, onPressed: () => openPage(context, 'Criar Cliente', const CreateCustomerPage()), child: const Icon(Icons.add)),
    );
  }
}

class CreateCustomerPage extends StatefulWidget {
  const CreateCustomerPage({super.key});
  @override
  State<CreateCustomerPage> createState() => _CreateCustomerPageState();
}

class _CreateCustomerPageState extends State<CreateCustomerPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final document = TextEditingController();
  final address = TextEditingController();
  final notes = TextEditingController();
  bool saving = false;
  Future<void> save() async {
    if (name.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      await rpc('cobrapp_app_create_customer', params: {'p_name': name.text.trim(), 'p_document': document.text.trim(), 'p_phone': phone.text.trim(), 'p_address': address.text.trim(), 'p_notes': notes.text.trim()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente criado.')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar cliente: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [field(name, 'Nome completo'), const SizedBox(height: 10), field(phone, 'Telefone'), const SizedBox(height: 10), field(document, 'CPF / documento'), const SizedBox(height: 10), field(address, 'Endereço'), const SizedBox(height: 10), TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Observações')), const SizedBox(height: 18), FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Salvando...' : 'SALVAR CLIENTE'))]);
  Widget field(TextEditingController c, String label) => TextField(controller: c, decoration: InputDecoration(labelText: label));
}

class CustomerDetail extends StatelessWidget {
  const CustomerDetail({super.key, required this.customer});
  final Map<String, dynamic> customer;
  @override
  Widget build(BuildContext context) {
    final name = (customer['name'] ?? 'Cliente').toString();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Center(child: CircleAvatar(radius: 38, backgroundColor: mintDark, child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(fontSize: 28)))),
      const SizedBox(height: 12),
      Center(child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
      const SizedBox(height: 18),
      Card(child: Column(children: [ListTile(leading: const Icon(Icons.phone, color: mint), title: Text((customer['phone'] ?? 'Sem telefone').toString())), ListTile(leading: const Icon(Icons.badge_outlined, color: mint), title: Text((customer['document'] ?? 'Sem documento').toString())), ListTile(leading: const Icon(Icons.location_on_outlined, color: mint), title: Text((customer['address'] ?? 'Sem endereço').toString()))])),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: () => openPage(context, 'Criar Empréstimo', CreateLoanPage(initialCustomerId: customer['id']?.toString())), icon: const Icon(Icons.request_quote), label: const Text('CRIAR EMPRÉSTIMO')),
    ]);
  }
}

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});
  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final result = await rpc('cobrapp_app_list_loans');
      if (!mounted) return;
      setState(() { rows = (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(); loading = false; });
    } catch (_) { if (mounted) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(14), children: [if (loading) const LinearProgressIndicator(), for (final r in rows) Card(child: ListTile(leading: const CircleAvatar(backgroundColor: mintDark, child: Icon(Icons.account_balance_wallet_outlined)), title: Text((r['customer_name'] ?? 'Cliente').toString(), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${money(toDouble(r['amount']))} • ${statusPt(r['status'])}'), trailing: Text(money(toDouble(r['total_debt'])), style: const TextStyle(fontWeight: FontWeight.w900)), onTap: () => openPage(context, (r['customer_name'] ?? 'Empréstimo').toString(), LoanDetail(loanId: r['id'].toString())))), const SizedBox(height: 80)]));
}

class LoanDetail extends StatefulWidget {
  const LoanDetail({super.key, required this.loanId});
  final String loanId;
  @override
  State<LoanDetail> createState() => _LoanDetailState();
}

class _LoanDetailState extends State<LoanDetail> {
  Map<String, dynamic>? data;
  bool loading = true;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final result = await rpc('cobrapp_app_get_loan_detail', params: {'p_loan_id': widget.loanId});
      if (mounted) setState(() { data = Map<String, dynamic>.from(result as Map); loading = false; });
    } catch (_) { if (mounted) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final x = data ?? {};
    final installments = ((x['installments'] ?? const []) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return ListView(padding: const EdgeInsets.all(14), children: [
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text((x['customer_name'] ?? 'Cliente').toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 14), Wrap(spacing: 28, runSpacing: 14, children: [kv('Valor', money(toDouble(x['principal'] ?? x['amount']))), kv('Juros do crédito', '${toDouble(x['interest_rate']).toStringAsFixed(1)}%'), kv('Tipo de juros', (x['interest_type'] ?? 'Capital inicial').toString()), kv('Frequência', (x['payment_frequency'] ?? 'Mensal').toString())]), const SizedBox(height: 20), const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [IconLabel(Icons.visibility_outlined, 'Em formação'), IconLabel(Icons.edit_outlined, 'Editar crédito'), IconLabel(Icons.delete_outline, 'Remover', danger: true)])]))),
      const SizedBox(height: 12),
      const Row(children: [Expanded(child: TabPill(icon: Icons.monetization_on_outlined, label: 'Plano de pagamento', selected: true)), Expanded(child: TabPill(icon: Icons.receipt_long_outlined, label: 'Registro')), Expanded(child: TabPill(icon: Icons.headset_mic_outlined, label: 'Gestões'))]),
      const SizedBox(height: 14),
      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [StatusPill('Encostas', Colors.yellow), StatusPill('Pago', Colors.lightGreen), StatusPill('Atrasado', Colors.redAccent), StatusPill('Anulada', Colors.white70)]),
      const SizedBox(height: 10),
      for (final r in installments) Card(child: ListTile(title: Text('Parcela ${r['number'] ?? ''}'), subtitle: Text('Expira ${formatDate(r['due_date'])}\nSaldo: ${money(toDouble(r['amount']))} • Pago: ${money(toDouble(r['paid_amount']))}'), isThreeLine: true, trailing: PopupMenuButton<String>(itemBuilder: (_) => const [PopupMenuItem(value: 'pay', child: Text('Registrar pagamento'))], onSelected: (_) => openPage(context, 'Registrar pagamento', PaymentPage(initialInstallmentId: r['id']?.toString()))))),
      const SizedBox(height: 80),
      FilledButton.icon(onPressed: () => openPage(context, 'Registrar pagamento', const PaymentsPage()), icon: const Icon(Icons.monetization_on_outlined), label: const Text('Adicionar')),
    ]);
  }
  Widget kv(String label, String value) => SizedBox(width: 150, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: muted)), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))]));
}

class IconLabel extends StatelessWidget {
  const IconLabel(this.icon, this.label, {super.key, this.danger = false});
  final IconData icon; final String label; final bool danger;
  @override Widget build(BuildContext context) => Column(children: [Icon(icon, color: danger ? Colors.redAccent : mint), Text(label, style: TextStyle(color: danger ? Colors.redAccent : mint, fontWeight: FontWeight.w700))]);
}

class TabPill extends StatelessWidget {
  const TabPill({super.key, required this.icon, required this.label, this.selected = false});
  final IconData icon; final String label; final bool selected;
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10), decoration: BoxDecoration(color: selected ? mint.withOpacity(.15) : Colors.transparent, border: selected ? Border.all(color: mint) : null, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: selected ? mint : muted), const SizedBox(width: 5), Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? mint : muted)))]));
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, this.color, {super.key});
  final String label; final Color color;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), decoration: BoxDecoration(color: color.withOpacity(.85), borderRadius: BorderRadius.circular(22)), child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)));
}

class CreateLoanPage extends StatefulWidget {
  const CreateLoanPage({super.key, this.initialCustomerId});
  final String? initialCustomerId;
  @override
  State<CreateLoanPage> createState() => _CreateLoanPageState();
}

class _CreateLoanPageState extends State<CreateLoanPage> {
  List<Map<String, dynamic>> customers = [];
  String? customerId;
  final amount = TextEditingController();
  final rate = TextEditingController(text: '30');
  final installments = TextEditingController(text: '1');
  final notes = TextEditingController();
  String interestType = 'initial_capital';
  String frequency = 'monthly';
  DateTime startDate = DateTime.now();
  bool saving = false;

  @override
  void initState() { super.initState(); loadCustomers(); }
  Future<void> loadCustomers() async {
    try {
      final result = await rpc('cobrapp_app_list_customers');
      if (!mounted) return;
      setState(() {
        customers = (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        customerId = widget.initialCustomerId ?? (customers.isEmpty ? null : customers.first['id']?.toString());
      });
    } catch (_) {}
  }
  Future<void> save() async {
    final principal = parseNumber(amount.text);
    final pct = parseNumber(rate.text);
    final qty = max(1, int.tryParse(installments.text) ?? 1);
    if (customerId == null || principal <= 0) return;
    setState(() => saving = true);
    try {
      final totalInterest = interestType == 'each_payment' ? principal * (pct / 100) * qty : principal * (pct / 100);
      final totalDebt = principal + totalInterest;
      final rows = <Map<String, dynamic>>[];
      for (var i = 1; i <= qty; i++) {
        final due = frequency == 'weekly' ? startDate.add(Duration(days: 7 * i)) : DateTime(startDate.year, startDate.month + i, startDate.day);
        rows.add({'number': i, 'due_date': DateFormat('yyyy-MM-dd').format(due), 'principal': principal / qty, 'interest': totalInterest / qty, 'total': totalDebt / qty});
      }
      final endDate = frequency == 'weekly' ? startDate.add(Duration(days: 7 * qty)) : DateTime(startDate.year, startDate.month + qty, startDate.day);
      await rpc('cobrapp_app_create_loan', params: {'p_customer_id': customerId, 'p_principal': principal, 'p_interest_rate': pct, 'p_interest_type': interestType, 'p_payments_number': qty, 'p_payment_frequency': frequency, 'p_start_date': DateFormat('yyyy-MM-dd').format(startDate), 'p_end_date': DateFormat('yyyy-MM-dd').format(endDate), 'p_total_interest': totalInterest, 'p_total_debt': totalDebt, 'p_note': notes.text.trim(), 'p_installments': rows});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empréstimo criado.')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar empréstimo: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    DropdownButtonFormField<String>(value: customerId, decoration: const InputDecoration(labelText: 'Cliente'), items: customers.map((r) => DropdownMenuItem(value: r['id'].toString(), child: Text((r['name'] ?? 'Cliente').toString()))).toList(), onChanged: (v) => setState(() => customerId = v)),
    const SizedBox(height: 10),
    TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor do crédito')),
    const SizedBox(height: 10),
    TextField(controller: rate, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Juros (%)')),
    const SizedBox(height: 10),
    TextField(controller: installments, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Número de pagamentos')),
    const SizedBox(height: 10),
    DropdownButtonFormField<String>(value: interestType, decoration: const InputDecoration(labelText: 'Tipo de juros'), items: const [DropdownMenuItem(value: 'initial_capital', child: Text('Capital inicial')), DropdownMenuItem(value: 'each_payment', child: Text('Cada parcela'))], onChanged: (v) => setState(() => interestType = v ?? 'initial_capital')),
    const SizedBox(height: 10),
    DropdownButtonFormField<String>(value: frequency, decoration: const InputDecoration(labelText: 'Frequência'), items: const [DropdownMenuItem(value: 'monthly', child: Text('Mensal')), DropdownMenuItem(value: 'weekly', child: Text('Semanal'))], onChanged: (v) => setState(() => frequency = v ?? 'monthly')),
    const SizedBox(height: 10),
    ListTile(tileColor: const Color(0xFF143028), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: const Text('Data do empréstimo'), subtitle: Text(formatDate(startDate)), trailing: const Icon(Icons.calendar_month, color: mint), onTap: () async { final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime.now()); if (picked != null) setState(() => startDate = picked); }),
    const SizedBox(height: 10),
    TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Observações')),
    const SizedBox(height: 18),
    FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Salvando...' : 'CRIAR EMPRÉSTIMO')),
  ]);
}

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});
  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final result = await rpc('cobrapp_app_list_pending_installments');
      if (!mounted) return;
      setState(() { rows = (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(); loading = false; });
    } catch (_) { if (mounted) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: load, child: ListView(padding: const EdgeInsets.all(14), children: [if (loading) const LinearProgressIndicator(), for (final r in rows) Card(child: ListTile(title: Text((r['customer_name'] ?? 'Cliente').toString()), subtitle: Text('Parcela ${r['number']} • ${formatDate(r['due_date'])}'), trailing: Text(money(toDouble(r['total']) - toDouble(r['paid_amount']))), onTap: () => openPage(context, 'Registrar pagamento', PaymentPage(initialInstallmentId: r['id']?.toString())))), const SizedBox(height: 80)]));
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, this.initialInstallmentId});
  final String? initialInstallmentId;
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  List<Map<String, dynamic>> rows = [];
  String? installmentId;
  final amount = TextEditingController();
  final late = TextEditingController(text: '0');
  final note = TextEditingController();
  String method = 'Dinheiro';
  String type = 'total';
  DateTime paidAt = DateTime.now();
  bool saving = false;
  @override
  void initState() { super.initState(); installmentId = widget.initialInstallmentId; load(); }
  Future<void> load() async {
    try {
      final result = await rpc('cobrapp_app_list_pending_installments');
      if (!mounted) return;
      setState(() {
        rows = (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        installmentId ??= rows.isEmpty ? null : rows.first['id']?.toString();
      });
    } catch (_) {}
  }
  Future<void> save() async {
    if (installmentId == null || parseNumber(amount.text) <= 0) return;
    setState(() => saving = true);
    try {
      await rpc('cobrapp_app_register_payment_v3', params: {'p_installment_id': installmentId, 'p_amount': parseNumber(amount.text), 'p_late_charge': parseNumber(late.text), 'p_method': method, 'p_note': note.text.trim(), 'p_type': type, 'p_paid_at': DateFormat('yyyy-MM-dd').format(paidAt)});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pagamento registrado.')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao registrar pagamento: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    DropdownButtonFormField<String>(value: installmentId, decoration: const InputDecoration(labelText: 'Parcela'), items: rows.map((r) => DropdownMenuItem(value: r['id'].toString(), child: Text('${r['customer_name']} • ${r['number']}'))).toList(), onChanged: (v) => setState(() => installmentId = v)),
    const SizedBox(height: 10),
    TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor do pagamento')),
    const SizedBox(height: 10),
    TextField(controller: late, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Juros / multa de atraso')),
    const SizedBox(height: 10),
    DropdownButtonFormField<String>(value: method, decoration: const InputDecoration(labelText: 'Método'), items: const [DropdownMenuItem(value: 'Dinheiro', child: Text('Dinheiro')), DropdownMenuItem(value: 'Pix', child: Text('Pix')), DropdownMenuItem(value: 'Transferência', child: Text('Transferência'))], onChanged: (v) => setState(() => method = v ?? 'Dinheiro')),
    const SizedBox(height: 10),
    DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Aplicar o pagamento a'), items: const [DropdownMenuItem(value: 'total', child: Text('Juros e Principal')), DropdownMenuItem(value: 'partial', child: Text('Pagamento parcial')), DropdownMenuItem(value: 'advance', child: Text('Adiantamento'))], onChanged: (v) => setState(() => type = v ?? 'total')),
    const SizedBox(height: 10),
    ListTile(tileColor: const Color(0xFF143028), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: const Text('Data do Pagamento'), subtitle: Text(formatDate(paidAt)), trailing: const Icon(Icons.calendar_month, color: mint), onTap: () async { final picked = await showDatePicker(context: context, initialDate: paidAt, firstDate: DateTime(2000), lastDate: DateTime.now()); if (picked != null) setState(() => paidAt = picked); }),
    const SizedBox(height: 10),
    TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Notas')),
    const SizedBox(height: 18),
    FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Registrando...' : 'REGISTRAR PAGAMENTO')),
  ]);
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final company = TextEditingController();
  final document = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final receiptHeader = TextEditingController();
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    company.text = prefs.getString('company_name') ?? 'Roots Cobranças';
    document.text = prefs.getString('company_document') ?? '';
    phone.text = prefs.getString('company_phone') ?? '';
    address.text = prefs.getString('company_address') ?? '';
    receiptHeader.text = prefs.getString('receipt_header') ?? '';
    if (mounted) setState(() {});
  }
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', company.text.trim());
    await prefs.setString('company_document', document.text.trim());
    await prefs.setString('company_phone', phone.text.trim());
    await prefs.setString('company_address', address.text.trim());
    await prefs.setString('receipt_header', receiptHeader.text.trim());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configurações salvas.')));
  }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: bg, body: SafeArea(child: ListView(padding: const EdgeInsets.only(bottom: 100), children: [const SimpleHeader(title: 'Configurações'), Padding(padding: const EdgeInsets.all(16), child: Column(children: [TextField(controller: company, decoration: const InputDecoration(labelText: 'Nome da empresa')), const SizedBox(height: 10), TextField(controller: document, decoration: const InputDecoration(labelText: 'CPF / CNPJ')), const SizedBox(height: 10), TextField(controller: phone, decoration: const InputDecoration(labelText: 'Telefone')), const SizedBox(height: 10), TextField(controller: address, decoration: const InputDecoration(labelText: 'Endereço')), const SizedBox(height: 10), TextField(controller: receiptHeader, maxLines: 3, decoration: const InputDecoration(labelText: 'Cabeçalho dos recibos')), const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton(onPressed: save, child: const Text('SALVAR'))), const SizedBox(height: 18), const Card(child: Column(children: [ListTile(leading: Icon(Icons.notifications_none, color: mint), title: Text('Notificações'), trailing: Icon(Icons.chevron_right)), ListTile(leading: Icon(Icons.palette_outlined, color: mint), title: Text('Aparência'), trailing: Icon(Icons.chevron_right)), ListTile(leading: Icon(Icons.cloud_sync_outlined, color: mint), title: Text('Backup e sincronização'), trailing: Icon(Icons.chevron_right)), ListTile(leading: Icon(Icons.help_outline, color: mint), title: Text('Ajuda e suporte'), trailing: Icon(Icons.chevron_right))]))]))])));
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: bg, body: SafeArea(child: ListView(padding: const EdgeInsets.only(bottom: 100), children: [const SimpleHeader(title: 'Menu'), menu(context, Icons.account_balance_wallet_outlined, 'Empréstimos', const LoansPage()), menu(context, Icons.payments_outlined, 'Pagamentos', const PaymentsPage()), menu(context, Icons.receipt_long_outlined, 'Recibos', const PlaceholderPage('Recibos')), menu(context, Icons.route_outlined, 'Rotas', const PlaceholderPage('Rotas')), menu(context, Icons.bar_chart_outlined, 'Relatórios', const PlaceholderPage('Relatórios')), menu(context, Icons.business_outlined, 'Empresa', const SettingsPage()), menu(context, Icons.calculate_outlined, 'Calculadora', const CalculatorPage()), menu(context, Icons.info_outline, 'Sobre', const PlaceholderPage('Roots Cobranças'))])));
  Widget menu(BuildContext context, IconData icon, String label, Widget page) => ListTile(leading: Icon(icon, color: mint), title: Text(label), trailing: const Icon(Icons.chevron_right), onTap: () => openPage(context, label, page));
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final amount = TextEditingController();
  final rate = TextEditingController();
  final count = TextEditingController(text: '1');
  double? total;
  double? installment;
  void calculate() {
    final principal = parseNumber(amount.text);
    final pct = parseNumber(rate.text);
    final qty = max(1, int.tryParse(count.text) ?? 1);
    setState(() {
      total = principal + principal * pct / 100;
      installment = total! / qty;
    });
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capital inicial')), const SizedBox(height: 10), TextField(controller: rate, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Juros (%)')), const SizedBox(height: 10), TextField(controller: count, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pagamentos')), const SizedBox(height: 15), FilledButton.icon(onPressed: calculate, icon: const Icon(Icons.calculate), label: const Text('CALCULAR')), if (total != null) ...[const SizedBox(height: 18), Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Total: ${money(total!)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text('Pagamento: ${money(installment!)}', style: const TextStyle(fontSize: 18))])))]]);
}

class SimpleHeader extends StatelessWidget {
  const SimpleHeader({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(18, 20, 12, 16), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A6049), Color(0xFF67CEAF)])), child: Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)));
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Center(child: Text('$label\nEm reconstrução fiel ao original.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)));
}

String money(double value) => 'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(value).trim()}';
double toDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
double parseNumber(String value) => double.tryParse(value.trim().replaceAll('.', '').replaceAll(',', '.')) ?? 0;
String formatDate(dynamic value) {
  if (value is DateTime) return DateFormat('dd/MM/yyyy').format(value);
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed == null ? (value?.toString() ?? '') : DateFormat('dd/MM/yyyy').format(parsed);
}
String statusPt(dynamic value) {
  switch (value?.toString()) {
    case 'active': return 'Ativo';
    case 'completed': return 'Pago';
    case 'renewed': return 'Renovado';
    default: return value?.toString() ?? '';
  }
}
