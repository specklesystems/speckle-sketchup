/*
 * Common methods for webdialogs.
 *
 * Requires jQuery
 *
 * Javascript Namespace: http://www.dustindiaz.com/namespace-your-javascript/
 * http://www.crockford.com/javascript/private.html
 */


////////////////////////////////////////////////////////////////////////////////
// Structures

function Point3d( x, y, z ) {
  this.x = x;
  this.y = y;
  this.z = z;
}
Point3d.prototype.toString = function()
{
  // (!) Format numbers
	return 'Point3d(' + this.x + ', ' + this.y + ', ' + this.z + ')';
}


function Vector3d( x, y, z ) {
  this.x = x;
  this.y = y;
  this.z = z;
}
Vector3d.prototype.toString = function()
{
  // (!) Format numbers
	return 'Vector3d(' + this.x + ', ' + this.y + ', ' + this.z + ')';
}


function Color( r, g, b, a ) {
  this.r = r;
  this.g = g;
  this.b = b;
  this.a = a;
}
Color.prototype.toString = function()
{
	return 'Color(' + this.r + ', ' + this.g + ', ' + this.b + ', ' + this.a + ')';
}


////////////////////////////////////////////////////////////////////////////////

/* Sketchup namespace */
var Sketchup = function() {
  
  // Incorrect under OSX (SU8M4). No custom SketchUp userAgent.
  var environment_regex = /SketchUp\/(\d+\.\d+)\s+\((\w+)\)/;
  var environment = environment_regex.exec( navigator.userAgent );
  
  return {
  
    /* Relay events back to the webdialog.
     */
    callback : function( controlID, event, args ) {
      if ( args === undefined ) {
        params = controlID+'||'+event;
      }
      else {
        params = controlID+'||'+event+'||'+args.join(',');
      }
      Bridge.queue_message( params )
    },
    
    version : function() {
      if ( environment == null ) {
        return null;
      } else {
        return environment[1];
      }
    },
    
    platform : function() {
      if ( environment == null ) {
        return 'OSX'; // (!) Might incorrect to assume this.
      } else {
        return environment[2]; // 'WIN'
      }
    },
    
    is_webdialog : function() {
      return environment != null;
    }
    
    
  };
  
}(); // Sketchup


/* System namespace */
var System = function() {
  
  return {
    
    font_names : function() {
      var rgFonts = new Array();
      if ( Sketchup.platform() == 'PC' ) {
        var $body = $('body');
        var $object = $('<object>');
        $object.attr('CLASSID', 'clsid:3050f819-98b5-11cf-bb82-00aa00bdce0b');
        $object.attr('width',  '0px');
        $object.attr('height', '0px');
        $body.append( $object );
        var dlgHelper = $object.get(0);
        if (dlgHelper.fonts) {
          // Extract list of font names.
          var nFontLen = dlgHelper.fonts.count;
          for ( var i = 1; i < nFontLen + 1; i++ ) {
            rgFonts.push( dlgHelper.fonts(i) );
          }
          rgFonts.sort();
        }
        // Clean up
        $object.remove();
      }
      return rgFonts;
    }
    
    
  };
  
}(); // System


if ( true ) {
  /* Console namespace */
  var Console = function() {
    return {
    
    
      /* Relay events back to the webdialog.
       */
      log : function( string ) {
        Sketchup.callback( 'Console', 'log', string );
      }
      
      
    };
    
  }(); // Console
}


