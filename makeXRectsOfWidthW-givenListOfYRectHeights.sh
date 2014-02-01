#!/bin/bash

templatesDir='sbcTemplates'
headSVG="$templatesDir"'/decs-n-root.svg'
tailSVG="$templatesDir"'/tail.svg'
rectTemplate="$templatesDir"'/rectWithLabel.svg' # 'rectXYC00.svg'

sbcInstance='rectSet_DT-STAMP.svg'
rectangleSetOut="$templatesDir"'/derivatives/'
rectangleSetOutInstance="$rectangleSetOut$sbcInstance"
derivativesCache="$rectangleSetOut"'.cache/'
derivativesCacheInstance="$derivativesCache$sbcInstance"

copyrightGPL='COPYING'

### Copyright 2014 Mark S. Kalusha (MSK) ### 
### DUAL GPLv3 or later # or Artistic # Templates can be CC-BY-SA XOR GPL #
#
# This program, and optionally the SVG template files listed above,
# under 'sbc/sbcTemplates', are free software:
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

# Bar Colors are dynamically calculated/derived from the constants below:
# Colors are RGB (Red-Green-Blue), 256 based triples for about 256^3 
baseR=8
baseG=13
baseB=5
baseMultiplier=10
deltaMultiplier=2
colorModulus=255

defaultAspectRatio="16:9"
arMultiplier=45 # Determines the scale-up factor in pixels.
# FIX-ME NOTE: The current implementation is limited to all 
# integer inputs.  This gives great resolution and scaling
# but it would require some multiplication and rounding to
# handle decimal values.
# Another way might be to use fully float arithmetic in 
# combination with controlled rounding points.

#plotWidth=720
#plotHeight=405
rectSpacing=5
xStartRect=10
yStartRect=10

slideRectsToBottomOfPlot=1
useMinimumPlotDims=1

chartLabelText='' # 'Bar Chart - Text Title'
labelInverseFactor=12 # Used to dynamically determine label text size/height based on the height of plot 
xChartLabelStart=$xStartRect
yChartLabelStart=$yStartRect
labelPadding=$rectSpacing
printChartLabel=1
workingDir=`pwd`

### Usage ###
#
# This program uses several internal variables allow making a bar chart
# with a minimum of user input.  Creating an SVG bar chart is as easy as
# calling/invoking this program with a list of integers.
#
# i.e. ./barChart "1 4 9 16 25 36 49"
# 
# Arg-1 => List of Bar Heigths #
# The 1st argument to this program is a quoted list of heigths, and is the only
# required argument.
#
# The height of the plot, the bar chart, is determined by using the maximum
# value in the list of bar/rectangle heights that is passed by the user.
#
# The width of the plot is determined using the height of plot along with the
# 'defaultAspectRatio', forcing the 'plotWidth' and 'plotHeight' to fit the
# aspect ratio.
#
# COMING SOON => If you want to label your bars just add a semi-colon and label after each
# height value in the list.  i.e. "20:A 15:B 54:C" 
# 
# Arg-2 => Bar Width or Chart Asoect Ratio #
# If a specific/known width, or a different aspect ratio, is desired then it
# can be provided by the user as the 2nd argument to this program.
# i.e. 640 or 3:2
#
# Arg-3 => Title #
# Provide a quoted string as a 3rd argument to title your chart.
#
# Arg-4 => Y-Max (Headroom) #
# By default the maximum Y value of the chart is set equal to the max height
# from the list of bar heights given in the 1st argument.  To set a higher
# value for the maximum Y, and give your chart some headroom, pass your max-Y
# as a 4th argument.

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
				chartLabelText="$3"
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

if test "$chartLabelText" = ''; then printChartLabel=0; fi; 

printf '\nTemplates (HEAD:BAR:TAIL) => (%s:%s:%s)\n' "$headSVG" "$rectTemplate" "$tailSVG" 
#printf '\nwidth: %i and heigths:' "$rectWidth" 
printf '\nRectangle/Bar Heigths:' 

minPlotWidth=`expr \( $xStartRect \* 2 \) + $rectSpacing`
minPlotHeight=`expr \( $yStartRect \* 2 \) + $rectSpacing`

