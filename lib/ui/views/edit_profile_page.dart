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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cos_connect/data/models/user_profile.dart';
import 'package:cos_connect/data/provider/user_profile_notifier.dart';

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

  final List<String> _allRegions = ["北部", "中部", "南部", "東部"];

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

              /// 坑單選擇
              Text("坑單", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _selectedPits.isEmpty
                  ? Text("尚未加入坑單", style: TextStyle(color: Colors.grey))
                  : Wrap(
                spacing: 8,
                children: _selectedPits.map((pit) {
                  return Chip(
                    label: Text(pit),
                    onDeleted: () {
                      setState(() => _selectedPits.remove(pit));
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pitController,
                      decoration: InputDecoration(labelText: "新增坑單"),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addPit,
                    child: Text("新增"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              /// 地區選擇
              Text("選擇地區", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _allRegions.map((region) {
                  final isSelected = _selectedRegions.contains(region);
                  return ChoiceChip(
                    label: Text(region),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRegions.add(region);
                        } else {
                          _selectedRegions.remove(region);
                        }
                      });
                    },
                    selectedColor: Colors.blueAccent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _saveUserProfile, // 儲存資料
                  child: Text("儲存"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
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
      gender: _selectedGender,
      cn: _cnController.text,
      bio: _bioController.text,
      pits: _selectedPits,
      regions: _selectedRegions,
      coverPhotoUrl: '',
    );

    try {
      await ref
          .read(userProfileProvider.notifier)
          .updateUserProfile(updatedUserProfile);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("資料儲存成功！")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("儲存失敗，請稍後再試")));
    }
  }
}

