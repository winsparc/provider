import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:dio/dio.dart';
class UserImage {
  final String id;
  final String username;
  final String imageUrl;

  UserImage({
    required this.id,
    required this.username,
    required this.imageUrl,
  });

  factory UserImage.fromJson(Map<String, dynamic> json) {
    return UserImage(
      id: json['id'].toString(),
      username: json['username'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'image_url': imageUrl,
    };
  }
}

class RandomUserResponse {
  final List<RandomUser> results;

  RandomUserResponse({required this.results});

  factory RandomUserResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List;
    final users = list.map((e) => RandomUser.fromJson(e)).toList();
    return RandomUserResponse(results: users);
  }
}

class RandomUser {
  final String name;
  final String email;
  final String imageUrl;

  RandomUser({
    required this.name,
    required this.email,
    required this.imageUrl,
  });

  factory RandomUser.fromJson(Map<String, dynamic> json) {
    final name = '${json['name']['first']} ${json['name']['last']}';
    return RandomUser(
      name: name,
      email: json['email'] ?? '',
      imageUrl: json['picture']['large'] ?? '',
    );
  }
}

class UploadProvider extends ChangeNotifier {
  File? _selectedImage;
  String _username = '';
  UserImage? _editingItem;
  List<UserImage> _userImages = [];
  bool _isLoadingUpload = false;
  bool _isLoadingList = false;
  String? _errorMessage;
  String? _successMessage;

