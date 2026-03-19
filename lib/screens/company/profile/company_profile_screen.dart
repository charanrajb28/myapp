import 'package:flutter/material.dart';
import 'edit_company_profile_screen.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  String companyName = 'Cloud9 Systems Inc.';
  String tagline = 'Scaling Intelligence for a Decentralized World';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            Positioned.fill(child: _DotGrid()),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── ADMIN_BANNER_UNIT ──
                SliverToBoxAdapter(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=1000'), fit: BoxFit.cover, opacity: 0.3),
                        ),
                      ),
                      Positioned(
                        bottom: -40, left: 24,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: const Center(child: Text('C9', style: TextStyle(color: Color(0xFF6366F1), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1))),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
                
                // ── ADMIN_IDENTITY_UNIT ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(companyName, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 6),
                            Text('VERIFIED_CORPORATE_PARTNER', style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── ADMIN_ACTION_CONSOLE ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(child: _adminBtn('EDIT_CONSOLE', true, Icons.edit_note_rounded, () async {
                          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditCompanyProfileScreen(companyData: {'name': companyName, 'tagline': tagline})));
                          if (result != null) {
                            setState(() {
                              companyName = result['name'];
                              tagline = result['tagline'];
                            });
                          }
                        })),
                        const SizedBox(width: 12),
                        Expanded(child: _adminBtn('TEAM_SYNC', false, Icons.sync_rounded, () => _showSyncProcess(context))),
                        const SizedBox(width: 12),
                        _iconBtn(Icons.settings_input_component_rounded, () => _showSystemDialog(context)),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),

                // ── MANAGEMENT_TABS ──
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: Color(0xFF6366F1),
                      indicatorWeight: 3,
                      labelColor: Color(0xFF0F172A),
                      labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                      unselectedLabelColor: Color(0xFF94A3B8),
                      dividerColor: Color(0xFFE2E8F0),
                      tabs: [
                        Tab(text: 'CORP_DATA'),
                        Tab(text: 'SECURITY_LOG'),
                        Tab(text: 'BRANDING_MOD'),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── TAB_CONTENT ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _narrativeCard(),
                      const SizedBox(height: 24),
                      const Text('> CORPORATE_LEDGER', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 12),
                      _ledgerRow('ESTABLISHED', 'OCT 2018', () => _showLedgerDetail(context, 'FOUNDING_DATE')),
                      _ledgerRow('EMPLOYEE_VAL', '850+ MEMBERS', () => _showLedgerDetail(context, 'ORGANIZATIONAL_SCALE')),
                      _ledgerRow('HQ_NODE', 'BANGALORE, KA', () => _showLedgerDetail(context, 'PRIMARY_LOCATION')),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminBtn(String label, bool isPrimary, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isPrimary ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF0F172A), size: 16),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isPrimary ? Colors.white : const Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: const Color(0xFF64748B), size: 20),
      ),
    );
  }

  Widget _narrativeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MISSION_STATEMENT', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(
            tagline,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.6, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _ledgerRow(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showSyncProcess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      duration: Duration(seconds: 2),
      content: Text('INITIALIZING_TEAM_SYNC_V1.2... DATA_FLOW_ACTIVE'),
      backgroundColor: Color(0xFF6366F1),
    ));
  }

  void _showSystemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('SYSTEM_PARAMETERS', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w900)),
        content: const Text('ALL_SYSTEMS_OPERATIONAL. LATENCY: 24ms. NODE_ACTIVE.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE', style: TextStyle(color: Color(0xFF6366F1)))),
        ],
      ),
    );
  }

  void _showLedgerDetail(BuildContext context, String key) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('READING_LEDGER_${key}... ACCESS_GRANTED')));
  }
}

class _DotGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(rect),
      child: CustomPaint(painter: _DotPainter()),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 30) {
      for (double j = 0; j < size.height; j += 30) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
