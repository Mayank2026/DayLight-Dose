<div align="center">

# DayLight Dose

![App Logo](DayLight%20Dose/Assets.xcassets/AppIcon.appiconset/Daylight_Dose-iOS-Default-1024x1024@2x.png)

**Your intelligent companion for safe sun exposure and optimal vitamin D synthesis.**

</div>

**Your intelligent companion for safe sun exposure and optimal vitamin D synthesis.**

DayLight Dose is a scientifically-backed iOS app designed for people suffering from vitamin deficiency, particularly vitamin D deficiency. The app helps you track UV exposure and calculate personalized vitamin D intake in real-time using foundation models based on cutting-edge research in photobiology, dermatology, and nutrition science. These foundation models incorporate multiple environmental and personal factors to provide accurate estimates of vitamin D synthesis while prioritizing your safety with burn time warnings and seasonal alerts.

[📖 Read the detailed methodology](METHODOLOGY.md)

## App Demo Video

https://drive.google.com/file/d/1XwW2SqBMng0wWIQEU_qAnxGiMsZQze2m/view?usp=share_link

## Features

- Real-time UV index from your location
- Vitamin D calculation based on UV, skin type, clothing, age, and altitude
- Moon phase display at night
- Sunrise/sunset times with notifications
- Session tracking with detailed history
- Interactive charts showing Vitamin D, sessions, and UV trends
- Burn time calculations for safe sun exposure
- Vitamin D winter warnings for high latitudes
- Saves to Apple Health
- Offline mode with cached UV data
- No API keys required
- Small and medium widgets for your home screen
- Personalized daily summaries and tips

## Requirements

- iOS 26.0+
- iPhone only
- Xcode 26+

## Setup

1. Clone the repo
2. Open `DayLight Dose.xcodeproj`
3. Select your development team
4. Build and run

## Usage

1. Allow location and health permissions when prompted
2. Complete the onboarding to set your skin type and preferences
3. Press the sun button to start tracking a vitamin D session
4. Select your clothing level and skin type
5. The app calculates vitamin D intake automatically based on real-time UV
6. View your history in the Sessions tab
7. Check charts and trends in the History card
8. Learn more about vitamin D and UV in the Learn tab

## APIs Used

- Open-Meteo for UV data (free, no key)
- Farmsense for moon phases (free, no key)

## Foundation Models

DayLight Dose is built on scientifically rigorous foundation models that integrate:

- **Photobiology models**: UV absorption and vitamin D synthesis pathways based on current research
- **Dermatological algorithms**: Skin type classification and melanin impact on vitamin D production
- **Environmental factors**: UV index, altitude, cloud cover, and atmospheric conditions
- **Physiological parameters**: Age-related synthesis efficiency, clothing coverage, and body surface area
- **Safety thresholds**: Burn time calculations and minimum erythema dose (MED) considerations

These foundation models ensure accurate, personalized recommendations specifically tailored for individuals managing vitamin D deficiency.

## Target Audience

DayLight Dose is specifically designed for:
- Individuals diagnosed with vitamin D deficiency
- People at risk of vitamin D insufficiency
- Patients managing conditions related to vitamin deficiency
- Anyone seeking to optimize vitamin D levels through safe sun exposure

## License

Public domain. Use however you want.
