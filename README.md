## Application idea and purpose

This project is a simple **maze game** built with **Flutter** and the **Flame** game engine.  
The player controls a ball and tries to navigate it through a series of mazes to reach the exit as quickly and efficiently as possible.  
The purpose of the game is to provide a casual but engaging challenge where the mazes get slightly more complex on each level, encouraging the player to improve their spatial thinking and planning.

The game includes:
- A **start screen** where the player can begin or continue their game.
- A **level selection screen** that shows at least three levels and which ones have been completed.
- A **game screen** where the maze is rendered and the player moves the ball.
- A **result screen** that shows whether the level was completed and allows returning to the level selection.

Player progression (completed levels) is saved locally so that it is preserved between application restarts.

## Deployed application

The game is deployed as a Flutter web application and can be played in a modern web browser at:

**URL:** `https://<your-deployment-url-here>`

> Replace the placeholder above with the actual URL of your deployed web build (for example, a GitHub Pages, university, or other hosting URL).

## How to play

- **Starting the game**
  - Open the deployed URL in a modern web browser.
  - On the **start screen**, press the button to go to the **level selection**.

- **Selecting a level**
  - On the **level selection screen**, tap/click one of the available levels.
  - Levels that have already been completed are visually indicated (for example with a check mark or different color).

- **Controls**
  - The game is designed so that it can be played **without a keyboard or mouse**.
  - On touch devices, you control the ball with on-screen controls (for example by tapping or dragging in the desired direction, or using virtual buttons/joystick).
  - On desktop, the same on-screen controls can be used with mouse or touchpad.
  - (Optional extra) On supported devices, you may also be able to control the ball using **device sensors** (for example by tilting the device), if enabled.

- **Objective and progression**
  - Guide the ball from the start position to the maze exit while avoiding walls and obstacles.
  - Completing a level marks it as finished in the level selection screen.
  - Completed levels are saved locally, so when you reopen the application your progress is preserved.

## Notes for reviewers

- The project is implemented with **Flutter** and **Flame**, and the game screen scales with the device resolution so that it can be played on different screen sizes.
- The web build in this repository is intended for deployment; the submission zip for the course omits non-plaintext asset files in accordance with the project instructions.

