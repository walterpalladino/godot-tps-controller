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
All you have to do is to add it under the **Model** node and retarget the animation player **Root Node** to this model.

### Sample Scenes
#### Side Action Controller
Scene to test the controller full features on a side view scene

#### TPS Controller
Scene to test the controller (not all the features at this moment) on a third person view.


## Extended Controller
The folde x-controller includes the file character_controller_3d.gd contains the class CharacterController3D which yould be used for a new controller to extend instead of the standard CharacterBody3D.
 
