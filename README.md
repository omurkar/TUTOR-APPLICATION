# 🎓 Tutor Near Me (NextSolves)

**Connect with expert tutors or find students nearby!**

NextSolves is a comprehensive tutoring platform built with **Flutter** and **Firebase**. It bridges the gap between students and educators through smart location search, instant booking, and in-app messaging.

Experience a seamless, modern way to teach and learn with the **Yuva UI** design system. 🚀📚

---

## ✨ Features

### 👨‍🎓 For Students
* **Smart Search:** Find tutors by name or subject.
* **Location-Based:** Automatically detect your location to find nearby educators.
* **Booking System:** Request sessions, view upcoming schedules, and track completed classes.
* **Real-Time Chat:** Chat with tutors before booking.
* **Ratings:** Rate and review tutors after sessions.

### 👩‍🏫 For Tutors
* **Dashboard:** Manage booking requests (Accept/Decline) and view your daily schedule.
* **Profile Management:** Set your hourly rate, subjects, bio, and weekly availability.
* **Session Tracking:** Mark sessions as completed and track your history.
* **Student Interaction:** Direct messaging with potential students.

### 📱 General
* **Secure Authentication:** Email/Password & Google Sign-In via Firebase.
* **Modern UI:** "Yuva" Design System using Royal Blue & Orange branding.
* **Cloud Storage:** Profile picture uploads and management.

---

## 🛠️ Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **Backend:** [Firebase](https://firebase.google.com/)
    * **Authentication:** User login & signup.
    * **Cloud Firestore:** Real-time database for users, bookings, and chats.
    * **Storage:** Profile images.
* **Key Packages:**
    * `geolocator` & `geocoding`: GPS and address handling.
    * `image_picker`: Uploading profile photos.
    * `intl`: Date and time formatting.

---

## 📸 Screenshots
LOGIN PAGE 
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/05c9c890-615a-49c7-a759-70ef77d34148" />

STUDENT LOGIN PAGE 
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/76bad785-882e-406a-a8d3-32f59a8ffd4b" />


STUDENT DASHBORD 
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/b77a2969-46f1-4b2b-a51a-b00ca1317afd" />


MASSAGE PAGE 
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/3ecc6c29-d5ff-4bde-83a1-95a1a1fd13fa" />

TUTOR DASHBORD 
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/9a7aeee2-5b73-4ceb-a200-3ba5bd88fdc7" />




## 🚀 Getting Started

Follow these steps to run the project locally.

### Prerequisites
* Flutter SDK installed.
* A Firebase project set up.

### Installation

1.  **Clone the repository**
    ```bash
    git clone [https://github.com/omurkar/TUTOR-APPLICATION.git](https://github.com/omurkar/TUTOR-APPLICATION.git)
    cd TUTOR-APPLICATION
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup**
    * Create a project on the [Firebase Console](https://console.firebase.google.com/).
    * Add an Android app and download the `google-services.json`.
    * Place `google-services.json` inside `android/app/`.
    * Enable **Authentication** (Email/Password).
    * Enable **Firestore Database** and **Storage**.

4.  **Run the App**
    ```bash
    flutter run
    ```

---

## 📂 Project Structure

```text
lib/
├── screens/
│   ├── auth/           # Login & Signup screens
│   ├── common/         # Chat & Role Selection
│   ├── student/        # Student Home, Profile, Booking
│   └── tutor/          # Tutor Dashboard, Profile, Requests
├── services/           # Firebase & Logic services
└── main.dart           # Entry point
