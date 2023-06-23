CLASS ycl_axage_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_group TYPE string VALUE space.
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

    METHODS constructor IMPORTING location TYPE string.

    METHODS info_msg
      IMPORTING !title       TYPE string
                subtitle     TYPE string
                !description TYPE string.
    METHODS warning_msg
      IMPORTING !title       TYPE string
                subtitle     TYPE string
                !description TYPE string.
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
    DATA location_name TYPE string.

    METHODS add_msg
      IMPORTING !type        TYPE string
                !title       TYPE string
                subtitle     TYPE string
                !description TYPE string
                !group       TYPE string.
ENDCLASS.


CLASS ycl_axage_log IMPLEMENTATION.

  METHOD constructor.
    me->location_name = location.
  ENDMETHOD.

  METHOD add_msg.
    APPEND VALUE #( type = type
                    title = title
                    subtitle = subtitle
                    description = description
                    group = group ) TO me->t_msg.
    add( description ).
  ENDMETHOD.

  METHOD warning_msg.
    add_msg( type = 'Warning'
             title = title
             subtitle = subtitle
             description = description
             group = c_group ).
  ENDMETHOD.

  METHOD info_msg.
    add_msg( type = 'Information'
             title = title
             subtitle = subtitle
             description = description
             group = c_group ).
  ENDMETHOD.

  METHOD success_msg.
    add_msg( type = 'Success'
             title = title
             subtitle = subtitle
             description = description
             group = c_group ).
  ENDMETHOD.

  METHOD error_msg.
    add_msg( type = 'Error'
             title = title
             subtitle = subtitle
             description = description
             group = c_group ).
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
