CLASS ycl_axage_room DEFINITION INHERITING FROM ycl_axage_thing
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA north TYPE REF TO ycl_axage_room.
    DATA east TYPE REF TO ycl_axage_room.
    DATA south TYPE REF TO ycl_axage_room.
    DATA west TYPE REF TO ycl_axage_room.
    DATA up TYPE REF TO ycl_axage_room.
    DATA down TYPE REF TO ycl_axage_room.
    DATA no_exit TYPE REF TO ycl_axage_room.

    DATA dark TYPE abap_bool.
    DATA cheat TYPE string READ-ONLY.

    METHODS get_image RETURNING VALUE(data) TYPE string.
    METHODS constructor
      IMPORTING
        name  TYPE clike
        descr TYPE clike
        state TYPE clike OPTIONAL
        dark TYPE abap_bool OPTIONAL
        background TYPE string OPTIONAL
        cheat TYPE string OPTIONAL
        repository TYPE REF TO ycl_axage_repository
        no_exit TYPE REF TO ycl_axage_room.
    METHODS set_exits
      IMPORTING
        u TYPE REF TO ycl_axage_room OPTIONAL
        d TYPE REF TO ycl_axage_room OPTIONAL
        n TYPE REF TO ycl_axage_room OPTIONAL
        e TYPE REF TO ycl_axage_room OPTIONAL
        s TYPE REF TO ycl_axage_room OPTIONAL
        w TYPE REF TO ycl_axage_room OPTIONAL.

    METHODS look_around
      IMPORTING log TYPE REF TO ycl_axage_log.

  PROTECTED SECTION.
    METHODS set_exit
      IMPORTING
        room        TYPE REF TO ycl_axage_room
      RETURNING
        VALUE(exit) TYPE REF TO ycl_axage_room.

    METHODS add_exits
      RETURNING VALUE(way_out) TYPE string_table.
  PRIVATE SECTION.
ENDCLASS.

CLASS ycl_axage_room IMPLEMENTATION.

  METHOD get_image.
    IF dark EQ abap_false.
      data = background.
    ENDIF.
  ENDMETHOD.

  METHOD constructor.
    super->constructor( type = c_type_room
                        name = name
                        state = state
                        descr = descr
                        repository = repository
                        background = background
                        prefix = prefix ).
    me->dark       = dark.
    me->no_exit = no_exit.
    me->cheat = cheat.
  ENDMETHOD.


  METHOD set_exit.
    IF room IS BOUND.
      exit = room.
    ELSE.
      exit = no_exit.
    ENDIF.
  ENDMETHOD.


  METHOD set_exits.
    north = set_exit( n ).
    east  = set_exit( e ).
    south = set_exit( s ).
    west  = set_exit( w ).
    up    = set_exit( u ).
    down  = set_exit( d ).
  ENDMETHOD.

  METHOD look_around.
    DATA lt_msg TYPE string_table.

    IF dark = abap_true.
      log->warning_msg( title = 'Trying to LOOK around'
                        subtitle = name
                        description = 'You cannot see in the dark.' ).
      RETURN.
    ENDIF.

    APPEND space TO lt_msg.

    IF get_list( ) IS INITIAL.
      APPEND |You are in { describe( ) }| TO lt_msg.
    ELSE.
      APPEND |You see| TO lt_msg.

      LOOP AT index_list into DATA(idx).
        DATA(thing) = repository->all_things[ idx ].
        CHECK thing->type <> c_type_node.
        APPEND thing->describe( ) TO lt_msg.
      ENDLOOP.
    ENDIF.

    APPEND space TO lt_msg.

    APPEND LINES OF add_exits( ) TO lt_msg.

    log->success_msg( title = 'LOOK around'
                      subtitle = name
                      description = concat_lines_of( table = lt_msg sep = |\n| ) ).
  ENDMETHOD.

  METHOD add_exits.
    IF east->name <> no_exit->name.
      APPEND 'There is a door on the east side' TO way_out.
    ENDIF.
    IF west->name <> no_exit->name.
      APPEND 'There is a door on the west side' TO way_out.
    ENDIF.
    IF north->name <> no_exit->name.
      APPEND 'There is a door on the north side' TO way_out.
    ENDIF.
    IF south->name <> no_exit->name.
      APPEND 'There is a door on the south side' TO way_out.
    ENDIF.
    IF up->name <> no_exit->name.
      APPEND 'There is a ladder going upstairs' TO way_out.
    ENDIF.
    IF down->name <> no_exit->name.
      APPEND 'There is a ladder going downstairs' TO way_out.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
