CLASS ycl_axage DEFINITION
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
    TYPES tv_classname  TYPE c LENGTH 30.

    TYPES: BEGIN OF ts_command,
             action    TYPE tv_action,
             classname TYPE tv_classname,
             operation TYPE string, " canonical name
           END OF ts_command.
    TYPES tt_command TYPE SORTED TABLE OF ts_command WITH UNIQUE KEY action.

    TYPES tv_combine_category TYPE tv_index.
    TYPES: BEGIN OF ts_combine,
             operation TYPE string,
             name1     TYPE string,
             name2     TYPE string,
             result    TYPE string,
             category  TYPE tv_combine_category,
           END OF ts_combine.
    TYPES tt_combine TYPE SORTED TABLE OF ts_combine WITH UNIQUE KEY operation name1 name2.

    CONSTANTS c_combine_category_noop  TYPE tv_combine_category VALUE 0.
    CONSTANTS c_combine_category_merge TYPE tv_combine_category VALUE 1.
    CONSTANTS c_combine_category_into  TYPE tv_combine_category VALUE 2.
    CONSTANTS c_combine_category_on    TYPE tv_combine_category VALUE 3.

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
    CONSTANTS c_action_inv       TYPE tv_action VALUE 'INV'.
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


    CLASS-METHODS standard_commands RETURNING VALUE(rt_command) TYPE tt_command.

    CLASS-METHODS standard_combinations RETURNING VALUE(rt_kits) TYPE tt_combine.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_AXAGE IMPLEMENTATION.


  METHOD standard_combinations.
    rt_kits = VALUE #( ).
  ENDMETHOD.


  METHOD standard_commands.
    rt_command = VALUE #(   ( action = c_action_ask classname = 'LCL_ASK' )
                            ( action = c_action_cast classname = 'LCL_COMMAND' )
                            ( action = c_action_drop classname = 'LCL_DROP' )
                            ( action = c_action_dunk classname = 'LCL_DUNK' )
                            ( action = c_action_down )
                            ( action = c_action_east )
                            ( action = c_action_inv classname = 'LCL_INVENTORY' )
                            ( action = c_action_inventory classname = 'LCL_INVENTORY' )
                            ( action = c_action_look classname = 'LCL_LOOK' )
                            ( action = c_action_map )
                            ( action = c_action_north )
                            ( action = c_action_open classname = 'LCL_OPEN' )
                            ( action = c_action_pickup classname = 'LCL_PICKUP' )
                            ( action = c_action_south )
                            ( action = c_action_splash classname = 'LCL_SPLASH' )
                            ( action = c_action_take classname = 'LCL_PICKUP' operation = 'PICKUP' )
                            ( action = c_action_up )
                            ( action = c_action_weld classname = 'LCL_WELD' )
                            ( action = c_action_west ) ).
  ENDMETHOD.
ENDCLASS.