/* Webdialog namespace */
var Webdialog = function() {
  return {
  
  
    /* Returns an array of the viewports' size.
     */
    get_client_size : function() {
      return [ $(window).width(), $(window).height() ];
    },
    
    /* Returns the HTML for the given UI ID.
     */
    get_checkbox_state : function( ui_id ) {
      return $('#'+ui_id+' input').prop('checked');
    },
    
    
    /* Returns the HTML for the given jQuery selector.
     */
    get_checked_state : function( selector ) {
      return $(selector).prop('checked');
    },
    
    
    /* Returns the HTML for the given jQuery selector.
     */
    get_html : function(selector) {
      return $(selector).html();
    },
    
    
    /* Returns the HTML for the given jQuery selector.
     */
    get_text : function(selector) {
      return $(selector).text();
    },

    
    /* Returns the value for the given jQuery selector.
     */
    get_value : function(selector) {
      return $(selector).val();
    },
    
    
    /* Returns the IE document mode.
     */
    documentMode : function() {
      return document.documentMode;
    },
    
    
    /* Returns the quirks mode for the document.
     */
    compatMode : function() {
      // CSS1Compat = Standard
      return document.compatMode;
    },
    
    
    userAgent : function() {
      return navigator.userAgent;
    }
    
    
  };
  
}(); // WebDialog


/* Bridge Namespace */
var Bridge = function() {

  // Due to OSX' async callback nature the messages needs to be queued up and
  // carefully sent in sequence.
  var messages = [];
  var busy = false;

  return {
    
    
    /* Escapes backslashes and single quotes.
     * (private ?)
     */
    escape_string : function( value ) {
      return value.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
    },
    
    
    /* Executes a Javascript command and returns the return value to the
     * Ruby bridge.
     */
    execute : function( code_string ) {
      // Clean up <SCRIPT></SCRIPT> elements which Ruby UI::WebDialog.execute_script
      // leaves behind.
      $('body script').detach();
      // Execute the JavaScript code and put the return value back into the bridge.
      // (!) Catch error.
      Bridge.return_ruby( eval(code_string) );
    },
    
    
    /* Send the next message in the queue to Ruby.
     */
    push_message : function() {
      if ( busy ) {
        return false;
      } else {
        message = messages.shift();
        if ( message ) {
          busy = true;
          window.location = 'skp:Event_Callback@' + message;
          return true;
        } else {
          return false;
        }
      }
    },


    /* Ruby calls this when a message has been received which means the next
     * message can be sent.
     */
    pump_message : function() {
      busy = false;
      Bridge.push_message();
      return busy;
    },


    /* Send the next message in the queue to Ruby.
     */
    queue_message : function( message ) {
      messages.push( message );
      return Bridge.push_message();
    },


    /* Resets the Ruby bridge.
     */
    reset : function() {
      $('#RUBY_bridge').val( '' );
    },
    
    
    /* Returns a Javascript object to the Ruby bridge element so that SketchUp
     * Ruby script can fetch the value.
     */
    return_ruby : function( value ) {
      $('#RUBY_bridge').val( Bridge.value_to_ruby(value) );
    },
    
    
    /* Converts Javascript objects into Ruby objects.
     *
     * TODO:
     * * JSON
     * * ...
     *
     * (private ?)
     */
    value_to_ruby : function( value ) {
      var ruby_string = '';
      switch ( $.type( value ) ) {
        case 'boolean':
          ruby_string = value.toString();
          break;
        case 'number':
          if ( isNaN( value ) ) {
            ruby_string = '0.0/0.0';
          } else if ( isFinite( value ) ) {
            ruby_string = value.toString();
          } else {
            // Infinite
            ruby_string = ( value > 0 ) ? '1.0/0.0' : '-1.0/0.0';
          }
          break;
        case 'string':
          ruby_string = "'" + Bridge.escape_string( value ) + "'";
          break;
        case 'null':
        case 'undefined':
          ruby_string = 'nil';
          break;
        case 'array':
          ruby_values = $.map(value, function(value, index) { 
            return Bridge.value_to_ruby( value );
          });
          ruby_string = '[' + ruby_values.join(',') + ']';
          break;
        case 'date':
          ruby_string = 'Time.at(' + value.getTime() + ')';
          break;
        case 'regexp':
          ruby_string = "'<REGEXP>'";
          break;
        case 'function':
          ruby_string = "'<FUNCTION>'";
          break;
        case 'object':
          // (!) JSON
          ruby_string = "'<OBJECT>'";
          break;
      }
      return ruby_string;
    }
    
    
  };
  
}(); // Bridge


