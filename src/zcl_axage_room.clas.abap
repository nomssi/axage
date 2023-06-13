CLASS zcl_axage_room DEFINITION INHERITING FROM zcl_axage_thing
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA north TYPE REF TO zcl_axage_room.
    DATA east TYPE REF TO zcl_axage_room.
    DATA south TYPE REF TO zcl_axage_room.
    DATA west TYPE REF TO zcl_axage_room.
    DATA up TYPE REF TO zcl_axage_room.
    DATA down TYPE REF TO zcl_axage_room.
    DATA no_exit TYPE REF TO zcl_axage_room.

    DATA dark TYPE abap_bool.

    METHODS get_image RETURNING VALUE(data) TYPE string.
    METHODS constructor
      IMPORTING
        name  TYPE clike
        descr TYPE clike
        state TYPE clike OPTIONAL
        dark TYPE abap_bool OPTIONAL
        image_data TYPE string OPTIONAL
        repository TYPE REF TO zcl_axage_repository
        no_exit TYPE REF TO zcl_axage_room.
    METHODS set_exits
      IMPORTING
        u TYPE REF TO zcl_axage_room OPTIONAL
        d TYPE REF TO zcl_axage_room OPTIONAL
        n TYPE REF TO zcl_axage_room OPTIONAL
        e TYPE REF TO zcl_axage_room OPTIONAL
        s TYPE REF TO zcl_axage_room OPTIONAL
        w TYPE REF TO zcl_axage_room OPTIONAL.

  PROTECTED SECTION.
    DATA image_data TYPE string.
    METHODS set_exit
      IMPORTING
        room        TYPE REF TO zcl_axage_room
      RETURNING
        VALUE(exit) TYPE REF TO zcl_axage_room.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_AXAGE_ROOM IMPLEMENTATION.

  METHOD get_image.
    IF dark EQ abap_false.
      data = image_data.
    ENDIF.
  ENDMETHOD.

  METHOD constructor.
    super->constructor( type = c_type_room
                        name = name
                        state = state
                        descr = descr
                        repository = repository
                        prefix = prefix ).
    me->dark       = dark.
    me->image_data = image_data.
    me->no_exit = no_exit.
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
ENDCLASS.
