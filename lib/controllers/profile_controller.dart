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
  DateTime? _lastUploadTime;

  String _addCacheBuster(String url) {
    if (!url.startsWith('http')) return url;
    // Don't add if it's a data URI
    if (url.startsWith('data:')) return url;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return url.contains('?') ? '$url&t=$timestamp' : '$url?t=$timestamp';
  }

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
              profile.value = profile.value?.copyWith(profilePic: _addCacheBuster(imageUrl));
            }
          } catch (e) {
            // Raw URL string
            if (response.body.trim().startsWith('http')) {
              profile.value = profile.value?.copyWith(profilePic: _addCacheBuster(response.body.trim()));
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

  Future<void> fetchProfile({bool refreshPic = false}) async {
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

          final newUserProfile = UserProfile.fromJson(jsonResponse);
          
          // Protection: If we recently uploaded an image (within 10 seconds), 
          // and the fetched profile has no image, keep our local image.
          // This prevents the "flicker" when the backend is eventually consistent.
          bool recentlyUploaded = _lastUploadTime != null && 
                                DateTime.now().difference(_lastUploadTime!).inSeconds < 10;
          
          if (recentlyUploaded && (newUserProfile.profilePic == null || newUserProfile.profilePic!.isEmpty)) {
            debugPrint('Preserving recently uploaded image as backend returned empty');
            profile.value = newUserProfile.copyWith(profilePic: profile.value?.profilePic);
          } else {
            // Add cache buster to the incoming URL if it's a network image
            if (newUserProfile.profilePic != null && newUserProfile.profilePic!.isNotEmpty) {
              profile.value = newUserProfile.copyWith(profilePic: _addCacheBuster(newUserProfile.profilePic!));
            } else {
              profile.value = newUserProfile;
            }
          }

          // Fetch the profile pic from the dedicated webhook if requested
          if (refreshPic) {
            await fetchProfilePic(force: true);
          }
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
    _lastUploadTime = DateTime.now();
    try {
      // Create a local data URI for immediate UI update
      final bytes = await imageFile.readAsBytes();
      final localDataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      
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
        // Successfully uploaded, set the local image first for immediate feedback
        profile.value = profile.value?.copyWith(profilePic: localDataUri);
        
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
        } else {
          // It's not an image binary, try to parse as JSON or text
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
                profile.value = profile.value?.copyWith(profilePic: _addCacheBuster(imageUrl));
                debugPrint('Set profile picture from JSON response with cache buster: ${profile.value?.profilePic}');
              } else {
                // Wait a bit before fetching to let the backend settle
                await Future.delayed(const Duration(seconds: 2));
                await fetchProfile();
              }
            } catch (e) {
              if (responseData.trim().startsWith('http')) {
                profile.value = profile.value?.copyWith(profilePic: _addCacheBuster(responseData.trim()));
              } else {
                await Future.delayed(const Duration(seconds: 1));
                await fetchProfile();
              }
            }
          } else {
            await Future.delayed(const Duration(seconds: 1));
            await fetchProfile();
          }
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
    
    // If no picture exists locally, don't bother calling the server if the user is just trying to clear it
    if (profile.value!.profilePic == null || profile.value!.profilePic!.isEmpty) {
      Get.snackbar('Info', 'The image does not exist');
      return;
    }

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
        } else if (data['Result']?.toString().toLowerCase().contains('not exist') == true || 
                   data['Message']?.toString().toLowerCase().contains('not found') == true ||
                   data['Message']?.toString().toLowerCase().contains('does not exist') == true) {
          // Specific case for non-existent image
          profile.value = profile.value?.copyWith(profilePic: '');
          Get.snackbar('Info', 'The image does not exist');
        } else {
          Get.snackbar('Error', 'Failed to delete profile picture: ${data['Message'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 404) {
        profile.value = profile.value?.copyWith(profilePic: '');
        Get.snackbar('Info', 'The image does not exist');
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
