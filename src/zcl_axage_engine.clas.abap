CLASS zcl_axage_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_serializable_object.

    TYPES: BEGIN OF ts_action,
             action  TYPE string,
             execute TYPE classname,
           END OF ts_action.
    TYPES tt_action TYPE SORTED TABLE OF ts_action WITH UNIQUE KEY action.

    METHODS constructor IMPORTING repository TYPE REF TO zcl_axage_repository.

    METHODS new_node
      IMPORTING !name           TYPE clike
                descr           TYPE clike OPTIONAL
      RETURNING VALUE(ro_thing) TYPE REF TO zcl_axage_thing.

    METHODS new_object
      IMPORTING !type              TYPE zcl_axage_thing=>tv_type DEFAULT zcl_axage_thing=>c_type_thing
                !name              TYPE clike
                descr              TYPE clike
                !state             TYPE clike                    OPTIONAL
                !prefix            TYPE string                   DEFAULT zcl_axage_thing=>c_prefix
                can_be_pickup      TYPE abap_bool                DEFAULT abap_true
                can_be_drop        TYPE abap_bool                DEFAULT abap_true
                can_weld           TYPE abap_bool                DEFAULT abap_false
                can_be_weld        TYPE abap_bool                DEFAULT abap_false
                can_be_open        TYPE abap_bool                DEFAULT abap_false
                can_be_splash_into TYPE abap_bool                DEFAULT abap_false
                can_be_dunk_into   TYPE abap_bool                DEFAULT abap_false
      RETURNING VALUE(ro_thing)    TYPE REF TO zcl_axage_thing.

    METHODS new_room
      IMPORTING !name       TYPE clike
                descr       TYPE clike     OPTIONAL
                !state      TYPE clike     OPTIONAL
                dark        TYPE abap_bool OPTIONAL
                image_data  TYPE string    OPTIONAL
      RETURNING VALUE(room) TYPE REF TO zcl_axage_room.

    METHODS new_actor
      IMPORTING !name       TYPE clike
                descr       TYPE clike
                !state      TYPE clike OPTIONAL
      RETURNING VALUE(room) TYPE REF TO zcl_axage_actor.

    METHODS interprete
      IMPORTING !command      TYPE clike
                auto_look     TYPE boolean DEFAULT abap_true
      RETURNING VALUE(result) TYPE REF TO zcl_axage_result.

    METHODS is_completed
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS get_location
      RETURNING VALUE(result) TYPE string.

    METHODS get_inventory
      IMPORTING !result TYPE REF TO zcl_axage_result.

    DATA player            TYPE REF TO zcl_axage_actor.
    DATA map               TYPE REF TO zcl_axage_map.
    DATA actor_node        TYPE REF TO zcl_axage_thing.
    DATA repository        TYPE REF TO zcl_axage_repository.
    DATA no_exit           TYPE REF TO zcl_axage_room.
    DATA mission_completed TYPE abap_bool.
    DATA allowed_commands  TYPE tt_action.

  PROTECTED SECTION.
    METHODS propose_command
      IMPORTING token          TYPE string
                !percentage    TYPE i DEFAULT 70  " 70% similarity
      RETURNING VALUE(variant) TYPE string.

    METHODS add_exits
      IMPORTING location TYPE REF TO zcl_axage_room
                !result  TYPE REF TO zcl_axage_result.

    METHODS next_room IMPORTING !action       TYPE string
                      RETURNING VALUE(target) TYPE REF TO zcl_axage_room.

    METHODS custom_action IMPORTING !action         TYPE clike
                                    params          TYPE string_table
                                    !result         TYPE REF TO zcl_axage_result
                          RETURNING VALUE(executed) TYPE abap_bool.

    METHODS parse_command IMPORTING !command TYPE string
                          EXPORTING !action  TYPE string
                                    params   TYPE string_table.

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
      IMPORTING !result  TYPE REF TO zcl_axage_result
                location TYPE REF TO zcl_axage_room.

ENDCLASS.


