# Fonts Directory

This directory contains font files used in the Javied Nama application.

## Font Files
- Place your font files (`.ttf`, `.otf`) in this directory
- The application uses the following font:
  - Jameelnoori (default font for all text)

## Usage
To use fonts in your Flutter application:

1. Add the font file to this directory
2. Update the `pubspec.yaml` file to include the font
3. Reference the font in your code using the font family name

Example `pubspec.yaml` configuration:
```yaml
flutter:
  fonts:
    - family: Jameelnoori
      fonts:
        - asset: assets/fonts/Jameelnoori.ttf
```

## Adding New Fonts
1. Copy the font file to this directory
2. Update the `pubspec.yaml` file
3. Restart the application 