CLASS zcl_axage_thing DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    DATA name TYPE string.
    DATA description TYPE string.
    DATA state TYPE string.

    METHODS constructor
      IMPORTING
        name  TYPE clike
        descr TYPE clike
        state TYPE clike.

    METHODS to_text RETURNING VALUE(text) TYPE string.
    METHODS describe RETURNING VALUE(text) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_axage_thing IMPLEMENTATION.
  METHOD constructor.
    me->name = name.
    me->description = descr.
    me->state = state.
  ENDMETHOD.

  METHOD to_text.
    IF description IS INITIAL.
      text = name.
    ELSE.
      text = |{ name } { description }|.
    ENDIF.
  ENDMETHOD.

  METHOD describe.
    text = `a ` && to_text( ).
    IF state IS NOT INITIAL.
      text = text && |, { state }|.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