maxY=0
numRects=0
barHeigths=''
barLabels=''
numLabels=0
for Y in $listOfRectHeigths;
	do
		numRects=`expr $numRects + 1`
		printf ' %s' "$Y"
		hasLabel=`printf '%s' "$Y" | grep -ce ':'`
		barHeight="$Y"
		if test $hasLabel -eq 1;
			then
				barHeight=`printf '%s' "$Y" | cut -d ':' -f 1`
				barLabel=`printf '%s' "$Y" | cut -d ':' -f 2`
				numLabels=`expr $numLabels + 1`
			else
				barLabel=''
				barHeight="$Y"
		fi;
		if test $numRects -eq 1;
			then
				barHeigths="$barHeight"
				barLabels="$barLabel"
			else
				barHeigths="$barHeigths $barHeight"
				barLabels="$barLabels $barLabel"
		fi;
		if test $barHeight -ge $maxY; then maxY=$barHeight; fi;
	done;

if test $userMaxY -ge $maxY; then maxY=$userMaxY; fi;
if test $maxY -gt 0; then minPlotHeight=`expr $maxY + \( $yStartRect \* 2 \)`; fi;

chartLabelHeight=`expr $minPlotHeight / $labelInverseFactor`
yChartLabelStart=`expr $chartLabelHeight + $labelPadding`
chartLabelDisplay='none'
barLabelHeight=`expr $minPlotHeight / $labelInverseFactor`
barLabelsDisplay='none'
barLabelsOnTop=1
if test $printChartLabel -eq 1;
	then
		printf '\nChart Label Text (%s), Chart Label Height (%i) ::: Num Bars (%i), Num Bar Labels (%i)\n' "$chartLabelText" "$chartLabelHeight" "$numRects" "$numLabels"
		chartLabelDisplay='block'
		if test $numLabels -eq 0;
			then
				minPlotHeight=`expr $minPlotHeight + $chartLabelHeight + \( $labelPadding \* 2 \)`
			else
				barLabelsDisplay='block'
				if test $barLabelsOnTop -eq 0;
					then
						minPlotHeight=`expr $minPlotHeight + $chartLabelHeight + \( $labelPadding \* 2 \) + $barLabelHeight + \( $labelPadding \* 2 \)`
					else
						minPlotHeight=`expr $minPlotHeight + $chartLabelHeight + \( $labelPadding \* 2 \)`
				fi;
		fi;
	else
		if test $numLabels -ge 1;
			then
				barLabelsDisplay='block'
				if test $barLabelsOnTop -eq 0;
					then
						minPlotHeight=`expr $minPlotHeight + $barLabelHeight + \( $labelPadding \* 2 \)`
					else
						minPlotHeight=`expr $minPlotHeight`
				fi;
		fi;
fi;
#chartLabelHeight=`expr $minPlotHeight / $labelInverseFactor`
#yChartLabelStart=`expr $chartLabelHeight + \( $labelPadding \*2 \)`

