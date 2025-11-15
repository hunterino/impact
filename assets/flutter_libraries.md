# Flutter Coding approach:

Generate each major module, using the Attached wireframes for reference.  Generate a project file outline.  All code needs to be done using yaml files, with the key as the file path, and the value as the file content.  Break the project up into modules, and so each module has a yaml file.  All code needs to be commented, including a file comment with coyote forge copywrite information, and file purpose.  Each method needs to be commented, with appropriate dart doc style comments.

## Flutter Libraries Selection

If you need to choose a library, present each library 1 at a time, and present you top 3 choices, and list pros and cons, and ask for a selection from me.

## High Level Approach.

Using the 5x platform approach.

## Core Libraries

### 1. MQTT Client: mqtt_client: ^10.8.0
- Purpose: Provides the MQTT client implementation for real-time communication
- Features: 
  - Support for MQTT 3.1.1 and 5.0
  - QoS levels 0, 1, and 2
  - Persistent sessions
  - Last will and testament
  - Keep alive and ping functionality
- GitHub: https://github.com/shamblett/mqtt_client

### 2. State Management: provider: ^6.1.2
- Purpose: Manages application state and facilitates updates to the UI
- Features:
  - Reactive state management
  - Simple API for managing state inheritance
  - Built-in widget rebuilding optimization
- Alternative options: 
  - `bloc/flutter_bloc` (more structured but complex for this use case)
  - `riverpod` (more powerful but possibly overkill)

### 3. UI Components: flutter_card_swiper: ^7.0.2
- Purpose: Provides card swiping and stacking capabilities for the card game
- Features:
  - Card animations
  - Customizable card layout
  - Swipe detection with direction
- GitHub: https://github.com/ricardolui/flutter_card_swiper

### 4. Animations: flutter_animate: ^4.5.2
- Purpose: Creates smooth animations for card movements and game events
- Features:
  - Chain-based animation API
  - Rich set of pre-built effects
  - Fine-grained control over timing and curves
- GitHub: https://github.com/gskinner/flutter_animate

### 5. Storage: shared_preferences: ^2.5.2
- Purpose: Persists game settings and user preferences
- Features:
  - Simple key-value storage
  - Synchronous and asynchronous API
  - Platform-independent implementation

## Additional Libraries

### 1. UUID Generation: `uuid` 
- Purpose: Generates unique identifiers for games and players
- Features: Creates RFC4122 compliant UUIDs

### 2. Logging: `logging` 
- Purpose: Provides structured logging for debugging and monitoring
- Features: Multiple log levels, formatted output

### 3. Text-to-Speech: `flutter_tts`
- Purpose: Adds audio feedback for game events and actions
- Features: Cross-platform TTS implementation

### 4. SVG Rendering: `flutter_svg` 
- Purpose: Renders card designs and game assets as scalable SVGs
- Features: Efficient SVG parsing and rendering

### 5. Confetti Effects: `confetti` 
- Purpose: Adds celebratory effects for completed ideas or achievements
- Features: Customizable particle systems
