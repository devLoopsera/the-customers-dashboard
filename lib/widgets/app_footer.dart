import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  final Color labelColor = const Color(0xFF6B7280);
  final Color valueColor = const Color(0xFF374151);
  final Color linkColor = const Color(0xFF5A67D8); // Blue color for links as seen in screenshot

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTab = MediaQuery.of(context).size.width < 1024 && !isMobile;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFF2E7D6A), width: 1), // Top teal border
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isTab ? 40 : 60),
        vertical: 40,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompanyInfo(),
                const SizedBox(height: 24),
                _buildContactInfo(),
                const SizedBox(height: 24),
                _buildWebsiteTaxInfo(),
                const SizedBox(height: 24),
                _buildIdNumberInfo(),
                const SizedBox(height: 24),
                _buildBankInfo(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildCompanyInfo()),
                Expanded(child: _buildContactInfo()),
                Expanded(child: _buildWebsiteTaxInfo()),
                Expanded(child: _buildIdNumberInfo()),
                Expanded(child: _buildBankInfo()),
              ],
            ),
    );
  }

  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fleckfrei.de', style: TextStyle(color: labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('Postanschrift', style: TextStyle(color: labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Herzbergstr 100', style: TextStyle(color: valueColor)),
        Text('10317 Berlin Germany', style: TextStyle(color: valueColor)),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Telefonnummer', style: TextStyle(color: labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _launchUrl('tel:+1509743228'),
          child: Text('+1509743228', style: TextStyle(color: linkColor)),
        ),
        const SizedBox(height: 12),
        Text('E-Mail', style: TextStyle(color: labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _launchUrl('mailto:info@fleckfrei.de'),
          child: Text('info@fleckfrei.de', style: TextStyle(color: linkColor)),
        ),
      ],
    );
  }

  Widget _buildWebsiteTaxInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Webseite', style: TextStyle(color: labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _launchUrl('https://www.fleckfrei.de'),
          child: Text('www.fleckfrei.de', style: TextStyle(color: linkColor)),
        ),
        const SizedBox(height: 12),
        Text('Steuernummer', style: TextStyle(color: labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('132/571/00584', style: TextStyle(color: valueColor)),
      ],
    );
  }

  Widget _buildIdNumberInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('USt-IdNr', style: TextStyle(color: labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('DE301503988', style: TextStyle(color: valueColor)),
        const SizedBox(height: 12),
        Text('Betriebsnummer', style: TextStyle(color: labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('969504433', style: TextStyle(color: valueColor)),
      ],
    );
  }

  Widget _buildBankInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bankverbindung', style: TextStyle(color: labelColor, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('N26', style: TextStyle(color: valueColor)),
        Text('NTSBDEB1XXX', style: TextStyle(color: valueColor)),
        const SizedBox(height: 8),
        Text('DE04 1001 1001 2626 4474 99', style: TextStyle(color: valueColor, fontSize: 13)),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }
}
