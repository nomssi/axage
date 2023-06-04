CLASS zcl_axage_room DEFINITION INHERITING FROM zcl_axage_thing
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA north TYPE REF TO zcl_axage_room.
    DATA east TYPE REF TO zcl_axage_room.
    DATA south TYPE REF TO zcl_axage_room.
    DATA west TYPE REF TO zcl_axage_room.
    DATA up TYPE REF TO zcl_axage_room.
    DATA down TYPE REF TO zcl_axage_room.
    DATA things TYPE REF TO zcl_axage_thing_list.
    CLASS-DATA no_exit TYPE REF TO zcl_axage_room.
    CLASS-METHODS class_constructor.
    METHODS constructor
      IMPORTING
        name  TYPE clike
        descr TYPE clike.
    METHODS set_exits
      IMPORTING
        u TYPE REF TO zcl_axage_room OPTIONAL
        d TYPE REF TO zcl_axage_room OPTIONAL
        n TYPE REF TO zcl_axage_room OPTIONAL
        e TYPE REF TO zcl_axage_room OPTIONAL
        s TYPE REF TO zcl_axage_room OPTIONAL
        w TYPE REF TO zcl_axage_room OPTIONAL.
     CLASS-METHODS add_exits
       IMPORTING location TYPE REF TO zcl_axage_room
                 result TYPE REF TO zcl_axage_result.
  PROTECTED SECTION.
    METHODS set_exit
      IMPORTING
        room        TYPE REF TO zcl_axage_room
      RETURNING
        VALUE(exit) TYPE REF TO zcl_axage_room.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_axage_room IMPLEMENTATION.
  METHOD constructor.
    super->constructor( name = name descr = descr ).
    things = NEW #( ).
  ENDMETHOD.
  METHOD class_constructor.
    no_exit = NEW zcl_axage_room( name = 'No Exit'
                                  descr = 'There is no exit in this direction...' ).
  ENDMETHOD.

  METHOD set_exits.
    north = set_exit( n ).
    east  = set_exit( e ).
    south = set_exit( s ).
    west  = set_exit( w ).
    up    = set_exit( u ).
    down  = set_exit( d ).
  ENDMETHOD.

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

  METHOD set_exit.
    IF room IS BOUND.
      exit = room.
    ELSE.
      exit = no_exit.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