  File? get selectedImage => _selectedImage;
  String get username => _username;
  UserImage? get editingItem => _editingItem;
  List<UserImage> get userImages => _userImages;
  bool get isLoadingUpload => _isLoadingUpload;
  bool get isLoadingList => _isLoadingList;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _selectedImage = File(image.path);
      _errorMessage = null;
      print('✅ Image selected: ${_selectedImage!.path}');
      print('✅ Image size: ${_selectedImage!.lengthSync()} bytes');
      notifyListeners();
    }
  }

  Future<void> pickFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to open camera: $e';
      notifyListeners();
    }
  }

  void updateUsername(String value) {
    _username = value;
    notifyListeners();
  }

  void loadForEdit(UserImage item) {
    _editingItem = item;
    _username = item.username;
    _selectedImage = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearEditMode() {
    _editingItem = null;
    _username = '';
    _selectedImage = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Future<void> saveImageAndUsername({
  //   required String baseUrl,
  //   required String fieldName,
  //   String? fileName,
  //   String usernameFieldName = 'name',
  //   String email = 'email',
  //   String password = 'password',
  // }) async {
  //   if (_username.isEmpty) {
  //     _errorMessage = 'Username is required';
  //     notifyListeners();
  //     return;
  //   }

  //   final hasImage = _selectedImage != null;
  //   if (_editingItem != null && !hasImage) {
  //     // Allow username-only update if no new image
  //   } else if (!hasImage) {
  //     _errorMessage = 'Image is required for new items';
  //     notifyListeners();
  //     return;
  //   }

  //   _isLoadingUpload = true;
  //   _errorMessage = null;
  //   _successMessage = null;
  //   notifyListeners();

  //   try {
  //     http.MultipartRequest request;
  //     String url;

  //     if (_editingItem == null) {
  //       // Insert
  //       url = '$baseUrl/save-user-data';
  //       request = http.MultipartRequest('POST', Uri.parse(url));
  //       print('🚀 Starting INSERT request to: $url');
  //     } else {
  //       // Update
  //       url = '$baseUrl/update-user-data/${_editingItem!.id}';
  //       request = http.MultipartRequest('PUT', Uri.parse(url));
  //       print('🚀 Starting UPDATE request to: $url');
  //     }

  //     // Add image if provided
  //     if (hasImage) {
  //       print('📁 Adding image file:');
  //       print('   - Path: ${_selectedImage!.path}');
  //       print('   - Size: ${_selectedImage!.lengthSync()} bytes');
  //       print('   - Field name: $fieldName');

  //       request.files.add(
  //         await http.MultipartFile.fromPath(
  //           fieldName,
  //           _selectedImage!.path,
  //           filename: fileName ?? _selectedImage!.path.split('/').last,
  //         ),
  //       );
  //       print('✅ Image file added to request');
  //     } else {
  //       print('ℹ️ No image file to upload (update mode)');
  //     }

  //     // Add form fields
  //     print('📝 Adding form fields:');
  //     print('   - $usernameFieldName: $_username');
  //     print('   - $email: test@gmail.com');
  //     print('   - $password: password');

  //     request.fields['name'] = _username;
  //     // request.fields[email] = 'test@gmail.com';
  //     // request.fields[password] = 'password';

  //     print('📤 Sending multipart request...');
  //     print(request);
  //     var streamedResponse = await request.send();
  //     print('📥 Received response stream');

  //     var response = await http.Response.fromStream(streamedResponse);
  //     print('📄 Response converted to http.Response');

  //     print('🔍 RESPONSE DETAILS:');
  //     print('   - Status Code: ${response.statusCode}');
  //     print('   - Headers: ${response.headers}');
  //     print('   - Body Length: ${response.body.length}');
  //     print('   - Body Content: ${response.body}');

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       try {
  //         final responseData = json.decode(response.body);
  //         print('✅ Success! Response data: $responseData');

  //         final action = _editingItem == null ? 'Insert' : 'Update';
  //         _successMessage = '$action successful for: $_username!';
  //         print('✅ $_successMessage');

  //         _editingItem = null;
  //         _fetchUserImages(baseUrl: baseUrl);
  //       } catch (e) {
  //         print('⚠️ Success status but JSON parse error: $e');
  //         final action = _editingItem == null ? 'Insert' : 'Update';
  //         _successMessage = '$action successful for: $_username!';
  //       }
  //     } else {
  //       print('❌ API Error:');
  //       print('   - Status: ${response.statusCode}');
  //       print('   - Body: ${response.body}');

  //       try {
  //         final errorData = json.decode(response.body);
  //         _errorMessage = 'Failed: ${errorData['message'] ?? 'Unknown error'}';
  //       } catch (e) {
  //         _errorMessage = 'Failed: HTTP ${response} - ${response.body}';
  //       }
  //       print('❌ Error message: $_errorMessage');
  //     }
  //   } catch (e) {
  //     print('💥 EXCEPTION during upload:');
  //     print('   - Error type: ${e.runtimeType}');
  //     print('   - Error message: $e');
  //     print('   - Stack trace: ${e.toString()}');

  //     _errorMessage = 'Network error: $e';
  //     print('❌ Exception error: $_errorMessage');
  //   } finally {
  //     _isLoadingUpload = false;
  //     notifyListeners();
  //     print('🏁 Upload process completed');
  //   }
  // }

  Future<void> saveImageAndUsername({
    required String baseUrl,
    required String fieldName,
    String? fileName,
    String usernameFieldName = 'name',
    String email = 'email',
    String password = 'password',
  }) async {
    if (_username.isEmpty) {
      _errorMessage = 'Username is required';
      notifyListeners();
      return;
    }

    final hasImage = _selectedImage != null;
    if (_editingItem != null && !hasImage) {
      // Allow username-only update if no new image
    } else if (!hasImage) {
      _errorMessage = 'Image is required for new items';
      notifyListeners();
      return;
    }

    _isLoadingUpload = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      http.MultipartRequest request;
      String url;

      if (_editingItem == null) {
        // INSERT - POST
        url = '$baseUrl/save-user-data';
        request = http.MultipartRequest('POST', Uri.parse(url));
        print('🚀 Starting INSERT request to: $url');
      } else {
        // UPDATE - POST (not PUT)
        url = '$baseUrl/update-user-data/${_editingItem!.id}';
        request = http.MultipartRequest(
            'POST', Uri.parse(url)); // POST instead of PUT
        print('🚀 Starting UPDATE request to: $url');
      }

      // Add image if provided
      if (hasImage) {
        print('📁 Adding image file:');
        print('   - Path: ${_selectedImage!.path}');

        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            _selectedImage!.path,
            filename:
                fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
        print('✅ Image file added to request');
      }

      // Add form fields - use exact field names
      print('📝 Adding form fields:');
      print('   - name: $_username');

      request.fields['name'] = _username;
      request.fields['email'] = 'test@gmail.com';
      request.fields['password'] = 'password';

      // Debug the complete request
      print('🔍 FINAL REQUEST:');
      print('   - URL: $url');
      print('   - Method: ${request.method}');
      print('   - Fields: ${request.fields}');
      print('   - Files: ${request.files.length}');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 RESPONSE: ${response.statusCode}');
      print('   - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('✅ Success! Response: $responseData');

        final action = _editingItem == null ? 'Insert' : 'Update';
        _successMessage = '$action successful for: $_username!';

        _editingItem = null;
        _fetchUserImages(baseUrl: baseUrl);
      } else {
        _errorMessage = 'Failed: HTTP ${response.statusCode}';
        print('❌ Error: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('💥 Exception: $e');
    } finally {
      _isLoadingUpload = false;
      notifyListeners();
    }
  }

  Future<void> saveUserDataJson({
    required String baseUrl,
    required String username,
    required String email,
    required String password,
  }) async {
    if (_username.isEmpty) {
      _errorMessage = 'Username is required';
      notifyListeners();
      return;
    }

    _isLoadingUpload = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      String url;
      http.Response response;

      if (_editingItem == null) {
        // ➕ Insert new user
        url = '$baseUrl/save-user-data';
        print('🚀 Sending JSON INSERT request to: $url');

        response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'name': username, 'email': email, 'password': password}),
        );
      } else {
        // ✏️ Update existing user
        url = '$baseUrl/update-user-data/${_editingItem!.id}';
        print('🚀 Sending JSON UPDATE request to: $url');

        response = await http.put(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'name': username, 'email': email, 'password': password}),
        );
      }

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          print('✅ Success! Response data: $responseData');

          final action = _editingItem == null ? 'Insert' : 'Update';
          _successMessage = '$action successful for: $_username!';
          _editingItem = null;
          _fetchUserImages(baseUrl: baseUrl);
        } catch (e) {
          print('⚠️ JSON parse error: $e');
          _successMessage = 'Operation successful (no JSON response).';
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          _errorMessage = 'Failed: ${errorData['message'] ?? 'Unknown error'}';
        } catch (e) {
          _errorMessage =
              'Failed: HTTP ${response.statusCode} - ${response.body}';
        }
        print('❌ $_errorMessage');
      }
    } catch (e) {
      print('💥 Exception: $e');
      _errorMessage = 'Network error: $e';
    } finally {
      _isLoadingUpload = false;
      notifyListeners();
      print('🏁 JSON upload process completed');
    }
  }

  Future<void> saveUserPutDataJson({
    required String baseUrl,
    required String username,
    required String email,
    required String password,
  }) async {
    if (_username.isEmpty) {
      _errorMessage = 'Username is required';
      notifyListeners();
      return;
    }

    _isLoadingUpload = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      String url;
      http.Response response;

      if (_editingItem == null) {
        // ➕ Insert new user - POST
        url = '$baseUrl/save-user-data';
        print('🚀 Sending JSON INSERT request to: $url');

        response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'name': username, 'email': email, 'password': password}),
        );
      } else {
        // ✏️ Update existing user - PUT
        url =
            '$baseUrl/update-user-data/${_editingItem!.id}'; // Changed endpoint name
        print('🚀 Sending JSON UPDATE request to: $url');

        response = await http.put(
          // Using PUT method
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'name': username, 'email': email, 'password': password}),
        );
      }

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          print('✅ Success! Response data: $responseData');

          final action = _editingItem == null ? 'Insert' : 'Update';
          _successMessage = '$action successful for: $username!';
          _editingItem = null;
          _fetchUserImages(baseUrl: baseUrl);
        } catch (e) {
          print('⚠️ JSON parse error: $e');
          _successMessage = 'Operation successful (no JSON response).';
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          _errorMessage = 'Failed: ${errorData['message'] ?? 'Unknown error'}';
        } catch (e) {
          _errorMessage =
              'Failed: HTTP ${response.statusCode} - ${response.body}';
        }
        print('❌ $_errorMessage');
      }
    } catch (e) {
      print('💥 Exception: $e');
      _errorMessage = 'Network error: $e';
    } finally {
      _isLoadingUpload = false;
      notifyListeners();
      print('🏁 JSON upload process completed');
    }
  }

