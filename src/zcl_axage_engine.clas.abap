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

    METHODS walk_to
      IMPORTING
        direction TYPE clike
        result TYPE REF TO zcl_axage_result
        auto_look TYPE boolean
      RETURNING VALUE(location) TYPE REF TO zcl_axage_room.

    METHODS do_open
      IMPORTING
        box TYPE clike
        player TYPE REF TO zcl_axage_actor
        result TYPE REF TO zcl_axage_result.
    METHODS do_ask
      IMPORTING
        name TYPE clike
        player TYPE REF TO zcl_axage_actor
        result TYPE REF TO zcl_axage_result.
    METHODS do_weld
      IMPORTING
        object1 TYPE clike
        object2 TYPE clike
        player TYPE REF TO zcl_axage_actor
        result TYPE REF TO zcl_axage_result.
    METHODS do_splash
      IMPORTING
        object1 TYPE clike
        object2 TYPE clike
        player TYPE REF TO zcl_axage_actor
        result TYPE REF TO zcl_axage_result.
    METHODS do_dunk
      IMPORTING
        object1 TYPE clike
        object2 TYPE clike
        player TYPE REF TO zcl_axage_actor
        result TYPE REF TO zcl_axage_result.

    METHODS do_take
      IMPORTING
        object TYPE clike
        from TYPE REF TO zcl_axage_thing_list
        to TYPE REF TO zcl_axage_thing_list
        result TYPE REF TO zcl_axage_result.
    METHODS drop
      IMPORTING
        object TYPE clike
        from TYPE REF TO zcl_axage_thing_list
        result TYPE REF TO zcl_axage_result.

    METHODS add_help
      IMPORTING
        result TYPE REF TO zcl_axage_result.

ENDCLASS.

