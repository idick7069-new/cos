
import '../models/user_profile.dart';

class UserProfileState {
    final UserProfile? userProfile;
    final bool isLoading;
    final String? error;

    UserProfileState({this.userProfile, this.isLoading = false, this.error});

    // 工廠方法
    factory UserProfileState.loading() => UserProfileState(isLoading: true);
    factory UserProfileState.success(UserProfile userProfile) =>
    UserProfileState(userProfile: userProfile);
    factory UserProfileState.error(String error) =>
    UserProfileState(error: error);
}
