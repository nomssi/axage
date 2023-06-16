# AXAGE ~ ABAP teXt Adventure Game Engine
![axage-wizard](https://github.com/nomssi/axage/blob/main/img/living_room.jpg)

# Game engine
A simple game engine as base for text adventures, with a wizard's adventure as an example

# maps
define rooms with exits to north, east, south and west, up and down

# actors
define actors 

# things
define things that can be found, pickup (taken) or dropped.

## openable things
create things that can be opened using special things

## implement new operations (commands)
e.g. cast a spell, splash, weld

# parser
use simple syntax (one command, following by zero, one or more parameters) to navigate in the world

## navigation commands
```
N or NORTH        Go to the room on the north side
E or EAST         Go to the room on the east side
S or SOUTH        Go to the room on the south side
W or WEST         Go to the room on the west side
UP                Go to the room upstairs
DOWN              Go to the room downstairs
MAP               show floor plan/game world
```

## Game standard commands
```
INV or INVENTARY  Show everything you carry
LOOK              Look what''s in the room
LOOK <object>     Have a closer look at the object in the room or in your inventory
TAKE <object>     Take object in the room
DROP <object>     Drop an object that you carry

OPEN <object>     Open something that is in the room
ASK <person>      Ask a person to talk to you
```

## Game custom commands
```
SPLASH
WELD

```

# class diagram

https://mermaid-js.github.io/mermaid/#/classDiagram
    

```mermaid
classDiagram
  thing <|-- openable_thing
  thing <|-- room
  thing <|-- actor
  thing <|-- map
  repository <|-- engine
      
class repository{   
    +add()
    +add_index()  
  }

class engine{   
    +add_custom_command()
    +cmd_look()      
    +interprete()  
  }

class thing{ 
    +name
    +description 
    +constructor()
    }
    
  class openable_thing{ 
    +needed 
    +content
    +constructor
    +get_content()
    +open()
    +is_open()
    }

  
  class room{
    +north
    +east
    +south
    +west
    +things: thing
    +constructor()
    +class_constructor()
    +set_exits()
    #set_exit()
   
  }
```
