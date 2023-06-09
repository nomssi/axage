CLASS zcl_axage_actor DEFINITION INHERITING FROM zcl_axage_thing
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA location TYPE REF TO zcl_axage_room.
    DATA nameUpperCase TYPE string READ-ONLY.
    METHODS constructor
      IMPORTING
        name  TYPE clike
        state TYPE clike OPTIONAL
        descr TYPE clike
        engine TYPE REF TO zcl_axage_engine.
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



CLASS ZCL_AXAGE_ACTOR IMPLEMENTATION.


  METHOD add_sentences.
    my_sentences = sentences.
  ENDMETHOD.


  METHOD constructor.
    super->constructor( type = c_type_actor engine = engine name = name state = state descr = descr prefix = prefix ).
    nameUpperCase = to_upper( me->name ).
  ENDMETHOD.


  METHOD get_location.
    room = location.
  ENDMETHOD.


  METHOD set_location.
    location = room.
  ENDMETHOD.


  METHOD speak.
    sentences = my_sentences.
  ENDMETHOD.
ENDCLASS.
