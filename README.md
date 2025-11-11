# SnakeByte - 32-bit MASM Assembly Snake Game

## About the Project

SnakeByte is a classic Snake game implementation written in 32-bit x86 Assembly Language using Microsoft Macro Assembler (MASM). This project was developed as a group project for the **Computer Organization and Architecture** course during the 2nd year of Computer Science studies.

The game is built using:
- **Visual Studio 2022** with 32-bit MASM assembler
- **Irvine32 library** for console I/O and utility functions
- x86 Assembly Language (32-bit)

This project is a modified version of the [Snake Game Assembly Language](https://github.com/meixinchoy/Snake-Game-Assembly-Language) repository by meixinchoy, enhanced with additional features and improvements.

## Features and Functions

The game includes the following core features implemented through various assembly procedures:

### Core Gameplay Functions
- **DrawWall** - Renders the game boundaries in red
- **DrawPlayer** - Displays the snake at current position
- **UpdatePlayer** - Erases the snake from old position before redrawing
- **DrawCoin** - Renders the collectible coin on the game board
- **CreateRandomCoin** - Generates random positions for coins
- **EatingCoin** - Handles coin collection, score increment, and snake growth
- **DrawBody** - Renders the snake's body segments
- **CheckSnake** - Detects self-collision (snake hitting its own body)

### Scoring and Display
- **DrawScoreboard** - Displays the game title "SNAKEBYTE" and current score
- **ShowSpeed** - Shows current speed level on the scoreboard
- **UpdateSpeed** - Dynamically increases game speed every 3 points

### Hazard System
- **MaybeSpawnHazardBlock** - Spawns hazard blocks at score milestones
- **CreateRandomHazardBlock** - Generates random hazard block positions
- **CreateMidpointHazardBlock** - Creates hazard blocks between snake and coin
- **CreateBetweenOrRandomHazardBlock** - Hybrid hazard placement strategy
- **DrawHazardAt** - Renders hazard blocks on the game board
- **ClearHazardAt** - Removes hazard blocks from the display
- **CheckBlockCollision** - Detects collision between snake head and hazard blocks

### Game Over Handling
- **YouDiedWall** - Handles death by wall collision
- **YouDiedBody** - Handles death by self-collision
- **YouDiedHazard** - Handles death by hazard collision
- **FinishedGame** - Displays game completion message
- **ReinitializeGame** - Resets all game variables for a new game

### Game Features
- Classic snake gameplay with directional movement
- Dynamic speed progression (increases every 3 points)
- Real-time score tracking
- Multiple hazard blocks spawning every 5 points
- Wall collision detection
- Self-collision detection
- Coin collection mechanics with snake growth
- Retry functionality after game over
- Color-coded display (red walls, yellow title, white snake)

## Setup

To set up and run this project, follow these steps:

### Prerequisites

1. **Install Visual Studio 2022**
   - Download from [Microsoft's official website](https://visualstudio.microsoft.com/)
   - During installation, ensure you select "Desktop development with C++" workload
   - This includes MASM (Microsoft Macro Assembler) support

2. **Install Irvine32 Library**
   - Download the Irvine32 library from [Kip Irvine's website](http://www.asmirvine.com/)
   - Extract the library files to `C:\Irvine` directory
   - The directory should contain files like `Irvine32.lib`, `Irvine32.inc`, etc.

3. **Configure Assembly File in Visual Studio**
   - For detailed setup instructions, follow this comprehensive tutorial:
   - **Video Tutorial**: [Setting up MASM in Visual Studio 2022](https://www.youtube.com/watch?v=QJCamuX1Pdg&t=851s)
   - The video covers project configuration, build customizations, and MASM settings

### Running the Project

1. Clone this repository:
   ```bash
   git clone https://github.com/Hanzm10/SnakeByte-32bit-MASM-Assembly-Program.git
   ```

2. Open `SnakeByte_Program.sln` in Visual Studio 2022

3. Verify the Irvine32 library path in project settings:
   - Right-click project → Properties
   - Configuration Properties → Microsoft Macro Assembler → General
   - Check that Include Paths contains `C:\Irvine`
   - Configuration Properties → Linker → General
   - Check that Additional Library Directories contains `C:\Irvine`

4. Build the solution:
   - Press **F7** or go to Build → Build Solution

5. Run the program:
   - Press **F5** or go to Debug → Start Debugging
   - Or press **Ctrl+F5** for running without debugging

## Controls

- **W** - Move Up
- **A** - Move Left
- **S** - Move Down
- **D** - Move Right
- **X** - Quit/Exit Game

## Screenshots

*(Screenshots will be added here)*

## Project Structure

- `snake.asm` - Main assembly source file containing all game logic
- `SnakeByte_Program.sln` - Visual Studio solution file
- `Project.vcxproj` - Visual Studio project configuration file
- `Project.lst` - Assembly listing file (generated during build)

## Game Mechanics

- The snake starts with an initial length of 5 segments
- Collect coins to increase your score and snake length
- Speed increases as you progress through the game
- Avoid hitting walls, your own body, and hazard blocks
- The game ends when you collide with an obstacle

## Credits

- Original repository: [Snake Game Assembly Language](https://github.com/meixinchoy/Snake-Game-Assembly-Language) by meixinchoy
- Developed as a group project for Computer Organization and Architecture course
- Built using the Irvine32 library by Kip R. Irvine

## License

This project is for educational purposes as part of a Computer Science course curriculum.