if test $dynamicWidthDeterminationBasedOnDefaultAspectRatio -eq 1;
	then 
		minPlotWidthFloat=$(echo "$minPlotHeight * $aspectRatioA" | bc -l)
		rectWidthFloat=$(echo "( $minPlotWidthFloat - ( $xStartRect * 2 ) ) / ( $numRects * 1.2 )" | bc -l)
		rectSpacingFloat=$(echo "$rectWidthFloat * 0.2" | bc -l)
		rectWidth=`printf '%s' "$rectWidthFloat" | cut -d '.' -f 1` #`expr $rectWidthFloat + 1`
		rectSpacing=`printf '%s' "$rectSpacingFloat" | cut -d '.' -f 1` #`expr $rectSpacingFloat - 1`
		printf '\nminPlotWidthFloat (%s) and rectWidthFloat (%s) and rectSpacingFloat (%s) dynamically determined based on defaultAspectRatio (%s) and maxY (%s).\n' "$minPlotWidthFloat" "$rectWidthFloat" "$rectSpacingFloat" "$defaultAspectRatio" "$maxY"
		if test "$rectSpacing" = ''; then rectSpacing=1; fi;
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
for Y in $barHeigths;
	do
		spacing=`expr $i \* $rectSpacing`
		shiftRight=`expr $i \* $rectWidth + $spacing`
		i=`expr $i + 1`
		printf '\n %i: Bar Height (%i)' "$i" "$Y"
		barLabelText=`printf '%s' "$barLabels" | cut -d ' ' -f $i`
		xBarLabelStart=`expr $xStartRect + $shiftRight + \( $rectSpacing \* 2 \)`
		if test $barLabelsOnTop -eq 1;
			then
				yBarLabelStart=`expr $plotHeight - $Y - $barLabelHeight`
			else
				yBarLabelStart=`expr $plotHeight - $barLabelHeight`
		fi;
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
		red=`expr $red % $colorModulus`
		green=`expr $baseG \* $baseMultiplier`
		green=`expr $green + $delta`
		green=`expr $green % $colorModulus`
		blue=`expr $baseB \* $baseMultiplier`
		blue=`expr $blue + $delta`
		blue=`expr $blue % $colorModulus`
		RGB='#'"$red$green$blue" # "s/cFill/$RGB/g"
		printf ', Bar Color => R(%i), G(%i), B(%i)' "$red" "$blue" "$green"
		RGB='rgb('"$red"', '"$green"', '"$blue"')'
		customRect=`sed -e "s/xStart/$xStartRect/g" -e "s/yStart/$yStartRect/g" -e "s/\"X\"/\"$rectWidth\"/g" -e "s/\"Y\"/\"$Y\"/g" -e "s/cFill/$RGB/g" -e "s/xTrans/$shiftRight/g" -e "s/yTrans/$yTrans/g" $rectTemplate` # -e "s/LABEL_DISPLAY/$barLabelsDisplay/g" $rectTemplate`
		customRect=`printf '%s\n' "$customRect" | sed -e "s/LABEL_TEXT/$barLabelText/g" -e "s/LABEL_HEIGHT/$barLabelHeight/g" -e "s/xLabelStart/$xBarLabelStart/g" -e "s/yLabelStart/$yBarLabelStart/g" -e "s/LABEL_DISPLAY/$barLabelsDisplay/g"` # -e "s/LABEL_PADDING/labelPadding/g"`
		rectSet="$rectSet$customRect"
	done;

printf '\n%s\n' ''

svgHead=`sed -e "s/SVG_DOC_WIDTH/$plotWidth/g" -e "s/SVG_DOC_HEIGHT/$plotHeight/g" -e "s/CHART_DOC_WIDTH/$plotWidth/g" -e "s/CHART_DOC_HEIGHT/$plotHeight/g" $headSVG`
svgTail=`sed -e "s/LABEL_TEXT/$chartLabelText/g" -e "s/LABEL_HEIGHT/$chartLabelHeight/g" -e "s/xLabelStart/$xChartLabelStart/g" -e "s/yLabelStart/$yChartLabelStart/g" -e "s/LABEL_PADDING/labelPadding/g" -e "s/LABEL_DISPLAY/$chartLabelDisplay/g" $tailSVG`
dtStamp=`date +%Y%m%d_%H%M_%s` # 20140129_1817_1391041044
printf '%s' "$svgHead$rectSet$svgTail" > $rectangleSetOutInstance
yourSimpleBarChart_SVG=`printf '%s' "$derivativesCacheInstance" | sed -e "s/DT-STAMP/$dtStamp/g"`

if test ! -d $workingDir/$derivativesCache; then mkdir -vp $derivativesCache; fi;
YSBC="$workingDir/$yourSimpleBarChart_SVG"
WB='chromium-browser'
WBoptsA='--app=file://'
WBoptsB='--app-window-size'
printf '\nDisplaying your SBC instance (%s) using a new browser (%s) window!\n' "$YSBC" "$WB"

cp -p $rectangleSetOutInstance $yourSimpleBarChart_SVG
$WB $WBoptsA/$YSBC $WBoptsB=$plotWidth,$plotHeight &

# ./makeXRectsOfWidthW-givenListOfYRectHeights.sh 65 "5 8 13 21 34 55 89 144 233 377"
# ./makeXRectsOfWidthW-givenListOfYRectHeights.sh 20 "10 20 30 40 50 60 70 80 90 100 110 120 130 140 150 160 170 180 190 200 210 220 230 240 250 260 270 280 290 300 310 320 330 340 350 360 380"

exit 0;

