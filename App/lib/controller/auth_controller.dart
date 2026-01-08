import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobile_project/models/user.dart';
import 'package:mobile_project/service/socket_service.dart';
import 'package:mobile_project/view/account_screen.dart';
import '../service/auth_service.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();
  final RxBool _isFirstTime = true.obs;
  final RxBool _isLoggedIn = false.obs;

  var isLoading = true.obs;

  final AuthService _authService = AuthService();

  final user = Rx<User?>(null);
  var error = RxnString();

  bool get isFirstTime => _isFirstTime.value;
  bool get isLoggedIn => _isLoggedIn.value;

  final SocketService _socketService = Get.find<SocketService>();

  String get token => _storage.read('token') ?? '';


  @override
  void onInit(){
    super.onInit();
    _loadInitialState();
    fetchUserInfo();
  }

  void _loadInitialState(){
    _isFirstTime.value = _storage.read('isFirstTime')?? true;
    _isLoggedIn.value = _storage.read('isLoggedIn')?? false ;

    final savedUser = _storage.read('user');
    if (savedUser != null) {
      user.value = User.fromJson(savedUser);
    }
  }

  void setFirstTimeDone(){
    _isFirstTime.value = false;
    _storage.write('isFirstTime', false);
  }

  // ---- Login ----
  Future<bool> login(String username, String password) async {
    final result = await _authService.login(username, password);

    if (result != null && result['access_token'] != null) {
      final userJson = result['user'];

      _isLoggedIn.value = true;
      _storage.write('isLoggedIn', true);

      // luu token
      _storage.write('token', result['access_token']);

      // luu user
      if (userJson != null) {
        final loggedInUser = User.fromJson(userJson);
        user.value = loggedInUser;
        _storage.write('user', userJson);

        _socketService.connect(token);
      }
      return true;
    }

    return false;
  }

// --- Register ---
  Future<bool> register(String username, String password, String email) async {
    final result = await _authService.register(username, password, email);

    if (result != null ) {
      return true;
    }

    return false;
  }


  void logout() {
    _isLoggedIn.value = false;
    _storage.write('isLoggedIn', false);
    _storage.remove('token');
    _storage.remove('user');
    _socketService.disconnect();

  }

  Future<void> fetchUserInfo() async {
    try {
      isLoading(true);

      final result = await _authService.getUserInfo(token);

      if (result != null) {
        user.value = result;
        user.refresh();
      } else {
        error.value = "Không tải được thông tin người dùng";
      }
    } finally {
      isLoading(false);
    }
  }

  // ---- Update Profile ----
  Future<bool> updateProfile(String? name, String? email, String? phone) async {
    try {
      isLoading.value = true;

      // Gọi API
      final response = await _authService.updateProfile(
        name,
        email,
        phone,
        token,
      );

      // Nếu response khác null → thành công
      if (response != null) {
        // Cập nhật user local nếu backend trả về user mới
        if (response['user'] != null) {
          final newUser = User.fromJson(response['user']);
          user.value = newUser;
          await _storage.write('user', response['user']);
          user.refresh(); // <-- Quan trọng: ép rebuild ngay lập tức
        }


        // Thông báo thành công
        Get.snackbar(
          "Success",
          "Đã cập nhật profile",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        if (Get.isOverlaysClosed == false) {
          Get.back();
        }


        return true;
      } else {
        // API trả về null
        Get.snackbar(
          "Error",
          "Update failed. Please try again.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      // Bắt lỗi 400, 409 hoặc lỗi khác
      Get.snackbar(
        "Error",
        e.toString().replaceAll("Exception: ", ""),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // change password
  Future<bool> changePassword(
      String oldPassword,
      String newPassword,
      ) async {
    try {
      isLoading.value = true;

      final token = GetStorage().read('token'); // đảm bảo lấy token
      if (token == null) {
        return false; // không có token → thất bại
      }

      final response = await _authService.changePassword(
        oldPassword,
        newPassword,
        token,
      );

      if (response != null) {
        // có thể xử lý message nếu cần
        return true; // đổi mật khẩu thành công
      } else {
        return false; // API trả null → thất bại
      }
    } catch (e) {
      return false; // lỗi ngoại lệ → thất bại
    } finally {
      isLoading.value = false;
    }
  }


}