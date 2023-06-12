CLASS zcl_axage_result DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_msg,
        type        TYPE string,
        title       TYPE string,
        subtitle    TYPE string,
        description TYPE string,
        group       TYPE string,
      END OF ty_msg.
    TYPES tt_msg TYPE STANDARD TABLE OF ty_msg WITH EMPTY KEY.

    DATA t_msg TYPE tt_msg.

    METHODS success_msg
      IMPORTING !title       TYPE string
                subtitle     TYPE string
                !description TYPE string.
    METHODS error_msg
      IMPORTING !title       TYPE string
                subtitle     TYPE string
                !description TYPE string.

    METHODS add
      IMPORTING !text TYPE clike.

    METHODS insert
      IMPORTING !text TYPE clike.

    METHODS addTab
      IMPORTING textTab TYPE string_table.

    METHODS get
      RETURNING VALUE(textString) TYPE string.

  PROTECTED SECTION.
    DATA text TYPE string_table.

    METHODS add_msg
      IMPORTING !type        TYPE string
                !title       TYPE string
                subtitle     TYPE string
                !description TYPE string
                !group       TYPE string.
ENDCLASS.


CLASS zcl_axage_result IMPLEMENTATION.
  METHOD add_msg.
    APPEND VALUE #( type = type
                    title = title
                    subtitle = subtitle
                    description = description
                    group = group ) TO me->t_msg.
    add( description ).
  ENDMETHOD.

  METHOD success_msg.
    add_msg( type = 'Success'
             title = title
             subtitle = subtitle
             description = description
             group = space ).
  ENDMETHOD.

  METHOD error_msg.
    add_msg( type = 'Error'
             title = title
             subtitle = subtitle
             description = description
             group = space ).
  ENDMETHOD.

  METHOD add.
    APPEND text TO me->text.
  ENDMETHOD.

  METHOD addTab.
    APPEND LINES OF textTab TO text.
  ENDMETHOD.

  METHOD get.
    LOOP AT text REFERENCE INTO DATA(line).
      textstring &&= line->* && |\n|.
    ENDLOOP.
  ENDMETHOD.

  METHOD insert.
    INSERT text INTO me->text INDEX 1.
  ENDMETHOD.

ENDCLASS.
