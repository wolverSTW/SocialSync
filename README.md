# Project Documentation: Social Sync
## Mobile Application Development (7CC012)
### Final Technical Submission

---

## 1.0 Introduction
Social Sync is a high-fidelity mobile application developed using the Google Flutter framework. The system is designed to provide a robust, offline-first environment for the orchestration of social media content. By leveraging Material Design 3 principles and a local relational database, the application ensures data integrity and user accessibility without the requirement of persistent network connectivity.

## 2.0 System Design and Architecture
The application is implemented using the Model-View-Controller (MVC) design pattern, ensuring a modular separation between data representation, user interface, and business logic.

### 2.1 Directory Structure
*   **lib/models**: Contains data entities and serialization logic for media payloads.
*   **lib/screens**: Implements the presentation layer using Material Design 3 components.
*   **lib/services**: Manages persistent storage transactions via the DatabaseHelper singleton.
*   **assets**: Repository for static resources, including typography and iconography.

### 2.2 Technical Stack
| Component | Technology | Rationale |
| :--- | :--- | :--- |
| Framework | Flutter / Dart | High-performance rendering and cross-platform compatibility. |
| Persistence | SQLite (sqflite) | Structured data management and offline reliability. |
| UI Specification | Material 3 | Adherence to modern accessibility and design standards. |
| Integration | share_plus | Native operating system bridge for content distribution. |

## 3.0 Installation and Deployment
The following procedures are required to initialize the development environment and execute the application.

### 3.1 Prerequisites
*   Flutter SDK version 3.10.0 or higher.
*   Integrated Development Environment (IDE) with Flutter/Dart plugin support.

### 3.2 Execution Steps
1.  Extract the source code from the project archive.
2.  Navigate to the project root and execute the dependency initialization:
    `flutter pub get`
3.  Ensure that the target device or emulator is active.
4.  Launch the application using the following command:
    `flutter run`

## 4.0 Quality Assurance and Testing
The project maintains a comprehensive test suite to ensure the reliability of core business logic and user interface stability.

*   **Automated Verification**: Includes unit, widget, and integration tests with a 100% pass rate.
*   **Heuristic Evaluation**: The interface has been audited against Nielsen’s 10 Usability Heuristics, specifically focusing on system status visibility and aesthetic minimalism.
*   **Data Integrity**: SQLite transactions are validated through an in-memory mock repository during testing phases.

## 5.0 Academic Statement
This project is submitted as the final assessment for the MSc Computer Science (Mobile Application Development) module. It demonstrates advanced proficiency in mobile architecture, persistent data management, and systematic software validation.

**Developed by:** Swunn Thut Wonn