/* UI namespace */
var UI = function() {
  return {
  
  
    init : function() {
      // Ruby Bridge
      bridge = $('<input id="RUBY_bridge" name="RUBY_bridge" type="hidden" />');
      $('body').append( bridge );
      // Focus property
      UI.add_focus_property();
      // URL Links
      UI.redirect_links();
      // Buttons
      $('.button').live('mousedown', control_left_button_down );
      $('.button').live('mouseup', control_left_button_up );
      // ToolbarButtons
      $('.toolbarbutton').live('mousedown', control_left_button_down );
      $('.toolbarbutton').live('mouseup', control_left_button_up );
      // Disable native browser functions to make the dialog appear more native.
      UI.disable_select();
      UI.disable_context_menu();
      // Ready Event
      window.location = 'skp:Window_Ready';
    },
    
    
    /* Toggle the content DIV of the clicked element this function is attached to.
     * Attach this event to the Click event of its sibling;
     * <div>
     *   <h2>Section Header</h2>
     *   <div>Content DIV which is toggled.</div>
     * </div>
     */
    toggle_content : function() {
      $(this).siblings('div').slideToggle('fast');
    },
    
    
    // Ensure links are opened in the default browser.
    redirect_links : function() {
      $('a.url').live('click', function()
      {
        window.location = 'skp:Open_URL@' + this.href;
        return false;
      } );
    },
    
    
    // Ensure links are opened in the default browser.
    disable_select : function() {
      $(document).on('mousedown selectstart', function(e) {
        return $(e.target).is('input, textarea, select, option');
      });
    },
    
    
    // Ensure links are opened in the default browser.
    disable_context_menu : function() {
      $(document).on('contextmenu', function(e) {
        return $(e.target).is('input[type=text], textarea');
      });
    },
    
    
    /* Loops over all input elements and ensure that they get an .focus class
     * added upon focus and remove it when it loses focus. This is a workaround
     * for IE7's lack of :hover support.
     */
    add_focus_property : function() {
      $('input').live('focusin', function () {
        $(this).addClass('focus');
      });
      $('input').live('focusout', function () {
        $(this).removeClass('focus');
      });
    },
    
    
    /* Adds a control to the window.
     */
    add_control : function(properties) {
      switch ( properties.type )
      {
      case 'TT::GUI::Button':
        UI.add_button( properties );
        return true;
      case 'TT::GUI::Checkbox':
        UI.add_checkbox( properties );
        return true;
      case 'TT::GUI::Container':
        UI.add_container( properties );
        return true;
      case 'TT::GUI::Groupbox':
        UI.add_groupbox( properties );
        return true;
      case 'TT::GUI::Label':
        UI.add_label( properties );
        return true;
      case 'TT::GUI::Listbox':
        UI.add_list( properties );
        return true;
      case 'TT::GUI::Textbox':
        UI.add_textbox( properties );
        return true;
      case 'TT::GUI::ToolbarButton':
        UI.add_toolbar_button( properties );
        return true;
      default:
        alert( 'Invalid Control Type: ' + properties.type );
        return false;
      }
    },
    
    
    /* Adds a button.
     */
    add_button : function(properties) {
      var $parent = get_parent( properties );
      var $control = $('<div class="button"></div>');
      $control.text( properties.caption );
      UI.add_event( 'click', $control );
      $control.appendTo( $parent );
      UI.update_properties( $control, properties );
    },
    
    
    /* Adds a checkbox.
     */
    add_checkbox : function( properties ) {
      var $parent = get_parent( properties );
      var $control = $('<label/>');
      var $label = $('<span/>');
      var $checkbox = $('<input type="checkbox" />');
      $checkbox.appendTo( $control );
      $label.appendTo( $control );
      // Set properties
      $checkbox.prop( 'checked', properties.checked );
      $label.text( properties.value );
      //UI.add_event( 'click', $control ); // (!) Block 'change' event on OSX.
      UI.add_event( 'change', $control, $checkbox );
      // Add to document
      $control.appendTo( $parent );
      UI.update_properties( $control, properties );
    },
    
    
    /* Adds a container.
     */
    add_container : function(properties) {
      var $parent = get_parent( properties );
      var $control = $('<div class="container"></div>');
      $control.appendTo( $parent );
      UI.update_properties( $control, properties );
    },
    
    
    /* Adds a container.
     */
    add_groupbox : function( properties ) {
      var $parent = get_parent( properties );
      var $control = $('<fieldset/>');
      var $label = $('<legend/>');
      $label.appendTo( $control );
      $label.text( properties.label );
      $control.appendTo( $parent );
      UI.update_properties( $control, properties );
    },
    
    
    /* Adds a button.
     */
    add_textbox : function( properties ) {
      var $parent = get_parent( properties );
      if ( properties.multiline ) {
        var $control = $('<textarea>');
      } else {
        var $control = $('<input type="text" />');
      }
      $control.val( properties.value );
      UI.add_event( 'change', $control );
      UI.add_event( 'keydown', $control );
      UI.add_event( 'keypress', $control );
      UI.add_event( 'keyup', $control );
      UI.add_event( 'focus', $control );
      UI.add_event( 'blur', $control );
      UI.add_event( 'copy', $control );
      UI.add_event( 'cut', $control );
      UI.add_event( 'paste', $control );
      UI.add_event( 'textchange', $control );
      $control.appendTo( $parent );
      UI.update_properties( $control, properties );
    },
    
    
    /* Adds a label.
     */
    add_label : function(properties) {
      var $parent = get_parent( properties );
      var $control = $('<label/>');
      $control.text( properties.caption );
      if ( 'control' in properties ) {
        $control.attr( 'for', properties.control );
      }
      $control.appendTo( $parent );
      UI.update_properties( $control, properties );
    },
    
    
    /* Adds a toolbar button.
     */
    add_toolbar_button : function(properties) {
      var $parent = get_parent( properties );
      var $control = $('<div class="toolbarbutton"></div>');
      if ( 'icon' in properties )
      {
        $control.attr( 'title', properties.caption );
        var $icon = $('<img />').appendTo( $control );
        $icon.attr('src', properties.icon);
        $icon.attr('alt', 'N/A');
      }
      else
      {
        $control.text( properties.caption );
      }
      UI.add_event( 'click', $control );
      $control.appendTo( $parent );
      UI.update_properties( $control, properties );
    },
    
    
    /* Adds a list.
     */
    add_list : function(properties) {
      var $parent = get_parent( properties );
      var $list = $('<select/>')
      if ( 'size' in properties ) {
        $list.attr( 'size', properties.size )
      }
      if ( 'multiple' in properties && properties.multiple ) {
        $list.prop( 'multiple', 'multiple' );
      }
      if ( 'items' in properties ) {
        var items = properties.items;
        for ( i in items ) {
          $item = $('<option/>');
          $item.text( items[i] );
          $item.val( items[i] );
          $item.appendTo( $list );
        }
      }
      $list.change( function(){
        var $this = $(this);
        var args = [ $this.val() ];
        Sketchup.callback( $list.attr( 'id' ), 'change', args );
      } );
      $list.appendTo( $parent );
      UI.update_properties( $list, properties );
    },
    
    
    /* Adds a list.
     */
    add_list_item : function(ui_id, items) {
      var $list = $('#' + ui_id);
      if ( $.isArray(items) ) {
        for ( i in items ) {
          $item = $('<option/>');
          $item.text( items[i] );
          $item.val( items[i] );
          $item.appendTo( $list );
        }
      } else {
        $item = $('<option/>');
        $item.text( items );
        $item.val( items );
        $item.appendTo( $list );
      }
      return true;
    },
    
    
    add_event : function( eventname, $control, $child ) {
      control = $child || $control
      control.on( eventname, function( event ) {
        var args = new Array();
        var $c = $(this);
        // Prevent events if control is disabled
        // (?) Find parent of any sub-control?
        if ( $c.hasClass('disabled') ) {
          event.stopPropagation();
          event.preventDefault();
          return false;
        }
        /*
        // http://api.jquery.com/category/events/event-object/
        switch ( eventname )
        {
        case 'click':
          args[0] = event.pageX;
          args[1] = event.pageY;
          break;
        }
        */
        // Defer some events to allow content to update.
        var defer_events = [ 'copy', 'cut', 'paste' ];
        if ( $.inArray( eventname, defer_events ) ) {
          setTimeout( function() {
            Sketchup.callback( $control.attr( 'id' ), eventname, args );
          }, 0 );
        } else {
          Sketchup.callback( $control.attr( 'id' ), eventname, args );
        }
        return true;
      } );
    },
    
    /* Removes a control from the window.
     */
    remove_control : function( control ) {
      var $control = get_object(control);
      $control.remove();
      return true;
    },

    /* Adds a control to the window.
     */
    update_properties : function( control, properties ) {  
      var $control = get_object( control );
      
      // Common properties
      for ( property in properties ) {
        value = properties[property];
        switch ( property )
        {
        case 'id':
          $control.attr( 'id', properties.id );
          break;
        case 'top':
          $control.css( 'position', 'absolute' );
          $control.css( 'top', properties.top );
          break;
        case 'left':
          $control.css( 'position', 'absolute' );
          $control.css( 'left', properties.left );
          break;
        case 'bottom':
          $control.css( 'position', 'absolute' );
          $control.css( 'bottom', properties.bottom );
          break;
        case 'right':
          $control.css( 'position', 'absolute' );
          $control.css( 'right', properties.right );
          break;
        case 'width':
          $control.outerWidth( properties.width );
          break;
        case 'height':
          $control.outerHeight( properties.height );
          break;
        case 'font_name':
          $control.css( 'font-family', properties.font_name );
          break;
        case 'font_size':
          $control.css( 'font-size', properties.font_size );
          break;
        case 'disabled':
          $control.toggleClass( 'disabled', properties.disabled );
          $control.prop( 'readonly', properties.disabled );
          // Disable form controls.
          $form_elements = $control.find( 'input, select, textarea, button' );
          $form_elements.prop( 'readonly', properties.disabled );
          break;
        default:
          /*alert('Invalid Control Property.')*/
          break;
        }
      }
      
      switch ( properties.type )
      {
      case 'TT::GUI::Button':
        update_button_properties( $control, properties );
        break;
      case 'TT::GUI::Checkbox':
        update_checkbox_properties( $control, properties );
        break;
      case 'TT::GUI::Groupbox':
        update_groupbox_properties( $control, properties );
        break;
      case 'TT::GUI::Label':
        update_label_properties( $control, properties );
        break;
      case 'TT::GUI::Textbox':
        update_textbox_properties( $control, properties );
        break;
      case 'TT::GUI::Listbox':
        update_listbox_properties( $control, properties );
        break;
      }
      
      return true;
    }
    
    
  };
  
  /* PRIVATE */
  
  function control_left_button_down() {
    $(this).addClass('pressed');
    return false;
  }
  
  function control_left_button_up() {
    $(this).removeClass('pressed');
    return false;
  }
  
  /* Returns the parent object.
   */
  function get_parent(properties) {
    if ( 'parent' in properties ) {
      return $( '#' + properties.parent );
    }
    else {
      return $( 'body' );
    }
  }
  
  function get_object( id_or_object ) {
    if ( $.type( id_or_object ) == 'string' ) {
      return $( '#' + id_or_object );
    }
    else {
      return id_or_object;
    }
  }
  
  function update_button_properties( $control, properties ) {
    for ( property in properties ) {
      value = properties[property];
      switch ( property )
      {
      case 'height':
        /* Set line-height to match so the text centers vertically.
         * Subtract border and padding size.
         * (!) Does not work until control is added to document.
         */
        var offset = $control.outerHeight() - $control.height();
        $control.css( 'line-height', (properties.height-offset) + 'px' );
        break;
      }
    }
    return true;
  }
  
  function update_checkbox_properties( $control, properties ) {
    $label = $control.children('span');
    $checkbox = $control.children('input');
    for ( property in properties ) {
      value = properties[property];
      switch ( property )
      {
      case 'checked':
        $checkbox.prop( 'checked', value );
        break;
      case 'label':
        $label.text( value );
        break;
      }
    }
    return true;
  }
  
  function update_groupbox_properties( $control, properties ) {
    $label = $control.children('legend');
    for ( property in properties ) {
      value = properties[property];
      switch ( property )
      {
      case 'label':
        $label.text( value );
        break;
      }
    }
    return true;
  }
  
  function update_label_properties( $control, properties ) {
    for ( property in properties ) {
      value = properties[property];
      switch ( property )
      {
      case 'caption':
        update_label_text( $control, properties );
        break;
      case 'url':
        update_label_text( $control, properties );
        break;
      }
    }
    return true;
  }
  
  function update_label_text( $control, properties ) {
    var caption = properties['caption'];
    if ( 'url' in properties ) {
      $control.empty();
      var $url = $( '<a/>' );
      $url.text( caption );
      $url.attr( 'href', properties['url'] );
      $url.addClass( 'url' );
      $url.appendTo( $control );
    } else {
      $control.text( caption );
    }
    return true;
  }
  
  function update_textbox_properties( $control, properties ) {
    for ( property in properties ) {
      value = properties[property];
      switch ( property )
      {
      case 'value':
        $control.val( value );
        break;
      }
    }
    return true;
  }
  
  function update_listbox_properties( $control, properties ) {
    for ( property in properties ) {
      value = properties[property];
      switch ( property )
      {
      case 'value':
        $control.val( value );
        break;
      }
    }
    return true;
  }
  
}(); // UI
$(document).ready( UI.init );



