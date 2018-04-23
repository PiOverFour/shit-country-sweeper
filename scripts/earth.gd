# Copyright (C) 2018  Damien Picard dam.pic AT free.fr
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

extends Spatial

# nav vars
const INTERP_SPEED = 2
const ROT_SPEED = 0.05
var rot_x = 0
var rot_y = 0
var zoom = 7
const ZOOM_SPEED = 0.1
const ZOOM_MAX = 2
const ZOOM_MIN = 7
const ray_length = 1000

# game vars
var mouse_event
var current_country
var previous_country
var mine_number = state.mine_number
var countries = {}
var game_state = 'WAITING'
var elapsed_time = 0.0

class Country:
	var name
	var nice_name
	var mesh_node
	var sprites = []
	var adjacent_countries = []
	var adjacent_mines = 0
	var is_mine = false
	var is_flagged = false
	var is_open = false
	
	const flagged_color = Color(1.0, 0.0, 0.0)
	const flagged_selected_color = Color(1.0, 0.3, 0.3)
	
	const open_color = Color(0.0, 1.0, 0.0)
	const open_selected_color = Color(0.3, 1.0, 0.3)
	
	const selected_color = Color(0.5, 0.5, 0.5)
	const unselected_color = Color(1.0, 1.0, 1.0)
	
	const dead_color = Color(0.0, 0.0, 0.0)

	const region_rects = {1: Rect2(  0, 384, 128, 128),
						  2: Rect2(128, 384, 128, 128),
						  3: Rect2(256, 384, 128, 128),
						  4: Rect2(384, 384, 128, 128),
						  5: Rect2(  0, 256, 128, 128),
						  6: Rect2(128, 256, 128, 128),
						  7: Rect2(256, 256, 128, 128),
						  8: Rect2(384, 256, 128, 128),
						  9: Rect2(  0, 128, 128, 128),
						 10: Rect2(128, 128, 128, 128),
						 11: Rect2(256, 128, 128, 128),
						 12: Rect2(384, 128, 128, 128),
						 13: Rect2(  0,   0, 128, 128),
						 14: Rect2(128,   0, 128, 128),
						  }

	func set_mat_color(color):
		var mat = self.mesh_node.mesh.surface_get_material(0)
		mat.albedo_color = color
		
	func _init(name, mesh_node):
		self.name = name
		self.mesh_node = mesh_node

	func reset():
		self.adjacent_mines = 0
		self.is_mine = false
		self.is_flagged = false
		self.is_open = false
		self.set_mat_color(self.unselected_color)
		for s in self.sprites:
			s.visible = false
		
	func set_adjacent_countries(countries, adjacent_countries):
		for c in adjacent_countries:
			self.adjacent_countries.append(countries[c])
		
	func set_nice_name(nice_name):
		self.nice_name = nice_name
	
	func set_sprites(centers):
		for c in centers:
			var node = Sprite3D.new()
			node.texture = load('res://textures/numbers/numbers.png')
			node.material_override = load('res://scenes/Number_Sprite.material')
			node.translation = Vector3(c[0], c[1], c[2])*1.01
			node.scale = Vector3(0.02, 0.02, 0.02)
			node.visible = false
			node.region_enabled = true
