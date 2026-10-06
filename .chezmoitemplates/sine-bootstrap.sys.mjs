/*
 * Installs the chezmoi-managed Sine mods on first launch.
 *
 * Check installed mods on each launch and repair any missing managed mods.
 */

import { setTimeout } from "resource://gre/modules/Timer.sys.mjs";

import manager from "./core/manager.sys.mjs";
import utils from "./core/utils.sys.mjs";

const COMPLETION_PREF = "sine.chezmoi-mods-installed";
const RELOAD_REPOSITORY =
  "https://github.com/1unarzDev/caelestia_nebula_hot_reload";

async function getInstalledMods() {
  try {
    return (await utils.getMods()) ?? {};
  } catch {
    return {};
  }
}

function hasReloadMod(mods) {
  return Object.values(mods).some(mod => {
    const homepage = String(mod?.homepage ?? "").toLowerCase();
    const name = String(mod?.name ?? "").toLowerCase();
    const id = String(mod?.id ?? "").toLowerCase();

    return (
      homepage.includes("1unarzdev/caelestia_nebula_hot_reload") ||
      name.includes("caelestia nebula hot reload") ||
      id.includes("caelestia_nebula_hot_reload") ||
      id.includes("caelestia-nebula-hot-reload")
    );
  });
}

async function installManagedMods() {
  try {
    /*
     * sine.sys.mjs loads this module asynchronously. Wait until Sine has
     * initialized its mod directory and mods.json.
     */
    for (let attempt = 0; attempt < 100; attempt++) {
      if (await IOUtils.exists(utils.modsDataFile)) {
        break;
      }

      await new Promise(resolve => setTimeout(resolve, 100));
    }

    if (!(await IOUtils.exists(utils.modsDataFile))) {
      throw new Error("Sine did not initialize mods.json.");
    }
    let installed = await getInstalledMods();
    let changed = false;

    if (!installed.Nebula) {
      console.info("[chezmoi/Sine] Installing Nebula...");

      await manager.installMod(
        "Nebula",
        "store",
        false
      );

      changed = true;
      installed = await getInstalledMods();
    }

    if (!hasReloadMod(installed)) {
      console.info(
        "[chezmoi/Sine] Installing Caelestia Nebula hot reload..."
      );

      await manager.installMod(
        RELOAD_REPOSITORY,
        null,
        false
      );

      changed = true;
    }

    if (changed) {
      await manager.rebuildMods();
      await manager.loadMods();
    }

    const finalMods = await getInstalledMods();

    if (!finalMods.Nebula || !hasReloadMod(finalMods)) {
      throw new Error(
        "One or more managed Sine mods were not found after installation."
      );
    }

    Services.prefs.setBoolPref(COMPLETION_PREF, true);

    console.info(
      "[chezmoi/Sine] Automatic mod installation complete."
    );
  } catch (error) {
    /*
     * Do not set the completion preference when installation fails.
     * This allows another attempt on the next Zen launch.
     */
    console.error(
      "[chezmoi/Sine] Automatic mod installation failed:",
      error
    );
  }
}

installManagedMods();
