With the advanced controls in Celeste, it's nice to make a D-pad for your secondary hand that just triggers dashes.

### The control set this mod improves

I use a *mostly* US-QWERTY keyboard layout (r_shift is thumb controlled) when gaming (though [not always](https://github.com/mikenrafter/voyager.qmk)).

| action | keybind |
| ------ | ------- |
| move up | W |
| move left | A |
| move down | S |
| move right | D |
| jump | space |
| aim dash up | U, I, O |
| aim dash left | U, J, M |
| aim dash down | M, K, period |
| aim dash right | O, L, period |
| crouch dash | comma |
| dash | U, I, O, J, K, L, M, period |
| grab | r_shift |

ASCII visualization of the controls:

```
  W         |         UIO
 ASD  space | r_shift JKL
            |         M,.
```

Where U is up and left diagonally, O is up and right diagonally, period is down and right diagonally, and M is down and left diagonally.

### Why it didn't work before

Having both dash and aim dash in <direction> bound to a single key resulted in a scenario where you had to hold the dash key for 2 input frames.  
This is a problem, because Celeste is a challenging platformer where there is already plenty of precision necessary. Having to hold the dash button for longer isn't helpful.  
This isn't an issue normally since the direction key and dash input typically have a lot of temporal separation. Anyway, this mod makes this control scheme much nicer to use.

#### A rough edge still present

I added the diagonal keys not because I wanted them originally (though having come up with the idea, I am well pleased with how it works), but instead because even with this mod,  
having dash activated in the same frame as your direction is challenging when it comes to diagonals. You have to be very precise and land your 2 key presses in the same split second.
Most of the time, this works just fine. On occasion, you mess up in a frustrating way. More often than I'd like. I did extend the duration of the input frames (not sure what effect 
that has on speedrun rules, though I'd be surprised if this mod ever got approved for that anyway) in order to make this problem less pronounced. I'm sure there's some cleaner solution, 
but diagonal keys is a low-tech solution that keeps the spirit of the control scheme.

### How it works now

The game now remembers the last pressed dash direction, eliminating the need to hold it down. This may affect other control schemes, which are not supported.
