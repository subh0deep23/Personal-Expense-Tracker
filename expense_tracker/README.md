# Personal Expense Tracker

A mobile application that helps users log and categorize their daily expenses, providing a clear overview of their spending habits.

## Features

### Core Features

- **Add Expenses**: Log expenses with details such as amount, category, date, and optional notes.
- **View Spending Summary**: Display total spending per category with visual charts.
- **Manage Categories**: Create, edit, and delete expense categories with custom colors.

### Optional Enhancements

- **Visualize Spending Trends**: View spending patterns using pie charts.
- **Time Range Filters**: Filter expenses by different time periods (All Time, This Month, This Week).
- **Category Breakdown**: See detailed breakdown of expenses by category with percentages.

## Technologies Used

- **Framework**: Flutter
- **Database**: SQLite (via sqflite package)
- **State Management**: Stateful Widgets
- **Visualization**: fl_chart package
- **Utilities**: intl for date and currency formatting

## Project Structure

```
lib/
├── database/
│   └── database_helper.dart    # SQLite database operations
├── models/
│   ├── category.dart           # Category data model
│   └── expense.dart            # Expense data model
├── screens/
│   ├── add_expense_screen.dart # Add/Edit expense screen
│   ├── categories_screen.dart  # Manage categories screen
│   ├── expense_detail_screen.dart # Expense details screen
│   ├── home_screen.dart        # Main screen with tabs
│   └── summary_screen.dart     # Spending summary with charts
├── utils/
│   ├── app_theme.dart          # App theme configuration
│   ├── color_utils.dart        # Color utility functions
│   └── formatters.dart         # Date and currency formatters
└── main.dart                   # App entry point
```

## Setup and Installation

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Dart SDK (version 2.17.0 or higher)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/expense_tracker.git
   ```

2. Navigate to the project directory:
   ```
   cd expense_tracker
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the app:
   ```
   flutter run
   ```

## Usage

1. **Adding an Expense**:
   - Tap the + button on the Expenses tab
   - Fill in the expense details (title, amount, category, date, optional note)
   - Tap 'Add Expense' to save

2. **Viewing Expense Details**:
   - Tap on any expense in the list to view its details
   - From the details screen, you can edit or delete the expense

3. **Managing Categories**:
   - Navigate to the Categories tab
   - Add new categories with custom colors
   - Edit or delete existing categories

4. **Viewing Spending Summary**:
   - Navigate to the Summary tab
   - View total expenses and category breakdown
   - Change time range to filter data

## Assumptions

- The app is designed primarily for personal use by a single user
- All expenses are stored locally on the device
- The app works offline without requiring internet connectivity
- Currency is set to USD by default

## Future Enhancements

- Cloud synchronization for backup and multi-device access`
- Budget setting and notifications when exceeding limits
- Income tracking and balance calculation
- Export data to CSV/PDF for reporting
- Multiple currency support
- Receipt scanning and automatic expense entry
