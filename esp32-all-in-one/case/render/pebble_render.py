# Photo-style renders of the real Pebble STLs (exported with PART="w_*" from pebble_case.scad).
# blender -b -P pebble_render.py -- <stl_dir> <out.png> <view> <colorway> <mood> [samples] [res] [explode]
import bpy, sys, math, os, bmesh
from mathutils import Vector, Matrix

a = sys.argv[sys.argv.index("--") + 1:]
STL, OUT, VIEW, CW, MOOD = a[:5]
SAMPLES = int(a[5]) if len(a) > 5 else 128
RES = int(a[6]) if len(a) > 6 else 1200
EXPLODE = float(a[7]) if len(a) > 7 else 0.0

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene

COLORS = {"cream": ((0.80, 0.76, 0.69), (0.06, 0.06, 0.065)),
          "orange": ((0.95, 0.22, 0.04), (0.06, 0.06, 0.065)),
          "sage": ((0.45, 0.54, 0.45), (0.80, 0.78, 0.74)),
          "black": ((0.03, 0.03, 0.035), (0.50, 0.50, 0.51)),
          "allblack": ((0.025, 0.025, 0.028), (0.025, 0.025, 0.028)),
          "white": ((0.86, 0.86, 0.85), (0.86, 0.86, 0.85))}

def mat(name, col, rough=0.5, coat=0.0, emit=None, strength=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*col, 1); b.inputs["Roughness"].default_value = rough
    if "Coat Weight" in b.inputs: b.inputs["Coat Weight"].default_value = coat
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1); b.inputs["Emission Strength"].default_value = strength
    return m

shell_c, base_c = COLORS[CW]
M = {"shell": mat("shell", shell_c, 0.45), "base": mat("base", base_c, 0.55),
     "face": mat("face", (0.006, 0.006, 0.008), 0.08, coat=1.0), "glass": mat("glass", (0.004, 0.004, 0.006), 0.03, coat=1.0)}
EYE = (0.05, 0.75, 1.0) if CW != "orange" else (1.0, 0.85, 0.6)
M["eye"] = mat("eye", EYE, 0.3, emit=EYE, strength=2.4)
M["floor"] = mat("floor", (0.93, 0.92, 0.90), 0.8)

def load(name, m, offset=(0, 0, 0)):
    path = os.path.join(STL, name + ".stl")
    try: bpy.ops.wm.stl_import(filepath=path)
    except Exception: bpy.ops.import_mesh.stl(filepath=path)
    o = bpy.context.selected_objects[0]
    bm = bmesh.new(); bm.from_mesh(o.data); bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.001); bm.to_mesh(o.data); bm.free()
    o.scale = (0.1, 0.1, 0.1); o.location = (-3.6 + offset[0], -2.7 + offset[1], offset[2])
    for p in o.data.polygons: p.use_smooth = True
    if hasattr(o.data, "use_auto_smooth"): o.data.use_auto_smooth = True; o.data.auto_smooth_angle = math.radians(35)
    else:
        try: bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))
        except Exception: pass
    o.data.materials.append(M[m]); return o

e = EXPLODE
load("w_stand", "base"); load("w_standlid", "base", (0, 0, -e))
load("w_post", "base", (0, 0, e * 0.5))
load("w_head", "shell", (0, 0, e * 1.2)); load("w_headlid", "shell", (0, e * 0.9, e * 1.2))
load("w_face", "face", (0, -e * 0.9, e * 1.2)); load("w_glass", "glass", (0, -e * 0.5, e * 1.2))

# head transform (same as head_place in the .scad), in mm
TILT = math.radians(6); T0 = 5.5 / math.cos(TILT)
P = Vector((36, 27 + T0 * math.sin(TILT), 22 + T0 * math.cos(TILT)))
R = Matrix.Rotation(-TILT, 3, "X")
def head_pt(x, y, z):
    w = P + R @ Vector((x - 39, y - 29, z))
    return Vector(((w.x - 36) * 0.1, (w.y - 27) * 0.1 - e * 0.05, w.z * 0.1 + e * 0.12))

