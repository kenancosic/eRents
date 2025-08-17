# e_rents_desktop

A desktop application for the eRents property management system built with Flutter.

## Getting Started

### Prerequisites
- Flutter SDK 3.7.0 or higher
- Dart SDK 
- eRents backend API running (default: http://localhost:5000)

### Environment Setup

1. Create a `.env` file in the root directory of the project (`e_rents_desktop/.env`) with the following content:

```
# Google Maps API Key for address autocomplete
# Get your key from: https://console.cloud.google.com/apis/credentials
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY_HERE

# Backend API URL (optional, defaults to localhost:5000)
API_BASE_URL=http://localhost:5000
```

2. **To get a Google Maps API Key:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
   - Create a new project or select an existing one
   - Enable the "Places API" 
   - Create credentials (API Key)
   - Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key

**Note:** The Google Maps integration is optional. If no API key is provided, the app will still work but address autocomplete will be disabled and you'll need to enter addresses manually.

### Installation

1. Clone the repository
2. Navigate to the desktop app directory: `cd e_rents_desktop`
3. Get Flutter dependencies: `flutter pub get`
4. Create your `.env` file as described above
5. Run the app: `flutter run`

## Features

- Property management (add, edit, view properties)
- Maintenance issue tracking
- Tenant management
- Statistics and reports
- Real-time chat
- Address autocomplete (with Google Maps API)
- Image upload and management

## Development Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)

## Project Structure

- `lib/features/` - Feature-specific code (properties, maintenance, etc.)
- `lib/services/` - API and business logic services  
- `lib/widgets/` - Reusable UI components
- `lib/models/` - Data models
- `lib/theme/` - Application theming

## Setup Instructions

### 1. Environment Configuration

Create a `.env` file in the `lib` directory with the following content:

```bash
# Create lib/.env file
API_BASE_URL=http://localhost:5000
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

**Important**: The `.env` file is required for proper image loading and API communication.

### 2. Image Loading Issues

If property images are not displaying:

1. **Check .env file**: Ensure `lib/.env` exists with correct `API_BASE_URL`
2. **Verify backend**: Make sure the API server is running on the configured port
3. **Check image data**: Properties may reference non-existent image IDs
4. **Debug mode**: Run with `flutter run --debug` to see detailed image loading logs

### 3. Backend Requirements

Ensure the backend API is running and accessible:
- Default URL: `http://localhost:5000`
- Image endpoint: `/Image/{id}`
- Properties endpoint: `/api/Properties`

## Development

### Running the Application

```bash
flutter run --debug
```

### Debugging Image Issues

The app now provides detailed debug information for image loading:
- Console logs show URL construction process
- Error widgets display specific image IDs that failed to load
- Visual indicators distinguish between missing images and loading errors

## Configuration

### API Base URL
API_BASE_URL=http://localhost:5000
