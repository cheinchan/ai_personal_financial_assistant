// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Replace with your actual values from google-services.json
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'your-web-api-key',
    appId: 'your-web-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-project-id',
    authDomain: 'your-project-id.firebaseapp.com',
    storageBucket: 'your-project-id.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBd21Od9iUWa3mIy7Jhtf4wa_oXZmX0X8k',              // From google-services.json: client[0].api_key[0].current_key
    appId: '1:145718227216:android:54b5ad7b06cbc1a3f07595',                // From google-services.json: client[0].client_info.mobilesdk_app_id
    messagingSenderId: '145718227216', // From google-services.json: project_info.project_number
    projectId: 'ai-financial-assistant-2',        // From google-services.json: project_info.project_id
    storageBucket: 'ai-financial-assistant-2.firebasestorage.app',        // From google-services.json: project_info.storage_bucket
  );
}


// {
//   "project_info": {
//     "project_number": "145718227216",
//     "project_id": "ai-financial-assistant-2",
//     "storage_bucket": "ai-financial-assistant-2.firebasestorage.app"
//   },
//   "client": [
//     {
//       "client_info": {
//         "mobilesdk_app_id": "1:145718227216:android:54b5ad7b06cbc1a3f07595",
//         "android_client_info": {
//           "package_name": "com.example.ai_personal_financial_assistant"
//         }
//       },
//       "oauth_client": [],
//       "api_key": [
//         {
//           "current_key": "AIzaSyBd21Od9iUWa3mIy7Jhtf4wa_oXZmX0X8k"
//         }
//       ],
//       "services": {
//         "appinvite_service": {
//           "other_platform_oauth_client": []
//         }
//       }
//     }
//   ],
//   "configuration_version": "1"
// }


// {
//   "project_info": {
//     "project_number": "1047927650769",
//     "project_id": "aipersonalfinancialassistant",
//     "storage_bucket": "aipersonalfinancialassistant.firebasestorage.app"
//   },
//   "client": [
//     {
//       "client_info": {
//         "mobilesdk_app_id": "1:1047927650769:android:1f502f875a0ad4164f08f0",
//         "android_client_info": {
//           "package_name": "com.example.ai_personal_financial_assistant"
//         }
//       },
//       "oauth_client": [],
//       "api_key": [
//         {
//           "current_key": "AIzaSyBGE01FTHzNcX8M0j0z0QXgUB6ISRgiOOo"
//         }
//       ],
//       "services": {
//         "appinvite_service": {
//           "other_platform_oauth_client": []
//         }
//       }
//     }
//   ],
//   "configuration_version": "1"
// }