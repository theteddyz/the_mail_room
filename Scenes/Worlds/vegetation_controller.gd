extends Node3D

@export_category("Tree Swaying")
## The amount of sway the trees should do.
@export_range(0, 2, 0.01) var amount: float = 1.0
## The speed of the swaying motion.
@export_range(0, 2, 0.01) var speed: float = 1.0
## Position Influence affects how much rotational difference the trees should have depending on their position.
## 0 means that they all move at the same time.
@export_range(0, 2, 0.01) var position_influence: float = 1.0
## Speed of the animation.
@export_category("Leaf animations")
@export_range(0, 2, 0.01) var animation_speed: float = 1.0
## Controls the exaggeration of the animation keyframes.
## 0 is no animation, 2 will exaggerate the animation movements by double.
@export_range(0, 2, 0.01) var animation_strength: float = 1.0
