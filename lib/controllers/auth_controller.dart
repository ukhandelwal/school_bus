import 'package:get/get.dart';
import 'package:flutter/material.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var rememberMe = false.obs;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter both email and password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.black,
      );
      return;
    }

    isLoading.value = true;

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Mock login logic
    if (emailController.text == 'driver@example.com' && passwordController.text == 'password') {
      isLoading.value = false;
      Get.offAllNamed('/'); // Navigate to home screen
      Get.snackbar(
        'Success',
        'Logged in successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.black,
      );
    } else {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Invalid email or password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.black,
      );
    }
  }

  void navigateToForgotPassword() {
    // Implement forgot password navigation
    Get.snackbar(
      'Info',
      'Forgot password feature coming soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void navigateToSignUp() {
    // Implement sign up navigation
    Get.snackbar(
      'Info',
      'Sign up feature coming soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}