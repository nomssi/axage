CLASS ycl_axage_actor DEFINITION INHERITING FROM ycl_axage_thing
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA location      TYPE REF TO ycl_axage_room.
    DATA nameUpperCase TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING !name       TYPE clike
                !state      TYPE clike  OPTIONAL
                descr       TYPE clike
                active      TYPE abap_bool
                prefix      TYPE string DEFAULT c_prefix
                !background TYPE string OPTIONAL
                repository  TYPE REF TO ycl_axage_repository.

    METHODS set_location
      IMPORTING room TYPE REF TO ycl_axage_room.

    METHODS get_location
      RETURNING VALUE(room) TYPE REF TO ycl_axage_room.

    METHODS speak
      RETURNING VALUE(sentences) TYPE string_table.

    METHODS add_sentences
      IMPORTING sentences TYPE string_table.

    METHODS add_inactive_sentences
      IMPORTING sentences TYPE string_table.

  PROTECTED SECTION.
    DATA active TYPE abap_bool.
  PRIVATE SECTION.
    DATA my_info TYPE string_table.
    DATA my_status TYPE string_table.
ENDCLASS.


CLASS YCL_AXAGE_ACTOR IMPLEMENTATION.


  METHOD add_sentences.
    my_info = sentences.
  ENDMETHOD.

  METHOD add_inactive_sentences.
    my_status = sentences.
  ENDMETHOD.

  METHOD constructor.
    super->constructor( type = c_type_actor
                        repository = repository
                        name = name
                        state = state
                        descr = descr
                        prefix = prefix
                        background = background

                        can_be_pickup      = abap_false
                        can_be_drop        = abap_false

                        can_be_weld        = abap_false
                        can_be_open        = abap_false
                        can_be_dunked      = abap_false
                        can_be_dunked_into = abap_false

                        can_be_splashed    = abap_true
                        can_be_splashed_on = abap_true
                        can_weld           = abap_false ).
    me->active = active.
    nameUpperCase = to_upper( me->name ).
  ENDMETHOD.


  METHOD get_location.
    room = location.
  ENDMETHOD.


  METHOD set_location.
    location = room.
  ENDMETHOD.


  METHOD speak.
    IF active EQ abap_true.
      sentences = my_info.
    ELSE.
      sentences = my_status.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
