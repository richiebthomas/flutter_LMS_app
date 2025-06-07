# Flutter LMS App

A comprehensive Learning Management System (LMS) mobile application built with Flutter, designed for both teachers and students to manage educational content, assignments, and communication.

## Features

- **User Authentication**: Secure login and registration with Firebase Authentication
- **Role-Based Access**: Different interfaces and functionalities for teachers and students
- **Course Management**: Create, join, and manage courses
- **Content Sharing**: Upload and download educational materials
- **Assignment Management**: Create, submit, and grade assignments
- **Real-time Updates**: Get instant notifications for new content and feedback

## Technologies

- **Frontend**: Flutter
- **Backend**: Firebase
  - Firebase Authentication for user management
  - Cloud Firestore for database
  - Firebase Storage for file storage
- **State Management**: Provider

## Getting Started

### Prerequisites

- Flutter SDK (version 3.6.1 or higher)
- Dart SDK (latest version)
- Firebase account
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository
   ```
   git clone https://github.com/yourusername/flutter_LMS_app.git
   ```

2. Navigate to the project directory
   ```
   cd flutter_LMS_app
   ```

3. Install dependencies
   ```
   flutter pub get
   ```

4. Configure Firebase
   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and add the `google-services.json` file to the Android app
   - Download and add the `GoogleService-Info.plist` file to the iOS app

5. Run the app
   ```
   flutter run
   ```

## Project Structure

- `lib/`: Contains all the Dart code for the application
  - `main.dart`: Entry point of the application
  - `models/`: Data models
  - `screens/`: UI screens for different app features
    - `auth/`: Authentication screens
    - `teacher/`: Teacher-specific screens
    - `student/`: Student-specific screens
  - `services/`: Business logic and API services
  - `widgets/`: Reusable UI components
  - `utils/`: Utility functions and constants
  - `theme/`: App theme and styling

