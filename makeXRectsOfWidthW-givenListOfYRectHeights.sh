#!/bin/bash

headSVG='decs-n-root.svg'
tailSVG='tail.svg'
rectTemplate='rectXYC00.svg'
rectangleSetOut='rectSet.svg'
baseR=13
baseG=5
baseB=8
baseMultiplier=10
deltaMultiplier=2
plotWidth=720
plotHeight=405
rectSpacing=5
xStartRect=10
yStartRect=10
plotWidth=$1
plotHeight=$2
rectWidth=$3
listOfRectHeigths="$4"
slideRectsToBottomOfPlot=1
echo "Rectangle Template: $rectTemplate" 
printf 'width: %i and heigths:' "$rectWidth" 

for Y in $listOfRectHeigths;
	do
		printf ' %i' $Y
	done;

printf '\n%s\n' ''

i=0
rectSet=''
for Y in $listOfRectHeigths;
	do
		spacing=`expr $i \* $rectSpacing`
		shiftRight=`expr $i \* $rectWidth + $spacing`
		i=`expr $i + 1`
		printf ' %i' $Y
		if test $slideRectsToBottomOfPlot -eq 1;
			then
				slideDown=`expr \( $plotHeight - $Y \) - \( $yStartRect \* 2 \)`
				yTrans=$slideDown
			else
				yTrans=0
		fi;
		delta=`expr $i \* $deltaMultiplier`
		red=`expr $baseR \* $baseMultiplier`
		red=`expr $red + $delta` 
		red=`expr $red % 256`
		green=`expr $baseG \* $baseMultiplier`
		green=`expr $green + $delta`
		green=`expr $green % 256`
		blue=`expr $baseB \* $baseMultiplier`
		blue=`expr $blue + $delta`
		blue=`expr $blue % 256`
		RGB='#'"$red$green$blue" # "s/cFill/$RGB/g"
		RGB='rgb('"$red"', '"$green"', '"$blue"')'
		customRect=`sed -e "s/xStart/$xStartRect/g" -e "s/yStart/$yStartRect/g" -e "s/X/$rectWidth/g" -e "s/Y/$Y/g" -e "s/cFill/$RGB/g" -e "s/xTrans/$shiftRight/g" -e "s/yTrans/$yTrans/g" $rectTemplate`
		rectSet="$rectSet$customRect"
	done;

printf '\n%s\n' ''

svgHead=`sed -e "s/DOC_WIDTH/$plotWidth/g" -e "s/DOC_HEIGHT/$plotHeight/g" $headSVG`
svgTail=`cat $tailSVG`
printf '%s\n' "$svgHead$rectSet$svgTail" > $rectangleSetOut

chromium-browser %U $rectangleSetOut &

# ./makeXRectsOfWidthW-givenListOfYRectHeights.sh 65 "5 8 13 21 34 55 89 144 233 377"
# ./makeXRectsOfWidthW-givenListOfYRectHeights.sh 14 "10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 210 220 230 240 250 260 270 280 290 300 310 320 330 340 350 360 380"

exit 0;

