import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../models/user_profile.dart';

class ProfileController extends GetxController {
  var isLoading = false.obs;
  var isUploading = false.obs;
  var profile = Rxn<UserProfile>();

  final GetStorage _storage = GetStorage();
  final String _profileUrl = 'https://n8n.la-renting.com/webhook/customer-profile';
  final String _profilePicWebhookUrl = 'https://n8n.la-renting.com/webhook/customer-profile-pic';
  final String _deletePicWebhookUrl = 'https://n8n.la-renting.com/webhook/customer-profile-pic-delete';
  final String _profilePicRequestUrl = 'https://n8n.la-renting.com/webhook/customer-profile-pic-request';
  
  final ImagePicker _picker = ImagePicker();
  
  // Guard to prevent multiple simultaneous requests
  bool _isFetchingPic = false;

  @override
  void onInit() {
    super.onInit();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    await fetchProfile();
    // Only fetch if profile exists and we don't already have a picture
    if (profile.value != null && (profile.value!.profilePic == null || profile.value!.profilePic!.isEmpty)) {
      await fetchProfilePic();
    }
  }

  Future<void> fetchProfilePic({bool force = false}) async {
    if (profile.value == null) return;
    
    // Skip if already fetching or if we already have a pic and not forcing a refresh
    if (_isFetchingPic) return;
    if (!force && profile.value!.profilePic != null && profile.value!.profilePic!.isNotEmpty) return;
    
    _isFetchingPic = true;
    try {
      debugPrint('Requesting profile pic for: ${profile.value!.email}');
      final response = await http.post(
        Uri.parse(_profilePicRequestUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profile.value!.toJson()),
      );

      debugPrint('Profile Pic Request Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type']?.toLowerCase() ?? '';
        
        // Handle image binary response
        if (contentType.startsWith('image/')) {
          final base64String = base64Encode(response.bodyBytes);
          final dataUri = 'data:$contentType;base64,$base64String';
          profile.value = profile.value?.copyWith(profilePic: dataUri);
          debugPrint('Set profile pic from binary request');
          return;
        }

        // Handle JSON or Text
        if (response.body.isNotEmpty) {
          try {
            final decoded = json.decode(response.body.trim());
            String? imageUrl;
            
            if (decoded is Map<String, dynamic>) {
              imageUrl = (decoded['profile_pic'] ?? decoded['image_url'] ?? decoded['url'])?.toString();
            } else if (decoded is List && decoded.isNotEmpty) {
              final first = decoded.first;
              if (first is Map<String, dynamic>) {
                imageUrl = (first['profile_pic'] ?? first['image_url'] ?? first['url'])?.toString();
              }
            }

            if (imageUrl != null && imageUrl.startsWith('http')) {
              profile.value = profile.value?.copyWith(profilePic: imageUrl);
            }
          } catch (e) {
            // Raw URL string
            if (response.body.trim().startsWith('http')) {
              profile.value = profile.value?.copyWith(profilePic: response.body.trim());
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile pic: $e');
    } finally {
      _isFetchingPic = false;
    }
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final storedUser = _storage.read('user');
      String email = '';
      if (storedUser != null) {
        email = storedUser['email'] ?? '';
      }

      if (email.isEmpty) {
        debugPrint('Email is empty, cannot fetch profile');
        return;
      }

      final response = await http.post(
        Uri.parse(_profileUrl),
        body: {'email': email},
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final data = json.decode(response.body);
          
          Map<String, dynamic> jsonResponse;
          if (data is List) {
            if (data.isNotEmpty) {
              jsonResponse = data.first;
            } else {
              return;
            }
          } else {
            jsonResponse = data;
          }

          profile.value = UserProfile.fromJson(jsonResponse);
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        await uploadProfilePic(image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      Get.snackbar('Error', 'Failed to pick image');
    }
  }

  Future<void> uploadProfilePic(XFile imageFile) async {
    if (profile.value == null) return;

    isUploading.value = true;
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_profilePicWebhookUrl));
      
      // Add all customer data
      final profileData = profile.value!.toJson();
      profileData.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      
      // Add action type
      request.fields['action'] = 'upload';

      // Add file
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'profile_pic',
          bytes,
          filename: imageFile.name,
          contentType: MediaType('image', 'jpeg'),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_pic',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final response = await request.send();
      final httpResponse = await http.Response.fromStream(response);
      
      debugPrint('Upload Response Status: ${httpResponse.statusCode}');
      
      if (httpResponse.statusCode == 200) {
        // Check if the response is an image binary
        final contentType = httpResponse.headers['content-type']?.toLowerCase() ?? '';
        bool isImage = contentType.startsWith('image/');
        
        // signature check for common image types if content-type is generic or missing
        if (!isImage && httpResponse.bodyBytes.length >= 4) {
          final bytes = httpResponse.bodyBytes;
          if ((bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) || // PNG
              (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)) { // JPEG
            isImage = true;
          }
        }

        if (isImage) {
          final base64String = base64Encode(httpResponse.bodyBytes);
          final finalContentType = isImage && contentType.startsWith('image/') ? contentType : 'image/png';
          final dataUri = 'data:$finalContentType;base64,$base64String';
          
          profile.value = profile.value?.copyWith(profilePic: dataUri);
          debugPrint('Set profile picture from binary response (base64)');
          Get.snackbar('Success', 'Profile picture updated successfully');
          return;
        }

        // It's not an image, try to parse as JSON or text
        String responseData = '';
        try {
          responseData = utf8.decode(httpResponse.bodyBytes, allowMalformed: true);
        } catch (e) {
          debugPrint('Could not decode response as UTF-8');
        }

        if (responseData.isNotEmpty) {
          try {
            final decoded = json.decode(responseData.trim());
            String? imageUrl;
            
            if (decoded is Map<String, dynamic>) {
              imageUrl = (decoded['profile_pic'] ?? decoded['image_url'] ?? decoded['url'])?.toString();
            } else if (decoded is List && decoded.isNotEmpty) {
              final first = decoded.first;
              if (first is Map<String, dynamic>) {
                imageUrl = (first['profile_pic'] ?? first['image_url'] ?? first['url'])?.toString();
              } else if (first is String) {
                imageUrl = first;
              }
            }

            if (imageUrl != null && imageUrl.startsWith('http')) {
              profile.value = profile.value?.copyWith(profilePic: imageUrl);
              debugPrint('Set profile picture from JSON response: $imageUrl');
            } else {
              await fetchProfile();
            }
          } catch (e) {
            if (responseData.trim().startsWith('http')) {
              profile.value = profile.value?.copyWith(profilePic: responseData.trim());
            } else {
              await fetchProfile();
            }
          }
        } else {
          await fetchProfile();
        }
        Get.snackbar('Success', 'Profile picture updated successfully');
      } else {
        Get.snackbar('Error', 'Upload failed: ${httpResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      Get.snackbar('Error', 'An error occurred during upload');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> deleteProfilePic() async {
    if (profile.value == null) return;

    isLoading.value = true;
    try {
      // Send delete request with all customer data
      final response = await http.post(
        Uri.parse(_deletePicWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          ...profile.value!.toJson(),
          'action': 'delete',
        }),
      );

      debugPrint('Delete Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Result'] == 'success') {
          // Remove pic locally
          profile.value = profile.value?.copyWith(profilePic: '');
          Get.snackbar('Success', 'Your profile pic has been deleted successfully.');
        } else {
          Get.snackbar('Error', 'Failed to delete profile picture');
        }
      } else {
        Get.snackbar('Error', 'Failed to delete profile picture');
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
      Get.snackbar('Error', 'An error occurred during deletion');
    } finally {
      isLoading.value = false;
    }
  }
}
