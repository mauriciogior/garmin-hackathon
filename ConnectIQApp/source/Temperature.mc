using Toybox.Graphics as Gfx;

class Temperature
{
	// fields
	hidden var max;
	hidden var min;
	hidden var current;
	hidden var city;
	

	// Getters
	function getCity () {
		return city;
	}
	
	function getMax() {
		return max;
	}
	
	function getMin() {
		return min;
	}
	
	function getCurrent() {
		return current;
	}	

	// Setters
	function setMax (temperature) {
		max = temperature;
	}
	
	function setMin (temperature) {
		min = temperature;
	}
	
	function setCurrent (temperature) {
		current = temperature;
	}
	
	function setCity (newcity) {
		city = newcity;
	}
		
	// Converter
	function FahrenheitToCelsius (temperature) {
		return  ((9/5) * (temperature+32));	
	}
}
