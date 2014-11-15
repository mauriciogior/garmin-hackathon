using Toybox.Graphics as Gfx;

class PageIndicator {

    // fields
    hidden var mSize;
    hidden var mSelectedColor;
    hidden var mNotSelectedColor;
    hidden var mAlignment;

    function setup(size, selectedColor, notSelectedColor, alignment) {
        mSize = size;
        mSelectedColor = selectedColor;
        mNotSelectedColor = notSelectedColor;
        mAlignment = alignment;
    }

    function draw(dc, selectedIndex) {
        var height = 10;
        var width = mSize * height;
        var x = 0;
        var y = 0;

        x = dc.getWidth() - width;
        y = dc.getHeight() - height;  

        for (var i = 0 ; i < mSize ; i += 1) {
            if (i == selectedIndex) {
                dc.setColor(mSelectedColor, Gfx.COLOR_WHIE);
            } else {
                dc.setColor(mNotSelectedColor, Gfx.COLOR_BLACK);
            }

            var tempX = (x + (i * height)) + height / 2;
            dc.fillCircle(tempX, y, height / 2);
        }
    }
}