Future<void> updateUserProfile({
  required String baseUrl,
    required String fieldName,
    String? fileName,
    String usernameFieldName = 'name',
    String email = 'email',
    String password = 'password',
}) async {
//   var uri = Uri.parse('$baseUrl/update-user-data/${_editingItem!.id}');
//    final hasImage = _selectedImage != null;

//   var request = http.MultipartRequest('PUT', uri);

//   // Add text fields
//   request.fields['username'] = username;

//   // Add image file (optional)
//  if (hasImage) {
//         print('📁 Adding image file:');
//         print('   - Path: ${_selectedImage!.path}');

//         request.files.add(
//           await http.MultipartFile.fromPath(
//             fieldName,
//             _selectedImage!.path,
//             filename:
//                 fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg',
//           ),
//         );
//         print('✅ Image file added to request');
//       }

  

//   // Send the request
//   var response = await request.send();

//   if (response.statusCode == 200) {
//     print('✅ Profile updated successfully');
//     var responseBody = await response.stream.bytesToString();
//     print(responseBody);
//   } else {
//     print('❌ Failed to update profile. Status: ${response.statusCode}');
//   }


try {
   print('✅ Image file added to request');
    Dio dio = Dio();

    final hasImage = selectedImage != null;

    // Create FormData
    FormData formData = FormData.fromMap({
      'name': usernameFieldName,
      'email': email,
      // 'password': password,
      if (hasImage)
        fieldName: await MultipartFile.fromFile(
          selectedImage!.path,
          filename: fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
    });

    //print('🚀 Sending PUT request to: '$baseUrl/update-user-data/${_editingItem!.id}');
    if (hasImage) {
      print('📁 Including image: ${selectedImage!.path}');
    }

    // Send PUT request
    final response = await dio.put(
      '$baseUrl/update-user-data/${_editingItem!.id}',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
          // 'Authorization': 'Bearer YOUR_TOKEN',  // optional if API secured
        },
      ),
      onSendProgress: (sent, total) {
        if (total != -1) {
          print('📤 Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        }
      },
    );

    // Handle response
    if (response.statusCode == 200) {
      print('✅ Profile updated successfully');
      print(response.data);
    } else {
      print('❌ Failed to update profile. Status: ${response.statusCode}');
    }
  } catch (e) {
    print('⚠️ Error while updating profile: $e');
  }











}











  Future<void> saveAuthorizationToken({
    required String baseUrl,
    required String username,
    required String email,
    required String password,
    String? token, // 👈 Optional: pass token from caller
  }) async {
    if (_username.isEmpty) {
      _errorMessage = 'Username is required';
      notifyListeners();
      return;
    }
// final prefs = await SharedPreferences.getInstance();
//   final token = prefs.getString('auth_token'); // ✅ get token
    _isLoadingUpload = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      String url;
      http.Response response;

      // ✅ Common headers (with or without token)
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token', // 👈 Add token here
      };

      if (_editingItem == null) {
        // ➕ Insert new user
        url = '$baseUrl/save-user-data';
        print('🚀 Sending JSON INSERT request to: $url');

        response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({
            'name': username,
            'email': email,
            'password': password,
          }),
        );
      } else {
        // ✏️ Update existing user
        url = '$baseUrl/update-user-data/${_editingItem!.id}';
        print('🚀 Sending JSON UPDATE request to: $url');

        response = await http.put(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({
            'name': username,
            'email': email,
            'password': password,
          }),
        );
      }

      print('📥 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('✅ Success! Response data: $responseData');

        final action = _editingItem == null ? 'Insert' : 'Update';
        _successMessage = '$action successful for: $_username!';
        _editingItem = null;
        _fetchUserImages(baseUrl: baseUrl);
      } else {
        try {
          final errorData = json.decode(response.body);
          _errorMessage = 'Failed: ${errorData['message'] ?? 'Unknown error'}';
        } catch (e) {
          _errorMessage =
              'Failed: HTTP ${response.statusCode} - ${response.body}';
        }
        print('❌ $_errorMessage');
      }
    } catch (e) {
      print('💥 Exception: $e');
      _errorMessage = 'Network error: $e';
    } finally {
      _isLoadingUpload = false;
      notifyListeners();
      print('🏁 JSON upload process completed');
    }
  }

  // Future<void> _fetchUserImages({required String baseUrl}) async {
  //   final url = '$baseUrl/get-user-test';
  //   _isLoadingList = true;
  //   _errorMessage = null;
  //   print('🔄 Fetching user images from: $url');
  //   notifyListeners();

  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     print('📥 Fetch response:');
  //     print('   - Status: ${response.statusCode}');
  //     print('   - Body length: ${response.body.length}');
  //     print('   - Raw body: ${response.body}');

  //     if (response.statusCode == 200) {
  //       try {
  //         final List<dynamic> data = json.decode(response.body);
  //         print('✅ Fetched ${data.length} user images');
  //         _userImages = data.map((json) => UserImage.fromJson(json)).toList();
  //         print('✅ User images list updated');
  //       } catch (e) {
  //         print('❌ JSON parse error in fetch: $e');
  //         _errorMessage = 'Data format error: $e';
  //       }
  //     } else {
  //       _errorMessage = 'Failed to fetch list: ${response}';
  //       print('❌ Fetch failed: $_errorMessage');
  //     }
  //   } catch (e) {
  //     _errorMessage = 'Error fetching list: $e';
  //     print('💥 Fetch exception: $_errorMessage');
  //   } finally {
  //     _isLoadingList = false;
  //     notifyListeners();
  //     print('🏁 Fetch process completed');
  //   }
  // }

  // Future<void> _fetchUserImages({required String baseUrl}) async {
  //   final url = '$baseUrl/get-user-test';
  //   _isLoadingList = true;
  //   _errorMessage = null;
  //   print('🔄 Fetching user images from: $url');
  //   notifyListeners();

  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     print('📥 Fetch response:');
  //     print('   - Status: ${response.statusCode}');
  //     print('   - Body length: ${response.body.length}');
  //     print('   - Raw body: ${response.body}');

  //     if (response.statusCode == 200) {
  //       try {
  //         final Map<String, dynamic> responseData = json.decode(response.body);
  //         print('✅ API Response: $responseData');

  //         // Extract the users array from the response
  //         if (responseData.containsKey('users') &&
  //             responseData['users'] is List) {
  //           final List<dynamic> usersData = responseData['users'];
  //           print('✅ Found ${usersData.length} user images');

  //           _userImages = usersData
  //               .map((userJson) => UserImage.fromJson(userJson))
  //               .toList();
  //           print(
  //               '✅ User images list updated with ${_userImages.length} items');
  //         } else {
  //           print('❌ No "users" array found in response');
  //           _errorMessage = 'No user data found in response';
  //         }
  //       } catch (e) {
  //         print('❌ JSON parse error in fetch: $e');
  //         _errorMessage = 'Data format error: $e';
  //       }
  //     } else {
  //       _errorMessage = 'Failed to fetch list: ${response.statusCode}';
  //       print('❌ Fetch failed: $_errorMessage');
  //     }
  //   } catch (e) {
  //     _errorMessage = 'Error fetching list: $e';
  //     print('💥 Fetch exception: $_errorMessage');
  //   } finally {
  //     _isLoadingList = false;
  //     notifyListeners();
  //     print('🏁 Fetch process completed');
  //   }
  // }



