#!/usr/bin/env python3
"""Empacota data/city.json em data/city.tres (recurso Godot)."""
import json
t = open("data/city.json", encoding="utf8").read()
esc = t.replace("\\", "\\\\").replace('"', '\\"')
open("data/city.tres", "w", encoding="utf8").write(
 '[gd_resource type="Resource" script_class="CityData" load_steps=2 format=3]\n\n'
 '[ext_resource type="Script" path="res://scripts/city_data.gd" id="1"]\n\n'
 '[resource]\nscript = ExtResource("1")\njson_text = "' + esc + '"\n')
print("ok", len(t))
