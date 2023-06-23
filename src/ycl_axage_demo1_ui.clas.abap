class YCL_AXAGE_DEMO1_UI definition
  public
  final
  create public .

public section.

  interfaces IF_SERIALIZABLE_OBJECT .
  interfaces Z2UI5_IF_APP .

  data COMMAND type STRING .
  data RESULTS type STRING .
  data HELP type STRING .
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA bill_developer TYPE REF TO ycl_axage_actor.
    DATA mark_consultant TYPE REF TO ycl_axage_actor.
    DATA engine TYPE REF TO ycl_axage_engine.
    DATA check_initialized TYPE abap_bool.
    METHODS init_game.
ENDCLASS.



CLASS YCL_AXAGE_DEMO1_UI IMPLEMENTATION.


  METHOD INIT_GAME.
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


  METHOD Z2UI5_IF_APP~MAIN.
    IF check_initialized = abap_false.
      check_initialized = abap_true.
      command = 'MAP'.
      init_game(  ).
      help = engine->interprete( 'HELP' )->get( ).

    ENDIF.


    CASE client->get( )-event.
      WHEN 'BUTTON_POST'.
        client->popup_message_toast( |{ command } - send to the server| ).
        DATA(result) = engine->interprete( command ).
        result->add( |You are in the { engine->player->location->name }.| ).

        IF engine->player->location->exists( 'RFC' )
          AND engine->player->location->name = bill_developer->location->name.
          engine->mission_completed = abap_true.
          result->add( 'Congratulations! You delivered the RFC to the developers!' ).
        ENDIF.
        results = |{ result->get(  ) } \n | &&  results.

      WHEN 'BACK'.
        client->nav_app_leave( client->get_app( client->get( )-id_prev_app_stack  ) ).
    ENDCASE.

    DATA(view) = z2ui5_cl_xml_view=>factory( )->shell( ).
    DATA(page) = view->page(
      title          = 'abap2UI5 and AXAGE - ABAP teX Adventure #1'
      navbuttonpress = client->_event( 'BACK' )
      shownavbutton  = abap_false
    ).
    page->header_content(
         )->link(
             text = 'Source_Code'
             href = z2ui5_cl_xml_view=>hlp_get_source_code_url( app = me )
             target = '_blank'
     ).

    DATA(grid) = page->grid( 'L12 M12 S12' )->content( 'layout' ).
    grid->simple_form(
        title = 'Axage' editable = abap_true
        )->content( 'form'
            )->title( 'Game Input'
            )->label( 'Command'
            )->input( placeholder = 'enter next command'
                      submit = client->_event( 'BUTTON_POST' )
                      value =  client->_bind( command )
            )->button(
                text  = 'Execute Command'
                press = client->_event( 'BUTTON_POST' ) ).

    page->grid( 'L8 M8 S8' )->content( 'layout' ).
    grid->simple_form( title = 'Game Console' editable = abap_true )->content( 'form'
        )->code_editor( value = client->_bind( results ) editable = 'false' type = `plain_text`
                      height = '600px'
        )->text_area( value = client->_bind( help ) editable = 'false' growingmaxlines = '40' growing = abap_True
                      height = '600px'
        ).
    client->set_next( VALUE #( xml_main = page->get_root( )->xml_get( ) ) ).

  ENDMETHOD.
ENDCLASS.
