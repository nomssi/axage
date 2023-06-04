CLASS zcl_axage_thing DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_serializable_object.
    DATA name TYPE string.
    DATA description TYPE string.
    DATA state TYPE string.

    DATA can_be_pickup TYPE abap_bool READ-ONLY.
    DATA can_weld TYPE abap_bool READ-ONLY.
    DATA can_be_weld TYPE abap_bool READ-ONLY.
    DATA can_be_drop TYPE abap_bool READ-ONLY.
    DATA can_be_open TYPE abap_bool READ-ONLY.
    DATA can_be_splash_into TYPE abap_bool READ-ONLY.
    DATA can_be_dunk_into TYPE abap_bool READ-ONLY.

    METHODS constructor
      IMPORTING
        name  TYPE clike
        descr TYPE clike
        state TYPE clike
         can_be_pickup TYPE abap_bool DEFAULT abap_true
         can_be_drop TYPE abap_bool DEFAULT  abap_true
         can_weld TYPE abap_bool DEFAULT abap_false
         can_be_weld TYPE abap_bool DEFAULT abap_false
         can_be_open TYPE abap_bool DEFAULT abap_false
         can_be_splash_into TYPE abap_bool DEFAULT abap_false
         can_be_dunk_into TYPE abap_bool DEFAULT abap_false.

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

    me->can_be_pickup = can_be_pickup.
    me->can_be_drop = can_be_drop.

    me->can_weld = can_weld.
    me->can_be_weld  = can_be_weld.
    me->can_be_open = can_be_open.
    me->can_be_splash_into = can_be_splash_into.
    me->can_be_dunk_into = can_be_dunk_into.


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
