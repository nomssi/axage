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

  PROTECTED SECTION.

    METHODS next_room IMPORTING action TYPE string
                      RETURNING VALUE(target) TYPE REF TO zcl_axage_room.

    METHODS custom_action IMPORTING action TYPE clike
                                    params TYPE string_table
                                    result TYPE REF TO zcl_axage_result
                          RETURNING VALUE(executed) TYPE abap_bool.

    METHODS parse_command IMPORTING command TYPE string
                          EXPORTING action TYPE string
                                    params TYPE string_table.
    METHODS cmd_look
      IMPORTING !result TYPE REF TO zcl_axage_result
                params  TYPE string_table OPTIONAL.

    METHODS walk_to
      IMPORTING room           TYPE REF TO zcl_axage_room
                !result        TYPE REF TO zcl_axage_result
      RETURNING VALUE(rv_gone) TYPE abap_bool.

    METHODS add_help
      IMPORTING !result TYPE REF TO zcl_axage_result.

  PRIVATE SECTION.
    METHODS look_around
      IMPORTING result TYPE REF TO zcl_axage_result
                location TYPE REF TO zcl_axage_room.

    METHODS look_at
      IMPORTING result TYPE REF TO zcl_axage_result
                object_list TYPE string_table OPTIONAL.
ENDCLASS.



CLASS ZCL_AXAGE_ENGINE IMPLEMENTATION.


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
    result->add( |CAST <spell>            You must use the Spell name| ).
    result->add( |WELD <subject> <object>   Weld subject to the object if allowed| ).
    result->add( |DUNK <subject> <object>   Dunk subject into object if allowed| ).
    result->add( |SPLASH <subject> <object> Splash  subject into object| ).
    result->add( `` ).
  ENDMETHOD.


  METHOD cmd_look.
    IF player->location->dark EQ abap_true.
      result->add( 'You cannot see in the dark.' ).
      RETURN.
    ENDIF.
    IF params IS INITIAL.
      look_around( location = player->location   " Surroundings
                   result = result ).
    ELSE.
      look_at( object_list = params              " Object list
               result = result ).
    ENDIF.
  ENDMETHOD.


  METHOD constructor.
    map = NEW #( ).
    player = NEW #( name = 'PLAYER' descr = 'player name' ).
    actors = NEW #( ).
    allowed_commands = VALUE #( ( action = 'ASK' execute = 'LCL_PICKUP' )
                                ( action = 'CAST' execute = 'LCL_CAST' )
                                ( action = 'DROP' execute = 'LCL_DROP' )
                                ( action = 'DUNK' execute = 'LCL_DUNK' )
                                ( action = 'OPEN' execute = 'LCL_OPEN' )
                                ( action = 'PICKUP' execute = 'LCL_PICKUP' )
                                ( action = 'SPLASH' execute = 'LCL_SPLASH' )
                                ( action = 'TAKE' execute = 'LCL_PICKUP' )
                                ( action = 'WELD' execute = 'LCL_WELD' ) ).
  ENDMETHOD.


  METHOD custom_action.
    DATA lo_action TYPE REF TO lcl_action.

    executed = abap_false.
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
            executed = abap_true.
          ENDIF.
        CATCH cx_root.

      ENDTRY.

    ENDIF.
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


  METHOD interprete.
    DATA processed TYPE abap_bool VALUE abap_false.

    result = NEW #( ).

    parse_command( EXPORTING command = command
                   IMPORTING action = DATA(action)
                             params = DATA(params) ).

    processed = walk_to( room = next_room( action )
                         result = result ).
    IF processed = abap_false.
      processed = custom_action( action = action
                                 params = params
                                 result = result ).
    ENDIF.

    IF processed = abap_false.
      CASE action.
        WHEN 'MAP'.
          result->addTab( map->show( ) ).
          processed = abap_true.

        WHEN 'HELP'.
          add_help( result ).

        WHEN 'LOOK'.
          cmd_look(
            result = result
            params = params ).

        WHEN 'INV' OR 'INVENTORY'.
          get_inventory( result ).

        WHEN OTHERS.
          IF action IS INITIAL.
            result->add( 'Got your wizard hat on too tight? Try looking around' ).
          ELSE.
            result->add( |You cannot { action }| ).
          ENDIF.
      ENDCASE.
    ENDIF.

    IF processed = abap_true.
      IF auto_look = abap_true.
        cmd_look( result ).
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD is_completed.
    result = mission_completed.
  ENDMETHOD.


  METHOD look_around.
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
  ENDMETHOD.


  METHOD look_at.
    DATA(available_things) = player->location->things.
    LOOP AT object_list INTO DATA(an_object).
      IF available_things->exists( an_object ).
        result->add( |It's { available_things->get( an_object )->describe( ) }| ).
      ELSEIF player->things->exists( an_object ).
        result->add( |You carry a { player->things->get( an_object )->to_text( ) }| ).
      ELSE.
        result->add( |There is no { an_object } to look at| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD next_room.
    CLEAR target.
    CASE action.
      WHEN 'N' OR 'NORTH'.
        target = player->location->north.

      WHEN 'S' OR 'SOUTH'.
        target = player->location->south.

      WHEN 'E' OR 'EAST'.
        target = player->location->east.

      WHEN 'W' OR 'WEST'.
        target = player->location->west.

      WHEN 'U' OR 'UP'.
        target = player->location->up.

      WHEN 'D' OR 'DOWN'.
        target = player->location->down.
    ENDCASE.
  ENDMETHOD.


  METHOD parse_command.
    DATA cmd TYPE string.

    cmd = to_upper( command ).

    SPLIT cmd AT space INTO action DATA(cmd2).
    SPLIT cmd2 AT space INTO TABLE params.
  ENDMETHOD.


  METHOD walk_to.
    rv_gone = abap_false.
    IF room IS BOUND.
      IF room->name = zcl_axage_room=>no_exit->name.
        result->add( 'you cannot go that way.' ).
      ELSE.
        player->set_location( room ).
      ENDIF.
      rv_gone = abap_true.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