#				node.region_rect = self.region_rects[self.adjacent_mines]
			self.mesh_node.add_child(node)
			self.sprites.append(node)
				
	func set_adjacent_number():
		for s in self.sprites:
			if self.adjacent_mines > 0:
				s.region_rect = self.region_rects[self.adjacent_mines]
	
	func set_is_mine():
		if self.is_mine or len(self.adjacent_countries) == 0:
			return false
		else:
			self.is_mine = true
			return true
			
	func get_adjacent_flags():
		var adjacent_flags = 0
		for adj in self.adjacent_countries:
			if adj.is_flagged:
				adjacent_flags += 1
		return adjacent_flags
	
	func toggle_flag():
		var result
		if not self.is_open:
			if not self.is_flagged:
				set_mat_color(self.flagged_color)
				result = 'FLAGGED'
			else:
				set_mat_color(self.selected_color)
				result = 'UNFLAGGED'
			self.is_flagged = not self.is_flagged
		return result
	
	func set_selected(do_select):
		if self.is_mine and self.is_open:
			return
		if self.is_open:
			if do_select:
				set_mat_color(self.open_selected_color)
			else:
				set_mat_color(self.open_color)
		elif self.is_flagged:
			if do_select:
				set_mat_color(self.flagged_selected_color)
			else:
				set_mat_color(self.flagged_color)
		else:
			if do_select:
				set_mat_color(self.selected_color)
			else:
				set_mat_color(self.unselected_color)
	
	func open():
		if not self.is_flagged:
			self.is_open = true
			if get_adjacent_flags() == self.adjacent_mines:
				# Recursively open adjacent countries
				for adj in self.adjacent_countries:
					if not adj.is_flagged and not adj.is_open:
						if adj.open():
							return true
			if self.is_mine:
				set_mat_color(self.dead_color)
				return true
			else:
				if self.adjacent_mines:
					for s in self.sprites:
						s.visible = true
				set_mat_color(self.open_color)
				return false
		
func is_country_name(name):
	return name.find('Sea') == -1

func set_mines_randomly(mine_number, ignore=[]):
	var country_keys = countries.keys()
	while mine_number > 0:
		var i = randi() % len(countries)
		if not country_keys[i] in ignore and countries[country_keys[i]].set_is_mine():
			mine_number -= 1

func set_adjacent_mines():
	# Set number of adjacent mines
	for c in countries:
		countries[c].adjacent_mines = 0
		for adj in countries[c].adjacent_countries:
			if adj.is_mine:
				countries[c].adjacent_mines += 1

func _ready():
	# Randomize seed
	randomize()

	# Parse connectivity file
	var file = File.new()
	file.open('res://scripts/connectivity.json', file.READ)
	var connectivity = JSON.parse(file.get_as_text()).result
	
	# Parse country nice names file
	file.open('res://scripts/country_nice_names.json', file.READ)
	var country_nice_names = JSON.parse(file.get_as_text()).result

	for child in $Countries.get_children():
		# Create Country instances
		countries[child.name] = Country.new(child.name, child)
		# Copy materials to be able to set their colors individually
		child.mesh.surface_set_material(0, child.mesh.surface_get_material(0).duplicate())

#	Set all adjacencies
	for k in connectivity.keys():
#		print(countries)
		countries[k].set_adjacent_countries(countries, connectivity[k])
		countries[k].set_nice_name(country_nice_names[k])
		
	previous_country = $Sea_raycast
	
	# Parse country centers file
	file = File.new()
	file.open('res://scripts/country_centers.json', file.READ)
	var centers = JSON.parse(file.get_as_text()).result
	
# 	# Set number sprites
	for k in centers.keys():
		countries[k].set_sprites(centers[k])
	
	init()

func init():
	var ignore = ["038_N__Cyprus",
				  "039_Cyprus",
				  "044_Dominican_Rep_",
				  "057_United_Kingdom",
				  "070_Haiti",
				  "074_Ireland"]
	# Set mines randomly
	set_mines_randomly(mine_number, ignore)
	set_adjacent_mines()
	
	for k in countries.keys():
		countries[k].set_adjacent_number()
	
	# Open all isolated countries
	for c in countries:
		if len(countries[c].adjacent_countries) == 0:
			countries[c].open()
#	Open some islands as well
	for c in ignore:
		countries[c].open()
		
	$Labels/Col/Info/remaining.text = '%02d' % mine_number

func game_over(result):
	for c in countries:
		countries[c].open()
	game_state = 'GAMEOVER'
	$End_screen.visible = true
	if result == 'win':
		$End_screen/Result.text = """Congratulations, you swept all fuckin' shit countries!
		Start again ?"""
	elif result == 'lose':
		$End_screen/Result.text = """That shit blew up all over your face!
		Shall you try that shitström again?"""
		

func _start_game(difficulty):
	mine_number = state.diff_map[difficulty]
	elapsed_time = 0.0
	$End_screen.visible = false
	game_state = 'WAITING'
	for c in countries:
		countries[c].reset()
	init()

