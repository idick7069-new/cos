import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/data/models/user_profile.dart';
import 'package:cos_connect/data/provider/firebase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/data/models/user_profile.dart';
import 'package:cos_connect/data/provider/firebase_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  String? _selectedGender;
  final TextEditingController _cnController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _pitController = TextEditingController();
  List<String> _selectedPits = [];
  List<String> _selectedRegions = [];

  @override
  void dispose() {
    _cnController.dispose();
    _bioController.dispose();
    _pitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text("編輯資料")),
      body: userProfileAsync.when(
        data: (userProfile) {
          if (userProfile == null) return Center(child: Text("找不到使用者資料"));

          // 初始化 UI 欄位
          _selectedGender ??= userProfile.gender;
          _cnController.text = userProfile.cn ?? '';
          _bioController.text = userProfile.bio ?? '';
          _selectedPits = List.from(userProfile.pits ?? []);
          _selectedRegions = List.from(userProfile.regions ?? []);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(labelText: "性別"),
                    items: ["男", "女", "其他"].map((gender) {
                      return DropdownMenuItem(value: gender, child: Text(gender));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedGender = value),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _cnController,
                    decoration: InputDecoration(labelText: "CN (名稱)"),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    decoration: InputDecoration(labelText: "自我介紹"),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Text("坑單"),
                  Wrap(
                    children: _selectedPits.map((pit) {
                      return Chip(
                        label: Text(pit),
                        onDeleted: () {
                          setState(() => _selectedPits.remove(pit));
                        },
                      );
                    }).toList(),
                  ),
                  TextFormField(
                    controller: _pitController,
                    decoration: InputDecoration(labelText: "新增坑單"),
                    onFieldSubmitted: (_) => _addPit(),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveUserProfile, // 儲存資料
                    child: Text("儲存"),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('錯誤: $error')),
      ),
    );
  }

  void _addPit() {
    if (_pitController.text.isNotEmpty) {
      setState(() {
        _selectedPits.add(_pitController.text);
        _pitController.clear();
      });
    }
  }

  // ** 儲存資料到 Firestore **
  void _saveUserProfile() async {
    final firebaseService = ref.read(firebaseServiceProvider);
    final currentUser = ref.read(userProfileProvider).value;
    if (currentUser == null) return;

    final updatedUserProfile = currentUser.copyWith(
      gender: _selectedGender,
      cn: _cnController.text,
      bio: _bioController.text,
      pits: _selectedPits,
      regions: _selectedRegions,
    );

    try {
      await ref.read(userProfileNotifierProvider.notifier).updateUserProfile(updatedUserProfile);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("資料儲存成功！")));
      Navigator.pop(context); // ✅ 返回 ProfilePage，UI 會自動更新
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("儲存失敗，請稍後再試")));
    }
  }
}
