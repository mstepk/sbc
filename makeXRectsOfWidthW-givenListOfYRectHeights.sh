#!/bin/bash

headSVG='decs-n-root.svg'
tailSVG='tail.svg'
rectTemplate='rectXYC00.svg'
rectangleSetOut='rectSet.svg'
copyrightGPL='COPYING'

### Copyright 2014 Mark S. Kalusha (MSK) ###
#
# This program, and the SVG template files listed abive, are free software:
# you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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

slideRectsToBottomOfPlot=1
useMinimumPlotDims=1

labelText='' # 'Bar Chart - Text Title'
labelInverseFactor=12 # Used to dynamically determine label text size/height based on the height of plot 
xLabelStart=$xStartRect
yLabelStart=$yStartRect
labelPadding=$rectSpacing
printLabel=1
workingDir=`pwd`

### Usage ###
#
# This program uses several internal variables allow making a bar chart
# with a minimum of user input.  Creating an SVG bar chart is as easy as
# calling/invoking this program with a list of integers.
#
# i.e. ./barChart "1 4 9 16 25 36 42"
# 
# The 1st argument to this program is a list of heigths, and that is the only
# required argument.
#
# The height of the plot, the bar chart, is determined by using the maximum
# value in the list of bar/rectangle heights that is passed by the user.
#
# The width of the plot is determined using the height of plot along with the
# 'defaultAspectRatio', forcing the 'plotWidth' and 'plotHeight' to fit the
# aspect ratio.
#
# If a specific/known width, or a different aspect ratio, is desired then it
# can be provided by the user as the 2nd argument to this program.
# i.e. 640 or 3:2
#
# An optional 3rd argument ...

listOfRectHeigths="$1" # "$2" # "$4"
dynamicWidthDeterminationBasedOnDefaultAspectRatio=1
userMaxY=0
if test $# -gt 1;
	then
		rectWidthOrAspectRatioInput="$2" # $1 # $3
		hasColon=`printf '%s' "$rectWidthOrAspectRatioInput" | grep -ce ':'`
		if test $hasColon -eq 1;
			then
				xAspect=`printf '%s' "$rectWidthOrAspectRatioInput" | cut -d ':' -f 1`
				yAspect=`printf '%s' "$rectWidthOrAspectRatioInput" | cut -d ':' -f 2`
				defaultAspectRatio="$xAspect:$yAspect"
			else
				rectWidthInput="$rectWidthOrAspectRatioInput"
				if test "$rectWidthInput" = '' -o "$rectWidthInput" = '0' -o "$rectWidthInput" = 'dynamic';
					then  
						printf '\nDynamic rectWidth and plotWidth in effect (%s|%s)\n' "$rectWidthOrAspectRatioInput" "$defaultAspectRatio"
					else
						dynamicWidthDeterminationBasedOnDefaultAspectRatio=0
						rectWidth="$rectWidthInput"
				fi;
		fi;
		if test $# -gt 2;
			then
				labelText="$3"
				if test $# -gt 3;
					then
						userMaxY=$4
						if test $# -gt 4;
							then
								plotWidth=$5 # $1
								plotHeight=$5 # $2
						fi;
				fi;
		fi;
	else
		printf '\nSingle argument provided, dynamic rectWidth and plotWidth in effect (%s).\n' "$defaultAspectRatio"
fi;

if test $dynamicWidthDeterminationBasedOnDefaultAspectRatio -eq 1;
	then
		pi=$(echo "scale=10; 4*a(1)" | bc -l)
		arW=`printf '%s' "$defaultAspectRatio" | cut -d ':' -f 1` 
		arH=`printf '%s' "$defaultAspectRatio" | cut -d ':' -f 2`
		aspectRatioA=$(echo "$arW / $arH" | bc -l)
		aspectRatioB=$(echo "$arH / $arW" | bc -l)
fi; 

if test "$labelText" = ''; then printLabel=0; fi; 

printf '\nTemplates (HEAD:BAR:TAIL) => (%s:%s:%s)\n' "$headSVG" "$rectTemplate" "$tailSVG" 
#printf '\nwidth: %i and heigths:' "$rectWidth" 
printf '\nRectangle/Bar Heigths:' 

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

if test $userMaxY -ge $maxY; then maxY=$userMaxY; fi;
if test $maxY -gt 0; then minPlotHeight=`expr $maxY + \( $yStartRect \* 2 \)`; fi;

labelHeight=`expr $minPlotHeight / $labelInverseFactor`
yLabelStart=`expr $labelHeight + $labelPadding`
if test $printLabel -eq 1;
	then
		printf '\nLabel Text (%s), Label Height (%i)\n' "$labelText" "$labelHeight"
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

printf '\nPlot Width (%s), Plot Height (%s)\n' "$plotWidth" "$plotHeight"

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

chromium-browser --app=file:///$workingDir/$rectangleSetOut --app-window-size=$plotWidth,$plotHeight &

# ./makeXRectsOfWidthW-givenListOfYRectHeights.sh 65 "5 8 13 21 34 55 89 144 233 377"
# ./makeXRectsOfWidthW-givenListOfYRectHeights.sh 20 "10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 210 220 230 240 250 260 270 280 290 300 310 320 330 340 350 360 380"

exit 0;

