# Intern-Connect Blueprint

## Overview

Intern-Connect is a mobile application that connects students with companies for internships. Students can browse and apply for internships, and companies can post internships and manage applications.

## Style, Design, and Features

### Style and Design

*   **Framework:** Flutter
*   **Design System:** Material Design 3
*   **Theming Engine:**
    *   A centralized `AppTheme` is defined in `lib/core/theme/theme.dart`.
    *   It uses `ColorScheme.fromSeed` to generate harmonious light and dark color schemes from a single primary color.
    *   Consistent typography is managed using the `google_fonts` package.
    *   Component themes (e.g., `AppBarTheme`, `ElevatedButtonTheme`, `CardTheme`) are defined for a consistent look and feel.
    *   Light/Dark mode is supported and managed by a `ThemeProvider` using the `provider` package, allowing users to toggle themes.
*   **Primary Seed Color:** Deep Purple
*   **Typography:** A combination of Google Fonts is used, such as Oswald, Roboto, and Open Sans, for different text styles.

### Features

*   **User Authentication:**
    *   Firebase Authentication for email/password login.
    *   `shared_preferences` to persist login sessions.
    *   Role-based access for "Student" and "Company" user types.

*   **Navigation:**
    *   Declarative routing is handled by `go_router`.
    *   The main student interface uses a `BottomNavigationBar` for primary sections.
    *   The `AppBar` provides access to secondary pages like Notifications and a global logout function.
    *   Dedicated routes for authentication (`/login`, `/register`) and feature pages like `/settings`.

*   **UI/UX:**
    *   A modern, clean, and consistent user interface across all pages.
    *   The main layout for students is managed by `StudentHomePage`, which includes a persistent `AppBar` and `BottomNavigationBar`.
    *   Individual pages (`HomePage`, `InternshipsPage`, etc.) are rendered as the body of the main layout, ensuring a seamless user experience.

*   **Student Features:**
    *   **Dashboard (`HomePage`):** A central hub providing an overview of recent activities and key information.
    *   **Internships (`InternshipsPage`):** A feature-rich page to browse, search, and filter internship listings.
    *   **Applications (`ApplicationsPage`):** A page to track the status of job applications, organized by tabs (e.g., "In Review," "Interview," "Offered").
    *   **Certificates (`CertificatesPage`):** A visually organized grid to display and manage the student's certificates.
    *   **Profile (`ProfilePage`):** A comprehensive user profile page displaying personal information, skills, and resume details, with a navigation link to the Settings page.
    *   **Settings (`SettingsPage`):** A dedicated page for application preferences, including the dark/light mode toggle.
    *   **Notifications (`NotificationsPage`):** A page to view a list of recent notifications, such as application status updates.

*   **Company Features:**
    *   Post new internship opportunities.
    *   View and manage applications for their posted internships.

## Current Task: UI Modernization and Feature Enhancement

### Plan

1.  **Theme Overhaul:** Implement a centralized Material 3 theme (`AppTheme`) with robust light and dark mode support using `ColorScheme.fromSeed` and the `provider` package for state management.
2.  **UI Refactoring:** Update all student-facing pages (`HomePage`, `InternshipsPage`, `ApplicationsPage`, `CertificatesPage`, `ProfilePage`) to adopt the new, consistent theme. This involved removing redundant `Scaffold` and `AppBar` widgets and ensuring all UI components derive their styles from the central theme.
3.  **Create Settings Page:** Develop a new, separate `SettingsPage` to house application preferences, including the theme toggle. A new route (`/settings`) was added to the `go_router` configuration.
4.  **Create Notifications Page:** Build a new `NotificationsPage` to display a list of user notifications with a clean, modern design.
5.  **Integrate Navigation:**
    *   Add an `ActionChip` to the `ProfilePage` to allow users to navigate to the new `SettingsPage`.
    *   Add an `IconButton` to the main `AppBar` in `StudentHomePage` to provide easy access to the `NotificationsPage`.
6.  **Update Blueprint:** Revise and update the `blueprint.md` file to accurately document the new architectural design, styling guidelines, and expanded feature set of the application.
