# SmartForm

A smart form builder app that simplifies Chinese government and business form filling with OCR autofill.

## Features
- Multi-step form with card-based navigation
- OCR recognition for ID cards (Vision framework, offline)
- Smart prefill engine using user profile
- Support for government, business, finance, education forms
- Auto-save with debounce protection
- Privacy-first: all processing offline

## Architecture
- MVVM pattern with ObservableObject
- Service layer (OCRService, StorageService, TemplateService)
- PrefillEngine for intelligent field autofill
- Local JSON storage (Documents directory)

## Requirements
- iOS 17.0+
- Xcode 15.0+

## Security Notes
- User profile data (ID card, bank card) stored as JSON in local Documents directory
- OCR processing uses on-device Vision framework - no data leaves the device
