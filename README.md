# Ponto

Ponto Eletrônico is a Flutter-based app designed to efficiently manage employee time tracking. It provides features for both administrators and employees, allowing control over work hours, location, and data management directly through the app.

## Main Features
### For Employees
```dart
-Secure Login:               Access the employee dashboard with data validation.
-Time Clocking:              Check-in and check-out with automatic location recording.
-Hours Overview:             Displays check-in and check-out times, as well as hours worked daily and monthly.
-Intuitive Interface:        Simplified dashboard for everyday use.
```

### For Administrators
```dart
-Employee Registration:       Add new employees to the system with name and phone number.
-Employee Management:         View the list of registered employees and their time records.
-Location Display:            View the employee's location at the time of clock-in on an interactive map.
-Work Hours Monitoring:       Track monthly worked hours of each employee.
-Secure Logout:               Logout as the only way to return to the main menu.
```

### General Features
```dart
-Firebase Integration:        Real-time data management using Firebase Firestore.
-Geolocation:                 Records employee location at check-in and check-out.
-Google Maps:                 Displays locations using interactive maps.
-Responsive Design:           Interface adapts to different screen sizes.
```
## Technologies Used
```dart
->Flutter:                    Cross-platform development framework.
->Firebase:                   Real-time database and authentication management.
->Google Maps API:            Map and location display.
->Geolocator:                 Device location tracking.
->Shared Preferences:         Local data storage for administrator info.
```
---
### How to Use
**Employee:**
<ol> 
  <li>Log in using your name and phone number.</li> 
  <li>Register your check-in and check-out, and track your worked hours.</li> 
</ol>

**Administrator:**
<ol> 
  <li>Log in or register as an administrator.</li> 
  <li>Manage employees, view time records, and track real-time location.</li> 
</ol>

## Target Audience
This app is ideal for small and medium-sized businesses that want to manage employee time tracking in a digital, practical, and efficient way.
