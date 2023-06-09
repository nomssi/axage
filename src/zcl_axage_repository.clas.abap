CLASS zcl_axage_repository DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    TYPES tv_index  TYPE i.
    TYPES tt_things TYPE STANDARD TABLE OF REF TO zcl_axage_thing WITH EMPTY KEY.

    DATA all_things TYPE tt_things READ-ONLY.

    METHODS add
      IMPORTING thing        TYPE REF TO zcl_axage_thing
      RETURNING VALUE(index) TYPE tv_index.

    METHODS at_index
      IMPORTING !index       TYPE tv_index
      RETURNING VALUE(thing) TYPE REF TO zcl_axage_thing.

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
