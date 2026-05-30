"""
Headless FBX -> compact GLB conversion for UK1 Outboxer.
Target: 30-100 MB output, skeleton intact, materials simplified.

Strategy:
  1. Import the FBX (Character Creator 5 export).
  2. Strip textures - replace every material with a simple Principled BSDF
     using a flat base color sampled from the original material if available.
     This drops hundreds of MB of texture data while keeping the model
     visible (single color per material).
  3. Export as GLB without animations (we don't need them for retargeting).
  4. Keep skins (skeleton + skin weights) since that's what mocap drives.
"""
import bpy
import os

SRC = "D:/Boxing game/Assets/BoxingGame/Characters/UK1Outboxer/uk1_outboxer.fbx"
DST = "D:/AI project/browser_mocap/uk1_outboxer.glb"

print("[convert] starting...")
print("[convert] src:", SRC)
print("[convert] dst:", DST)

# Clean slate
bpy.ops.wm.read_factory_settings(use_empty=True)

# Import FBX
print("[convert] importing FBX...")
bpy.ops.import_scene.fbx(filepath=SRC)
print("[convert] FBX imported. Objects:", len(bpy.data.objects))

# Strip textures - replace each material with a simple Principled BSDF
# carrying just the base color. This drops the heavy texture maps.
def get_base_color(mat):
    """Try to pull a representative color out of a material before we strip it."""
    if not mat or not mat.use_nodes or not mat.node_tree:
        return (0.6, 0.6, 0.6, 1.0)
    for node in mat.node_tree.nodes:
        if node.type == 'BSDF_PRINCIPLED':
            try:
                c = node.inputs['Base Color'].default_value
                return (c[0], c[1], c[2], c[3])
            except Exception:
                pass
    return (0.6, 0.6, 0.6, 1.0)

mat_count = 0
for mat in list(bpy.data.materials):
    if mat is None:
        continue
    base = get_base_color(mat)
    # Hint colors by material name so the character is visually parseable
    name_lower = (mat.name or "").lower()
    if "skin" in name_lower or "body" in name_lower or "face" in name_lower or "head" in name_lower:
        base = (0.85, 0.7, 0.6, 1.0)  # skin tone
    elif "hair" in name_lower:
        base = (0.15, 0.1, 0.08, 1.0)  # dark hair
    elif "eye" in name_lower:
        base = (0.05, 0.05, 0.05, 1.0)  # eye dark
    elif "teeth" in name_lower or "tooth" in name_lower:
        base = (0.95, 0.95, 0.9, 1.0)
    elif "tongue" in name_lower:
        base = (0.7, 0.3, 0.35, 1.0)
    elif "short" in name_lower or "pant" in name_lower or "thai" in name_lower:
        base = (0.2, 0.25, 0.45, 1.0)  # blue shorts
    elif "glove" in name_lower:
        base = (0.6, 0.1, 0.1, 1.0)  # red gloves
    elif "lash" in name_lower or "brow" in name_lower:
        base = (0.05, 0.04, 0.03, 1.0)

    mat.use_nodes = True
    nt = mat.node_tree
    # Wipe nodes
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out_node = nt.nodes.new('ShaderNodeOutputMaterial')
    bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.inputs['Base Color'].default_value = base
    bsdf.inputs['Roughness'].default_value = 0.7
    try:
        bsdf.inputs['Specular IOR Level'].default_value = 0.2
    except Exception:
        pass
    nt.links.new(bsdf.outputs['BSDF'], out_node.inputs['Surface'])
    mat_count += 1

print(f"[convert] simplified {mat_count} materials")

# Wipe image data to remove all texture payload from .blend
for img in list(bpy.data.images):
    try:
        bpy.data.images.remove(img)
    except Exception:
        pass
print("[convert] removed all image data")

# Drop the heaviest non-skeletal meshes (hair, eyelashes, tear ducts, stubble)
# These don't affect mocap retargeting and add huge geometry.
# We keep: body, eye, teeth, shorts -- the parts needed to read pose visually.
DROP_OBJECT_SUBSTRINGS = (
    "lash", "tear", "eyeoccl", "tearline", "tongue",
    "slick_back", "hair", "stubble", "glove",
)
to_remove = []
for obj in list(bpy.data.objects):
    if obj.type != 'MESH':
        continue
    name_l = (obj.name or "").lower()
    for sub in DROP_OBJECT_SUBSTRINGS:
        if sub in name_l:
            to_remove.append(obj)
            break
for obj in to_remove:
    print(f"[convert] dropping mesh: {obj.name}")
    bpy.data.objects.remove(obj, do_unlink=True)

# Decimate the heavy body mesh.  Keep the armature & skin weights intact.
# Apply a Decimate modifier at ratio ~0.18 -- preserves silhouette enough
# for retargeting verification while cutting most of the triangle weight.
print("[convert] applying Decimate to remaining meshes...")
DECIMATE_RATIOS = {
    "cc_base_body": 0.18,
    "cc_base_eye":  0.40,
    "cc_base_teeth": 0.40,
    "cc4_thai_shorts": 0.30,
}
DEFAULT_DECIMATE = 0.30

for obj in list(bpy.data.objects):
    if obj.type != 'MESH':
        continue
    name_l = (obj.name or "").lower()
    ratio = DEFAULT_DECIMATE
    for key, r in DECIMATE_RATIOS.items():
        if key in name_l:
            ratio = r
            break
    try:
        # Use built-in operator since we need it to be applied
        bpy.context.view_layer.objects.active = obj
        # Add modifier
        mod = obj.modifiers.new(name="DecimateMocap", type='DECIMATE')
        mod.decimate_type = 'COLLAPSE'
        mod.ratio = ratio
        mod.use_collapse_triangulate = True
        # Apply modifier
        bpy.ops.object.modifier_apply(modifier="DecimateMocap")
        verts = len(obj.data.vertices)
        print(f"[convert] decimated {obj.name} ratio={ratio} -> {verts} verts")
    except Exception as e:
        print(f"[convert] decimate failed on {obj.name}: {e}")

# Export GLB with Draco mesh compression for additional reduction
print("[convert] exporting GLB with Draco compression...")
try:
    bpy.ops.export_scene.gltf(
        filepath=DST,
        export_format='GLB',
        export_animations=False,
        export_skins=True,
        export_image_format='NONE',         # no texture pixel data
        export_apply=False,
        export_materials='EXPORT',
        use_selection=False,
        export_yup=True,
        export_draco_mesh_compression_enable=True,
        export_draco_mesh_compression_level=6,
        export_draco_position_quantization=14,
        export_draco_normal_quantization=10,
        export_draco_texcoord_quantization=12,
        export_draco_color_quantization=10,
        export_draco_generic_quantization=12,
    )
except TypeError as e:
    # older Blender API — fall back to plain export
    print(f"[convert] Draco params not supported ({e}); using plain export")
    bpy.ops.export_scene.gltf(
        filepath=DST,
        export_format='GLB',
        export_animations=False,
        export_skins=True,
        export_image_format='NONE',
        export_apply=False,
        export_materials='EXPORT',
        use_selection=False,
        export_yup=True,
    )
print("[convert] GLB export complete")

# Verify
if os.path.exists(DST):
    size = os.path.getsize(DST)
    print(f"[convert] GLB size: {size/1024/1024:.2f} MB")
    print("CONVERT_OK")
else:
    print("[convert] ERROR: GLB not written")
    print("CONVERT_FAIL")
