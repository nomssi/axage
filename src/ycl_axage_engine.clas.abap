CLASS ycl_axage_engine DEFINITION INHERITING FROM ycl_axage_repository
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor.

    METHODS new_node
      IMPORTING !name           TYPE clike
                descr           TYPE clike OPTIONAL
      RETURNING VALUE(ro_thing) TYPE REF TO ycl_axage_thing.

    METHODS new_object
      IMPORTING !type              TYPE ycl_axage=>tv_type DEFAULT ycl_axage=>c_type_thing
                !name              TYPE clike
                descr              TYPE clike
                !state             TYPE clike              OPTIONAL
                prefix             TYPE string             DEFAULT ycl_axage=>c_prefix
                can_be_pickup      TYPE abap_bool          DEFAULT abap_true
                can_be_drop        TYPE abap_bool          DEFAULT abap_true
                can_be_weld        TYPE abap_bool          DEFAULT abap_false
                can_be_open        TYPE abap_bool          DEFAULT abap_false
                can_be_splashed_on TYPE abap_bool          DEFAULT abap_false
                can_be_dunked_into TYPE abap_bool          DEFAULT abap_false
                can_be_dunked      TYPE abap_bool          DEFAULT abap_true
                can_be_splashed    TYPE abap_bool          DEFAULT abap_true
                can_weld           TYPE abap_bool          DEFAULT abap_false
                !background        TYPE string             OPTIONAL
      RETURNING VALUE(ro_thing)    TYPE REF TO ycl_axage_thing.

    METHODS clone_object
      IMPORTING !name           TYPE clike
                descr           TYPE clike
      RETURNING VALUE(ro_thing) TYPE REF TO ycl_axage_thing.

    METHODS combine
      IMPORTING !action     TYPE ycl_axage=>tv_action
                object1     TYPE REF TO ycl_axage_thing
                object2     TYPE REF TO ycl_axage_thing
      EXPORTING es_mapping  TYPE ycl_axage=>ts_combine
      RETURNING VALUE(done) TYPE abap_bool.

    METHODS new_spell
      IMPORTING !name           TYPE clike
                descr           TYPE clike
                !state          TYPE clike  OPTIONAL
                prefix          TYPE string DEFAULT ycl_axage=>c_prefix
      RETURNING VALUE(ro_thing) TYPE REF TO ycl_axage_thing.

    METHODS new_room
      IMPORTING !name       TYPE clike
                descr       TYPE clike     OPTIONAL
                !state      TYPE clike     OPTIONAL
                dark        TYPE abap_bool OPTIONAL
                !background TYPE string    OPTIONAL
                cheat       TYPE string    OPTIONAL
      RETURNING VALUE(room) TYPE REF TO ycl_axage_room.

    METHODS new_actor
      IMPORTING !name        TYPE clike
                descr        TYPE clike
                !state       TYPE clike     OPTIONAL
                location     TYPE REF TO ycl_axage_room
                active       TYPE abap_bool DEFAULT abap_true
                !background  TYPE string    OPTIONAL
      RETURNING VALUE(actor) TYPE REF TO ycl_axage_actor.

    METHODS add_custom_command
      IMPORTING it_command TYPE ycl_axage=>tt_command.

    METHODS interprete
      IMPORTING !command   TYPE clike
                auto_look  TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(log) TYPE REF TO ycl_axage_log.

    METHODS is_completed
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS get_location
      RETURNING VALUE(result) TYPE string.

    DATA player            TYPE REF TO ycl_axage_actor.
    DATA map               TYPE REF TO ycl_axage_map.
    DATA actor_node        TYPE REF TO ycl_axage_thing.
    DATA no_exit           TYPE REF TO ycl_axage_room.
    DATA mission_completed TYPE abap_bool.
    DATA allowed_commands  TYPE ycl_axage=>tt_command.
    DATA combinations      TYPE ycl_axage=>tt_combine.

  PROTECTED SECTION.

    METHODS next_room IMPORTING !action       TYPE string
                      RETURNING VALUE(target) TYPE REF TO ycl_axage_room.

    METHODS parse_command IMPORTING !command TYPE string
                          EXPORTING !action  TYPE string
                                    params   TYPE string_table.

    METHODS walk_to
      IMPORTING room           TYPE REF TO ycl_axage_room
                log        TYPE REF TO ycl_axage_log
      RETURNING VALUE(rv_gone) TYPE abap_bool.

    METHODS add_help
      IMPORTING !log TYPE REF TO ycl_axage_log.

  PRIVATE SECTION.
    METHODS look_around
      IMPORTING log  TYPE REF TO ycl_axage_log
                location TYPE REF TO ycl_axage_room.

