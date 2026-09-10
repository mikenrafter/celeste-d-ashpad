using Celeste.Mod;
using Microsoft.Xna.Framework;
using Monocle;

namespace Celeste.Mod.Dashpad {

    // Fixes dashing in the wrong (neutral/facing) direction when Dash and a
    // dash-direction are bound to the same physical key.
    //
    // Root cause: Player.DashCoroutine doesn't read the dash direction on
    // the frame Dash is pressed. It does `yield return null;` first, so the
    // direction is actually sampled on the *following* Player.Update call
    // (see Monocle.StateMachine: a state's coroutine is created and ticked
    // once, synchronously, in the same Update() call as the transition into
    // that state -- and that first tick only runs up to the first `yield`).
    // A same-key tap that's shorter than that one-frame gap has already
    // released by the time direction is sampled, so it falls back to the
    // player's current Facing.
    //
    // Fix: keep a short rolling memory of the last nonzero aim direction
    // (mirrors the leniency Celeste already gives the Dash *button* itself
    // via its own press buffer, just applied to the axis instead), and feed
    // it into Player.OverrideDashDirection -- a field DashCoroutine already
    // checks before falling back to the live-sampled direction -- for
    // exactly the two Player.Update calls that matter: the press frame
    // (where the coroutine starts but doesn't consume it) and the frame
    // after (where it does).
    public class DashpadModule : EverestModule {

        public static DashpadModule Instance { get; private set; }

        public override Type SettingsType => null;

        private const float DirectionBufferSeconds = 0.1f; // ~6 frames at 60fps

        private Vector2 bufferedDirection;
        private float bufferedDirectionTimer;

        // Arms on the press frame (after OverrideDashDirection is set, so
        // the *next* call knows to clear it once that call's orig() --
        // which is where the coroutine actually consumes it -- has run).
        private bool clearOverrideNextCall;

        public DashpadModule() {
            Instance = this;
        }

        public override void Load() {
            On.Celeste.Player.Update += OnPlayerUpdate;
        }

        public override void Unload() {
            On.Celeste.Player.Update -= OnPlayerUpdate;
        }

        private void OnPlayerUpdate(On.Celeste.Player.orig_Update orig, Player player) {
            bool clearAfterThisCall = clearOverrideNextCall;
            clearOverrideNextCall = false;

            Vector2 aim = Input.GetAimVector(player.Facing);
            if (aim != Vector2.Zero) {
                bufferedDirection = aim;
                bufferedDirectionTimer = DirectionBufferSeconds;
            } else if (bufferedDirectionTimer > 0f) {
                bufferedDirectionTimer -= Engine.DeltaTime;
            }

            if (Input.Dash.Pressed && bufferedDirectionTimer > 0f) {
                player.OverrideDashDirection = bufferedDirection;
                clearOverrideNextCall = true;
            }

            orig(player);

            if (clearAfterThisCall) {
                player.OverrideDashDirection = null;
            }
        }
    }
}
