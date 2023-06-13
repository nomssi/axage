CLASS zcl_axage DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .
  PUBLIC SECTION.
    TYPES tv_type       TYPE c LENGTH 6.
    TYPES tv_index      TYPE i.
    TYPES tt_index      TYPE SORTED TABLE OF tv_index WITH UNIQUE DEFAULT KEY.
    TYPES tt_index_list TYPE STANDARD TABLE OF tt_index.

    TYPES tv_action     TYPE string.
    TYPES tt_action     TYPE SORTED TABLE OF tv_action WITH UNIQUE DEFAULT KEY.

    TYPES: BEGIN OF ts_command,
             action    TYPE tv_action,
             classname TYPE classname,
             operation TYPE string, " canonical name
           END OF ts_command.
    TYPES tt_command TYPE SORTED TABLE OF ts_command WITH UNIQUE KEY action.

    CONSTANTS c_prefix           TYPE string    VALUE `a `.
    CONSTANTS c_type_node        TYPE tv_type   VALUE 'node'.

    CONSTANTS c_type_thing       TYPE tv_type   VALUE 'thing'.
    CONSTANTS c_type_actor       TYPE tv_type   VALUE 'actor'.
    CONSTANTS c_type_room        TYPE tv_type   VALUE 'room'.
    CONSTANTS c_type_no_exit     TYPE tv_type   VALUE 'noexit'.

    CONSTANTS c_action_ask       TYPE tv_action VALUE 'ASK'.
    CONSTANTS c_action_cast      TYPE tv_action VALUE 'CAST'.
    CONSTANTS c_action_drop      TYPE tv_action VALUE 'DROP'.
    CONSTANTS c_action_dunk      TYPE tv_action VALUE 'DUNK'.
    CONSTANTS c_action_down      TYPE tv_action VALUE 'DOWN'.
    CONSTANTS c_action_east      TYPE tv_action VALUE 'EAST'.
    CONSTANTS c_action_inv       TYPE tv_action VALUE 'INVENTORY'.
    CONSTANTS c_action_inventory TYPE tv_action VALUE 'INVENTORY'.
    CONSTANTS c_action_look      TYPE tv_action VALUE 'LOOK'.
    CONSTANTS c_action_map       TYPE tv_action VALUE 'MAP'.
    CONSTANTS c_action_north     TYPE tv_action VALUE 'NORTH'.
    CONSTANTS c_action_open      TYPE tv_action VALUE 'OPEN'.
    CONSTANTS c_action_pickup    TYPE tv_action VALUE 'PICKUP'.
    CONSTANTS c_action_south     TYPE tv_action VALUE 'SOUTH'.
    CONSTANTS c_action_splash    TYPE tv_action VALUE 'SPLASH'.
    CONSTANTS c_action_take      TYPE tv_action VALUE 'TAKE'.
    CONSTANTS c_action_up        TYPE tv_action VALUE 'UP'.
    CONSTANTS c_action_weld      TYPE tv_action VALUE 'WELD'.
    CONSTANTS c_action_west      TYPE tv_action VALUE 'WEST'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_axage IMPLEMENTATION.
ENDCLASS.
