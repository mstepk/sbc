#!/bin/bash

headSVG='decs-n-root.svg'
tailSVG='tail.svg'
rectTemplate='rectXYC00.svg'
rectangleSetOut='rectSet.svg'

baseR=8
baseG=13
baseB=5
baseMultiplier=10
deltaMultiplier=2

defaultAspectRatio="16:9"
arMultiplier=45
#plotWidth=720
#plotHeight=405
rectSpacing=5
xStartRect=10
yStartRect=10

listOfRectHeigths="$1" # "$2" # "$4"
slideRectsToBottomOfPlot=1
useMinimumPlotDims=1

labelText='Bar Chart'
labelInverseFactor=12 # Used to dynamically determine label text size/height based on height of plot 
xLabelStart=$xStartRect
yLabelStart=$yStartRect
labelPadding=$rectSpacing
printLabel=1

if test $# -gt 1;
	then
		rectWidthInput=$2 # $1 # $3
		if test "$rectWidthInput" = '' -o "$rectWidthInput" = '0' -o "$rectWidthInput" = 'dynamic';
			then  
				dynamicWidthDeterminationBasedOnDefaultAspectRatio=1
			else
				dynamicWidthDeterminationBasedOnDefaultAspectRatio=0
				rectWidth=$rectWidthInput
		fi;
		if test $# -gt 2;
			then
				labelText="$3"
				if test "$labelText" = ''; then printLabel=0; fi; 
				if test $# -gt 3;
					then
						plotWidth=$4 # $1
						plotHeight=$5 # $2
				fi;
		fi;
	else
		dynamicWidthDeterminationBasedOnDefaultAspectRatio=1
fi;

if test $dynamicWidthDeterminationBasedOnDefaultAspectRatio -eq 1;
	then
		pi=$(echo "scale=10; 4*a(1)" | bc -l)
		arW=`printf '%s' "$defaultAspectRatio" | cut -d ':' -f 1` 
		arH=`printf '%s' "$defaultAspectRatio" | cut -d ':' -f 2`
		aspectRatioA=$(echo "$arW / $arH" | bc -l)
		aspectRatioB=$(echo "$arH / $arW" | bc -l)
fi; 


printf '\n\nRectangle Template: %s\n' "$rectTemplate" 
#printf '\nwidth: %i and heigths:' "$rectWidth" 
printf '\nRectangle Heigths:' 

minPlotWidth=`expr \( $xStartRect \* 2 \) + $rectSpacing`
minPlotHeight=`expr \( $yStartRect \* 2 \) + $rectSpacing`

maxY=0
numRects=0
for Y in $listOfRectHeigths;
	do
		numRects=`expr $numRects + 1`
		printf ' %i' $Y
		#minPlotWidth=`expr $minPlotWidth + $rectWidth + $rectSpacing`
		#printf '\n:%s:\n' ":$minPlotWidth:$rectWidth:$rectSpacing:"
		if test $Y -ge $maxY; then maxY=$Y; fi;
	done;

if test $maxY -gt 0;
	then
		minPlotHeight=`expr $maxY + \( $yStartRect \* 2 \)`
fi;

labelHeight=`expr $minPlotHeight / $labelInverseFactor`
yLabelStart=`expr $labelHeight + $labelPadding`
if test $printLabel -eq 1;
	then
		printf '\nLabel (%s) Height: %i\n' "$labelText" "$labelHeight"
		minPlotHeight=`expr $minPlotHeight + $labelHeight + \( $labelPadding \* 2 \)`
		labelDisplay='block'
	else
		labelDisplay='none'
fi;

if test $dynamicWidthDeterminationBasedOnDefaultAspectRatio -eq 1;
	then 
		minPlotWidthFloat=$(echo "$minPlotHeight * $aspectRatioA" | bc -l)
		rectWidthFloat=$(echo "( $minPlotWidthFloat - ( $xStartRect * 2 ) ) / ( $numRects * 1.2 )" | bc -l)
		rectSpacingFloat=$(echo "$rectWidthFloat * 0.2" | bc -l)
		rectWidth=`printf '%s' "$rectWidthFloat" | cut -d '.' -f 1` #`expr $rectWidthFloat + 1`
		rectSpacing=`printf '%s' "$rectSpacingFloat" | cut -d '.' -f 1` #`expr $rectSpacingFloat - 1`
		printf '\nminPlotWidthFloat (%s) and rectWidthFloat (%s) and rectSpacingFloat (%s) dynamically determined based on defaultAspectRatio (%s) and maxY (%s).\n' "$minPlotWidthFloat" "$rectWidthFloat" "$rectSpacingFloat" "$defaultAspectRatio" "$maxY"
fi;

printf '\nRectangle Widths (all equal): %i' "$rectWidth"
minPlotWidth=`expr \( \( $rectWidth + $rectSpacing \) \* $numRects \) + \( $xStartRect \* 2 \) - $rectSpacing`

if test $useMinimumPlotDims -eq 1;
	then
		plotWidth="$minPlotWidth"
		plotHeight="$minPlotHeight"
fi;

printf '\nPlot Width: %s, Plot Height: %s\n' "$plotWidth" "$plotHeight"

printf '\n%s\n' 'Building Rects/Bars ...'

i=0
rectSet=''
for Y in $listOfRectHeigths;
	do
		spacing=`expr $i \* $rectSpacing`
		shiftRight=`expr $i \* $rectWidth + $spacing`
		i=`expr $i + 1`
		printf '\n %i: Bar Height (%i)' "$i" "$Y"
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
		printf ', Bar Color => R(%i), G(%i), B(%i)' "$red" "$blue" "$green"
		RGB='rgb('"$red"', '"$green"', '"$blue"')'
		customRect=`sed -e "s/xStart/$xStartRect/g" -e "s/yStart/$yStartRect/g" -e "s/X/$rectWidth/g" -e "s/Y/$Y/g" -e "s/cFill/$RGB/g" -e "s/xTrans/$shiftRight/g" -e "s/yTrans/$yTrans/g" $rectTemplate`
		rectSet="$rectSet$customRect"
	done;

printf '\n%s\n' ''

svgHead=`sed -e "s/DOC_WIDTH/$plotWidth/g" -e "s/DOC_HEIGHT/$plotHeight/g" $headSVG`
svgTail=`sed -e "s/LABEL_TEXT/$labelText/g" -e "s/LABEL_HEIGHT/$labelHeight/g" -e "s/xLabelStart/$xLabelStart/g" -e "s/yLabelStart/$yLabelStart/g" -e "s/LABEL_PADDING/labelPadding/g" -e "s/LABEL_DISPLAY/$labelDisplay/g" $tailSVG`
printf '%s\n' "$svgHead$rectSet$svgTail" > $rectangleSetOut

chromium-browser %U $rectangleSetOut &

# ./makeXRectsOfWidthW-givenListOfYRectHeights.sh 65 "5 8 13 21 34 55 89 144 233 377"
# ./makeXRectsOfWidthW-givenListOfYRectHeights.sh 20 "10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 210 220 230 240 250 260 270 280 290 300 310 320 330 340 350 360 380"

exit 0;

