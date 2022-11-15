# Keyboard vs. Mouse
#### [Video Demo](https://youtu.be/-27BL8dMzuA)
#### A 2D typing game created in Lua using [LÖVE](https://love2d.org/)

This game was created in November 2022 as the final project for Harvard's CS50. 
I have fond memories of taking an optional typing class in school and plaing games such as this one to test out speed-typing.
Additionally, I am a fan of custom mechanical keyboards. It was these combined interests that led me to the idea of making a typing game and the theme for it.

##### Game Outline
The player is stationary in the centre of the screen while enemies approach from all sides. The player must type the word beneath an enemy in order to defeat it.
The larger the word the slower the enemy but the larger the score reward, with the possible difficulty of the words and number of enemies increasing over time.
The player has 3 lives, and loses one if an enemy touches them. 
There are three difficulties: Easy, Normal, and Hard. 
The main difference between them is how fast the enemy spawn rate scales with time, however more difficulty word lists are available in hard mode.

##### Framework & Libraries
I opted to use the LÖVE framework for Lua and made use of two additional libraries: [*tick*](https://github.com/rxi/tick) and [*classic*](https://github.com/rxi/classic) both by *rxi*.
*Tick* includes basic functions for delaying function calls, however I implemented my own timer systems for more complicated effects.
*Classic* implements simple object classes, which I used to group the functions and properties for the different game elements.

##### Resources
I created the artwork and animations myself in [GIMP](https://www.gimp.org/).
My understanding of how to best make these sort of assets improved drastically throughout the project.

The sound effects and music are from free assets packs found on itch.io.
Sound effects are by [*VOiD1 Gaming*](https://void1gaming.itch.io/halftone-sound-effects-pack-lite)
The music used is *Ludum Dare 38 - Track Four* by [*Abstraction*](https://tallbeard.itch.io/music-loop-bundle)

##### File Overview
 - *main.lua*: handles game updating & drawing, game state, main game controls.
 - *mouse.lua*: the enemy (mouse) class, enemy state, animation, drawing, the enemy class object also includes a word object from *word.lua*.
 - *word.lua*: the word class, contains the word lists, handles the selection of words and organisation of letters to be assessed when typing.
 - *player.lua*: handles the player animation and drawing.
 - *arrow.lua*: draws and animates arrows over the currently targeted enemy.
 - *menu*: handles functionality and drawing of the game menus (pause screen and main menu).
 - *conf.lua*: game configuration.
 - *tick.lua* & *classic.lua*: libraries by *rxi*. See links above.