CLASS zcl_axage_engine IMPLEMENTATION.
  METHOD add_exits.
    IF location->east->name <> no_exit->name.
      result->add( 'There is a door on the east side' ).
    ENDIF.
    IF location->west->name <> no_exit->name.
      result->add( 'There is a door on the west side' ).
    ENDIF.
    IF location->north->name <> no_exit->name.
      result->add( 'There is a door on the north side' ).
    ENDIF.
    IF location->south->name <> no_exit->name.
      result->add( 'There is a door on the south side' ).
    ENDIF.
    IF location->up->name <> no_exit->name.
      result->add( 'There is a ladder going upstairs' ).
    ENDIF.
    IF location->down->name <> no_exit->name.
      result->add( 'There is a ladder going downstairs' ).
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
    result->add( |CAST <spell>            You must use the Spell name| ).
    result->add( |WELD <subject> <object>   Weld subject to the object if allowed| ).
    result->add( |DUNK <subject> <object>   Dunk subject into object if allowed| ).
    result->add( |SPLASH <subject> <object> Splash  subject into object| ).
    result->add( `` ).
  ENDMETHOD.

  METHOD cmd_look.
    IF player->location->dark = abap_true.
      result->add( 'You cannot see in the dark.' ).
      RETURN.
    ENDIF.
    IF params IS INITIAL.
      look_around( location = player->location   " Surroundings
                   result = result ).
    ELSE.
      NEW lcl_look( objects = params
                    player = player
                    actor_node = actor_node
                    engine = me
                    result = result )->execute( ).
    ENDIF.
  ENDMETHOD.

  METHOD constructor.
    me->repository = repository.
    no_exit = NEW zcl_axage_room( name = 'No Exit'
                                  descr = 'There is no exit in this direction...'
                                  " dark = abap_false
                                  " image_data = space
                                  state = space
                                  engine = me ).
    no_exit->no_exit = no_exit. " circular definition. of no_exit->no_exit not critical as the variable should not be used)
    map = NEW #( no_exit ).

    player = new_actor( name = 'PLAYER' descr = 'player name' ).
    " actors = NEW zcl_axage_actor( name = '' descr = 'AllActors' engine = me ).
    actor_node = new_node( name = 'AllActors' ).
    allowed_commands = VALUE #( ( action = 'ASK' execute = 'LCL_PICKUP' )
                                ( action = 'CAST' execute = 'LCL_CAST' )
                                ( action = 'DROP' execute = 'LCL_DROP' )
                                ( action = 'DUNK' execute = 'LCL_DUNK' )
                                ( action = 'DOWN' )
                                ( action = 'EAST' )
                                ( action = 'INVENTORY' )
                                ( action = 'LOOK' )
                                ( action = 'MAP' )
                                ( action = 'NORTH' )
                                ( action = 'OPEN' execute = 'LCL_OPEN' )
                                ( action = 'PICKUP' execute = 'LCL_PICKUP' )
                                ( action = 'SOUTH' )
                                ( action = 'SPLASH' execute = 'LCL_SPLASH' )
                                ( action = 'TAKE' execute = 'LCL_PICKUP' )
                                ( action = 'UP' )
                                ( action = 'WELD' execute = 'LCL_WELD' )
                                ( action = 'WEST' ) ).
  ENDMETHOD.

  METHOD custom_action.
    DATA lo_action TYPE REF TO lcl_action.

    executed = abap_false.
    DATA(classname) = VALUE #( allowed_commands[ action = action ]-execute OPTIONAL ).

    IF classname IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        CREATE OBJECT lo_action TYPE (classname)
          EXPORTING objects = params
                    player = player
                    actor_node = actor_node
                    engine = me
                    result = result.
        IF lo_action IS BOUND.
          lo_action->execute( ).
          executed = abap_true.
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        result->add( lx_error->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_inventory.
    DATA(your_things) = player->get_list( ).

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
          result->addtab( map->show( ) ).
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
            DATA(variant) = propose_command( token = action ).
            IF variant IS NOT INITIAL.
              result->add( |You cannot { action }. Do you want to { variant }?| ).
            ELSE.
              result->add( |You cannot { action }| ).
            ENDIF.
          ENDIF.
      ENDCASE.
    ENDIF.

    IF processed = abap_true.
      IF auto_look = abap_true.
        cmd_look( result ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD propose_command.
    TYPES: BEGIN OF distance,
             text TYPE string,
             dist TYPE i,
           END OF distance.

    DATA distances TYPE SORTED TABLE OF distance WITH NON-UNIQUE KEY dist.

    variant = space.
    DATA(len_token) = strlen( token ).
    " search Minimum
    LOOP AT allowed_commands ASSIGNING FIELD-SYMBOL(<command>).
      DATA(len_action) = strlen( <command>-action ).
      DATA(max) = COND i( WHEN len_action > len_token
                          THEN len_action
                          ELSE len_token ).
      max = ( 100 - percentage ) * max / 100 + 1.

      DATA(dist) = distance( val1 = <command>-action
                             val2 = token
                             max = max ).
      IF dist < max.
        distances = VALUE #( BASE distances
                            ( text = <command>-action dist = dist ) ).
      ENDIF.
    ENDLOOP.
    variant = VALUE #( distances[ 1 ]-text OPTIONAL ).
  ENDMETHOD.

  METHOD is_completed.
    result = mission_completed.
  ENDMETHOD.

  METHOD look_around.
    LOOP AT actor_node->get_list( ) INTO DATA(thing).
      DATA(actor) = CAST zcl_axage_actor( thing ).
      IF actor->get_location( ) = player->location.
        result->add( |There is { actor->to_text( ) }| ).
      ENDIF.
    ENDLOOP.

    IF player->location->get_list( ) IS INITIAL.
      result->add( 'There is nothing interesting to see...' ).
    ELSE.
      result->add( |You see| ).
      result->addtab( player->location->show( ) ).
    ENDIF.

    add_exits( location = player->location
               result = result ).
  ENDMETHOD.

  METHOD new_actor.
    room = NEW zcl_axage_actor( name = name
                                descr = descr
                                state = state
                                engine = me ).
  ENDMETHOD.

  METHOD new_node.
    ro_thing = new_object(
                       type = zcl_axage_thing=>c_type_node
                       name = name
                       descr = descr ).
  ENDMETHOD.

  METHOD new_object.
    ro_thing = NEW zcl_axage_thing(
                       type = type
                       engine = me
                       name = name
                       descr = descr
                       state = state
                       prefix = prefix
                       can_be_pickup = can_be_pickup
                       can_be_drop = can_be_drop
                       can_be_weld = can_be_weld
                       can_be_open = can_be_open
                       can_be_splash_into = can_be_splash_into
                       can_be_dunk_into = can_be_dunk_into ).
  ENDMETHOD.

  METHOD new_room.
    room = NEW zcl_axage_room( name = name
                               descr = descr
                               state = state
                               dark = dark
                               image_data = image_data
                               engine = me ).
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
      IF room->name = no_exit->name.
        result->add( 'you cannot go that way.' ).
      ELSE.
        player->set_location( room ).
      ENDIF.
      rv_gone = abap_true.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
