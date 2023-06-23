CLASS ycl_axage_repository DEFINITION
  PUBLIC ABSTRACT
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    TYPES tt_things TYPE STANDARD TABLE OF REF TO ycl_axage_thing WITH EMPTY KEY.

    DATA all_things TYPE tt_things READ-ONLY.

    METHODS add
      IMPORTING thing        TYPE REF TO ycl_axage_thing
      RETURNING VALUE(index) TYPE ycl_axage=>tv_index.

    METHODS at_index
      IMPORTING !index       TYPE ycl_axage=>tv_index
      RETURNING VALUE(thing) TYPE REF TO ycl_axage_thing.

protected section.
private section.
ENDCLASS.



CLASS YCL_AXAGE_REPOSITORY IMPLEMENTATION.


  METHOD ADD.
    APPEND thing TO all_things.
    index = sy-tabix.
  ENDMETHOD.


  METHOD AT_INDEX.
    IF index GT 0.
      thing = VALUE #( all_things[ index ] OPTIONAL ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
