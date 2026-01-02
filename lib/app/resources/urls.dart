class AppUrls{

  static const baseUrl = 'https://paharerdak.com';
  static const configUri = '/api/v1/config/list';
  static const loginUri = '/api/v1/auth/login';
  static const registrationUri = '/api/v1/auth/registration';
  static const deleteAccountUri = '/api/v1/profile/delete';
  static const otpVerifyUri = '/api/v1/auth/otp-verify';
  static const forgetPassRequestUri = '/api/v1/forget-password/reset-request';
  static const forgetPassOtpVerifyUri = '/api/v1/forget-password/otp-verify';
  static const forgetPassChangePassUri = '/api/v1/forget-password/change-password';
  static const locationUri = '/api/v1/location/list';
  static const logoutUri = '/api/v1/auth/logout';
  static const categoryUri = '/api/v1/category/list';
  static const profileUri = '/api/v1/profile/info';
  static const updateProfileUri = '/api/v1/profile/update-info';
  static const changePasswordUri = '/api/v1/profile/update-password';
  static const postCreateUri = '/api/v1/post/add';
  static const postListUri = '/api/v1/post/all-list';
  static const ownPostListUri = '/api/v1/post/list';
  static const addFavouriteUri = '/api/v1/post/add-favorite';
  static const favouriteListUri = '/api/v1/post/favorite-post-list';
  static const removeFavouriteUri = '/api/v1/post/remove-favorite';
  static const reviewListUri = '/api/v1/review-post/list';
  static const reviewSubmitUri = '/api/v1/review-post/add';
  static const reviewUpdateUri = '/api/v1/review-post/update'; /// need to implement..
  static const reviewDeleteUri = '/api/v1/review-post/delete';
  static const postDetailsUri = '/api/v1/post/details';
  static const postDeleteUri = '/api/v1/post/delete';
  static const chatListUri = '/api/v1/chat/list';
  static const chatDetailsUri = '/api/v1/chat/details';
  static const chatSendMessageUri = '/api/v1/chat/add';
  static const changeLanguageUri = '/api/v1/profile/change-language';
  static const deviceTokenUpdateUri = '/api/v1/profile/update-device-token';
  static const updateIdentityUri = '/api/v1/user-identity/update';
  static const getIdentityUri = '/api/v1/user-identity/get-identity';
  static const notificationListUri = '/api/v1/notification/list';


  ///App keys
  static const String token = 'user_token';
  static const String uuId = 'uuId';
  static const String seenIntro = 'intro';
}