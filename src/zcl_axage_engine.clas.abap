CLASS zcl_axage_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    TYPES: BEGIN OF ts_action,
             action TYPE string,
             execute TYPE classname,
           END OF ts_action.
    TYPES tt_action TYPE SORTED TABLE OF ts_action WITH UNIQUE KEY action.

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
      IMPORTING result TYPE REF TO zcl_axage_result.

    DATA player            TYPE REF TO zcl_axage_actor.
    DATA map               TYPE REF TO zcl_axage_map.
    DATA actors            TYPE REF TO zcl_axage_thing_list.
    DATA mission_completed TYPE abap_bool.
    DATA allowed_commands  TYPE tt_action.

  PRIVATE SECTION.

    METHODS parse_command IMPORTING command TYPE string
                          EXPORTING action TYPE string
                                    params TYPE string_table.

    METHODS cmd_look
      IMPORTING !result TYPE REF TO zcl_axage_result
                params  TYPE string_table OPTIONAL.

    METHODS walk_to
      IMPORTING room           TYPE REF TO zcl_axage_room
                !result        TYPE REF TO zcl_axage_result
                auto_look      TYPE boolean
      RETURNING VALUE(rv_gone) TYPE abap_bool.

    METHODS add_help
      IMPORTING !result TYPE REF TO zcl_axage_result.

ENDCLASS.


CLASS zcl_axage_engine IMPLEMENTATION.
  METHOD constructor.
    map = NEW #( ).
    player = NEW #( name = 'PLAYER' descr = 'player name' ).
    actors = NEW #( ).
    allowed_commands = VALUE #( ( action = 'ASK' execute = 'LCL_PICKUP' )
                                ( action = 'DROP' execute = 'LCL_DROP' )
                                ( action = 'DUNK' execute = 'LCL_DUNK' )
                                ( action = 'OPEN' execute = 'LCL_OPEN' )
                                ( action = 'PICKUP' execute = 'LCL_PICKUP' )
                                ( action = 'SPLASH' execute = 'LCL_SPLASH' )
                                ( action = 'TAKE' execute = 'LCL_PICKUP' )
                                ( action = 'WELD' execute = 'LCL_WELD' ) ).
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

  METHOD parse_command.
    DATA cmd TYPE string.

    cmd = to_upper( command ).

    SPLIT cmd AT space INTO action DATA(cmd2).
    SPLIT cmd2 AT space INTO TABLE params.
  ENDMETHOD.

  METHOD interprete.

    DATA next_room TYPE REF TO zcl_axage_room.
    DATA lo_action TYPE REF TO lcl_action.

    result = NEW #( ).

    parse_command( EXPORTING command = command
                   IMPORTING action = DATA(action)
                             params = DATA(params) ).

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

    DATA(classname) = VALUE #( allowed_commands[ action = action ]-execute OPTIONAL ).

    IF classname IS NOT INITIAL.
      TRY.
          CREATE OBJECT lo_action TYPE (classname)
            EXPORTING objects = params
                      player = player
                      actors = actors
                      result = result.
          IF lo_action IS BOUND.
            lo_action->execute( ).
            IF auto_look = abap_true.
              cmd_look( result ).
            ENDIF.
            RETURN.
          ENDIF.
        CATCH cx_root.

      ENDTRY.

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
          params = params ).

      WHEN 'INV' OR 'INVENTORY'.
        get_inventory( result ).

      WHEN OTHERS.
        result->add( 'You cannot do that' ).
    ENDCASE.
  ENDMETHOD.

  METHOD is_completed.
    result = mission_completed.
  ENDMETHOD.

  METHOD get_inventory.
    DATA(your_things) = player->things->get_list( ).

    IF lines( your_things ) IS INITIAL.
      result->add( |Your inventory is empty...| ).
    ELSE.
      result->add( |You are carrying:| ).
    ENDIF.
    LOOP AT your_things INTO DATA(thing_inv).
      result->add( thing_inv->to_text( ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD get_location.
    result = player->location->name.
  ENDMETHOD.

  METHOD cmd_look.
    IF params IS INITIAL.
      LOOP AT actors->get_list( ) INTO DATA(thing).
        DATA(actor) = CAST zcl_axage_actor( thing ).
        IF actor->get_location( ) = player->location.
          result->add( |There is { actor->to_text( ) }| ).
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
      DATA(available_things) = player->location->things.
      LOOP AT params INTO DATA(cmd2).
        IF available_things->exists( cmd2 ).
          result->add( |It's { available_things->get( cmd2 )->describe( ) }| ).
        ELSEIF player->things->exists( cmd2 ).
          result->add( |You carry a { player->things->get( cmd2 )->to_text( ) }| ).
        ELSE.
          result->add( |You cannot look at that { cmd2 }| ).
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
