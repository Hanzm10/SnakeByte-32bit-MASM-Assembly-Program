# SnakeByte - 32-bit MASM Assembly Snake Game

## About the Project

SnakeByte is a classic Snake game implementation written in 32-bit x86 Assembly Language using Microsoft Macro Assembler (MASM). This project was developed as a group project for the **Computer Organization and Architecture** course during the 2nd year of Computer Science studies.

The game is built using:
- **Visual Studio 2022** with 32-bit MASM assembler
- **Irvine32 library** for console I/O and utility functions
- x86 Assembly Language (32-bit)

This project is a modified version of the [Snake Game Assembly Language](https://github.com/meixinchoy/Snake-Game-Assembly-Language) repository by meixinchoy, enhanced with additional features and improvements.

## Game Features

- Classic snake gameplay with WASD controls
- Dynamic speed increase as the game progresses
- Score tracking system
- Hazard blocks for added difficulty
- Wall collision detection
- Self-collision detection
- Coin collection mechanics
- Game over and retry functionality

## Requirements

To build and run this project, you need:

1. **Visual Studio 2022** (or compatible version with MASM support)
2. **Irvine32 Library** - Download and install from [Kip Irvine's website](http://www.asmirvine.com/)
   - Place the Irvine library files in `C:\Irvine` directory
3. **Windows Operating System** (32-bit or 64-bit with 32-bit support)

## How to Build and Run

### Using Visual Studio:

1. Clone this repository:
   ```bash
   git clone https://github.com/Hanzm10/SnakeByte-32bit-MASM-Assembly-Program.git
   ```

2. Open `SnakeByte_Program.sln` in Visual Studio 2022

3. Ensure the Irvine32 library is properly installed in `C:\Irvine`

4. Build the solution (F7 or Build → Build Solution)

5. Run the program (F5 or Debug → Start Debugging)

## Game Controls

- **W** - Move Up
- **A** - Move Left
- **S** - Move Down
- **D** - Move Right
- **X** - Exit Game

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
