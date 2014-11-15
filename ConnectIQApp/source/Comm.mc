using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application as App;
using Toybox.System as Sys;
using Toybox.Communications as Comm;

var GATHER_TEMPERATURE = 10;

var page = 0;
var size = 3;

var celsius = 1;

var strings = ["","","","","","","","","","","","","","",""];
var stringsSize = 15;
var mIndicator;
var mIndex;

var transmitCode = 0;

var temperature;

var TEMPERATURE_PAGE = 0;
var CLOCK_PAGE = 1;
var NOTIFICATIONS_PAGE = 2;

class BaseView extends Ui.View
{
 	// Inicializing the variable   
    function initialize() {
    	mIndex = 1;
    	page = 1;
        celsius = 1;

        mIndicator = new PageIndicator();
        temperature = new Temperature();
        temperature.setMin(0);
        temperature.setMax(0);
        temperature.setCurrent(0);
        temperature.setCity("");
        
        
        mIndicator.setup(size, Gfx.COLOR_DK_GRAY, Gfx.COLOR_LT_GRAY, mIndicator.ALIGN_BOTTOM_RIGHT, 0);
    	
    	Comm.setMailboxListener( method(:onMail) );       
    }
    
    function onUpdate(dc)
    {
        dc.setColor( Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK );
        dc.clear();
        dc.setColor( Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT );
		
        if( page == TEMPERATURE_PAGE )
        {
            dc.drawText(5, 20, Gfx.FONT_MEDIUM, "Temperature", Gfx.TEXT_JUSTIFY_LEFT);
            
            dc.drawText(5, 50, Gfx.FONT_SMALL, "Location: ", Gfx.TEXT_JUSTIFY_LEFT);     
            dc.drawText(70, 50, Gfx.FONT_SMALL, temperature.getCity(), Gfx.TEXT_JUSTIFY_LEFT);  
                    
            dc.drawText(5, 70,Gfx.FONT_SMALL, "Current: ", Gfx.TEXT_JUSTIFY_LEFT);           
            dc.drawText(5, 90, Gfx.FONT_SMALL, "Max: ", Gfx.TEXT_JUSTIFY_LEFT);            
            dc.drawText(5, 110, Gfx.FONT_SMALL, "Min: ", Gfx.TEXT_JUSTIFY_LEFT);

            if (celsius == 1 ) {
                
                dc.drawText(100, 70, Gfx.FONT_SMALL, " C", Gfx.TEXT_JUSTIFY_RIGHT);
                dc.drawText(75, 70, Gfx.FONT_SMALL, temperature.getCurrent().toString() , Gfx.TEXT_JUSTIFY_CENTER);
                
                dc.drawText(100, 90, Gfx.FONT_SMALL, " C", Gfx.TEXT_JUSTIFY_RIGHT);                
                dc.drawText(75, 90, Gfx.FONT_SMALL, temperature.getMax().toString() , Gfx.TEXT_JUSTIFY_CENTER);
                
                dc.drawText(100, 110, Gfx.FONT_SMALL, " C", Gfx.TEXT_JUSTIFY_RIGHT);                
                dc.drawText(75, 110, Gfx.FONT_SMALL, temperature.getMin().toString() , Gfx.TEXT_JUSTIFY_CENTER);

            } else {

                dc.drawText(100, 70, Gfx.FONT_SMALL, " F", Gfx.TEXT_JUSTIFY_RIGHT);
                dc.drawText(75, 70, Gfx.FONT_SMALL, temperature.FahrenheitToCelsius(temperature.getCurrent()).toString() , Gfx.TEXT_JUSTIFY_CENTER);
                
                dc.drawText(100, 90, Gfx.FONT_SMALL, " F", Gfx.TEXT_JUSTIFY_RIGHT);
                dc.drawText(75, 90, Gfx.FONT_SMALL, temperature.FahrenheitToCelsius(temperature.getMax()).toString()  , Gfx.TEXT_JUSTIFY_CENTER);
                
                dc.drawText(100, 110, Gfx.FONT_SMALL, " F", Gfx.TEXT_JUSTIFY_RIGHT);
                dc.drawText(75, 110, Gfx.FONT_SMALL, temperature.FahrenheitToCelsius(temperature.getMin()).toString() , Gfx.TEXT_JUSTIFY_CENTER);
            }
            

        } else if( page == CLOCK_PAGE ) {
        	dc.drawText(10, 20,  Gfx.FONT_MEDIUM, "Clock", Gfx.TEXT_JUSTIFY_LEFT);
        	
	        var clockTime = Sys.getClockTime();
	        var timeString = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min]);
	        
	        var x = dc.getWidth() / 2;
	        var y = dc.getHeight() / 2;
	        dc.drawText(x, y, Gfx.FONT_LARGE, timeString, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            var i;
            var y = 50;
			var lineBreak = 30;
			
            dc.drawText(10, 20,  Gfx.FONT_MEDIUM, "Notifications", Gfx.TEXT_JUSTIFY_LEFT);
            for( i = 0 ; i < stringsSize ; i += 1 ) {
            
            	if(strings[i].length() > lineBreak) {
            		
            		var aux = strings[i];
            		
            		while(aux.length() >= lineBreak) {
            			// Display String
                		dc.drawText(10, y,  Gfx.FONT_SMALL, aux.substring(0, lineBreak - 1), Gfx.TEXT_JUSTIFY_LEFT);
                		aux = aux.substring(lineBreak - 1, aux.length());
            			y += 20;
                	}
                	
                	if(aux.length() > 0) {
                		dc.drawText(10, y,  Gfx.FONT_SMALL, aux, Gfx.TEXT_JUSTIFY_LEFT);
            			y += 20;
                	} else {
                		y -= 20;
                	}
                	
            	} else {
            		// Display String
               		dc.drawText(10, y,  Gfx.FONT_SMALL, strings[i], Gfx.TEXT_JUSTIFY_LEFT);
               	}
                // NEw line to display
                y += 23;
            }
        }
        
