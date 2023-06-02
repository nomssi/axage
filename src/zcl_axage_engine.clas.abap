CLASS zcl_axage_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  INTERFACES if_serializable_object.
    METHODS constructor.
    METHODS interprete
      IMPORTING
        command       TYPE clike
        auto_look     TYPE boolean DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE REF TO zcl_axage_result.
    METHODS is_completed
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS get_location
      RETURNING
        VALUE(result) TYPE string.
    METHODS get_inventory
      RETURNING
        VALUE(result) TYPE REF TO zcl_axage_result.
    DATA player TYPE REF TO zcl_axage_actor.
    DATA map TYPE REF TO zcl_axage_map.
    DATA actors TYPE REF TO zcl_axage_thing_list.
    DATA mission_completed TYPE abap_bool.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS cmd_look
      IMPORTING
        result TYPE REF TO zcl_axage_result
        cmd2   TYPE string OPTIONAL.
    METHODS goto
      IMPORTING
        location TYPE REF TO zcl_axage_room
        result TYPE REF TO zcl_axage_result
        look TYPE boolean.

ENDCLASS.

CLASS zcl_axage_engine IMPLEMENTATION.
  METHOD constructor.

    map = NEW #( ).
    player = NEW #( name = 'PLAYER' descr = 'player name' ).
    actors = NEW #( ).

  ENDMETHOD.

  METHOD goto.
    IF location IS BOUND.
      IF location->name = zcl_axage_room=>no_exit->name.
        result->add( 'you cannot go that way.' ).
      ELSE.
        player->set_location( location ).
      ENDIF.
      IF look EQ abap_true.
        cmd_look( result ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD interprete.
    DATA cmd TYPE string. "c LENGTH 100.
    DATA location TYPE REF TO zcl_axage_room.

    result = NEW #(  ).

    cmd = to_upper( command ).

    SPLIT cmd AT space INTO DATA(cmd1) DATA(cmd2).

    CLEAR location.

    CASE cmd1.
      WHEN 'MAP'.
        result->addTab( map->show( ) ).

      WHEN 'N' OR 'NORTH'.
        location = player->location->north.

      WHEN 'S' OR 'SOUTH'.
        location = player->location->south.

      WHEN 'E' OR 'EAST'.
        location = player->location->east.

      WHEN 'W' OR 'WEST'.
        location = player->location->west.

      WHEN 'U' OR 'UP'.
        location = player->location->up.

      WHEN 'D' OR 'DOWN'.
        location = player->location->down.

      WHEN 'HELP'.

        result->add( |N or NORTH        Go to the room on the north side| ).
        result->add( |E or EAST         Go to the room on the east side| ).
        result->add( |S or SOUTH        Go to the room on the south side| ).
        result->add( |W or WEST         Go to the room on the west side| ).
        result->add( |U or UP           Go to the room upstairs| ).
        result->add( |D or DOWN         Go to the room downstairs| ).
        result->add( |MAP               Show map/ floor plan/ world| ).
        result->add( || ).
        result->add( |INV or INVENTARY  Show everything you carry| ).
        result->add( |LOOK              Look what''s in the room| ).
        result->add( |LOOK <object>     Have a closer look at the object in the room or in your inventory| ).
        result->add( |TAKE <object>     Take object in the room| ).
        result->add( |DROP <object>     Drop an object that you carry| ).
        result->add( |OPEN <object>     Open something that is in the room| ).
        result->add( || ).
        result->add( |ASK <person>      Ask a person to tell you something| ).


      WHEN 'LOOK'.
        cmd_look(
          result = result
          cmd2   = cmd2 ).

      WHEN 'TAKE'.
        IF player->location->things->get_list( ) IS INITIAL.
          result->add( 'There is nothing you can take' ).
        ELSE.
          IF player->location->things->exists( cmd2 ).
            result->add( |You take the { cmd2 }| ).
            player->things->add( player->location->things->get( cmd2 ) ).
            player->location->things->delete( cmd2 ).
          ELSE.
            result->add( |You cannot take that { cmd2 }| ).
          ENDIF.
        ENDIF.

      WHEN 'DROP'.
        IF player->things->get_list( ) IS INITIAL.
          result->add( 'There is nothing you can drop' ).
        ELSE.
          IF player->things->exists( cmd2 ).
            result->add( |You drop the { cmd2 }| ).
            player->location->things->add( player->things->get( cmd2 ) ).
            player->things->delete( cmd2 ).
          ELSE.
            result->add( |You cannot drop that { cmd2 }| ).
          ENDIF.
        ENDIF.

      WHEN 'INV' OR 'INVENTORY'.
        IF player->things->get_list( ) IS INITIAL.
          result->add( 'You aren''t carrying anything' ).
        ELSE.
          result->add( 'You carry' ).
          result->addtab( player->things->show( ) ).
        ENDIF.

      WHEN 'OPEN'.
        IF cmd2 IS INITIAL.
          result->add( 'Open what?' ).
        ELSEIF player->things->get_list( ) IS INITIAL
        AND    player->location->things->get_list( ) IS INITIAL.
          result->add( 'There is nothing to open...' ).
        ELSE.
          IF player->things->exists( cmd2 ).
            DATA(thing) = player->things->get( cmd2 ).
          ELSEIF player->location->things->exists( cmd2 ).
            thing = player->location->things->get( cmd2 ).
          ENDIF.

          IF thing IS INSTANCE OF zcl_axage_openable_thing.
            DATA(thing_to_open) = CAST zcl_axage_openable_thing( thing ).
            DATA finds TYPE string_table.
            result->add( thing_to_open->open( player->things )->get( ) ).
            IF thing_to_open->is_open( ).
              LOOP AT thing_to_open->get_content( )->get_list( ) INTO DATA(content).
                APPEND |a { content->name }| TO finds.
              ENDLOOP.
              result->add( |The { thing->name } contains:| ).
              result->addtab( finds ).
              player->things->add( content ).
            ENDIF.
          ELSEIF thing IS BOUND.
            result->add( |{ thing->name } cannot be opened!| ).
          ELSE.
            result->add( |You cannot open { cmd2 }| ).
          ENDIF.
        ENDIF.

      WHEN 'ASK'.
        DATA actors_in_the_room TYPE STANDARD TABLE OF REF TO zcl_axage_actor.
        DATA actor TYPE REF TO zcl_axage_actor.
        LOOP AT actors->get_list( ) INTO thing.
          actor ?= thing.
          IF actor->get_location( ) = player->location.
            APPEND actor TO actors_in_the_room.
          ENDIF.
        ENDLOOP.

        IF actors_in_the_room IS INITIAL.
          result->add( 'There is no one here to ask...' ).
        ELSE.
          IF cmd2 IS INITIAL.
            result->add( 'Whom do you want to ask?' ).
          ELSE.
            LOOP AT actors_in_the_room INTO actor.
              IF to_upper( actor->name ) = cmd2.
                result->addtab( actor->speak( ) ).
              ELSE.
                result->add( |You cannot ask { cmd2 }| ).
              ENDIF.
            ENDLOOP.
          ENDIF.
        ENDIF.

      WHEN OTHERS.
        result->add( 'You cannot do that' ).
    ENDCASE.

    goto( location = location
          result = result
          look = auto_look ).

  ENDMETHOD.

  METHOD is_completed.
    result = mission_completed.
  ENDMETHOD.

  METHOD get_inventory.

    DATA inv TYPE abap_bool.

    result = NEW #( ).
    LOOP AT player->things->get_list( ) INTO DATA(thing_inv).
      IF inv IS INITIAL.
        result->add( |You are carrying:| ).
      ENDIF.
      result->add( |{ thing_inv->name } { thing_inv->description }| ).
    ENDLOOP.

    IF sy-subrc > 0.
      result->add( |Your inventory is empty...| ).
    ENDIF.

  ENDMETHOD.


  METHOD get_location.
    result = player->location->name.
  ENDMETHOD.


  METHOD cmd_look.

    IF cmd2 IS INITIAL.
      DATA actor TYPE REF TO zcl_axage_actor.
      LOOP AT actors->get_list( ) INTO DATA(thing).
        actor ?= thing.
        IF actor->get_location( ) = player->location.
          result->add( |There is { actor->name }, { actor->description }| ).
        ENDIF.
      ENDLOOP.

      IF player->location->things->get_list( ) IS INITIAL.
        result->add( 'There is nothing interesting to see...' ).
      ELSE.
        result->add( |You see| ).
        result->addtab( player->location->things->show( ) ).
      ENDIF.

      IF player->location->east->name <> zcl_axage_room=>no_exit->name.
        result->add( 'There is a door on the east side' ).
      ENDIF.
      IF player->location->west->name <> zcl_axage_room=>no_exit->name.
        result->add( 'There is a door on the west side' ).
      ENDIF.
      IF player->location->north->name <> zcl_axage_room=>no_exit->name.
        result->add( 'There is a door on the north side' ).
      ENDIF.
      IF player->location->south->name <> zcl_axage_room=>no_exit->name.
        result->add( 'There is a door on the south side' ).
      ENDIF.
      IF player->location->up->name <> zcl_axage_room=>no_exit->name.
        result->add( 'There is a ladder going upstairs' ).
      ENDIF.
      IF player->location->down->name <> zcl_axage_room=>no_exit->name.
        result->add( 'There is a ladder going downstairs' ).
      ENDIF.

    ELSE.
      IF player->location->things->exists( cmd2 ).
        result->add( |It's { player->location->things->get( cmd2 )->description }| ).
      ELSEIF player->things->exists( cmd2 ).
        result->add( |It's { player->things->get( cmd2 )->description }| ).
      ELSE.
        result->add( |You cannot look at that { cmd2 }| ).
      ENDIF.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
