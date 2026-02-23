import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:deeplink_x/deeplink_x.dart';
import '../models/support_config_model.dart';
import '../controllers/auth_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportService extends GetxService {
  final DeeplinkX _deeplinkX = DeeplinkX();
  
  Future<SupportConfig?> getSupportConfig() async {
    try {
      final authController = Get.find<AuthController>();
      final customerId = authController.currentUser.value?.customerId ?? '';
      
      final response = await http.post(
        Uri.parse('https://n8n.la-renting.com/webhook/customer-support'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customer_id': customerId,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          if (decoded.isNotEmpty) {
             return SupportConfig.fromJson(decoded[0]);
          }
        } else if (decoded is Map<String, dynamic>) {
          return SupportConfig.fromJson(decoded);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Failed to load support config: $e');
      return null;
    }
  }
  
  Future<void> launchWhatsApp(String phoneNumber) async {
    try {
      // Remove symbols from phone number just in case
      final number = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      if (number.isEmpty) return;

      final launched = await _deeplinkX.launchAction(
        WhatsApp.chat(
          phoneNumber: number,
          fallbackToStore: true,
        ),
      );
      
      if (!launched) {
        Get.snackbar('Error', 'Could not open WhatsApp');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to open WhatsApp: $e');
    }
  }
  
  Future<void> launchTelegram(String username) async {
    try {
      // Clean username (remove leading '@' if present, as sometimes deeplinks fail with '@')
      String cleanUsername = username.trim();
      if (cleanUsername.startsWith('@')) {
        cleanUsername = cleanUsername.substring(1);
      }
      if (cleanUsername.isEmpty) return;
      
      final launched = await _deeplinkX.launchAction(
        Telegram.openProfile(
          username: cleanUsername, 
          fallbackToStore: true,
        ),
      );
      
      if (!launched) {
        Get.snackbar('Error', 'Could not open Telegram');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to open Telegram: $e');
    }
  }
  
  Future<void> launchTelegramBot(String botLink) async {
    try {
      final uri = Uri.parse(botLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Error', 'Could not open Telegram bot');
      }
    } catch (e) {
       Get.snackbar('Error', 'Failed to open Telegram bot: $e');
    }
  }
}