/*
 * Natural Sort algorithm for Javascript - Version 0.4 - Released under MIT license
 * Author: Jim Palmer (based on chunking idea from Dave Koelle)
 * Contributors: Mike Grier (mgrier.com), Clint Priest, Kyle Adams
 */
function naturalSort(a, b) {
  // setup temp-scope variables for comparison evauluation
  var re = /(^[0-9]+\.?[0-9]*[df]?e?[0-9]?$|^0x[0-9a-f]+$|[0-9]+)/gi,
    sre = /(^[ ]*|[ ]*$)/g,
    hre = /^0x[0-9a-f]+$/i,
    ore = /^0/,
    // convert all to strings and trim()
    x = a.toString().replace(sre, '') || '',
    y = b.toString().replace(sre, '') || '',
    // chunk/tokenize
    xN = x.replace(re, '\0$1\0').replace(/\0$/,'').replace(/^\0/,'').split('\0'),
    yN = y.replace(re, '\0$1\0').replace(/\0$/,'').replace(/^\0/,'').split('\0'),
    // hex or date detection
    xD = parseInt(x.match(hre)) || (new Date(x)).getTime(),
    yD = parseInt(y.match(hre)) || xD && (new Date(y)).getTime() || null;
  // natural sorting of hex or dates - prevent '1.2.3' valid date
  if ( y.indexOf('.') < 0 && yD )
    if ( xD < yD ) return -1;
    else if ( xD > yD )	return 1;
  // natural sorting through split numeric strings and default strings
  for(var cLoc=0, numS=Math.max(xN.length, yN.length); cLoc < numS; cLoc++) {
    // find floats not starting with '0', string or 0 if not defined (Clint Priest)
    oFxNcL = !(xN[cLoc] || '').match(ore) && parseFloat(xN[cLoc]) || xN[cLoc] || 0;
    oFyNcL = !(yN[cLoc] || '').match(ore) && parseFloat(yN[cLoc]) || yN[cLoc] || 0;
    // handle numeric vs string comparison - number < string - (Kyle Adams)
    if (isNaN(oFxNcL) !== isNaN(oFyNcL)) return (isNaN(oFxNcL)) ? 1 : -1; 
    // rely on string comparison if different types - i.e. '02' < 2 != '02' < '2'
    else if (typeof oFxNcL !== typeof oFyNcL) {
      oFxNcL += ''; 
      oFyNcL += ''; 
    }
    if (oFxNcL < oFyNcL) return -1;
    if (oFxNcL > oFyNcL) return 1;
  }
  return 0;
}