func get_closed_number():
	var closed = 0
	for c in countries:
		if not countries[c].is_open:
			closed += 1
	return closed

func _input(event):
	if event is InputEventMouseMotion:
		mouse_event = event
	elif event is InputEventMouseButton:
		if not event.pressed and event.button_index == BUTTON_MASK_RIGHT:
			if is_country_name(current_country.name) and game_state in ['WAITING', 'PLAYING']:
				var flag_result = countries[current_country.name].toggle_flag()
				if flag_result == 'FLAGGED':
					mine_number -= 1
				elif flag_result == 'UNFLAGGED':
					mine_number += 1
				$Labels/Col/Info/remaining.text = '%02d' % mine_number
		if not event.pressed and event.button_index == BUTTON_MASK_LEFT:
			if is_country_name(current_country.name):
				if game_state == 'WAITING':
					# Reset first country if it is a mine
					if countries[current_country.name].is_mine:
						countries[current_country.name].is_mine = false
						set_mines_randomly(1, countries[current_country.name])
						set_adjacent_mines()
						for c in countries:
							countries[c].set_adjacent_number()
				
					game_state = 'PLAYING'
				
				if game_state == 'PLAYING' and countries[current_country.name].open():
					game_over('lose')
				elif game_state == 'PLAYING' and get_closed_number() == state.mine_number:
					game_over('win')

func _physics_process(delta):
	if mouse_event != null:
		var space_state = get_world().direct_space_state
		var camera = $Camera_xform/Camera
		var from = camera.project_ray_origin(mouse_event.position)

		var to = from + camera.project_ray_normal(mouse_event.position) * ray_length

		var result = space_state.intersect_ray(from, to)
#		print('result: ', result)
		if len(result) != 0:
			# Hit country!
			current_country = result['collider'].get_parent()

			if is_country_name(current_country.name):
				$Labels/Col/Info/country_name.text = str(countries[current_country.name].nice_name)
				$Labels/Col/DebugLabels/is_mine.text = 'is mine: ' + str(countries[current_country.name].is_mine)
				$Labels/Col/DebugLabels/adjacent_countries.text = 'adjacent countries: ' + str(len(countries[current_country.name].adjacent_countries))
				$Labels/Col/DebugLabels/is_flagged.text = 'is flagged: ' + str(countries[current_country.name].is_flagged)
				$Labels/Col/DebugLabels/is_open.text = 'is open: ' + str(countries[current_country.name].is_open)
				$Labels/Col/DebugLabels/game_state.text = game_state

				countries[current_country.name].set_selected(true)
			if previous_country != current_country and is_country_name(previous_country.name):
				countries[previous_country.name].set_selected(false)
			print(previous_country)
			previous_country = current_country
		mouse_event = null

func _unhandled_input(ev):

	if ev is InputEventMouseButton and ev.button_index == BUTTON_WHEEL_UP:
		if zoom > ZOOM_MAX:
			zoom -= ZOOM_SPEED
			get_node("Camera_xform/Camera").translation.z = zoom

	if ev is InputEventMouseButton and ev.button_index == BUTTON_WHEEL_DOWN:
		if zoom < ZOOM_MIN:
			zoom += ZOOM_SPEED
			get_node("Camera_xform/Camera").translation.z = zoom

	if ev is InputEventMouseMotion and ev.button_mask & BUTTON_MASK_MIDDLE:
		rot_x += ev.relative.x * ROT_SPEED * zoom
		rot_y += ev.relative.y * ROT_SPEED * zoom
		rot_y = clamp(rot_y, -90, 90)
#		rot_x = clamp(rot_x, 0, 150)
		var t = Basis()
		t = t.rotated(Vector3(0, 1, 0), deg2rad(rot_x))
		t = t.rotated(Vector3(1, 0, 0), deg2rad(rot_y))
		$Countries.transform.basis = t
#		$Sea.transform.basis = t

func _process(delta):
	if game_state == 'PLAYING':
		elapsed_time += delta
	var mins = elapsed_time / 60.0
	var secs = int(elapsed_time) % 60
	$Labels/Col/Info/counter.text = '{mins}:{secs}'.format({'mins': '%02d' % mins,
															'secs': '%02d' % secs})