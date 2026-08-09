
## Location Force Sync Pattern
When a user encounters a bug where a 'Force Sync' button fails to override a manual location setting in a Flutter app, ensure the following steps are verified in the code:
- **Storage Clearance**: The manual location data (e.g., city name, lat, lng) must be explicitly deleted or overwritten in persistent storage (SharedPreferences/Hive). Simply changing the in-memory variable is insufficient.
- **State Rebuild**: The state management solution (e.g., notifyListeners(), setState, or Riverpod/Bloc equivalent) must be triggered immediately after updating the variables and storage, so the UI instantly drops the manual location and reflects the GPS fetching state.
- **Permission Fallback**: If GPS permission is permanently denied, the function should gracefully redirect to openAppSettings() using the permission_handler package.
