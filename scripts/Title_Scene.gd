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

extends Control

func _input(event):
	if event is InputEventKey or event is InputEventMouseButton:
		$About_Panel.visible = false
		

func _show_about():
	$About_Panel.visible = true


func _start_game(difficulty):

	state.mine_number = state.diff_map[difficulty]
	get_tree().change_scene("res://scenes/Earth.tscn")
#	get_node("..").mine_number = diff_map[difficulty]
#	visible = false
#	get_node("../Labels").visible = true
#	get_node("..").init()
