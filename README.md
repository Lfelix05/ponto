# Ponto

Ponto Eletrônico is a Flutter-based app for employee time tracking, featuring real-time Firebase integration, geolocation, notifications, and an admin dashboard.

## Main Features

### For Employees
- **Secure Login:** Access the employee dashboard with data validation.
- **Time Clocking:** Check-in and check-out with automatic location recording.
- **Hours Overview:** View check-in/check-out times and daily/monthly worked hours.
- **Notifications:** Receive check-in and absence reminders via local notifications.
- **Intuitive Interface:** Simple dashboard for everyday use.

### For Administrators
- **Employee Registration:** Add new employees with name and phone number.
- **Employee Management:** View, search, and remove employees and their records.
- **Location Display:** See the employee's location at clock-in on an interactive map.
- **Work Hours Monitoring:** Track monthly worked hours for each employee.

### General
- **Firebase Integration:** Real-time data management with Firestore.
- **Geolocation:** Location is recorded at check-in and check-out.
- **Google Maps:** Display locations on interactive maps.
- **Local Notifications:** Alerts and reminders using device notifications.
- **Local Persistence:** User data storage with Shared Preferences.
- **Background Tasks:** Notification scheduling with WorkManager.
- **Responsive Design:** Interface adapts to different screen sizes.
- **Secure Logout:** Logout as the only way to return to the main menu.

---

## Technologies Used

- **Flutter:** Cross-platform framework.
- **Firebase (Firestore & Auth):** Real-time database and authentication.
- **Google Maps API:** Map and location display.
- **Geolocator:** Device location capture.
- **Shared Preferences:** Local data storage.
- **Flutter Local Notifications:** Device notifications.
- **WorkManager:** Background task execution.
- **Intl:** Date and time formatting.
- **Crypto:** Password hashing.
- **Timezone:** Timezone handling.

---

## How to Use

**Employee:**
1. Log in using your name and phone number.
2. Register your time (check-in/check-out) and track your worked hours.
3. Receive point reminders via notifications.

**Administrator:**
1. Log in or register as an administrator.
2. Manage employees, view time records, and see real-time locations.

---

## Security

- **API keys and sensitive files** such as `google-services.json`, `GoogleService-Info.plist`, and `.env` **must not be versioned**.
- Passwords are stored as SHA-256 hashes.
- Location permissions are requested only when needed.

---

## Target Audience

Ideal for small and medium businesses seeking a digital, practical, and efficient time tracking solution.

---