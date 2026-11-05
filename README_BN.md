# PrimeTV (Flutter source)

এই প্রজেক্টটি Android মোবাইল এবং Android TV/Google TV-এর জন্য তৈরি করা Flutter IPTV player starter project।

## ফিচার
- দেওয়া GitHub M3U playlist থেকে চ্যানেল লোড
- M3U channel name, group-title ও tvg-logo পড়া
- ক্যাটাগরি ও চ্যানেল সার্চ
- Favorite channel সংরক্ষণ
- HLS `.m3u8` stream playback
- Android TV remote-এর Left/Right দিয়ে আগের/পরের চ্যানেল
- মোবাইলে touch interface

## APK তৈরি
1. কম্পিউটারে Flutter SDK এবং Android Studio ইনস্টল করুন।
2. এই ফোল্ডারে টার্মিনাল খুলুন।
3. চালান:
   ```bash
   flutter pub get
   flutter create . --platforms=android
   flutter run
   ```
4. APK:
   ```bash
   flutter build apk --release
   ```
   ফাইল পাবেন `build/app/outputs/flutter-apk/app-release.apk`-এ।

## গুরুত্বপূর্ণ Android TV নোট
Android TV-তে Play Store/launcher banner দেখাতে `android/app/src/main/res/drawable/tv_banner.png` যোগ করুন। Manifest-এ `@drawable/tv_banner` রেফারেন্স রাখা হয়েছে। চাইলে banner লাইনটি সরিয়েও build করতে পারবেন।
Flutter-এর তৈরি `MainActivity` ফাইল ও Android Gradle সেটআপ `flutter create .` দিয়ে তৈরি হবে।

## Playlist
অ্যাপটি চালুর সময় এই ঠিকানা থেকে playlist নেয়:
`https://raw.githubusercontent.com/ashik4u/mrgify-clean/refs/heads/main/playlist.m3u`

Playlist-এর সব stream যে সবসময় কাজ করবে তার নিশ্চয়তা নেই। কিছু stream URL মেয়াদযুক্ত হতে পারে। শুধু আপনার ব্যবহারের অধিকার আছে এমন stream ব্যবহার করুন।
