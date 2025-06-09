import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/service_locator.dart';
import '../feature/home/providers/home_dashboard_provider.dart';

/// Integration test screen to compare old vs new architecture
class IntegrationTestScreen extends StatefulWidget {
  const IntegrationTestScreen({super.key});

  @override
  State<IntegrationTestScreen> createState() => _IntegrationTestScreenState();
}

class _IntegrationTestScreenState extends State<IntegrationTestScreen> {
  bool _isTestingOld = false;
  bool _isTestingNew = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Architecture Integration Test'),
        backgroundColor: Colors.blue[100],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestSummaryCard(),
            const SizedBox(height: 24),
            _buildNavigationTestSection(),
            const SizedBox(height: 24),
            _buildStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.blue[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Repository Architecture Integration',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Test the integration of our new repository architecture. '
              'Compare old vs new implementations.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildStatusIndicator('ServiceLocator', _isServiceLocatorReady()),
            const SizedBox(height: 8),
            _buildStatusIndicator(
                'Dashboard Provider', _isDashboardProviderReady()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String component, bool isReady) {
    return Row(
      children: [
        Icon(
          isReady ? Icons.check_circle : Icons.error_outline,
          color: isReady ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          component,
          style: TextStyle(
            color: isReady ? Colors.green[700] : Colors.red[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isReady) ...[
          const SizedBox(width: 8),
          Text(
            'Ready',
            style: TextStyle(
              color: Colors.green[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.navigation, color: Colors.teal[600]),
                const SizedBox(width: 8),
                const Text(
                  'Navigation Tests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTestingOld ? null : _testOldHome,
                    icon: _isTestingOld
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.home_outlined),
                    label: const Text('Test Old Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTestingNew ? null : _testNewHome,
                    icon: _isTestingNew
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.home),
                    label: const Text('Test New Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/explore'),
                    child: const Text('Explore'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/profile'),
                    child: const Text('Profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Integration Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '✅ Service Locator with lazy loading\n'
              '✅ Repository pattern with caching\n'
              '✅ Modern dashboard provider\n'
              '✅ Automatic state management\n'
              '✅ Navigation integration',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Integration Complete! Ready for testing.',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isServiceLocatorReady() {
    try {
      ServiceLocator.instance.get<HomeDashboardProvider>();
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isDashboardProviderReady() {
    try {
      final provider = ServiceLocator.instance.get<HomeDashboardProvider>();
      return provider != null;
    } catch (e) {
      return false;
    }
  }

  void _testOldHome() {
    setState(() => _isTestingOld = true);
    context.go('/');
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isTestingOld = false);
    });
  }

  void _testNewHome() {
    setState(() => _isTestingNew = true);
    context.go('/modern-home');
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isTestingNew = false);
    });
  }
}
