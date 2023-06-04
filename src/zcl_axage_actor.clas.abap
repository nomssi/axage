CLASS zcl_axage_actor DEFINITION INHERITING FROM zcl_axage_thing
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA location TYPE REF TO zcl_axage_room.
    DATA things TYPE REF TO zcl_axage_thing_list.
    DATA nameUpperCase TYPE string READ-ONLY.
    METHODS constructor
      IMPORTING
        name  TYPE clike
        state TYPE clike OPTIONAL
        descr TYPE clike.
    METHODS set_location
      IMPORTING
        room TYPE REF TO zcl_axage_room.
    METHODS get_location
      RETURNING
        VALUE(room) TYPE REF TO zcl_axage_room.
    METHODS speak
      RETURNING
        VALUE(sentences) TYPE string_table.
    METHODS add_sentences
      IMPORTING
        sentences TYPE string_table.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA my_sentences TYPE string_table.
ENDCLASS.



CLASS zcl_axage_actor IMPLEMENTATION.
  METHOD constructor.
    super->constructor( name = name state = state descr = descr ).
    nameUpperCase = to_upper( me->name ).
    things = NEW #( ).
  ENDMETHOD.

  METHOD set_location.
    location = room.
  ENDMETHOD.

  METHOD get_location.
    room = location.
  ENDMETHOD.

  METHOD speak.
    sentences = my_sentences.
  ENDMETHOD.

  METHOD add_sentences.
    my_sentences = sentences.
  ENDMETHOD.
ENDCLASS.
