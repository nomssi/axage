class ZCL_AXAGE_REPOSITORY definition
  public
  create PUBLIC.

public section.

  interfaces IF_SERIALIZABLE_OBJECT .

  types TV_INDEX type I .
  types:
    tt_things TYPE STANDARD TABLE OF REF TO zcl_axage_thing WITH EMPTY KEY .

  data ALL_THINGS type TT_THINGS read-only .

  methods ADD
    importing
      !THING type ref to ZCL_AXAGE_THING
    returning
      value(INDEX) type TV_INDEX .
  methods AT_INDEX
    importing
      !INDEX type TV_INDEX
    returning
      value(THING) type ref to ZCL_AXAGE_THING .
ENDCLASS.



CLASS ZCL_AXAGE_REPOSITORY IMPLEMENTATION.


  METHOD ADD.
    APPEND thing TO all_things.
    index = lines( all_things ).
  ENDMETHOD.


  METHOD AT_INDEX.
    IF index GT 0.
      thing = VALUE #( all_things[ index ] OPTIONAL ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
