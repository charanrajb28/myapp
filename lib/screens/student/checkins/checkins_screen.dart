import 'package:flutter/material.dart';

class CheckinsScreen extends StatefulWidget {
  const CheckinsScreen({super.key});

  @override
  State<CheckinsScreen> createState() => _CheckinsScreenState();
}

class _CheckinsScreenState extends State<CheckinsScreen>
    with SingleTickerProviderStateMixin {
  bool _checkedInToday = false;
  bool _submitting = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _submitCheckIn() async {
    // Show mock QR scanner first
    _showQRScanner();
  }

  void _showQRScanner() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _QRScannerOverlay(
          onScanComplete: () {
            Navigator.pop(context);
            _processCheckIn();
          },
          onCancel: () => Navigator.pop(context),
        );
      },
    );
  }

  Future<void> _processCheckIn() async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _submitting = false;
      _checkedInToday = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Attendance recorded successfully!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Daily Check-In',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ── Today's status card ──
          _todayCard(),
          const SizedBox(height: 24),

          // ── Check-in button ──
          _checkInButton(),
          const SizedBox(height: 28),

          // ── This week calendar strip ──
          _weekStrip(),
          const SizedBox(height: 28),

          // ── History section ──
          _historySection(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _todayCard() {
    final now = DateTime.now();
    final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][now.weekday - 1];
    final monthName = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ][now.month - 1];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_checkedInToday
                    ? const Color(0xFF10B981)
                    : const Color(0xFF0F172A))
                .withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Mesh background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _checkedInToday
                      ? [const Color(0xFF059669), const Color(0xFF10B981)]
                      : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY\'S LOG',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$dayName, ${now.day} $monthName',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _checkedInToday ? Icons.verified_rounded : Icons.info_outline_rounded,
                                size: 14,
                                color: _checkedInToday ? const Color(0xFF4ADE80) : Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _checkedInToday ? 'SECURED FOR TODAY' : 'PENDING CHECK-IN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _checkedInToday ? const Color(0xFF4ADE80) : Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _indicatorIcon(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicatorIcon() {
    if (_checkedInToday) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const Icon(Icons.check_circle_rounded, size: 36, color: Colors.white),
      );
    }
    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
              blurRadius: 20,
            ),
          ],
        ),
        child: const Icon(Icons.fingerprint_rounded, size: 36, color: Colors.white),
      ),
    );
  }

  Widget _checkInButton() {
    if (_checkedInToday) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 22),
            SizedBox(width: 10),
            Text(
              'Attendance Recorded for Today',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [const Color(0xFF0F172A), const Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submitting ? null : _submitCheckIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _submitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, size: 22),
                  SizedBox(width: 12),
                  Text(
                    'START QR SCANNER',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _weekStrip() {
    final today = DateTime.now().weekday; // 1=Mon ... 7=Sun
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    // Mock: Mon–today checked in, rest missing/upcoming
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Week',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 15,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final dayNum = i + 1;
              final isToday = dayNum == today;
              final isPast = dayNum < today;
              final isWeekend = dayNum >= 6;
              final isChecked = isPast && !isWeekend;

              Color accentColor = const Color(0xFF64748B);
              bool showCheck = false;

              if (isWeekend) {
                accentColor = const Color(0xFFE2E8F0);
              } else if ((isToday && _checkedInToday) || isChecked) {
                accentColor = const Color(0xFF10B981);
                showCheck = true;
              } else if (isToday) {
                accentColor = const Color(0xFF3B82F6);
              }

              return Column(
                children: [
                  Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accentColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isToday ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday ? Border.all(color: accentColor.withValues(alpha: 0.3)) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showCheck)
                          Icon(Icons.check_circle_rounded, size: 18, color: accentColor)
                        else
                          Text(
                            '${dayNum + 10}', // Mock dates
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isToday ? accentColor : const Color(0xFF94A3B8),
                            ),
                          ),
                        if (isToday)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _historySection() {
    const history = [
      _CheckInRecord('Mar 14', 'Friday', '9:08 AM', true),
      _CheckInRecord('Mar 13', 'Thursday', '9:21 AM', true),
      _CheckInRecord('Mar 12', 'Wednesday', '9:15 AM', true),
      _CheckInRecord('Mar 11', 'Tuesday', '—', false),
      _CheckInRecord('Mar 10', 'Monday', '9:33 AM', true),
      _CheckInRecord('Mar 7', 'Friday', '9:02 AM', true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Check-In History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '42 total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: history.length,
            separatorBuilder: (_, index) => const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF1F5F9),
              indent: 60,
            ),
            itemBuilder: (_, i) => _CheckInTile(record: history[i]),
          ),
        ),
      ],
    );
  }
}

class _CheckInRecord {
  final String date;
  final String day;
  final String time;
  final bool present;
  const _CheckInRecord(this.date, this.day, this.time, this.present);
}

class _CheckInTile extends StatelessWidget {
  final _CheckInRecord record;
  const _CheckInTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: record.present
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              record.present
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: record.present
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.date}  ·  ${record.day}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.present ? 'Checked in at ${record.time}' : 'Absent',
                  style: TextStyle(
                    fontSize: 12,
                    color: record.present
                        ? const Color(0xFF64748B)
                        : const Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: record.present
                  ? const Color(0xFF10B981).withValues(alpha: 0.08)
                  : const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              record.present ? 'Present' : 'Absent',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: record.present
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QRScannerOverlay extends StatefulWidget {
  final VoidCallback onScanComplete, onCancel;
  const _QRScannerOverlay({required this.onScanComplete, required this.onCancel});

  @override
  State<_QRScannerOverlay> createState() => _QRScannerOverlayState();
}

class _QRScannerOverlayState extends State<_QRScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Auto-complete after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onScanComplete();
    });
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: Stack(
        children: [
          // Scanning Frame
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Corner borders
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    // Animated Scanner Line
                    AnimatedBuilder(
                      animation: _scannerController,
                      builder: (context, child) {
                        return Positioned(
                          top: 20 + (_scannerController.value * 240),
                          left: 20,
                          right: 20,
                          child: Column(
                            children: [
                              Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.withValues(alpha: 0),
                                      Colors.blue.shade400,
                                      Colors.blue.withValues(alpha: 0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.6),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.blue.withValues(alpha: 0.15),
                                      Colors.blue.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Masking corners for a "Target" look
                    _corner(top: 0, left: 0, angle: 0),
                    _corner(top: 0, right: 0, angle: 90),
                    _corner(bottom: 0, left: 0, angle: 270),
                    _corner(bottom: 0, right: 0, angle: 180),
                  ],
                ),
                const SizedBox(height: 60),
                const Column(
                  children: [
                    Text(
                      'SCANNING...',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Align QR code within the frame',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Header with close button
          Positioned(
            top: 60,
            right: 24,
            child: IconButton(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({double? top, double? bottom, double? left, double? right, required double angle}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle * 3.14159 / 180,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.blue, width: 4),
              left: BorderSide(color: Colors.blue, width: 4),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
          ),
        ),
      ),
    );
  }
}
