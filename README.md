# 📱 MACIN

## 📝 Project Overview
This repository contains the source code for the mobile application of the **MasterClass** platform, an ecosystem for learning software development. The application is designed to offer a fluid, interactive, and accessible user experience, even under unstable network conditions.

### 🌟 Key Features
- **Classroom & Offline Mode:** Browse the course catalog and play videos with automatic local caching for offline access.
- **Interactive Assessments:** Quiz engine and code-writing playground with integrated syntax highlighting.
- **AI Tutor Chat:** Real-time communication channel (WebSockets) with an intelligent virtual tutor to address learning gaps.
- **Gamification & Affiliation:** Skill badges system and management of a virtual referral wallet.

---

## 🛠️ Tech Stack & Tools
- **Main Framework:** Flutter 3.x & Dart
- **State Management:** Bloc / Riverpod (Decoupled architecture)
- **Navigation:** GoRouter
- **Local Persistence (Offline Cache):** Hive / Isar Database
- **Security:** Flutter Secure Storage (Encrypted storage for JWT tokens)

---

## 📂 Folder Architecture
The project follows a **Feature-First** approach combined with *Clean Architecture* principles:

```text
lib/
├── core/                         # Global and shared components
│   ├── constants/                # Themes, colors (AppColors), dimensions
│   ├── error/                    # Centralized exception handling
│   ├── routes/                   # Navigation routes configuration
│   └── services/                 # Shared services (WebSocket, NetworkInfo)
└── features/                     # Isolated business modules
    ├── auth/                     # Authentication & Session (JWT)
    ├── classroom/                # Course management & viewing
    ├── assessment/               # Quizzes and code challenges
    └── ai_tutor/                 # AI Chatbot interface
```
