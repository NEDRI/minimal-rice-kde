// Lorien Opacity: replaces the "lorien-black-opacity" window rule. A rule cannot tell a game from an app (native
// games have any window class, e.g. ck3), so translucency showed the desktop through fullscreen games.
// Here: normal windows and dialogs 97 % active / 95 % inactive, but 100 % when fullscreen, when they fill their
// whole screen (borderless games, video), or for the apps listed below.
const OPAQUE = /^(firefox|com\.mitchellh\.ghostty|vlc|org\.videolan\.vlc|mpv|steam|steam_app_.*|gamescope|.*\.exe|org\.kde\.konsole|konsole)$/i;
const ACTIVE = 0.97, INACTIVE = 0.95;

function fillsScreen(w) {
    const o = w.output && w.output.geometry, g = w.frameGeometry;
    return o && g.x <= o.x && g.y <= o.y && g.x + g.width >= o.x + o.width && g.y + g.height >= o.y + o.height;
}

function apply(w) {
    if (!w || !(w.normalWindow || w.dialog) || w.specialWindow) return;
    let want;
    if (w.fullScreen || fillsScreen(w) || OPAQUE.test(w.resourceClass) || OPAQUE.test(w.resourceName)) want = 1;
    else want = w.active ? ACTIVE : INACTIVE;
    if (Math.abs(w.opacity - want) > 0.001) w.opacity = want;
}

function watch(w) {
    if (!w || w.__lorienOpacity) return;
    w.__lorienOpacity = true;
    w.fullScreenChanged.connect(() => apply(w));
    w.frameGeometryChanged.connect(() => apply(w));
    w.activeChanged.connect(() => apply(w));
    w.outputChanged.connect(() => apply(w));
    apply(w);
}

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(watch);