def eye_rect(cx, cz, w, h, r):
    bpy.ops.mesh.primitive_cube_add(size=1)
    o = bpy.context.object; o.scale = (w, 40.0, h); bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bv = o.modifiers.new("bv", "BEVEL"); bv.width = r; bv.segments = 10; bv.affect = "EDGES"; bpy.ops.object.modifier_apply(modifier="bv")
    o.scale = (0.1, 0.00003, 0.1); o.rotation_euler = (-TILT, 0, 0); o.location = head_pt(cx, 2.65, cz)
    o.data.materials.append(M["eye"]); return o

ZE = 26.5 + 1
if MOOD == "happy":
    for s in (-1, 1):
        bpy.ops.mesh.primitive_torus_add(major_radius=6.2, minor_radius=1.7, location=(0, 0, 0), rotation=(math.pi / 2, 0, 0))
        t = bpy.context.object; bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
        bm = bmesh.new(); bm.from_mesh(t.data)
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < 0.5], context="VERTS"); bm.to_mesh(t.data); bm.free()
        t.scale = (0.1, 0.005, 0.1); t.rotation_euler = (-TILT, 0, 0); t.location = head_pt(39 + s * 12, 2.65, ZE - 3)
        t.data.materials.append(M["eye"])
elif MOOD == "sleepy":
    for s in (-1, 1): eye_rect(39 + s * 12, ZE - 3, 13, 2.4, 1.1)
else:
    for s in (-1, 1): eye_rect(39 + s * 12, ZE, 12, 15.5, 4.2)

# camera lens behind its hole
bpy.ops.mesh.primitive_cylinder_add(radius=0.33, depth=0.05, rotation=(math.pi / 2 - TILT, 0, 0), location=head_pt(39, 4.2, 51))
bpy.context.object.data.materials.append(mat("lens", (0.02, 0.03, 0.07), 0.05, coat=1.0))

# studio
bpy.ops.mesh.primitive_plane_add(size=200); bpy.context.object.data.materials.append(M["floor"])
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 40, 0), rotation=(math.pi / 2, 0, 0)); bpy.context.object.data.materials.append(M["floor"])
def aim(o, t): o.rotation_euler = (Vector(t) - o.location).to_track_quat("-Z", "Y").to_euler()
def area(loc, size, power, col=(1, 1, 1)):
    bpy.ops.object.light_add(type="AREA", location=loc); l = bpy.context.object
    l.data.size = size; l.data.energy = power; l.data.color = col; aim(l, (0, 0, 4)); return l
area((-18, -22, 26), 22, 9000, (1.0, 0.97, 0.93)); area((24, -16, 10), 26, 3500, (0.93, 0.96, 1.0)); area((6, 22, 22), 14, 4500)
if VIEW == "back": area((10, 30, 12), 20, 6000)
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.9, 0.9, 0.92, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 0.25

VIEWS = {"hero": ((14, -26, 13.5), (0, 0, 4.6), 60), "front": ((0, -34, 5.5), (0, 0, 4.6), 72),
         "side": ((-34, -1, 6.0), (0, 0, 4.6), 72), "back": ((-16, 24, 12), (0, 0, 4.4), 60),
         "exploded": ((18, -30, 16), (0, 0, 6.0), 50)}
loc, tgt, lens = VIEWS[VIEW]
bpy.ops.object.camera_add(location=loc); cam = bpy.context.object; aim(cam, tgt); cam.data.lens = lens
cam.data.dof.use_dof = True; cam.data.dof.focus_distance = (Vector(loc) - Vector(tgt)).length; cam.data.dof.aperture_fstop = 5.6
sc.camera = cam
sc.render.engine = "CYCLES"; sc.cycles.samples = SAMPLES; sc.cycles.device = "CPU"
sc.cycles.use_denoising = False; sc.cycles.use_adaptive_sampling = True; sc.cycles.adaptive_threshold = 0.02; sc.cycles.max_bounces = 6
sc.render.resolution_x = RES; sc.render.resolution_y = RES
vt = [i.identifier for i in sc.view_settings.bl_rna.properties["view_transform"].enum_items]
sc.view_settings.view_transform = "AgX" if "AgX" in vt else "Filmic"
sc.render.filepath = OUT
bpy.ops.render.render(write_still=True)
