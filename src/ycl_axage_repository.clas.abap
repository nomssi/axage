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

    METHODS by_index
      IMPORTING !index       TYPE ycl_axage=>tv_index
      RETURNING VALUE(thing) TYPE REF TO ycl_axage_thing.

    METHODS by_name
      IMPORTING !name            TYPE string
                it_index         TYPE ycl_axage=>tt_index
      EXPORTING !from            TYPE REF TO ycl_axage_thing
      RETURNING VALUE(ro_object) TYPE REF TO ycl_axage_thing.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.


CLASS ycl_axage_repository IMPLEMENTATION.
  METHOD by_name.
    CLEAR ro_object.
    LOOP AT it_index INTO DATA(from_idx).
      from = by_index( from_idx ).
      IF from IS BOUND AND from->name = name.
        ro_object = from.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD add.
    APPEND thing TO all_things.
    index = sy-tabix.
  ENDMETHOD.

  METHOD by_index.
    IF index > 0.
      thing = VALUE #( all_things[ index ] OPTIONAL ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
