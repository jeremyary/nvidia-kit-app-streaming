# This project was developed with assistance from AI tools.
"""Isaac Lab demo: Cartpole balancing with viewport rendering."""

import argparse

from isaaclab.app import AppLauncher

parser = argparse.ArgumentParser(description="Isaac Lab cartpole demo")
AppLauncher.add_app_launcher_args(parser)
args_cli = parser.parse_args()
app_launcher = AppLauncher(args_cli)
simulation_app = app_launcher.app

import isaaclab.sim as sim_utils
from isaaclab.actuators import ImplicitActuatorCfg
from isaaclab.assets import ArticulationCfg, AssetBaseCfg
from isaaclab.scene import InteractiveScene, InteractiveSceneCfg
from isaaclab.sim import SimulationCfg
from isaaclab.utils import configclass


@configclass
class CartpoleSceneCfg(InteractiveSceneCfg):
    ground = AssetBaseCfg(
        prim_path="/World/ground",
        spawn=sim_utils.GroundPlaneCfg(),
    )

    dome_light = AssetBaseCfg(
        prim_path="/World/DomeLight",
        spawn=sim_utils.DomeLightCfg(intensity=2000.0, color=(0.75, 0.75, 0.75)),
    )

    cartpole = ArticulationCfg(
        prim_path="/World/Cartpole",
        spawn=sim_utils.UsdFileCfg(
            usd_path="http://omniverse-content-production.s3-us-west-2.amazonaws.com/Assets/Isaac/4.2/Isaac/Robots/Cartpole/cartpole.usd",
        ),
        init_state=ArticulationCfg.InitialStateCfg(pos=(0.0, 0.0, 2.0)),
        actuators={
            "cart_actuator": ImplicitActuatorCfg(
                joint_names_expr=["cartJoint"],
                effort_limit=400.0,
                velocity_limit=100.0,
                stiffness=0.0,
                damping=10.0,
            ),
            "pole_actuator": ImplicitActuatorCfg(
                joint_names_expr=["poleJoint"],
                effort_limit=400.0,
                velocity_limit=100.0,
                stiffness=0.0,
                damping=0.0,
            ),
        },
    )


def main():
    sim_cfg = SimulationCfg(dt=1 / 60)
    sim = sim_utils.SimulationContext(sim_cfg)
    sim.set_camera_view(eye=[5.0, 5.0, 5.0], target=[0.0, 0.0, 2.0])

    scene_cfg = CartpoleSceneCfg(num_envs=1, env_spacing=4.0)
    scene = InteractiveScene(scene_cfg)

    sim.reset()

    while simulation_app.is_running():
        scene.write_data_to_sim()
        sim.step()
        scene.update(sim_cfg.dt)


if __name__ == "__main__":
    main()
    simulation_app.close()
