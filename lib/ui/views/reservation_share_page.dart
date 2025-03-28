import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/reservation.dart';
import '../../data/models/event.dart';
import '../../data/provider/events_notifier.dart';
import '../../data/provider/share_page_provider.dart';
import 'model/event_view_model.dart';

class ReservationSharePage extends ConsumerWidget {
  final List<EventViewModel>? eventViewModels;
  final List<Reservation>? reservations;
  final ScreenshotController _screenshotController = ScreenshotController();
  final ImagePicker _picker = ImagePicker();
  bool _isInitialized = false;

  ReservationSharePage({
    Key? key,
    this.eventViewModels,
    this.reservations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 只在第一次構建時初始化數據
    if (!_isInitialized &&
        eventViewModels != null &&
        eventViewModels!.isNotEmpty) {
      _isInitialized = true;
      final firstEvent = eventViewModels!.first;
      final reservation = reservations?.firstWhere(
        (r) => r.eventId == firstEvent.event.id,
        orElse: () => Reservation(
          id: '',
          eventId: firstEvent.event.id,
          userId: '',
          identity: IdentityType.coser,
          createdAt: DateTime.now(),
        ),
      );

      // 使用 ref 初始化 provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(sharePageProvider.notifier).initializeWithEvent(
              firstEvent.event,
              reservation,
            );
      });
    }

    final state = ref.watch(sharePageProvider);
    final firstEvent = eventViewModels?.first;

    return Scaffold(
      appBar: AppBar(
        title: Text('分享預定'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareImage(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Screenshot(
            controller: _screenshotController,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 活動 Logo
                  if (firstEvent?.event.image != null)
                    Container(
                      height: 80,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: firstEvent!.event.image,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(Icons.error),
                        ),
                      ),
                    ),

                  SizedBox(height: 16),

                  // 活動地點
                  Text(
                    '活動地點',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    onChanged: (value) =>
                        ref.read(sharePageProvider.notifier).setLocation(value),
                    controller: TextEditingController(text: state.location),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // 身份選擇
                  Text(
                    '身份',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<IdentityType>(
                    value: state.identity,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: IdentityType.values.map((identity) {
                      return DropdownMenuItem(
                        value: identity,
                        child: Text(_getIdentityText(identity)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(sharePageProvider.notifier).setIdentity(value);
                      }
                    },
                  ),

                  SizedBox(height: 16),

                  // 名稱 (CN)
                  Text(
                    '名稱 (CN)',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    onChanged: (value) =>
                        ref.read(sharePageProvider.notifier).setName(value),
                    controller: TextEditingController(text: state.name),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // 備註
                  Text(
                    '備註',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    onChanged: (value) =>
                        ref.read(sharePageProvider.notifier).setNote(value),
                    controller: TextEditingController(text: state.note),
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),

                  SizedBox(height: 16),

                  // 照片上傳區域
                  _buildPhotoUploadGrid(state, ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(WidgetRef ref, int day) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        ref.read(sharePageProvider.notifier).setPhoto(day, File(image.path));
      }
    } catch (e) {
      print("error: $e");
      // 錯誤處理將在 build 方法中處理
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    try {
      final imageFile = await _screenshotController.capture();
      if (imageFile == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_image.png');
      await file.writeAsBytes(imageFile);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '我的預定',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失敗：$e')),
      );
    }
  }

  Widget _buildPhotoUploadGrid(SharePageState state, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: state.photos.length,
      itemBuilder: (context, index) {
        final photo = state.photos[index];
        return InkWell(
          onTap: () => _pickImage(ref, index),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      photo,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 32, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        '第 ${index + 1} 天\n點擊上傳照片',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  String _getIdentityText(IdentityType identity) {
    switch (identity) {
      case IdentityType.manager:
        return '馬內';
      case IdentityType.photographer:
        return '攝影師';
      case IdentityType.coser:
        return 'Coser';
      case IdentityType.original:
        return '原創';
    }
  }
}
