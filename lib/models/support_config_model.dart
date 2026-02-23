class SupportConfig {
  final String whatsappNumber;
  final String telegramUsername;
  final String telegramBotLink;
  
  SupportConfig({
    required this.whatsappNumber,
    required this.telegramUsername,
    required this.telegramBotLink,
  });
  
  factory SupportConfig.fromJson(Map<String, dynamic> json) {
    return SupportConfig(
      whatsappNumber: json['whatsapp_support_number'] ?? '',
      telegramUsername: json['telegram_support_username'] ?? '',
      telegramBotLink: json['telegram_support_bot_link'] ?? '',
    );
  }
}
