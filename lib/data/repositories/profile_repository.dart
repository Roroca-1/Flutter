import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../providers.dart';

/// 当前账号资料；未登录时保持 `null`。
class ProfileController extends AsyncNotifier<UserProfile?> {
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Future<UserProfile?> build() async {
    // 只看登录与否，token 刷新途中的 refreshing 快照不该把资料拆掉重拉。
    final authenticated = ref.watch(
      authSnapshotProvider.select((snapshot) => snapshot.isAuthenticated),
    );
    if (!authenticated) return null;
    var profile = await _api.getMyProfile();
    if (!profile.growth.signedToday) {
      try {
        await _api.checkIn();
        profile = await _api.getMyProfile();
      } catch (_) {
        // 自动签到不能阻止应用启动；网络恢复后下次重建资料时会再尝试。
      }
    }
    return profile;
  }

  Future<void> reload() async {
    state = const AsyncValue<UserProfile?>.loading();
    state = await AsyncValue.guard(() async {
      if (!ref.read(authSnapshotProvider).isAuthenticated) return null;
      return _api.getMyProfile();
    });
  }

  Future<DailyCheckInResult> checkIn() async {
    final result = await _api.checkIn();
    await reload();
    return result;
  }

  Future<void> setAvatar(String url) async {
    await _api.setAvatar(url);
    await reload();
  }
}

final AsyncNotifierProvider<ProfileController, UserProfile?> profileProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(
      ProfileController.new,
    );
