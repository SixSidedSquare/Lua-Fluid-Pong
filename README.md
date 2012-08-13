PO(NG)ETRY
==========

Pong game using some fluid dynamics, made for a mini Ludum Dare 48 hour game jam.
Coded using LUA, for a very simple engine made specifically for the game jam.  Fluid dynamics code based on the Navier–Stokes equations from http://www.autodeskresearch.com/pdf/GDC03.pdf
Also discovered that coding fluid dynamic simulations in a scrpting language isn't the best idea, but using the LUAJIT compiler and a decent CPU it runs fine.

Original RetroEngine README included below



RetroEngine README:
===================

RetroEngine.exe includes all required libraries statically linked (ok, that was a pain).

It is compiled with Visual Studio 2008 as Release with optimizations aggresively favoring fast code.

If you have a problem running this test game, then please try installed the Visual Studio 2008 runtime (google for it).

I added some arguments you can pass to the exe so you can control whether the game starts in windowed or fullscreen mode, and also
control the amount of scaling from the start of the game.

For example, if you use 'RetroEngine.exe fullscreen 9'. That should give you a relatively common 1440x900 fullscreen mode. See the batch files
for more examples. By the way scaling more than 4 seems to cause issues when you press F5 to do the 2x scale. Also, hitting the 
function keys F1 - F4 when in fullscreen mode may cause issues. However, this is still cool for debugging and testing. 
I like a nice big pixellated version of the game on my giant monitor.

Thanks and enjoy!