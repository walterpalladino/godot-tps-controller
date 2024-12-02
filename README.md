# GODOT Third Person Controller

I worked on this controller to cover several missing features as much to add some interesting ones.

### Features

- Standard locomotion standing and crouched. Different speeds for both.
- Handle steps.
- Jump with its own horizontal movement speed
- Wall climbing. Jump from wall to air and onto another wall. Climbing has its own speed.
- Retargetable Character Controller to allow use multiple models without rewriting code.

### Animations
For this project I used only Mixamo free animations so in some cases I had to edit those animations to better fit my needs.
The .fbx files are included in the format of libraries.

### Retargeting the Character Controller
To avoid rewrite code I created a structure on the character that allows to use any model with a Humanoid Bone Map.
All you have to do 
