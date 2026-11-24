# WormGPT X — Android starter

This is a Flutter starter project for a bilingual (Arabic/English) AI chat app with:
- Online mode using an OpenAI-compatible Chat Completions endpoint.
- Offline demo mode (currently a placeholder, **not** a local language model).
- Auto mode selector, dark UI, and endpoint/model/API-key settings.

## Build an APK

1. Install Flutter and Android Studio on a computer.
2. Extract this project.
3. In the project folder run:

```bash
flutter pub get
flutter doctor
flutter build apk --debug
```

APK output:
`build/app/outputs/flutter-apk/app-debug.apk`

For a release build, configure Android signing first, then run `flutter build apk --release`.

## Online mode

Open Settings and enter:
- An OpenAI-compatible Chat Completions endpoint.
- A model name supported by your provider.
- Your API key.

The key is held only in app memory in this starter and is not persisted. For a production app, use a backend proxy; do not embed a provider secret in a distributed APK.

## Offline mode

Offline mode is currently an explanatory placeholder. To make it truly offline, integrate a mobile inference runtime (for example, a compatible llama.cpp/ONNX/Gemma mobile runtime) and package or download a model that your device can run. Model size and RAM requirements matter.

## Scope

This project is an independent chat app starter. It does not break into accounts, bypass service licensing, disable security protections, or modify WhatsApp.
