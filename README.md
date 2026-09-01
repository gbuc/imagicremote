# iMagicRemote

Sideload **iMagicRemote** on an LG webOS TV. It shows the Mac HDMI picture and sends Magic Remote motion and clicks to a menu-bar helper that injects a real macOS mouse.

On Windows, use [MagicRemoteService](https://github.com/Cathwyler/MagicRemoteService) instead. The two projects are not wire-compatible.

The helper accepts an unencrypted mouse connection on port 18734. Keep the TV and Mac on the same LAN; do not expose that port.

## Install (no compile)

Download both files from the latest GitHub Release:

- `iMagicRemote-*-macos-universal.zip` — Mac helper (universal package, macOS 13+)
- `com.gbuc.imagicremote_*_all.ipk` — TV app

### 1. Mac helper

1. Unzip and drag **iMagicRemote** into `/Applications`.
2. First launch: right-click the app → **Open** (it is ad-hoc signed; Gatekeeper will warn).
3. Grant **Accessibility** to **iMagicRemote**. Allow incoming connections if the firewall asks.
4. The menu-bar title `iMR`. Copy the Mac IP from that menu. If more than one display is connected, pick the TV under Display.

Open at Login is in the same menu.

### 2. TV app

Unsigned webOS apps only run in **Developer Mode**. There is no USB install and this app is not in the LG Content Store.

1. Create a free account at the [LG webOS Developer](https://developer.lge.com/) site.
2. On the TV: LG Content Store → **Developer Mode** → sign in → **Dev Mode Status** on → **Key Server** on. Note the TV IP and passphrase.
3. On the Mac, install [webOS Dev Manager](https://github.com/webosbrew/dev-manager-desktop/releases).
4. Add Device: TV IP + passphrase. Install the `.ipk`.
5. On the TV, open **iMagicRemote** (not the HDMI input tile). Enter the Mac IPv4 from the `iMR` menu. Pick the HDMI port the Mac uses. Save.

Red toggles settings; Yellow opens the LG keyboard (types on the Mac); Back closes settings or the keyboard; Home shows the webOS launcher (the app stays in the background and the Mac connection pauses). Wheel click is left click; hold ~½s or press Green for right click; rotate the wheel to scroll. Clicking a Mac text field also opens the keyboard.

The first time the TV connects, the helper reads the Developer Mode session token from the TV (the same SSH setup used to install the `.ipk`) and calls LG’s reset so a 50-hour session becomes about 1000 hours. After that it resets again when **iMagicRemote** connects if 30 days have passed (or from **Extend Developer Mode** in the menu). Token and last reset are stored in `~/Library/Application Support/com.gbuc.imagicremote.mac/devmode.json`. After true expiry you must sign in on the TV again.

webOS will not autostart a sideloaded app by itself. After the TV is on with **Key Server** on, use **Install TV Start at Power-On** in the `iMR` menu (also tried on first connect). That appends a launch to Developer Mode’s boot script. Turn off **Simplink (HDMI-CEC)** so the Mac HDMI input does not steal the screen after boot.

HDMI-inside-the-app may not get the TV’s “PC” picture mode (4:4:4 / some HDR toggles). The Magic Remote pointer cannot be hidden without rooting; the helper hides the Mac cursor instead (toggle in the menu).

## Build from source

```bash
./scripts/release.sh
```

Writes a universal zip and the `.ipk` under `dist/`.

Mac only, this machine’s CPU (faster): `./scripts/package-mac.sh --native --install`

TV only: `./scripts/package-tv.sh` then install with webOS Dev Manager or `ares-install dist/com.gbuc.imagicremote_*_all.ipk`.

Dev-only, no Accessibility-friendly bundle: `cd mac && swift test && swift run iMagicRemote`.

## Protocol

`ws://HOST:18734/` JSON text: `{"t":"move","x":0-1,"y":0-1}`, `{"t":"down"}`, `{"t":"up"}`, `{"t":"rdown"}`, `{"t":"rup"}`, `{"t":"scroll","dx":0,"dy":1}` (positive `dy` is scroll down), `{"t":"text","s":"hi"}`, `{"t":"key","k":"enter"}` or `"backspace"`.
