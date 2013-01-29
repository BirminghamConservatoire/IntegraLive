# Scripting View 

Integra Live has a built-in scripting facility based on the [Lua programming language](http://lua.org). 
Scripts can be used to set and get parameters and perform a range of procedural operations on them.

* To add scripting within a Block, select a Block, then click the scripting tab in the properties panel, 
then click the ‘+’ icon to add a new script. Script can then be typed into the text-area
* Integra Script is a super-set of Lua, with the added functions integra.set() and integra.get(), which can be used as follows:

`x = integra.get("AudioIn1", "vu")`

`integra.set("TapDelay1", "delayTime", math.abs(x) / 10.)`

* Scripts can be triggered by routing any parameter to the Script ‘trigger’ parameter.
