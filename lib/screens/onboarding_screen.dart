import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_form_screen.dart';
import 'task_list_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  void _skip(BuildContext context) async {
    await _completeOnboarding(context);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TaskListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _Page1(),
              _Page2(),
              _Page3(),
              _Page4(onStart: () async {
                await _completeOnboarding(context);
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TaskFormScreen()),
                );
              }),
            ],
          ),
          // スキップボタン
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: TextButton(
              onPressed: () => _skip(context),
              child: const Text('スキップ', style: TextStyle(color: Colors.grey)),
            ),
          ),
          // ドットインジケーター
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: _DotIndicator(currentPage: _currentPage, pageCount: 4),
          ),
        ],
      ),
    );
  }
}

// ─── ページ1: TGLメーター ────────────────────────────────────────

class _Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      visual: CustomPaint(
        size: const Size(180, 180),
        painter: _GaugePainter(progress: 0.7),
      ),
      headline: '締切までの時間がわかる',
      body: 'OIKOMIは"心理的つらさ"で課題を管理する、\n新しいタスク管理アプリ',
    );
  }
}

// ─── ページ2: 入力フォームモック ─────────────────────────────────

class _Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      visual: _FormMockVisual(),
      headline: '入力はたった4つ',
      body: '課題名・締切・所要時間・やりたくなさを\n入力するだけ。あとはOIKOMIが判断する',
    );
  }
}

// ─── ページ3: 5段階ステータス ─────────────────────────────────────

class _Page3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      visual: _StatusPillsVisual(),
      headline: '5段階で"つらさ"を表示',
      body: 'まだ平和 → そのうちヤバ → もうヤバ現実 →\n逃げ場なし → 戦争。\n状況が変わると通知でお知らせ',
    );
  }
}

// ─── ページ4: CTA ────────────────────────────────────────────────

class _Page4 extends StatelessWidget {
  const _Page4({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      visual: const SizedBox(height: 180),
      headline: 'さあ始めよう',
      body: '',
      action: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('最初の課題を追加する'),
          ),
        ),
      ),
    );
  }
}

// ─── 共通ページレイアウト ────────────────────────────────────────

class _PageLayout extends StatelessWidget {
  const _PageLayout({
    required this.visual,
    required this.headline,
    required this.body,
    this.action,
  });

  final Widget visual;
  final String headline;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      children: [
        SizedBox(
          height: screenHeight * 0.5,
          child: Center(child: visual),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (action != null) ...[
                  const SizedBox(height: 32),
                  action!,
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 80), // ドットインジケーター分の余白
      ],
    );
  }
}

// ─── ドットインジケーター ────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.currentPage, required this.pageCount});
  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (i) {
        final active = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.blue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── ビジュアル: ゲージ（CustomPaint） ──────────────────────────

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.65);
    final radius = size.width * 0.42;

    // 背景アーク
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14 * 0.85,
      3.14 * 1.3,
      false,
      bgPaint,
    );

    // 進捗アーク
    final fgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFFFF5722)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14 * 0.85,
      3.14 * 1.3 * progress,
      false,
      fgPaint,
    );

    // 中央テキスト
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'TGL',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}

// ─── ビジュアル: 追加フォームモック ─────────────────────────────

class _FormMockVisual extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MockField(label: '課題名', value: '統計学レポート'),
          const SizedBox(height: 10),
          _MockField(label: '締切', value: '5/31 23:59'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MockField(label: '所要時間', value: '2時間')),
              const SizedBox(width: 8),
              Expanded(child: _MockField(label: 'やりたくなさ', value: '7')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MockField extends StatelessWidget {
  const _MockField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ─── ビジュアル: 5段階ステータスpill ────────────────────────────

class _StatusPillsVisual extends StatelessWidget {
  static const _states = [
    ('まだ平和', Color(0xFFD4EDDA), Color(0xFF155724)),
    ('そのうちヤバ', Color(0xFFFFF3CD), Color(0xFF856404)),
    ('もうヤバ現実', Color(0xFFFFE0B2), Color(0xFFE65100)),
    ('逃げ場なし', Color(0xFFFFCDD2), Color(0xFFC62828)),
    ('戦争', Color(0xFFB71C1C), Colors.white),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _states.map((s) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: s.$2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              s.$1,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: s.$3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

