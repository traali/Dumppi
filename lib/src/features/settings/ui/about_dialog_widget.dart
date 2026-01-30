import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutDialogWidget extends StatelessWidget {
  const AboutDialogWidget({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text('About Dumppi'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dumppi v1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Weather Data',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
             InkWell(
              onTap: () => _launchUrl('https://open-meteo.com/'),
              child: const Text(
                'Weather data by Open-Meteo.com',
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 12),
             const Text(
              'Map Data',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            InkWell(
              onTap: () => _launchUrl('https://www.openstreetmap.org/copyright'),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => _launchUrl('https://www.opensnowmap.org/'),
              child: const Text(
                'Piste data by OpenSnowMap',
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.gavel, size: 20),
              title: const Text('Third-Party Licenses'),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Dumppi',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.snowboarding, size: 48),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