CLASS zcl_axage_engine IMPLEMENTATION.
  METHOD constructor.

    map = NEW #( ).
    player = NEW #( name = 'PLAYER' descr = 'player name' ).
    actors = NEW #( ).

  ENDMETHOD.

  METHOD walk_to.
    CASE direction.

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
    ENDCASE.

    IF location IS BOUND.
      IF location->name = zcl_axage_room=>no_exit->name.
        result->add( 'you cannot go that way.' ).
      ELSE.
        player->set_location( location ).
      ENDIF.
      IF auto_look EQ abap_true.
        cmd_look( result ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD do_take.
    IF from->exists( object ).
      result->add( |You pickup the { object }| ).
      to->add( from->get( object ) ).
      from->delete( object ).
    ELSEIF from->get_list( ) IS INITIAL.
      result->add( 'You cannot pickup any object' ).
    ELSE.
      result->add( |There is no { object } you can pickup| ).
    ENDIF.
  ENDMETHOD.

  METHOD drop.
    IF from->exists( object ).
      result->add( |You drop the { object }| ).
      from->delete( object ).
    ELSEIF from->get_list( ) IS INITIAL.
      result->add( 'There is nothing you can drop' ).
    ELSE.
      result->add( |There is no { object } you can drop| ).
    ENDIF.
  ENDMETHOD.

  METHOD do_open.
    IF box IS INITIAL.
      result->add( 'Open what?' ).
    ELSEIF player->things->get_list( ) IS INITIAL
    AND    player->location->things->get_list( ) IS INITIAL.
      result->add( 'There is nothing to open...' ).
    ELSE.
      IF player->things->exists( box ).
        DATA(thing) = player->things->get( box ).
      ELSEIF player->location->things->exists( box ).
        thing = player->location->things->get( box ).
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
        result->add( |You cannot open that { box }| ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD do_ask.
    DATA actors_in_the_room TYPE STANDARD TABLE OF REF TO zcl_axage_actor.

    LOOP AT actors->get_list( ) INTO DATA(thing).
      DATA(actor) = CAST zcl_axage_actor( thing ).
      IF actor->get_location( ) = player->location.
        APPEND actor TO actors_in_the_room.
      ENDIF.
    ENDLOOP.

    IF actors_in_the_room IS INITIAL.
      result->add( 'There is no one here to ask...' ).
    ELSE.
      IF name IS INITIAL.
        result->add( 'Whom do you want to ask?' ).
      ELSE.
        LOOP AT actors_in_the_room INTO actor.
          IF to_upper( actor->name ) = name.
            result->addtab( actor->speak( ) ).
          ELSE.
            result->add( |You cannot ask { name }| ).
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD do_weld.
    IF object1 IS INITIAL OR object2 IS INITIAL.
      result->add( 'Weld which 2 objects?' ).
    ELSEIF player->things->get_list( ) IS INITIAL
    AND    player->location->things->get_list( ) IS INITIAL.
      result->add( 'There is nothing to weld...' ).
    ELSE.
      " to be implemented
      result->add( |You cannot weld yet| ).
      RETURN.

      IF player->things->exists( object1 ) AND player->things->exists( object2 ).
        DATA(subject) = player->things->get( object1 ).
        DATA(object) = player->things->get( object2 ).
      ELSEIF player->location->things->exists( object1 ).
        subject = player->location->things->get( object1 ).
        object = player->things->get( object2 ).
      ELSE.
        subject = player->things->get( object1 ).
        object = player->location->things->get( object2 ).
      ENDIF.


      IF subject IS BOUND.
        result->add( |{ subject->name } cannot be weld!| ).
      ELSE.
        result->add( |You cannot weld { object1 }| ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD do_splash.
    " to be implemented
    result->add( |You are too early, I still have to learn how to Splash yet, Sorry| ).
    RETURN.
  ENDMETHOD.

  METHOD do_dunk.
    " to be implemented
    result->add( |You are too early, I still have to learn how to Dunk yet, Sorry| ).
    RETURN.
  ENDMETHOD.

  METHOD add_help.
    result->add( `` ).
    result->add( `Navigation Commands:` ).
    result->add( |MAP               Show map/ floor plan/ world| ).
    result->add( |N or NORTH        Walk to the room on the north side| ).
    result->add( |E or EAST         Walk to the room on the east side| ).
    result->add( |S or SOUTH        Walk to the room on the south side| ).
    result->add( |W or WEST         Walk to the room on the west side| ).
    result->add( |U or UP           Go to the room upstairs| ).
    result->add( |D or DOWN         Go to the room downstairs| ).

    result->add( `` ).
    result->add( `Interaction with Objects:` ).
    result->add( |INV or INVENTORY  View everything you ae carrying| ).
    result->add( |LOOK              Describe your environment| ).
    result->add( |LOOK <object>     Have a closer look at the object in the room or in your inventory| ).
    result->add( |PICKUP <object>   Pickup an object in the current place| ).
    result->add( |DROP <object>     Drop an object that you carry| ).
    result->add( |OPEN <object>     Open something that is in the room| ).
    result->add( `` ).
    result->add( `Other Commands:` ).
    result->add( |ASK <person>            Ask a person to tell you something| ).
    result->add( |WELD <subject> <object>   Weld subject to the object if allowed| ).
    result->add( |DUNK <subject> <object>   Dunk subject into object if allowed| ).
    result->add( |SPLASH <subject> <object> Splash  subject into object| ).
    result->add( `` ).
  ENDMETHOD.

  METHOD interprete.
    DATA cmd TYPE string. "c LENGTH 100.

    result = NEW #(  ).

    cmd = to_upper( command ).

    SPLIT cmd AT space INTO DATA(cmd1) DATA(cmd2) DATA(cmd3).

    DATA(location) = walk_to( direction = cmd1
                              result = result
                              auto_look = auto_look ).
    IF location IS BOUND.
      RETURN.
    ENDIF.

    CASE cmd1.
      WHEN 'MAP'.
        result->addTab( map->show( ) ).
        IF auto_look EQ abap_true.
          cmd_look( result ).
        ENDIF.

      WHEN 'HELP'.
        add_help( result ).

      WHEN 'LOOK'.
        cmd_look(
          result = result
          cmd2   = cmd2 ).

      WHEN 'TAKE' OR 'PICKUP'.
        do_take( object = cmd2
                 from = player->location->things
                 to = player->things
                 result = result ).

      WHEN 'DROP'.
        drop( object = cmd2
              from = player->things
              result = result ).
        IF auto_look EQ abap_true.
          cmd_look( result ).
        ENDIF.

      WHEN 'INV' OR 'INVENTORY'.
        IF player->things->get_list( ) IS INITIAL.
          result->add( 'You aren''t carrying anything' ).
        ELSE.
          result->add( 'You carry' ).
          result->addtab( player->things->show( ) ).
        ENDIF.

      WHEN 'OPEN'.
        do_open( box = cmd2
                 player = player
                 result = result ).

      WHEN 'ASK'.
        do_ask( name = cmd2
                player = player
                result = result ).

      WHEN 'WELD'.
        do_weld( object1 = cmd2
                 object2 = cmd3
                 player = player
                 result = result ).
        IF auto_look EQ abap_true.
          cmd_look( result ).
        ENDIF.

      WHEN 'SPLASH'.
        do_splash( object1 = cmd2
                   object2 = cmd3
                   player = player
                   result = result ).
        IF auto_look EQ abap_true.
          cmd_look( result ).
        ENDIF.

      WHEN 'DUNK'.
        do_dunk( object1 = cmd2
                 object2 = cmd3
                 player = player
                 result = result ).
        IF auto_look EQ abap_true.
          cmd_look( result ).
        ENDIF.

      WHEN OTHERS.
        result->add( 'You cannot do that' ).
    ENDCASE.

  ENDMETHOD.

  METHOD is_completed.
    result = mission_completed.
  ENDMETHOD.

  METHOD get_inventory.
    result = NEW #( ).
    DATA(your_things) = player->things->get_list( ).

    IF lines( your_things ) IS INITIAL.
      result->add( |Your inventory is empty...| ).
    ELSE.
      result->add( |You are carrying:| ).
      LOOP AT your_things INTO DATA(thing_inv).
        result->add( |{ thing_inv->name } { thing_inv->description }| ).
      ENDLOOP.

    ENDIF.
  ENDMETHOD.


  METHOD get_location.
    result = player->location->name.
  ENDMETHOD.


  METHOD cmd_look.

    IF cmd2 IS INITIAL.
      LOOP AT actors->get_list( ) INTO DATA(thing).
        DATA(actor) = CAST zcl_axage_actor( thing ).
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