ENDCLASS.



CLASS YCL_AXAGE_ENGINE IMPLEMENTATION.


  METHOD add_custom_command.
    LOOP AT it_command INTO DATA(ls_command).
      INSERT ls_command INTO TABLE allowed_commands.
     ENDLOOP.
  ENDMETHOD.


  METHOD add_help.
    log->add( `` ).
    log->add( `Navigation Commands:` ).
    log->add( |MAP               Display the map, floor plan, or world.| ).
    log->add( |N or NORTH        Move to the room on the north side.| ).
    log->add( |E or EAST         Move to the room on the east side.| ).
    log->add( |S or SOUTH        Move to the room on the south side.| ).
    log->add( |W or WEST         Move to the room on the west side.| ).
    log->add( |U or UP           Go to the room upstairs.| ).
    log->add( |D or DOWN         Go to the room downstairs.| ).

    log->add( `` ).
    log->add( `Interaction with Objects:` ).
    log->add( |INV or INVENTORY  View everything you are carrying.| ).
    log->add( |LOOK              Describe your environment.| ).
    log->add( |LOOK <object>     Take a closer look at the object in the room or in your inventory.| ).
    log->add( |PICKUP <object>   (or TAKE) Pick up an object in the current place.| ).
    log->add( |DROP <object>     Drop an object that you are carrying.| ).
    log->add( |OPEN <object>     Open something that is in the room.| ).
    log->add( `` ).
    log->add( `Other Commands:` ).
    log->add( |ASK <person>              Request a person to tell you something.| ).
    log->add( |CAST <spell>              Utilize a spell by using its name.| ).
    log->add( |WELD <subject> <object>   Weld the subject to the object if allowed.| ).
    log->add( |DUNK <subject> <object>   Submerge the subject into the object if allowed.| ).
    log->add( |SPLASH <subject> <object> Splash the subject into the object.| ).
    log->add( `` ).
  ENDMETHOD.


  METHOD clone_object.
    ro_thing = NEW ycl_axage_thing(
                       type = ycl_axage=>c_type_thing
                       repository = me
                       name = name
                       descr = descr
                       state = space
                       prefix = `an `
                       can_be_pickup = abap_true
                       can_be_drop = abap_true
                       can_be_weld = abap_false
                       can_be_open = abap_false
                       can_be_splashed = abap_true
                       can_be_splashed_on = abap_true
                       can_be_dunked = abap_true
                       can_be_dunked_into = abap_false ).
  ENDMETHOD.

  METHOD combine.
    DATA new_object_name TYPE string.

    done = abap_false.
    CLEAR es_mapping.
    DATA(idx) = line_index( combinations[ operation = action
                                          name1 = object1->name
                                          name2 = object2->name ] ).
    IF idx EQ 0.
      idx = line_index( combinations[ operation = action
                                      name1 = object2->name
                                      name2 = object1->name ] ).
    ENDIF.

      IF idx GT 0.
        es_mapping = combinations[ idx ].
        new_object_name = es_mapping-result.
      ELSE.
        new_object_name = |{ object1->name }+{ object2->name }|.
      ENDIF.

      DATA(new_object) = clone_object( name = new_object_name
                                       descr = |created from { object1->name }+{ object2->name }| ).
      IF new_object IS BOUND.
        new_object->subject_to = object1->subject_to.
        new_object->capable_of = object1->capable_of.

        " Add new object object1+object2
        player->add( new_object ).

        done = abap_true.

      ENDIF.


  ENDMETHOD.

  METHOD constructor.
    super->constructor( ).

    no_exit = NEW ycl_axage_room( name = 'No Exit'
                                  descr = 'There is no exit in this direction...'
                                  state = space
                                  repository = me
                                  no_exit = no_exit ).
    no_exit->no_exit = no_exit. " circular definition. of no_exit->no_exit not critical as the variable should not be used)
    map = NEW #( no_exit ).

    " First create actor_node, then define actors
    actor_node = new_node( name = 'AllActors' ).

    player = new_actor( name = 'PLAYER' descr = '(you)' location = no_exit ).

    allowed_commands = ycl_axage=>standard_commands( ).
    combinations = ycl_axage=>standard_combinations( ).
  ENDMETHOD.


  METHOD get_location.
    result = player->location->name.
  ENDMETHOD.


  METHOD interprete.
    DATA processed TYPE abap_bool VALUE abap_false.

    log = NEW #( get_location( ) ).

    parse_command( EXPORTING command = command
                   IMPORTING action = DATA(action)
                             params = DATA(params) ).

    processed = walk_to( room = next_room( action )
                         log = log ).

    IF processed = abap_false.
      CASE action.

        WHEN 'HELP'.
          add_help( log ).

        WHEN 'MAP'.
          map->show( log ).
          processed = abap_true.

        WHEN OTHERS.
          processed = ycl_axage_action=>process( action = action
                                                 allowed_commands = allowed_commands
                                                 engine = me
                                                 params = params
                                                 log = log ).
      ENDCASE.
    ENDIF.

    IF processed = abap_true AND auto_look = abap_true.
      player->location->look_around( log ).
    ENDIF.
  ENDMETHOD.


  METHOD is_completed.
    result = mission_completed.
  ENDMETHOD.


  METHOD look_around.
    location->look_around( log ).
  ENDMETHOD.


  METHOD new_actor.
    actor = NEW ycl_axage_actor( name = name
                                 descr = descr
                                 state = state
                                 active = active
                                 background = background
                                 repository = me ).
    actor->set_location( location ).
    actor_node->add( actor ).
  ENDMETHOD.


  METHOD new_node.
    ro_thing = new_object(
                       type = ycl_axage_thing=>c_type_node
                       name = name
                       descr = descr ).
  ENDMETHOD.


  METHOD new_object.
    ro_thing = NEW ycl_axage_thing(
                       type = type
                       repository = me
                       name = name
                       descr = descr
                       state = state
                       prefix = prefix
                       can_weld = can_weld
                       can_be_dunked = can_be_dunked
                       can_be_splashed = can_be_splashed
                       can_be_pickup = can_be_pickup
                       can_be_drop = can_be_drop
                       can_be_weld = can_be_weld
                       can_be_open = can_be_open
                       can_be_splashed_on = can_be_splashed_on
                       can_be_dunked_into = can_be_dunked_into
                       background = background ).
  ENDMETHOD.


  METHOD new_room.
    room = NEW ycl_axage_room( name = name
                               descr = descr
                               state = state
                               dark = dark
                               background = background
                               repository = me
                               no_exit = me->no_exit
                               cheat = cheat ).
  ENDMETHOD.


  METHOD new_spell.
    ro_thing = NEW ycl_axage_castable_spell(
                   repository = me
                   name = name
                   descr = descr
                   state = state
                   prefix = prefix
                   can_be_pickup = abap_true
                   can_be_drop = abap_false
                   can_be_weld = abap_false
                   can_be_open = abap_false
                   can_be_splashed_on = abap_false
                   can_be_dunked_into = abap_false ).
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

    cmd = to_upper( condense( command ) ).

    SPLIT cmd AT space INTO action DATA(cmd2).
    SPLIT cmd2 AT space INTO TABLE params.
  ENDMETHOD.


  METHOD walk_to.
    rv_gone = abap_false.
    IF room IS BOUND.
      IF room->name = no_exit->name.
        log->add( 'you cannot go that way.' ).
      ELSE.
        player->set_location( room ).
      ENDIF.
      rv_gone = abap_true.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
