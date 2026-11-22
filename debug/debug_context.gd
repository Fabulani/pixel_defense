extends RefCounted
## Game references shared by the debug menu and its sections.

var level: Level
var building_manager: BuildingManager
var tower_menu: TowerMenu
var vfx: VfxManager
var camera: PanningCamera
## Release queue for extra waves; created by the menu shell.
var extra_wave_spawner: Node
