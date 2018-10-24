# GhostBuster

Ever marked a large area for deconstruction just to place it again offset by a few tiles?  Ever noticed how your
construction bots will happily go deconstruct a belt only to place the exact same belt in the same place?  GhostBuster
fixes these problems by intelligent cancelling deconstruction requests (and some other trickery).

Due to limitations in Factorio 0.16's API regarding ghosts, GhostBuster cannot figure out how to reconfigure entities
that might have a configuration.  This includes anything that can be circuit connected as well as assemblers, splitters,
and some other entities.  To workaround this until 0.17, GhostBuster may instead destroy the original item and then
immediately revive the ghost.  This *should* end up having the same effect, other than sound effects and some events.
In the details below, this is referred to as the "Revive Hack"

In general, for GhostBuster's magic to happen you must be placing the same item as you're being destroyed (a Fast
Transport Belt will only be replaced with another Fast Transport Belt), it must be rotated the same direction, and
it must be empty.  Details on individual cases are below.

## Supported Entities

* **Transport Belts**: (Revive Hack) Cannot have any items.  Otherwise, shifting all of your belts one tile might end
up with iron on a belt that's now supposed to have copper.

* **Underground Belts**: Cannot have any items.

* **Splitters**: (Revive Hack) Cannot have any items.  Uses the Revive Hack since mods cannot determine the priorities
and filters of a splitter ghost.

* **Railroads**: No restrictions.

* **Rail Signals**: (Revive Hack) No restrictions.  Uses the Revive Hack due to possible circuit connections.

* **Chests**: (Revive Hack) Must be empty.
  
* **Logistic Chests**: (Revive Hack) Must be empty.

* **Inserters**: (Revive Hack) Must be empty.  Burner inserters may be supported depending on mod settings, in which
  case any remaining fuel will be preserved.

* **Furnaces**: (Revive Hack) Must be empty and unmoduled.  Burner furnaces (e.g. Stone and Steel Furnaces) may be supported
  depending on mod settings, in which case any remaining fuel will be preserved.

* **Solar Panels**: No restrictions.

* **Accumulators**: (Revive Hack) No restrictions.

## Unsupported Entities

Everything else, but notable explanations: 

* **Anything with fluids**: Due to [this bug](https://forums.factorio.com/viewtopic.php?f=7&t=63052)

* **Tiles**:  Due to [this bug](https://forums.factorio.com/viewtopic.php?f=7&t=63051)

### 0.2.0 (2018-10-23)

* Add support for accumulators, solar panels, and furnaces.
* Properly detect and handle entities with burners instead of inadvertently clobbering their fuel state.
* Skip entities that have a non-empty module inventory or a non-empty output inventory in addition to other checks.

### 0.1.0 (2018-10-20)
 
* First release
