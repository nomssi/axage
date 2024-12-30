CLASS ycl_axage_demo1_ui DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA command  TYPE string.
    DATA results  TYPE string.
    DATA help     TYPE string.

    DATA messages TYPE ycl_axage_log=>tt_msg.

protected section.
  PRIVATE SECTION.
    CONSTANTS c_id_command TYPE string VALUE 'id_command'.

    DATA:
      BEGIN OF app,
        client            TYPE REF TO z2ui5_if_client,
        anzahl_items      TYPE string,
        check_initialized TYPE abap_bool,
        main_view         TYPE string,
        s_get             TYPE z2ui5_if_types=>ty_s_get,
      END OF app.

    DATA bill_developer  TYPE REF TO ycl_axage_actor.
    DATA mark_consultant TYPE REF TO ycl_axage_actor.
    DATA engine          TYPE REF TO ycl_axage_engine.

    METHODS init_game.
    METHODS execute IMPORTING !command TYPE string.
ENDCLASS.



CLASS YCL_AXAGE_DEMO1_UI IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method YCL_AXAGE_DEMO1_UI->INIT_GAME
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD init_game.
    engine = NEW #( ).
    DATA(entrance)   = engine->new_room( name = 'Entrance' descr = 'You are in the entrance area. Welcome.' ).
    DATA(developer)  = engine->new_room( name = 'Developers office' descr = 'The developers area. be quiet!' ).
    DATA(consulting) = engine->new_room( name = 'Consulting Department' descr = 'This is the area where the consultants work. Bring coffee!' ).

    engine->map->add_room( entrance ).
    engine->map->add_room( developer ).
    engine->map->add_room( consulting ).
    engine->map->set_floor_plan( VALUE #(
      ( `+--------------------+ +--------------------+` )
      ( `|                    | |                    |` )
      ( `|                    | |                    |` )
      ( `|                    +-+                    |` )
      ( `|     ENTRANCE              DEVELOPERS      |` )
      ( `|                    +-+                    |` )
      ( `|                    | |                    |` )
      ( `|                    | |                    |` )
      ( `+--------+  +--------+ +--------------------+` )
      ( `         |  |` )
      ( `+--------+  +--------+` )
      ( `|                    |` )
      ( `|                    |` )
      ( `|                    |` )
      ( `|   CONSULTANTS      |` )
      ( `|                    |` )
      ( `|                    |` )
      ( `|                    |` )
      ( `+--------------------+` ) ) ).

    entrance->set_exits(
      e = developer
      s = consulting ).
    developer->set_exits(
      w = entrance ).
    consulting->set_exits(
      n = entrance ).
    DATA(cutter_knife) = engine->new_object( name = 'KNIFE' descr = 'a very sharp cutter knife' ).
    developer->add( cutter_knife ).
    DATA(needed_to_open_box) = engine->new_node( 'BoxOpener' ).
    needed_to_open_box->add( cutter_knife ).
    DATA(content_of_box) = engine->new_node( 'BoxContent' ).
    content_of_box->add( engine->new_object( name = 'RFC' descr = 'The request for change.' ) ).
    DATA(card_box) = NEW ycl_axage_openable_thing(
      name    = 'BOX'
      descr   = 'a little card box'
      content = content_of_box
      needed  = needed_to_open_box
      repository = engine ).
    consulting->add( card_box ).

    engine->player->set_location( entrance ).

    bill_developer = engine->new_actor( name = 'Bill' descr = 'An ABAP developer' location = developer ).
    bill_developer->add_sentences( VALUE #(
      ( |Hey, I am Bill, an experienced ABAP developer.| )
      ( |If you have programming tasks for me, you can pass the requirement to me| ) ) ).

    mark_consultant = engine->new_actor( name = 'Mark' descr = 'An SAP consultant' location = consulting ).
    mark_consultant->add_sentences( VALUE #(
      ( |Hello, My name is Mark and I am an SAP consultant| )
      ( |You can ask me anything about SAP processes.| ) ) ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Private Method YCL_AXAGE_DEMO1_UI->EXECUTE