        mIndicator.draw(dc, mIndex);
    }

	// Mail Iterator
    function onMail(mailIter)
    {
        var mail;

        mail = mailIter.next();

		if(transmitCode == GATHER_TEMPERATURE) {
			transmitCode = 0;
			
			var comma = mail.find("|");
			
			var city = mail.substring(0, comma);
			mail = mail.substring(comma + 1, mail.length() - 1);
			
			comma = mail.find("|");
			
			var curr = mail.substring(0, comma - 1);
			mail = mail.substring(comma + 1, mail.length() - 1);
			
			comma = mail.find("|");
			
			var min = mail.substring(0, comma - 1);
			mail = mail.substring(comma + 1, mail.length() - 1);
			
			var max = mail;
			
			temperature.setCity(city);
			temperature.setCurrent(curr.toNumber() - 273);
			temperature.setMin(min.toNumber() - 273);
			temperature.setMax(max.toNumber() - 273);
			
	        page = TEMPERATURE_PAGE;
	        mIndex = TEMPERATURE_PAGE;
			
		} else {
	        while( mail != null ) {
	            var i;
	            
	            for( i = (stringsSize - 1) ; i > 0 ; i -= 1 ) {
	                strings[i] = strings[i-1];
	            }
	            strings[0] = mail;
	            page = NOTIFICATIONS_PAGE;
	            mIndex = NOTIFICATIONS_PAGE;
	            mail = mailIter.next();
	        }
	    }

        Comm.emptyMailbox(); 
        
        Ui.requestUpdate();       
    }
}



class BaseInputDelegate extends Ui.BehaviorDelegate
{
    var cnt = 0;
    
    function onMenu() {
        var menu = new Ui.Menu();
        
        menu.addItem( "Load weather info.", :load );

        Ui.pushView( menu, new MenuInput(), SLIDE_IMMEDIATE );
    }

	function onSwipe (evt) {
	
		if(evt.getDirection() == Ui.SWIPE_LEFT) {
	    	page -= 1;
	    	mIndex -= 1;    
	    }
	    
	    if(evt.getDirection() == Ui.SWIPE_RIGHT) {
	    	page += 1;
	    	mIndex += 1;    
	    }
	    
	    if(evt.getDirection() == Ui.SWIPE_UP && page == NOTIFICATIONS_PAGE) {
    		var i;
    		
    		var aux = strings[0];
    		
    		for(i=0; i<stringsSize; i++) {
    		
    			if(i + 1 == stringsSize) {
    				strings[i] = aux; 
    				break;
    			}
    			
    			strings[i] = strings[i + 1];
    		}
	    }
	    
	    if(evt.getDirection() == Ui.SWIPE_DOWN && page == NOTIFICATIONS_PAGE) {
    		var i;
    		
    		var aux = strings[stringsSize - 1];
    		
    		for(i=stringsSize - 1; i>=0; i--) {
    			
    			if(i - 1 < 0) {
    				strings[i] = aux;
    				break;
    			}
    			
    			strings[i] = strings[i - 1];
    		}
	    }
	    
	    if(page < 0) {
	    	page = 0;
	    	mIndex = 0;
	    } else if(page > size - 1) {
	    	page = size - 1;
	    	mIndex = size - 1;
	    }
	    
	    if(page == TEMPERATURE_PAGE) {
        	var listener = new CommListener();
        	transmitCode = GATHER_TEMPERATURE;
            Comm.transmit( "load", null, listener );
	    }

        // if(evt.getDirection() == Ui.SWIPE_UP and page == TEMPERATURE_PAGE) {
        //     celsius = 1;

        // }

        // if(evt.getDirection() == Ui.SWIPE_DOWN and page == TEMPERATURE_PAGE) {
        //     celsius = 0;

        // }
        
        Ui.requestUpdate();
	}
	
    function onTap()
    {
        if (celsius == 1) {
            celsius = 0;

        } else {
            celsius = 1;
        }

    	Ui.requestUpdate();    
    }
}

class MenuInput extends Ui.MenuInputDelegate
{
    var cnt = 0;
    
    function onMenuItem(item) {

        var listener = new CommListener();

        if( item == :load ) {
        	transmitCode = GATHER_TEMPERATURE;
            Comm.transmit( "load", null, listener );
        }
    }
}

class CommListener extends Comm.ConnectionListener
{
    function onComplete() {
        Sys.println( "Transmit Complete" );
    }

    function onError() {
        Sys.println( "Transmit Failed" );
    }
}

class CommExample extends App.AppBase
{
    //! Constructor
    function initialize()
    {
    }

    function onStart()
    {
    }

    function onStop()
    {
    }

    function getInitialView()
    {
        return [ new BaseView(), new BaseInputDelegate() ];
    }
}
