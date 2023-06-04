CLASS zcl_axage_openable_thing DEFINITION
  INHERITING FROM zcl_axage_thing
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_axage_openable.
    ALIASES: open FOR zif_axage_openable~open,
             get_content FOR zif_axage_openable~get_content,
             is_open FOR zif_axage_openable~is_open.

    METHODS constructor
      IMPORTING
        name    TYPE clike
        descr   TYPE clike
        needed  TYPE REF TO zcl_axage_thing_list
        content TYPE REF TO zcl_axage_thing_list.

    DATA needed TYPE REF TO zcl_axage_thing_list.
  PROTECTED SECTION.
    DATA opened TYPE abap_bool.
    DATA content TYPE REF TO zcl_axage_thing_list.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_axage_openable_thing IMPLEMENTATION.

  METHOD constructor.
    super->constructor(
      name  = name
      descr = descr ).
    me->needed = needed.
    me->content = content.
  ENDMETHOD.

  METHOD get_content.
    IF opened = abap_true.
      content = me->content.
    ENDIF.
  ENDMETHOD.

  METHOD is_open.
    result = opened.
  ENDMETHOD.

  METHOD open.
    result = NEW #( ).
    data allowed type abap_Bool.

    LOOP AT needed->get_list( ) INTO DATA(open_with).
      IF things->exists( open_with->name ).
        allowed = abap_true.
        result->add( |The { name } is now open| ).
        me->opened = abap_true.
        EXIT. "from loop
      ENDIF.
    ENDLOOP.

    IF allowed = abap_false.
      result->add( |You have nothing the { name } can be opened with!| ).
    ENDIF.

    opened = me->opened.
  ENDMETHOD.

ENDCLASS.
