# Belt 📦

![Belt Utility Icon](belt.png)

**Belt** is a utility library designed to make repetitive tasks in iOS development as easy as grabbing a tool from a utility belt. It provides abstractions for common tasks like photo album access, file management, location services, permissions handling, and more, all in a simple and reusable format.

## Main Features

Belt includes several handy utilities and kits:

### 1. **AssetUtility**
- Manage media files like photos and videos.
- Fetch, create, and delete albums in the photo library.

### 2. **FileUtility**
- Manage files and directories effortlessly.
- Easily read, write, delete files, and create directories.

### 3. **LocationUtility**
- Handle GPS and location-based services.
- Retrieve the current location, track real-time positions, and handle location permissions.

### 4. **PermissionUtility**
- Manage app permissions for camera, location, notifications, etc.
- Request, check status, and determine if permissions are granted.

### 5. **NotificationUtility**
- Manage local and push notifications.
- Set up notifications and handle both local and push notifications seamlessly.

### 6. **UserDefaultsUtility**
- Easily store and retrieve data using `UserDefaults`.
- Manage user settings efficiently.

### 7. **KeychainUtility**
- Store and retrieve secure data like passwords or tokens using the Keychain.

### 8. **BluetoothUtility**
- Discover, connect, and manage Bluetooth devices.

### 9. **CoreDataUtility**
- Simplifies working with Core Data, including creating, saving, fetching, and deleting data.

### 10. **AudioUtility**
- Handle audio playback and recording with ease.

### 11. **AnimationUtility**
- Quickly apply common animations to your UI elements.

### 12. **NetworkUtility**
- Simplifies making HTTP requests and handling responses for both GET and POST operations.

### 13. **ReachabilityUtility**
- Monitor network connection status and automatically handle network availability changes.

### 14. **DeviceInfoUtility**
- Retrieve basic device information such as OS version, model, and screen resolution.

### 15. **ClipboardUtility**
- Manage data on the clipboard, including copying and pasting text or images.

## Development Guidelines

### 1. **Stateless Design**
   Utility classes should be stateless, meaning they don't retain any state and are purely functional. This ensures predictable outcomes and simplifies testing.

### 2. **Testability**
   Ensure utility classes are easy to test by minimizing external dependencies. If dependencies are required, use **dependency injection** to reduce tight coupling and improve testability.

## Installation

### Swift Package Manager

You can easily add **Belt** to your project using the Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/realsilex/Belt.git", from: "1.0.0")
]
```

## Usage Examples

Belt is designed to be simple and intuitive. Each utility and kit can be quickly integrated into your project. Below are a few common usage scenarios:

- **AssetUtility**: Access and manage photo albums, and retrieve photos and videos.
- **LocationUtility**: Fetch current location and track real-time position updates.
- **UserDefaultsUtility**: Easily store and retrieve simple key-value data.
- **HapticFeedbackUtility**: Trigger various types of haptic feedback.
- **NotificationUtility**: Create and manage local and push notifications.

Each utility is designed with a straightforward API for easy integration into your project.

### Issue Reporting & Bugs

If you encounter bugs or have improvement suggestions, feel free to report them via the [issue tracker](https://github.com/realsilex/Belt/issues).
We also welcome feature requests and general feedback.

## License

Belt is licensed under the [MIT License](./LICENSE). You are free to use, modify, and distribute this library, as long as you include the license file in your distribution.

If you find this project helpful, please give it a ⭐️ and contribute to its improvement through pull requests and issue reporting!

## Contact

If you have any questions or need further assistance, feel free to contact us at [realsilex@gmail.com](mailto:realsilex@gmail.com).