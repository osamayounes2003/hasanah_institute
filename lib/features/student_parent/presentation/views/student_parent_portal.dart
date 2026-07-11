import 'package:flutter/material.dart';

import '../../domain/entities/hifz_plan.dart';
import '../../domain/entities/token_wallet.dart';
import '../../domain/repositories/abstract_wallet_repository.dart';

class StudentParentPortal extends StatelessWidget {
  const StudentParentPortal({
    required this.studentId,
    required this.hifzPlan,
    required this.walletRepository,
    super.key,
  });

  final String studentId;
  final HifzPlan hifzPlan;
  final AbstractWalletRepository walletRepository;

  @override
  Widget build(BuildContext context) {
    final completedFraction = hifzPlan.remainingUnits == 0 ? 1.0 : 0.35;
    return Scaffold(
      appBar: AppBar(title: const Text('رحلة الحفظ والمحفظة')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth >= 800 ? 720 : double.infinity,
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('خريطة الحفظ', style: TextStyle(fontSize: 20)),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: completedFraction),
                        const SizedBox(height: 12),
                        Text(
                          'المتبقي: ${hifzPlan.remainingUnits} ${hifzPlan.unit.name}',
                        ),
                        Text(
                          'الواجب اليومي: ${hifzPlan.dailyTarget.toStringAsFixed(1)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('محفظة الرموز', style: TextStyle(fontSize: 20)),
                FutureBuilder<TokenWallet>(
                  future: walletRepository.getWallet(studentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Text('تعذر تحميل رصيد الرموز.');
                    }
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.stars_outlined),
                        title: Text('${snapshot.data?.balance ?? 0} رمز'),
                        subtitle: const Text('يمكن استبدالها بمكافآت المؤسسة.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
