# 📱 Flutter Demo App

A simple Flutter application demonstrating core widget usage including layout management, network image loading, and state management with `StatefulWidget`.

---

## 🚀 Getting Started

```bash
flutter pub get
flutter run
```

---

## 📋 Requirements

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.0.0 |
| Dart | ≥ 3.0.0 |
| Platform | Android / Windows |

---

## 🧩 Widget Documentation

Penjelasan widget-widget yang digunakan, berurutan sesuai hierarki dari root ke leaf.

---

### 1. `MaterialApp`

The root widget of a Flutter application using Material Design. It wraps the entire app and provides global configurations such as the color theme and the initial page. Here, `home` is set to `RowColumnPage` as the main page.

---

### 2. `Scaffold`

A widget that provides the basic layout structure for a page. It acts as the "skeleton" of the page with dedicated slots for `appBar` and `body`. Without `Scaffold`, the page would not have a standard structure like a top bar and content area.

---

### 3. `AppBar`

A horizontal bar widget displayed at the top of the page. It shows the title **"My First App"** with a background color of `Colors.orange[200]` and centers the title using `centerTitle: true`.

---

### 4. `Text` — *inside AppBar*

A widget for displaying static text. It renders the title `"My First App"` in the AppBar with black text color via `TextStyle(color: Colors.black)`.

---

### 5. `Column` — *main body*

A layout widget that arranges its children **vertically**. It serves as the main content container of the page, stacking all elements (image, text, icons, counter) in a single centered column.

---

### 6. `Container` › `AspectRatio` › `Container` › `Center` › `Image.network`

A group of widgets for displaying an image from the internet.

| Widget | Function |
|--------|----------|
| `Container` *(outer)* | Outer wrapper that controls margin and area size |
| `AspectRatio` | Forces the image area to maintain a **1:1** ratio (square) for consistent proportions across screen sizes |
| `Container` *(inner)* | Manages padding, margin, and background color `lightBlue[100]` |
| `Center` | Centers the image within the container |
| `Image.network` | Displays an image from URL `https://picsum.photos/200` using `BoxFit.cover` |

---

### 7. `Container` › `Text` — *image description*

| Widget | Function |
|--------|----------|
| `Container` | Controls width, padding, margin, and background color `pink[200]` |
| `Text` | Displays the text `"What image is that"` as an image caption |

---

### 8. `Container` › `Row` › `Column` × 3 — *icon categories*

A group of widgets for displaying three icon categories horizontally.

| Widget | Function |
|--------|----------|
| `Container` | Controls width, padding, margin, and background color `yellow[200]` |
| `Row` | Arranges three icon columns **horizontally** with even spacing (`spaceEvenly`) |
| `Column` + `Icon` + `Text` | Each displays one icon and its label: Food, Scenery, People |

---

### 9. `CounterCard` — *StatefulWidget*

A custom widget with a mutable **state**. It displays a counter number that increments each time the `+` button is pressed. It uses `setState()` to automatically update the UI when the state changes.

| Widget | Function |
|--------|----------|
| `Container` | Styles the card with color `cyan[100]`, padding, and margin |
| `Row` | Arranges the counter text and button **horizontally** with `spaceBetween` alignment |
| `Text` | Displays `"Counter here: $_counter"` — the value updates dynamically based on state |
| `Container` | Wraps the button with color `cyan[200]` |
| `IconButton` | An `Icons.add` icon button — calls `_incrementCounter()` when pressed to increment the counter |

---

## 🗂️ Widget Hierarchy

```
MyApp (StatelessWidget)
└── MaterialApp
    └── RowColumnPage (StatelessWidget)
        └── Scaffold
            ├── AppBar
            │   └── Text ('My First App')
            │       └── TextStyle (color: black)
            │
            └── Column
                ├── Container
                │   └── AspectRatio (ratio: 1.0)
                │       └── Container (color: lightBlue[100])
                │           └── Center
                │               └── Image.network
                │
                ├── Container (color: pink[200])
                │   └── Text ('What image is that')
                │
                ├── Container (color: yellow[200])
                │   └── Row
                │       ├── Column
                │       │   ├── Icon (Icons.food_bank)
                │       │   └── Text ('Food')
                │       ├── Column
                │       │   ├── Icon (Icons.landscape)
                │       │   └── Text ('Scenery')
                │       └── Column
                │           ├── Icon (Icons.people)
                │           └── Text ('People')
                │
                └── CounterCard (StatefulWidget)
                    └── Container (color: cyan[100])
                        └── Row
                            ├── Text ('Counter here: $_counter')
                            └── Container (color: cyan[200])
                                └── IconButton (Icons.add)
```
