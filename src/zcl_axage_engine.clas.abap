CLASS zcl_axage_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    METHODS constructor.

    METHODS interprete
      IMPORTING !command      TYPE clike
                auto_look     TYPE boolean DEFAULT abap_true
      RETURNING VALUE(result) TYPE REF TO zcl_axage_result.

    METHODS is_completed
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS get_location
      RETURNING VALUE(result) TYPE string.

    METHODS get_inventory
      RETURNING VALUE(result) TYPE REF TO zcl_axage_result.

    DATA player            TYPE REF TO zcl_axage_actor.
    DATA map               TYPE REF TO zcl_axage_map.
    DATA actors            TYPE REF TO zcl_axage_thing_list.
    DATA mission_completed TYPE abap_bool.

  PRIVATE SECTION.

    METHODS cmd_look
      IMPORTING !result TYPE REF TO zcl_axage_result
                cmd2    TYPE string OPTIONAL.

    METHODS walk_to
      IMPORTING room           TYPE REF TO zcl_axage_room
                !result        TYPE REF TO zcl_axage_result
                auto_look      TYPE boolean
      RETURNING VALUE(rv_gone) TYPE abap_bool.

    METHODS do_open
      IMPORTING !objects TYPE string_table
                player  TYPE REF TO zcl_axage_actor
                !result TYPE REF TO zcl_axage_result.

    METHODS do_ask
      IMPORTING !objects TYPE string_table
                player  TYPE REF TO zcl_axage_actor
                !result TYPE REF TO zcl_axage_result.

    METHODS do_weld
      IMPORTING !objects TYPE string_table
                player  TYPE REF TO zcl_axage_actor
                !result TYPE REF TO zcl_axage_result.

    METHODS do_splash
      IMPORTING !objects TYPE string_table
                player  TYPE REF TO zcl_axage_actor
                !result TYPE REF TO zcl_axage_result.

    METHODS do_dunk
      IMPORTING !objects TYPE string_table
                player  TYPE REF TO zcl_axage_actor
                !result TYPE REF TO zcl_axage_result.

    METHODS do_take
      IMPORTING !objects TYPE string_table
                player  TYPE REF TO zcl_axage_actor
                !result  TYPE REF TO zcl_axage_result.

    METHODS drop
      IMPORTING !objects TYPE string_table
                player  TYPE REF TO zcl_axage_actor
                !result TYPE REF TO zcl_axage_result.

    METHODS add_help
      IMPORTING !result TYPE REF TO zcl_axage_result.

    METHODS validate1 IMPORTING param1       TYPE clike
                                operation    TYPE clike
                                !from        TYPE REF TO zcl_axage_thing_list
                                !result      TYPE REF TO zcl_axage_result
                      RETURNING VALUE(valid) TYPE abap_bool.
ENDCLASS.


CLASS zcl_axage_engine IMPLEMENTATION.
  METHOD constructor.
    map = NEW #( ).
    player = NEW #( name = 'PLAYER' descr = 'player name' ).
    actors = NEW #( ).
  ENDMETHOD.

  METHOD walk_to.
    rv_gone = abap_false.
    IF room IS BOUND.
      IF room->name = zcl_axage_room=>no_exit->name.
        result->add( 'you cannot go that way.' ).
      ELSE.
        player->set_location( room ).
      ENDIF.
      IF auto_look = abap_true.
        cmd_look( result ).
      ENDIF.
      rv_gone = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD validate1.
    valid = abap_false.
    IF param1 IS INITIAL.
      result->add( |{ operation } what?| ).
    ELSEIF from->exists( param1 ).
      result->add( |You { operation } the { param1 }| ).
      valid = abap_true.
    ELSEIF from->get_list( ) IS INITIAL.
      result->add( |You have nothing to { operation }...| ).
    ELSE.
      result->add( |There is no { param1 } you can { operation }| ).
    ENDIF.
  ENDMETHOD.

  METHOD do_take.
    DATA(object) = VALUE #( objects[ 1 ] OPTIONAL ).
    DATA(from) = player->location->things.
    DATA(to) = player->things.

    IF validate1( param1 = object
                  from = from
                  operation = 'pickup'
                  result = result ).
      to->add( from->get( object ) ).
      from->delete( object ).
    ENDIF.
  ENDMETHOD.

  METHOD drop.
    DATA(object) = VALUE #( objects[ 1 ] OPTIONAL ).
    DATA(from) = player->things.
    IF validate1( param1 = object
                  from = from
                  operation = 'drop'
                  result = result ).
      from->delete( object ).
    ENDIF.
  ENDMETHOD.

  METHOD do_open.
     DATA(box)  = VALUE #( objects[ 1 ] OPTIONAL ).