* +-------------------------------------------------------------------------------------------------+
* | [--->] COMMAND                        TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD execute.
    DATA(log) = engine->interprete( command = command
                                    auto_look = abap_false ).

    IF engine->mission_completed = abap_true.

      DATA(guild) = engine->new_room( name = 'Guild'
                                      descr = 'the Wizard''s Guild'
                                      state = 'recognized as a full wizard.' ).

      engine->player->location = guild.
      log->success_msg( title = 'Mission completed'
                        subtitle = 'You did it!'
                        description = 'Congratulations! You delivered the RFC to the developers!'  ).
    ENDIF.

    messages = log->t_msg.
    results = log->get( ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method YCL_AXAGE_DEMO1_UI->Z2UI5_IF_APP~MAIN
* +-------------------------------------------------------------------------------------------------+
* | [--->] CLIENT                         TYPE REF TO Z2UI5_IF_CLIENT
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD z2ui5_if_app~main.
    app-client = client.
    app-s_get  = client->get( ).

    IF app-check_initialized = abap_false.
      app-check_initialized = abap_true.
      app-anzahl_items = '0'.

      command = 'MAP'.
      init_game( ).
      help = engine->interprete( 'HELP' )->get( ).

    ENDIF.

    CASE client->get( )-event.
      WHEN 'LOOK' OR 'INV' OR 'MAP' OR 'UP'
        OR 'DOWN' OR 'NORTH' OR 'SOUTH' OR 'EAST' OR 'WEST'
        OR 'HELP'.
        execute( client->get( )-event ).

      WHEN 'BUTTON_POST'.
        client->message_toast_display( |{ command } - send to the server| ).
        DATA(result) = engine->interprete( command ).
        result->add( |You are in the { engine->player->location->name }.| ).

        IF     engine->player->location->exists( 'RFC' )
           AND engine->player->location->name = bill_developer->location->name.
          engine->mission_completed = abap_true.
          result->add( 'Congratulations! You delivered the RFC to the developers!' ).
        ENDIF.
        results = |{ result->get( ) } \n | && results.

      WHEN 'BACK'.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).
    ENDCASE.

    DATA(view) = z2ui5_cl_xml_view=>factory( )->shell( ).

    DATA(page) = view->page(
      id             = 'id_page'
      title          = 'abap2UI5 and AXAGE - ABAP teX Adventure #1'
      navbuttonpress = client->_event( 'BACK' )
      shownavbutton  = abap_true ).


    page->header_content(
      )->toolbar(        " )->overflow_toolbar(
        )->button(
            text  = 'Look'
            press = client->_event( 'LOOK' )
            icon  = 'sap-icon://show'
        )->button(
             text = 'Map'
             press = client->_event( 'MAP' )
             icon  = 'sap-icon://map-2'
        )->button( text = 'Inventory'
                   class = 'sapUiTinyMarginBeginEnd'
                   press = client->_event( 'INV' )
                   icon = 'sap-icon://menu'
             )->get( )->custom_data(
                        )->badge_custom_data(
                            key     = 'items'
                            value   = app-anzahl_items
                            visible = abap_true
        )->get_parent( )->get_parent(
        )->button(
           text  = 'Profile'
           icon  = 'sap-icon://account'
           press = client->_event( 'POPUP_SETUP_PLAYER' )

        )->toolbar_spacer(

        )->button(
             text = 'UP'
             press = client->_event( 'UP' )
             icon  = 'sap-icon://arrow-top'
        )->button(
             text = 'DOWN'
             press = client->_event( 'DOWN' )
             icon  = 'sap-icon://arrow-bottom'
        )->button(
             text = 'North'
             press = client->_event( 'NORTH' )
             icon  = 'sap-icon://navigation-up-arrow'
        )->button(
             text = 'South'
             press = client->_event( 'SOUTH' )
             icon  = 'sap-icon://navigation-down-arrow'
        )->button(
             text = 'West'
             press = client->_event( 'WEST' )
             icon  = 'sap-icon://navigation-left-arrow'
        )->button(
             text = 'East'
             press = client->_event( 'EAST' )
             icon  = 'sap-icon://navigation-right-arrow'

        )->button(
             text = 'Help'
             press = client->_event( 'HELP' )
             icon  = 'sap-icon://sys-help'

" Ctrl+F12?
*        )->link(
*             text = 'Source_Code'
*             href = view->hlp_get_source_code_url( )
*             target = '_blank'

       )->get_parent( ).



    DATA(grid) = page->grid( 'L12 M12 S12' )->content( 'layout' ).
    grid->simple_form(
        title = 'Axage' editable = abap_true
        )->content( 'form'
            )->title( 'Game Input'
            )->label( 'Command'
            )->input( placeholder = 'enter next command'
                      submit = client->_event( 'BUTTON_POST' )
                      value =  client->_bind_edit( command )
            )->button(
                text  = 'Execute Command'
                press = client->_event( 'BUTTON_POST' ) ).

    page->grid( 'L8 M8 S8' )->content( 'layout' ).
    grid->simple_form( title = 'Game Console' editable = abap_true )->content( 'form'
        )->code_editor( value = client->_bind( results ) editable = 'false' type = `plain_text`
                      height = '600px'
        )->text_area( value = client->_bind( help ) editable = 'false' growingmaxlines = '40' growing = abap_True
                      height = '600px' ).

    client->view_display( view->stringify( ) ).
  ENDMETHOD.
ENDCLASS.
