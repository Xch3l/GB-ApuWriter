# APU Writer

Little tool to play around with the GameBoy's sound registers.

## How to use

In the Main Menu, and all other submenus, use the directional pad's <kbd>UP</kbd> and <kbd>DOWN</kbd> to navigate between options and press <kbd>Ⓐ</kbd> to enter any submenu.

Inside the main menu, press <kbd>START</kbd> to retrigger all channels.

Inside any editor, use <kbd>Ⓐ</kbd> to toggle any option and <kbd>LEFT</kbd> or <kbd>RIGHT</kbd> to change values. Holding <kbd>Ⓑ</kbd> will allow for fast editing. Press <kbd>START</kbd> to reapply settings and <kbd>SELECT</kbd> to view the channel's raw data.

### Wave Editor

Selecting "Edit waveform" inside the Wave Channel editor will allow modifying the shape by selecting and moving the knobs up and down with the directional pad. Pressing <kbd>Ⓐ</kbd> will test the current waveform and <kbd>Ⓑ</kbd> will exit this mode.

## Acknowledgements

- [PanDocs](https://gbdev.io/pandocs/About.html): The main resource in all the GameBoy's workings and quirks
- [Zeda's Z80 Optimized Routines](https://github.com/Zeda/Z80-Optimized-Routines)
	- Specifically, their [very, very fast 8bit routine](https://github.com/Zeda/Z80-Optimized-Routines/blob/master/math/rng/rng8_very_very_fast.z80) (slightly modified for GB hardware)

**No Artificial Intelligence (AI) of any kind was used in the creation of this software and its assets**
