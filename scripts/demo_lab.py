# This project was developed with assistance from AI tools.
"""Isaac Lab demo scene loaded via Kit --exec (no AppLauncher)."""

import omni.usd
from pxr import UsdGeom, UsdLux, Gf, Sdf

stage = omni.usd.get_context().get_stage()
UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.z)

ground = UsdGeom.Mesh.Define(stage, "/World/GroundPlane")
ground.CreatePointsAttr([(-50, -50, 0), (50, -50, 0), (50, 50, 0), (-50, 50, 0)])
ground.CreateFaceVertexCountsAttr([4])
ground.CreateFaceVertexIndicesAttr([0, 1, 2, 3])
ground.CreateDisplayColorAttr([(0.3, 0.3, 0.3)])

light = UsdLux.DomeLight.Define(stage, "/World/DomeLight")
light.CreateIntensityAttr(1500)

print("[demo_lab] Scene ready.", flush=True)