Future<void> createUser() async {
  final dio = Dio();

  final url = 'https://jsonplaceholder.typicode.com/posts'; 

  
  final data = {
    'title': 'Flutter Post Example',
    'body': 'This is a POST request using Dio!',
    'userId': 1,
  };

  try {
    final response = await dio.post(url, data: data);

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✅ Success: ${response.data}');
    } else {
      print('⚠️ Failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}


Future<void> deleteWithHeaders(int id) async {
  final dio = Dio();

  const baseUrl = 'https://api.example.com/users';

  try {
    final response = await dio.delete(
      '$baseUrl/$id',
      options: Options(
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
          'Accept': 'application/json',
        },
      ),
    );

    print('✅ Deleted: ${response.statusCode}');
  } catch (e) {
    print('❌ Error: $e');
  }
}


Future<void> sendPostWithHeaders() async {
  final dio = Dio();

  const url = 'https://jsonplaceholder.typicode.com/posts';

  final data = {
    'title': 'Flutter Dio Example',
    'body': 'This is a POST request with headers!',
    'userId': 123,
  };

  try {
    final response = await dio.post(
      url,
      data: data,
      options: Options(
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
          'Content-Type': 'application/json',
          'Custom-Header': 'FlutterDioDemo',
        },
      ),
    );

    print('✅ Response: ${response.data}');
  } catch (e) {
    print('❌ Error: $e');
  }
}








  Future<void> _fetchUserImages({required String baseUrl}) async {
  final url = '$baseUrl/get-user-test';
  _isLoadingList = true;
  _errorMessage = null;
  print('🔄 Fetching user images from: $url');
  notifyListeners();

  try {
    final response = await Dio().get(url);
    print('📥 Fetch response:');
    print('   - Status: ${response.statusCode}');
    print('   - Data type: ${response.data.runtimeType}');
    print('   - Raw data: ${response.data}');

    if (response.statusCode == 200) {
      try {
        final responseData = response.data;
        print('✅ API Response: $responseData');

        // Extract the users array from the response
        if (responseData.containsKey('users') &&
            responseData['users'] is List) {
          final List<dynamic> usersData = responseData['users'];
          print('✅ Found ${usersData.length} user images');

          _userImages = usersData
              .map((userJson) => UserImage.fromJson(userJson))
              .toList();
          print(
              '✅ User images list updated with ${_userImages.length} items');
        } else {
          print('❌ No "users" array found in response');
          _errorMessage = 'No user data found in response';
        }
      } catch (e) {
        print('❌ Data processing error in fetch: $e');
        _errorMessage = 'Data format error: $e';
      }
    } else {
      _errorMessage = 'Failed to fetch list: ${response.statusCode}';
      print('❌ Fetch failed: $_errorMessage');
    }
  } on DioException catch (e) {
    // Dio specific error handling
    if (e.response != null) {
      // Server responded with error status code
      _errorMessage = 'Server error: ${e.response?.statusCode}';
      print('❌ Dio response error: ${e.response?.statusCode} - ${e.response?.data}');
    } else {
      // Something else happened (network, timeout, etc.)
      _errorMessage = 'Network error: ${e.message}';
      print('💥 Dio exception: ${e.message}');
    }
  } catch (e) {
    _errorMessage = 'Unexpected error: $e';
    print('💥 General exception: $_errorMessage');
  } finally {
    _isLoadingList = false;
    notifyListeners();
    print('🏁 Fetch process completed');
  }
}

// Future<void> _fetchUserImages({required String baseUrl}) async {
//   final url = 'https://randomuser.me/api/?results=10'; // fetch 10 users
//   _isLoadingList = true;
//   _errorMessage = null;
//   print('🔄 Fetching user images from: $url');
//   notifyListeners();

//   try {
//     final response = await http.get(Uri.parse(url));
//     print('📥 Fetch response: ${response.statusCode}');

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> jsonBody = json.decode(response.body);
//       final randomUserResponse = RandomUserResponse.fromJson(jsonBody);

//       // Convert RandomUser → UserImage (for your UI list)
//       _userImages = randomUserResponse.results
//           .map(
//             (user) => UserImage(
//               id: user.email, // use email as unique id
//               username: user.name,
//               imageUrl: user.imageUrl,
//             ),
//           )
//           .toList();

//       print('✅ Loaded ${_userImages.length} users successfully');
//     } else {
//       _errorMessage = 'Failed to fetch list: HTTP ${response.statusCode}';
//       print('❌ $_errorMessage');
//     }
//   } catch (e) {
//     _errorMessage = 'Error fetching list: $e';
//     print('💥 $_errorMessage');
//   } finally {
//     _isLoadingList = false;
//     notifyListeners();
//     print('🏁 Fetch process completed');
//   }
// }

  void fetchUserImages({required String baseUrl}) {
    _fetchUserImages(baseUrl: baseUrl);
  }

  Future<void> deleteItem(String id, {required String baseUrl}) async {
    _isLoadingUpload = true;
    _errorMessage = null;
    print('🗑️ Deleting item $id from: $baseUrl');
    notifyListeners();

    try {
      final response = await http.delete(Uri.parse('$baseUrl/user-images/$id'));
      print('📥 Delete response:');
      print('   - Status: ${response.statusCode}');
      print('   - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _successMessage = 'Delete successful!';
        print('✅ Delete successful');
        _fetchUserImages(baseUrl: baseUrl);
      } else {
        _errorMessage = 'Delete failed: ${response.statusCode}';
        print('❌ Delete failed: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Error deleting: $e';
      print('💥 Delete exception: $_errorMessage');
    } finally {
      _isLoadingUpload = false;
      notifyListeners();
    }
  }
}
