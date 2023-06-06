CLASS zcl_axage_result DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS reset.

    METHODS add
      IMPORTING
        text TYPE clike.

    METHODS insert
      IMPORTING
        text TYPE clike.

    METHODS addTab
      IMPORTING
        textTab TYPE string_table.

    METHODS get
      RETURNING
        VALUE(textString) TYPE string.

    METHODS last_message
      RETURNING
        VALUE(textString) TYPE string.

  PROTECTED SECTION.
    DATA text TYPE string_table.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_AXAGE_RESULT IMPLEMENTATION.


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


  METHOD last_message.
    CLEAR textstring.
    DATA(count) = lines( text ).
    IF count > 0.
      textstring = text[ count ].
    ENDIF.
  ENDMETHOD.


  METHOD reset.
    CLEAR text.
  ENDMETHOD.
ENDCLASS.
