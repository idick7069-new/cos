import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/data/models/user_profile.dart';
import 'package:cos_connect/data/provider/firebase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/data/models/user_profile.dart';
import 'package:cos_connect/data/provider/firebase_provider.dart';

import '../../data/provider/user_profile_notifier.dart';

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
  void initState() {
    super.initState();
    final userProfile =
        ref.read(userProfileProvider.notifier).getCurrentUserProfile();
    if (userProfile != null) {
      _selectedGender = userProfile.gender;
      _cnController.text = userProfile.cn ?? '';
      _bioController.text = userProfile.bio ?? '';
      _selectedPits = List.from(userProfile.pits ?? []);
      _selectedRegions = List.from(userProfile.regions ?? []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("編輯資料")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(labelText: "性別"),
                items: ["male", "female", "other"].map((gender) {
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

  void _saveUserProfile() async {
    final updatedUserProfile = UserProfile(
      gender: _selectedGender, // 使用選擇的性別
      cn: _cnController.text,
      bio: _bioController.text,
      pits: _selectedPits,
      regions: _selectedRegions,
      coverPhotoUrl: '', // 如果有封面照片欄位，可以在這裡處理
    );

    try {
      // 呼叫 updateUserProfile 來更新資料並儲存到 Firestore
      await ref
          .read(userProfileProvider.notifier)
          .updateUserProfile(updatedUserProfile);

      // 更新暫存資料後顯示成功訊息
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("資料儲存成功！")));

      // 成功後返回到 Profile 頁面，UI 會自動更新
      Navigator.pop(context);
    } catch (e) {
      // 儲存失敗時顯示錯誤訊息
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("儲存失敗，請稍後再試")));
    }
  }


// ** 儲存資料到 Firestore **
// void _saveUserProfile() async {
//   final firebaseService = ref.read(firebaseServiceProvider);
//   final currentUser = ref.read(userProfileProvider).value;
//   if (currentUser == null) return;
//
//   final updatedUserProfile = currentUser.copyWith(
//     gender: _selectedGender,
//     cn: _cnController.text,
//     bio: _bioController.text,
//     pits: _selectedPits,
//     regions: _selectedRegions,
//   );
//
//   try {
//     await ref.read(userProfileNotifierProvider.notifier).updateUserProfile(updatedUserProfile);
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text("資料儲存成功！")));
//     Navigator.pop(context); // ✅ 返回 ProfilePage，UI 會自動更新
//   } catch (e) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text("儲存失敗，請稍後再試")));
//   }
// }
}
