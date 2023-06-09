CLASS zcl_axage_map DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    METHODS constructor IMPORTING no_exit TYPE REF TO zcl_axage_room.
    METHODS add_room
      IMPORTING
        room TYPE REF TO zcl_axage_room.
    METHODS get_room
      IMPORTING
        name        TYPE clike
      RETURNING
        VALUE(room) TYPE REF TO zcl_axage_room.
    METHODS set_floor_plan
      IMPORTING
        input TYPE string_table.
    METHODS show
      RETURNING
        VALUE(result) TYPE string_table.
  PROTECTED SECTION.
    DATA no_exit TYPE REF TO zcl_axage_room.
    DATA rooms TYPE STANDARD TABLE OF REF TO zcl_axage_room WITH EMPTY KEY.
    DATA floor_plan TYPE string_table.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_AXAGE_MAP IMPLEMENTATION.


  METHOD add_room.
    INSERT room INTO TABLE rooms.
  ENDMETHOD.


  METHOD constructor.
    me->no_exit = no_exit.
  ENDMETHOD.


  METHOD get_room.
    room = VALUE #( rooms[ table_line->name = to_upper( name ) ] DEFAULT no_exit ).
  ENDMETHOD.


  METHOD set_floor_plan.
    me->floor_plan = input.
  ENDMETHOD.


  METHOD show.
    result = floor_plan.
  ENDMETHOD.
ENDCLASS.