*    IF validate1( param1 = box
*                  from = player->things
*                  operation = 'open'
*                  result = result ).
*    ENDIF.


    IF box IS INITIAL.
      result->add( 'Open what?' ).
    ELSEIF     player->things->get_list( )           IS INITIAL
           AND player->location->things->get_list( ) IS INITIAL.
      result->add( 'There is nothing to open...' ).
    ELSE.
      IF player->things->exists( box ).
        DATA(thing) = player->things->get( box ).
      ELSEIF player->location->things->exists( box ).
        thing = player->location->things->get( box ).
      ENDIF.

      IF thing IS INSTANCE OF zif_axage_openable.
        DATA(thing_to_open) = CAST zif_axage_openable( thing ).
        result->add( thing_to_open->open( player->things )->get( ) ).
        IF thing_to_open->is_open( ).
          DATA finds TYPE string_table.
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

    DATA(name) = VALUE #( objects[ 1 ] OPTIONAL ).

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
   DATA(object1) = VALUE #( objects[ 1 ] OPTIONAL ).
   DATA(object2) = VALUE #( objects[ 2 ] OPTIONAL ).

    IF NOT validate1( param1 = object1
                      from = player->things
                      operation = 'weld'
                      result = result ).
      RETURN.
    ENDIF.

    IF validate1( param1 = object2
                  from = player->things
                  operation = 'weld to'
                  result = result ).

      IF player->location->things->exists( 'WELDING TORCH' ).
        " to be implemented
        result->add( |You cannot weld yet, the developer was lazy| ).
        " Add new object object1+object2
        " Remove 2 objects
        RETURN.
      ELSE.
        result->add( 'There is no Welding Torch here...' ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD do_splash.
    " to be implemented
     DATA(object1) = VALUE #( objects[ 1 ] OPTIONAL ).
     DATA(object2) = VALUE #( objects[ 2 ] OPTIONAL ).
    result->add( |You are too early, I still have to learn how to Splash yet, Sorry| ).
    RETURN.
  ENDMETHOD.

  METHOD do_dunk.
    " to be implemented
     DATA(object1) = VALUE #( objects[ 1 ] OPTIONAL ).
     DATA(object2) = VALUE #( objects[ 2 ] OPTIONAL ).
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
    result->add( |PICKUP <object>   (or TAKE) Pickup an object in the current place| ).
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
    DATA cmd TYPE string.
    DATA next_room TYPE REF TO zcl_axage_room.

    result = NEW #( ).

    cmd = to_upper( command ).

    SPLIT cmd AT space INTO DATA(action) DATA(cmd2).
    SPLIT cmd2 AT space INTO TABLE DATA(params).

    CASE action.

      WHEN 'N' OR 'NORTH'.
        next_room = player->location->north.

      WHEN 'S' OR 'SOUTH'.
        next_room = player->location->south.

      WHEN 'E' OR 'EAST'.
        next_room = player->location->east.

      WHEN 'W' OR 'WEST'.
        next_room = player->location->west.

      WHEN 'U' OR 'UP'.
        next_room = player->location->up.

      WHEN 'D' OR 'DOWN'.
        next_room = player->location->down.
    ENDCASE.

    IF walk_to( room = next_room
                result = result
                auto_look = auto_look ).
      RETURN.
    ENDIF.

    CASE action.
      WHEN 'MAP'.
        result->addTab( map->show( ) ).
        IF auto_look = abap_true.
          cmd_look( result ).
        ENDIF.

      WHEN 'HELP'.
        add_help( result ).

      WHEN 'LOOK'.
        cmd_look(
          result = result
          cmd2   = cmd2 ).

      WHEN 'INV' OR 'INVENTORY'.
        IF player->things->get_list( ) IS INITIAL.
          result->add( 'You aren''t carrying anything' ).
        ELSE.
          result->add( 'You carry' ).
          result->addtab( player->things->show( ) ).
        ENDIF.

      WHEN 'TAKE' OR 'PICKUP'.
        do_take( objects = params
                 player = player
                 result = result ).

      WHEN 'DROP'.
        drop( objects = params
              player = player
              result = result ).
        IF auto_look = abap_true.
          cmd_look( result ).
        ENDIF.


      WHEN 'OPEN'.
        do_open( objects = params
                 player = player
                 result = result ).

      WHEN 'ASK'.
        do_ask( objects = params
                player = player
                result = result ).

      WHEN 'WELD'.
        do_weld( objects = params
                 player = player
                 result = result ).
        IF auto_look = abap_true.
          cmd_look( result ).
        ENDIF.

      WHEN 'SPLASH'.
        do_splash( objects = params
                   player = player
                   result = result ).
        IF auto_look = abap_true.
          cmd_look( result ).
        ENDIF.

      WHEN 'DUNK'.
        do_dunk( objects = params
                 player = player
                 result = result ).
        IF auto_look = abap_true.
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
    ENDIF.
    LOOP AT your_things INTO DATA(thing_inv).
      result->add( |{ thing_inv->name } { thing_inv->description }| ).
    ENDLOOP.
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

      zcl_axage_room=>add_exits( location = player->location
                                 result = result ).

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
