using System;
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
    //
    // Gotcha (found via frame-by-frame logging): Input.Dash.Pressed is not
    // a clean single-frame edge -- Celeste's own input buffer keeps it true
    // across several consecutive Update calls whenever the button can't be
    // acted on yet (e.g. the player is still mid-dash from a previous
    // press). Keying the "clear next call" arm off every Pressed==true call
    // let a stale clear -- armed by an earlier no-op frame while still
    // dashing -- fire right after the *real* dash-start frame, wiping the
    // override before the following frame could consume it. That's what
    // caused fast same-key double-taps to have their second dash fall back
    // to a stale direction instead of the newly tapped one.
    //
    // Fix for that: only set the override on a frame where the player isn't
    // already in the Dash state (a dash can only start from there), and
    // only arm the clear off the actual StateMachine transition into Dash
    // -- never off Pressed alone. That makes the clear fire exactly once,
    // exactly one call after the dash that owns it actually started,
    // regardless of how noisy Input.Dash.Pressed is around it.
    public class DashpadModule : EverestModule {

        public static DashpadModule Instance { get; private set; }

        public override Type SettingsType => null;

        private const float DirectionBufferSeconds = 0.133f; // ~8 frames at 60fps

        private Vector2 bufferedDirection;
        private float bufferedDirectionTimer;

        // Arms once a dash-start transition is observed, so the *next* call
        // knows to clear the override once that call's orig() -- which is
        // where the coroutine actually consumes it -- has run.
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

            bool wasDashing = player.StateMachine.State == Player.StDash;
            if (!wasDashing && Input.Dash.Pressed && bufferedDirectionTimer > 0f) {
                player.OverrideDashDirection = bufferedDirection;
            }

            orig(player);

            bool justStartedDash = !wasDashing && player.StateMachine.State == Player.StDash;
            if (justStartedDash) {
                // The override we just set is for THIS dash and is consumed
                // next call -- don't let a stale clear from a previous,
                // unrelated arm wipe it out from under it.
                clearOverrideNextCall = true;
            } else if (clearAfterThisCall) {
                player.OverrideDashDirection = null;
            }
        }
    }
}
